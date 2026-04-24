class PortfolioItem {
  final String symbol;
  final double amount;
  final double averageBuyPrice;

  PortfolioItem({
    required this.symbol,
    required this.amount,
    required this.averageBuyPrice,
  });

  Map<String, dynamic> toJson() => {
    'symbol': symbol,
    'amount': amount,
    'averageBuyPrice': averageBuyPrice,
  };

  factory PortfolioItem.fromJson(Map<String, dynamic> json) => PortfolioItem(
    symbol: json['symbol'],
    amount: json['amount'],
    averageBuyPrice: json['averageBuyPrice'],
  );
}
