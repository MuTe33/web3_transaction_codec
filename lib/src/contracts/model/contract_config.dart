class ContractConfig {
  ContractConfig(
    this.address,
    this.symbol,
    this.type,
    this.params,
  );

  ContractConfig.fromJson(Map<String, dynamic> json)
      : address = (json['address'] as String).toLowerCase(),
        symbol = json['symbol'],
        type = json['type'],
        params = json['params'];

  final String address;
  final String symbol;
  final String type;
  final Map<String, dynamic> params;

  @override
  String toString() {
    return 'ContractConfig{address: $address, symbol: $symbol, '
        'type: $type, params: $params}';
  }
}
