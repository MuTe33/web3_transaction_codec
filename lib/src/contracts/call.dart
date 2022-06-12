import 'dart:typed_data';

import 'package:web3_transaction_codec/src/contracts/abi.dart';

class ContractCall {
  ContractCall(this.functionName) : callParams = <String, dynamic>{};

  /// fromJson takes a Map<String, dynamic> as input
  ///
  ///```json
  ///{
  /// "address": "contract address",
  /// "function": "function name",
  /// "params": [
  ///   {
  ///     "name": "param name",
  ///     "value": "param value"
  ///   }
  /// ]
  ///}
  ///```
  ContractCall.fromJson(Map<String, dynamic> json)
      : functionName = json['function'],
        callParams = json['params'];

  String functionName;
  Map<String, dynamic> callParams;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'function': functionName,
        'params': callParams,
      };

  dynamic getCallParam(String paramName) => callParams[paramName];

  void setCallParam(String key, dynamic value) {
    callParams[key] = value;
  }

  /// fromBinary takes "input data" field of ethereum contract call as input
  static ContractCall fromBinary(Uint8List data, ContractAbi abi) {
    return abi.decomposeCall(data);
  }
}
