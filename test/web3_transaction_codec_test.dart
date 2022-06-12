import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart';
import 'package:web3_transaction_codec/src/contracts/contracts.dart';
import 'package:web3_transaction_codec/src/transaction.dart';
import 'package:web3dart/web3dart.dart';

void main() {
  HttpOverrides.global = _MyHttpOverrides();

  test('100% code coverage', () async {
    final client = Web3Client(
      'https://eth-mainnet.alchemyapi.io/v2/<YOUR API KEY>',
      Client(),
    );

    // USDC transfer
    const txHash =
        '0x5485536184d9cce80383202eebc9b3d3c966646d6e111574cdb2e4a868621534';

    // NFT sale on OpenSea
    // const txHash =
    //  '0xd07b7fbda819b8d7cd67005d9c7cfae1e95a0c674566c79c791573a8ad1c7afb';

    // modify web3dart package for testing purposes to receive this as raw json
    // since I get [EthereumTransaction] from a JSON or change converting in
    // line 35
    final tx = await client.getTransactionByHash(txHash);
    final contractJson = contractAbiToJson();

    initContractAbisFromJson(contractJson);

    final ethTx = EthereumTransaction.fromJson(tx);

    print('tx value: ${ethTx.value}');
    print('tx to: ${ethTx.to}');
    print('tx gas: ${ethTx.gas}');
    print('tx gas price: ${ethTx.gasPrice}');

    final contract = ethTx.getContractInfo();

    if (contract != null) {
      // it's a contract call
      print('contract symbol: ${contract['symbol']}');
      print('contract type: ${contract['type']}');
      print('contract method: ${contract['method']}');
      print('contract configs: ${contract['contract_params']}');
      print('contract params: ${contract['params']}');
    }

    /* print(
      '<--------- This is only for Opensea buy/sell further decoding ----- >',
    );
    print('<--------- Not needed for a simple transfer ----- >');

    final addrs = contract['params']['addrs'];
    final uints = contract['params']['uints'];

    final recipient = '0x' + addrs[1].toString();

    String? type;
    if (ethTx.from.toString().contains(addrs[1])) {
      type = 'Buy';
    } else if (ethTx.from.toString().contains(addrs[8])) {
      type = 'Sell';
    }

    if (type == null) {
      return ParsedResult(recipient, []);
    }

    final exchangeTokenAddr = addrs[13].toString();
    final amount = uints[13].toString();

    String? symbol = 'ETH';
    int decimal = 18;
    if (exchangeTokenAddr != '0000000000000000000000000000000000000000') {
      final exchangeToken = await getTokenInfo(exchangeTokenAddr, true);
      symbol = exchangeToken?.symbol;
      decimal = exchangeToken?.params['decimal'];
    }

    final a = ParsedResult(recipient, [
      type,
      amount.toString(),
      symbol,
    ]);

    print(a);*/
  });
}

class _MyHttpOverrides extends HttpOverrides {}

Map<String, dynamic> contractAbiToJson() {
  final result = <String, dynamic>{};
  final abis = <dynamic>[];

  final symbolFile = File('lib/src/data/contract_symbols.json');
  final symbols = symbolFile.readAsStringSync();
  result['contracts'] = jsonDecode(symbols);

  (result['contracts'] as List)
      .map<dynamic>((dynamic i) => i['type'])
      .toSet()
      .toList()
      .forEach(
    (dynamic element) {
      final abiFile = File('lib/src/data/contract_abi/$element.json');

      abis.add(
        <String, dynamic>{
          'type': element,
          'abi': jsonDecode(abiFile.readAsStringSync())
        },
      );
    },
  );

  result['abis'] = abis;

  return result;
}

class ParsedResult {
  ParsedResult(this.recipient, this.args);

  final String recipient;
  final List<String?> args;

  @override
  String toString() {
    return 'ParsedResult{recipient: $recipient, args: $args}';
  }
}

/*
Future<ContractConfig?> getTokenInfo(String addr,
    [bool allowUnsafe = false]) async {
  final token = getContractConfigByAddress(addr);
  if (token != null) {
    return token;
  }

  if (!allowUnsafe) {
    return null;
  }

  // Either you have the ERC20 contract saved to assets and you can read it or
  // you need to call a node to receive dynamically the contract to get symbol
  // and decimal
  //
  // But this is not ported, you need to modify it yourself
  // This is what you need when you make RPC calls
  // https://github.com/nbltrust/dart-eth-transaction-codec/blob/main/lib/src/rpc.dart
  try {
    final props = await ETHRpc.instance().getERC20Config(addr);
    return ContractConfig(
      addr,
      props[1],
      'ERC20',
      {'decimal': props[2].toString()},
    );
  } catch (e) {
    return null;
  }
}
*/
