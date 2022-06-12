library eth_abi_codec.abi;

import 'dart:typed_data';

import 'package:convert/convert.dart';
import 'package:pointycastle/pointycastle.dart';
import 'package:typed_data/typed_buffers.dart';
import 'package:web3_transaction_codec/src/contracts/call.dart';
import 'package:web3_transaction_codec/src/contracts/decoder.dart';
import 'package:web3_transaction_codec/src/util/formatting.dart';

class ContractInput {
  ContractInput.fromJson(Map<String, dynamic> json)
      : name = json['name'],
        _type = json['type'],
        components = List<ContractInput>.from(
          ((json['components'] ?? <dynamic>[]) as List).map<dynamic>(
            (dynamic i) => ContractInput.fromJson(i),
          ),
        );

  final String name;
  final String _type;
  final List<ContractInput> components;

  String get type {
    if (!_type.startsWith('tuple')) return _type;
    return _type.replaceFirst(
      'tuple',
      '(${components.map((i) => i.type).join(',')})',
    );
  }

  String get originType => _type;
}

class ContractOutput {
  ContractOutput.fromJson(Map<String, dynamic> json)
      : name = json['name'],
        type = json['type'];

  final String name;
  final String type;
}

class ContractAbiEntry {
  ContractAbiEntry.fromJson(Map<String, dynamic> json)
      : name = json['name'],
        type = json['type'],
        stateMutability = json['stateMutability'] as String?,
        constant = json['constant'] as bool?,
        payable = json['payable'] as bool?,
        inputs = List<ContractInput>.from(
            json['inputs'].map((dynamic i) => ContractInput.fromJson(i))),
        outputs = List<ContractOutput>.from(
            json['outputs'].map((dynamic i) => ContractOutput.fromJson(i)));

  final String name;
  final String type;
  final String? stateMutability;
  final bool? constant;
  final bool? payable;
  final List<ContractOutput> outputs;
  final List<ContractInput> inputs;

  String get paramDescription {
    final params = inputs.map((i) => i.type).join(',');
    return '($params)';
  }

  String get resultDescription {
    final results = outputs.map((i) => i.type).join(',');
    return '($results)';
  }

  Uint8List get methodBytes {
    final s = '$name$paramDescription'.codeUnits;

    return Digest('Keccak/256').process(Uint8List.fromList(s)).sublist(0, 4);
  }

  String get methodId {
    return hex.encode(methodBytes);
  }

  Map<String, dynamic> decomposeCall(Uint8List data) {
    final buffer = Uint8Buffer()..addAll(data);
    final dynamic decoded = decodeType(paramDescription, buffer);
    if ((decoded as List).length != inputs.length) {
      throw Exception(
        'Decoded param count does not match function input count',
      );
    }

    final result = <String, dynamic>{};
    for (int i = 0; i < inputs.length; i++) {
      result[inputs[i].name] = decoded[i];
    }
    return result;
  }

  Map<String, dynamic> decomposeResult(Uint8List data) {
    final buffer = Uint8Buffer()..addAll(data);
    final dynamic decoded = decodeType(resultDescription, buffer);
    if ((decoded as List).length != outputs.length) {
      throw Exception(
        'Decoded result count does not match function output count',
      );
    }

    final result = <String, dynamic>{};
    for (var i = 0; i < outputs.length; i++) {
      result[outputs[i].name] = decoded[i];
    }
    return result;
  }

  @override
  String toString() {
    return 'ContractAbiEntry{name: $name, type: $type, stateMutability: '
        '$stateMutability, constant: $constant, payable: $payable, '
        'outputs: $outputs, inputs: $inputs}';
  }
}

class ContractAbi {
  ContractAbi.fromJson(List<dynamic> json)
      : abis = List<ContractAbiEntry>.from(
          json
              // only processes functions, ignores events and constructor
              .where((dynamic i) => i['type'] == 'function')
              .map<dynamic>((dynamic i) => ContractAbiEntry.fromJson(i)),
        ) {
    for (final abi in abis) {
      methodIds[abi.methodId] = abi;
      methodNames[abi.name] = abi;
    }
  }

  final List<ContractAbiEntry> abis;
  // maps from method id to method entry
  Map methodIds = <String, ContractAbiEntry>{};
  // maps from method name to method entry
  Map methodNames = <String, ContractAbiEntry>{};

  ContractAbiEntry? getAbiEntryByMethodId(String methodId) {
    return methodIds[methodId];
  }

  ContractAbiEntry? getAbiEntryByMethodName(String methodName) {
    return methodNames[methodName];
  }

  Map<String, dynamic>? decomposeResult(String functionName, Uint8List data) {
    return getAbiEntryByMethodName(functionName)?.decomposeResult(data);
  }

  ContractCall decomposeCall(Uint8List data) {
    final methodId = bytesToHex(data.sublist(0, 4));
    final abiEntry = getAbiEntryByMethodId(methodId);

    if (abiEntry == null) {
      throw Exception(
        'Method id $methodId not found in abi, check whether input and abi'
        ' matches',
      );
    }
    final call = ContractCall(abiEntry.name);
    final params = abiEntry.decomposeCall(data.sublist(4));
    params.forEach(call.setCallParam);

    return call;
  }

  @override
  String toString() {
    return 'ContractAbi{abis: $abis, methodIds: $methodIds, methodNames: $methodNames}';
  }
}
