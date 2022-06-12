library eth_abi_codec.codec;

///
/// https://docs.soliditylang.org/en/v0.5.3/abi-spec.html
///
import 'dart:typed_data';

import 'package:web3_transaction_codec/src/util/formatting.dart';

/// Judge whether a type is dynamically located
/// definition: The following types are called “dynamic”:
/// bytes
/// string
/// T[] for any T
/// T[k] for any dynamic T and any k >= 0
/// (T1,...,Tk) if Ti is dynamic for some 1 <= i <= k

bool isDynamicType(String typeName) {
  if (typeName == 'bytes' || typeName == 'string') {
    return true;
  }

  final reg = RegExp(r'^([a-z\d\[\]\(\),]{1,})\[([\d]*)\]$');
  final match = reg.firstMatch(typeName);
  if (match != null) {
    final baseType = match.group(1);
    final repeatCount = match.group(2);
    if (repeatCount?.isEmpty == true) {
      return true;
    }
    // TODO(mute33): nullcheck
    return isDynamicType(baseType!);
  }

  if (typeName.endsWith(')') && typeName.startsWith('(')) {
    final subTypes = typeName.substring(1, typeName.length - 1).split(',');
    for (var i = 0; i < subTypes.length; i++) {
      if (isDynamicType(subTypes[i])) {
        return true;
      }
    }
    return false;
  }
  return false;
}

int sizeOfStaticType(String typeName) {
  final reg = RegExp(r'^([a-z\d\[\]\(\),]{1,})\[([\d]*)\]$');
  final match = reg.firstMatch(typeName);

  if (match != null) {
    final baseType = match.group(1);
    final repeatCount = match.group(2);
    // TODO(mute33): nullcheck
    assert(repeatCount != "");
    return sizeOfStaticType(baseType!) * int.parse(repeatCount!);
  }

  if (typeName.endsWith(')') && typeName.startsWith('(')) {
    final subTypes = typeName.substring(1, typeName.length - 1).split(',');
    return subTypes.fold(0,
        (previousValue, element) => previousValue + sizeOfStaticType(element));
  }

  // other static types all has capacity of 32
  return 32;
}

Uint8List padLeft(Uint8List d, int alignBytes) {
  int padLength = alignBytes - d.length % alignBytes;
  if (padLength == alignBytes) {
    padLength = 0;
  }
  final filled = List<int>.filled(padLength, 0);
  return Uint8List.fromList(Uint8List.fromList(filled) + d);
}

Uint8List padRight(Uint8List d, int alignBytes) {
  final padLength = alignBytes - d.length % alignBytes;

  final filled = List<int>.filled(padLength, 0);

  return Uint8List.fromList(d + Uint8List.fromList(filled));
}

BigInt decodeUint256(Iterable<int> b) {
  return BigInt.parse(bytesToHex(b.take(32).toList()), radix: 16);
}

BigInt decodeInt256(Iterable<int> b) {
  return BigInt.parse(bytesToHex(b.take(32).toList()), radix: 16);
}

int decodeInt(Iterable<int> b) {
  return decodeUint256(b).toInt();
}

bool decodeBool(Iterable<int> b) {
  final decoded = decodeUint256(b).toInt();

  if (decoded != 0 && decoded != 1) {
    throw Exception('invalid encoded value for bool');
  }

  return decoded == 1;
}

Uint8List decodeFixedBytes(Iterable<int> b, int length) {
  return Uint8List.fromList(b.take(length).toList());
}

Uint8List decodeBytes(Iterable<int> b) {
  final length = decodeInt(b);
  return Uint8List.fromList(b.skip(32).take(length).toList());
}

String decodeString(Iterable<int> b) {
  final length = decodeInt(b);

  return String.fromCharCodes(b.skip(32).take(length));
}

String decodeAddress(Iterable<int> b) {
  return bytesToHex(b.take(32).skip(12).toList());
}

List<dynamic> decodeList(Iterable<int> b, String type) {
  final length = decodeInt(b);
  return decodeFixedLengthList(b.skip(32), type, length);
}

List<dynamic> decodeFixedLengthList(Iterable<int> b, String type, int length) {
  final result = <dynamic>[];
  for (int i = 0; i < length; i++) {
    if (isDynamicType(type)) {
      final relocate = decodeInt(b.skip(i * 32));
      result.add(decodeType(type, b.skip(relocate)));
    } else {
      result.add(decodeType(type, b.skip(i * 32)));
    }
  }
  return result;
}

List<String> splitTypes(String typesStr) {
  if (typesStr.isEmpty) {
    return [];
  }

  int currentStart = 0;
  final subTypes = <String>[];
  final parentheses = <String>[];
  for (var i = 0; i < typesStr.length; i++) {
    final c = typesStr[i];
    switch (c) {
      case '(':
      case '[':
        parentheses.add(c);
        break;
      case ')':
        parentheses.removeLast();
        break;
      case ']':
        parentheses.removeLast();
        break;
      case ',':
        if (parentheses.isEmpty) {
          subTypes.add(typesStr.substring(currentStart, i));
          currentStart = i + 1;
        }
        break;
    }
  }

  if (currentStart < typesStr.length) {
    subTypes.add(typesStr.substring(currentStart));
  }
  return subTypes;
}

dynamic decodeType(String type, Iterable<int> b) {
  switch (type) {
    case 'string':
      return decodeString(b);
    case 'address':
      return decodeAddress(b);
    case 'bool':
      return decodeBool(b);
    case 'bytes':
      return decodeBytes(b);
    default:
      break;
  }

  final reg = RegExp(r'^([a-z\d\[\]\(\),]{1,})\[([\d]*)\]$');
  final match = reg.firstMatch(type);

  if (match != null) {
    final baseType = match.group(1);
    final repeatCount = match.group(2);

    // TODO(mute33): nullcheck
    if (repeatCount == '') {
      return decodeList(b, baseType!);
    } else {
      final repeat = int.parse(repeatCount!);
      return decodeFixedLengthList(b, baseType!, repeat);
    }
  }

  // support uint8, uint128, uint256
  if (type.startsWith('uint')) {
    return decodeUint256(b);
  }

  if (type.startsWith('int')) {
    return decodeInt256(b);
  }

  // bytes<M> 0 < M <= 32
  if (type.startsWith('bytes')) {
    final length = int.parse(type.substring(5));

    return decodeFixedBytes(b, length);
  }

  if (type.startsWith('(') && type.endsWith(')')) {
    final types = type.substring(1, type.length - 1);
    final subtypes = splitTypes(types);
    final result = <dynamic>[];

    int headerOffset = 0;
    for (var i = 0; i < subtypes.length; i++) {
      if (isDynamicType(subtypes[i])) {
        final relocate = decodeInt(b.skip(headerOffset));
        result.add(decodeType(subtypes[i], b.skip(relocate)));
        headerOffset += 32;
      } else {
        result.add(decodeType(subtypes[i], b.skip(headerOffset)));
        headerOffset += sizeOfStaticType(subtypes[i]);
      }
    }
    return result;
  }
}
