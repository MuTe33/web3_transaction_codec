import 'package:convert/convert.dart';
import 'package:web3_transaction_codec/src/contracts/abi.dart';
import 'package:web3_transaction_codec/src/contracts/model/contract_config.dart';
import 'package:web3_transaction_codec/src/util/formatting.dart';

class AddressConfig {
  AddressConfig.fromJson(Map<String, dynamic> json, [int chainId = 0]) {
    abis = Map<String, ContractAbi>();
    json['abis'].forEach((dynamic abi) {
      abis[abi['type']] = ContractAbi.fromJson(abi['abi']);
    });

    final configs = List<ContractConfig>.from(
      (json['contracts'] as List)
          .map<dynamic>((dynamic i) => ContractConfig.fromJson(i)),
    );

    configsMap = <String, List<ContractConfig>>{};
    configsMap['chainId:$chainId'] = configs;
  }

  Map configsMap = <String, List<ContractConfig>>{};
  // maps from type to abi, e.g. 'ERC20' => abi
  Map abis = <String, ContractAbi>{};

  void append(List<dynamic> configs, [int chainId = 0]) {
    final dynamic old = configsMap['chainId:$chainId'];

    if (old == null) {
      configsMap['chainId:$chainId'] = List<ContractConfig>.from(
        configs.map<dynamic>((dynamic i) => ContractConfig.fromJson(i)),
      );

      return;
    }

    configsMap['chainId:$chainId']?.addAll(
      List<ContractConfig>.from(
        configs.map<dynamic>((dynamic i) => ContractConfig.fromJson(i)),
      ),
    );
  }

  ContractConfig? getContractConfigByAddress(
    String address, [
    int chainId = 0,
  ]) {
    var addr = address.toLowerCase();

    if (!addr.startsWith('0x')) {
      try {
        hex.decode(addr);

        addr = append0x(addr);
      } catch (e) {
        //
      }
    }

    // TODO(mute33): null value
    return configsMap['chainId:$chainId'].firstWhere(
      (dynamic element) => element.address.toLowerCase() == addr,
    );
  }

  // TODO(mute33): null value
  ContractConfig? getContractConfigBySymbol(String symbol, [int chainId = 0]) {
    return configsMap['chainId:$chainId'].firstWhere(
      (dynamic element) => element.symbol == symbol,
    );
  }

  ContractAbi? getContractAbiByType(String type) {
    return abis[type];
  }

  static late AddressConfig _instance;

  static AddressConfig get instance => _instance;
  static void createInstanceFromJson(
    Map<String, dynamic> json, [
    int chainId = 0,
  ]) {
    _instance = AddressConfig.fromJson(json, chainId);
  }
}

/// Init contract abi from configurations
///
/// * contract_symbols format
/// ```json
/// [
///   {
///     "address": "hex address of contract",
///     "symbol": "human readable symbol of contract",
///     "type": "$CONTRACT_TYPE"
///   }
/// ]
/// ```
///
/// * abis format
/// ```json
/// [
///   {
///     "type": "ERC20",
///     "abi": [
///       {
///         "constant": true,
///         "inputs": [],
///         "name": "name",
///         "outputs": [
///            {
///                "name": "",
///                "type": "string"
///            }
///        ],
///        "payable": false,
///        "stateMutability": "view",
///        "type": "function"
///       }
///     ]
///   }
/// ]
/// ```
/// Each type in contract_symbols.json need to have corresponding json file in abi
/// the abi json file can be found in
/// https://etherscan.io/address/$CONTRACT_ADDRESS#code
///
/// * translators format
/// if translators is null, transaction can not be translated into description
/// [
///   {
///        "id": "UNISWAP_swapTokensForExactTokens",
///        "desc_en": "swap %s %s for %s %s to %s",
///        "translators": [
///            "ARG-amountInMax ARG-path IMMED-0 LSTITEM DECIMAL FMTAMT",
///            "ARG-path IMMED-0 LSTITEM SYMBOL",
///            "ARG-amountOut ARG-path IMMED--1 LSTITEM DECIMAL FMTAMT",
///            "ARG-path IMMED--1 LSTITEM SYMBOL",
///            "ARG-to FMTADDR"
///        ]
///    }
/// ]
void initContractAbisFromJson(Map<String, dynamic> abiConfigs) {
  AddressConfig.createInstanceFromJson(abiConfigs);
}

/// Returns the [ContractConfig] for required contract address
///
/// If no matching contract found, return null
ContractConfig? getContractConfigByAddress(String address, [int chainId = 0]) {
  return AddressConfig.instance.getContractConfigByAddress(address, chainId);
}

ContractAbi? getContractAbiByType(String type) {
  return AddressConfig.instance.getContractAbiByType(type);
}
