library ethereum_codec.transaction;

import 'dart:typed_data';

import 'package:convert/convert.dart';
import 'package:pointycastle/pointycastle.dart';
import 'package:web3_transaction_codec/src/contracts/call.dart';
import 'package:web3_transaction_codec/src/util/formatting.dart';

import 'contracts/contracts.dart';

class EthereumAddressHash {
  /// Fully specified constructor used by JSON deserializer.
  EthereumAddressHash(this.data) {
    if (data.length != size) throw const FormatException();
  }
  EthereumAddressHash.fromHex(String hexStr) : data = hexToBytes(hexStr);

  final Uint8List data;
  static const int size = 20;

  String get toJson => '0x${hex.encode(data)}';
  String get checksumAddress => toChecksumAddress(toJson);

  @override
  String toString() => toJson;
}

class EthereumTransactionId {
  /// Fully specified constructor used by JSON deserializer.
  EthereumTransactionId(this.data) {
    if (data.length != size) throw const FormatException();
  }

  /// Computes the hash of [transaction] - not implemented.
  EthereumTransactionId.compute(Uint8List rlpEncodedTransaction)
      : data = Digest('Keccak/256').process(rlpEncodedTransaction);

  final Uint8List data;
  static const int size = 32;

  String toJson() => '0x${hex.encode(data)}';

  /// Marshals [EthereumTransactionId] as a hex string.
  @override
  String toString() => toJson();
}

class EthereumTransaction {
  EthereumTransaction(
    this.from,
    this.to,
    this.value,
    this.gas,
    this.gasPrice,
    this.nonce, {
    required this.input,
    required this.sigR,
    required this.sigS,
    required this.sigV,
    this.chainId = 1,
  });

  factory EthereumTransaction.fromJson(Map<String, dynamic> json) {
    final sigV = int.parse(strip0x(json['v'] ?? '0x00'), radix: 16);
    final chainId = (sigV - 35) ~/ 2;

    return EthereumTransaction(
      EthereumAddressHash.fromHex(strip0x(json['from'])),
      EthereumAddressHash.fromHex(strip0x(json['to'])),
      BigInt.parse(strip0x(json['value']), radix: 16),
      int.parse(strip0x(json['gas']), radix: 16),
      int.parse(strip0x(json['gasPrice']), radix: 16),
      int.parse(strip0x(json['nonce']), radix: 16),
      input: hexToBytes(strip0x(json['input'])),
      sigR: hexToBytes(strip0x(json['r'] ?? '0x')),
      // TODO(mute33): this is uneven and needs another hexToBytes formatting
      sigS: my_hexdecode(strip0x(json['s'] ?? '0x')),
      //sigS: hexToBytes(strip0x(json['s'] ?? '0x')),
      sigV: sigV,
      chainId: chainId,
    );
  }

  /// Address of the sender.
  EthereumAddressHash? from;

  /// Address of the receiver. null when its a contract creation transaction.
  EthereumAddressHash? to;
  BigInt value;
  int gas;
  int gasPrice;
  int nonce;
  Uint8List input;
  int sigV;
  Uint8List sigR;
  Uint8List sigS;
  int chainId;

  /// Returns a dict
  /// ```json
  /// {
  ///   "name": "contract name",
  ///   "type": "contract type",
  ///   "method": "contract method",
  ///   "params": [
  ///     {
  ///       "name": "param name",
  ///       "value": "param value"
  ///     }
  ///   ]
  /// }
  /// ```
  /// if transaction does not contain a contract call, return {}
  /// if contract call target address can not be recognized, return null
  Map<String, dynamic>? getContractInfo() {
    final contractCfg = getContractConfigByAddress(to.toString());

    if (contractCfg == null) {
      if (input.isEmpty) {
        return <String, dynamic>{};
      } else {
        return null;
      }
    }

    final abi = getContractAbiByType(contractCfg.type);

    if (abi == null) {
      return null;
    }

    final callInfo = ContractCall.fromBinary(input, abi);

    return <String, dynamic>{
      'symbol': contractCfg.symbol,
      'type': contractCfg.type,
      'contract_params': contractCfg.params,
      'method': callInfo.functionName,
      'params': callInfo.callParams
    };
  }
}
