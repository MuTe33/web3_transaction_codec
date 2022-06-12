import 'dart:typed_data';

import 'package:convert/convert.dart';
import 'package:pointycastle/pointycastle.dart';

/// If present, removes the 0x from the start of a hex-string.
String strip0x(String hex) {
  if (hex.startsWith('0x')) {
    return hex.substring(2);
  }
  return hex;
}

/// If absent, appends the 0x from the start of a hex-string.
String append0x(String s) {
  if (s.startsWith('0x')) {
    return s;
  }
  return '0x$s';
}

/// Converts the hexadecimal string, which can be prefixed with 0x, to a byte
/// sequence.
Uint8List hexToBytes(String hexStr) {
  //(hexStr.length.isOdd ? '0' : '') + hexStr
  final bytes = hex.decode(strip0x(hexStr));
  if (bytes is Uint8List) return bytes;

  return Uint8List.fromList(bytes);
}

// TODO(mute33): Why do it need this
Uint8List my_hexdecode(String hexStr) {
  return hex.decode((hexStr.length.isOdd ? '0' : '') + hexStr) as Uint8List;
}

/// Converts the [bytes] given as a list of integers into a hexadecimal
/// representation.
///
/// If any of the bytes is outside of the range [0, 256], the method will throw.
/// The outcome of this function will prefix a 0 if it would otherwise not be
/// of even length. If [include0x] is set, it will prefix "0x" to the hexadecimal
/// representation. If [forcePadLength] is set, the hexadecimal representation
/// will be expanded with zeroes until the desired length is reached. The "0x"
/// prefix does not count for the length.
String bytesToHex(
  List<int> bytes, {
  bool include0x = false,
  int? forcePadLength,
  bool padToEvenLength = false,
}) {
  var encoded = hex.encode(bytes);

  if (forcePadLength != null) {
    assert(forcePadLength >= encoded.length);

    final padding = forcePadLength - encoded.length;
    encoded = ('0' * padding) + encoded;
  }

  if (padToEvenLength && encoded.length % 2 != 0) {
    encoded = '0$encoded';
  }

  return (include0x ? '0x' : '') + encoded;
}

/// convert address to checksum address
///
/// https://github.com/ethereum/EIPs/blob/master/EIPS/eip-55.md
String toChecksumAddress(String hexAddress) {
  final data = hexToBytes(hexAddress);

  final digest = Digest('Keccak/256').process(Uint8List.fromList(data));
  final hexStr = bytesToHex(digest);

  String checksumAddr = '';
  for (int i = 0; i < hexAddress.length; i++) {
    if (int.parse(hexStr[i], radix: 16) >= 8) {
      checksumAddr += hexAddress[i].toUpperCase();
    } else {
      checksumAddr += hexAddress[i];
    }
  }
  return '0x$checksumAddr';
}
