class TransactionItem {
  final String id;
  final String type; // 'buy' veya 'sell'
  final String symbol;
  final double amount;
  final double price; // Alım/Satım yapıldığı anki birim fiyat (USD)
  final DateTime date;

  TransactionItem({
    required this.id,
    required this.type,
    required this.symbol,
    required this.amount,
    required this.price,
    required this.date,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type,
    'symbol': symbol,
    'amount': amount,
    'price': price,
    'date': date.toIso8601String(),
  };

  factory TransactionItem.fromJson(Map<String, dynamic> json) => TransactionItem(
    id: json['id'],
    type: json['type'],
    symbol: json['symbol'],
    amount: json['amount'],
    price: json['price'],
    date: DateTime.parse(json['date']),
  );
}