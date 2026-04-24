class Coin {
  final String symbol;
  final String name;
  final double price;
  final double change24h;
  final double volume;
  final String? imageUrl;

  Coin({
    required this.symbol,
    required this.name,
    required this.price,
    required this.change24h,
    required this.volume,
    this.imageUrl,
  });

  // Factory to parse CryptoCompare API
  factory Coin.fromCryptoCompareJson(Map<String, dynamic> json) {
    final coinInfo = json['CoinInfo'];
    final raw = json['RAW']?['USD'];

    return Coin(
      symbol: (coinInfo['Name'] as String? ?? '').toUpperCase(),
      name: coinInfo['FullName'] ?? '',
      price: (raw?['PRICE'] as num?)?.toDouble() ?? 0.0,
      change24h: (raw?['CHANGEPCT24HOUR'] as num?)?.toDouble() ?? 0.0,
      volume: (raw?['VOLUME24HOUR'] as num?)?.toDouble() ?? 0.0,
      imageUrl: coinInfo['ImageUrl'],
    );
  }

  // Factory for CoinGecko API (Yedek 1)
  factory Coin.fromCoinGeckoJson(Map<String, dynamic> json) {
    return Coin(
      symbol: (json['symbol'] as String? ?? '').toUpperCase(),
      name: json['name'] ?? '',
      price: (json['current_price'] as num?)?.toDouble() ?? 0.0,
      change24h: (json['price_change_percentage_24h'] as num?)?.toDouble() ?? 0.0,
      volume: (json['total_volume'] as num?)?.toDouble() ?? 0.0,
      imageUrl: json['image'], // CoinGecko tam URL verir
    );
  }

  // Factory for CoinCap API (Yedek 2)
  factory Coin.fromCoinCapJson(Map<String, dynamic> json) {
    return Coin(
      symbol: (json['symbol'] as String? ?? '').toUpperCase(),
      name: json['name'] ?? '',
      price: double.tryParse(json['priceUsd'] ?? '0') ?? 0.0,
      change24h: double.tryParse(json['changePercent24Hr'] ?? '0') ?? 0.0,
      volume: double.tryParse(json['volumeUsd24Hr'] ?? '0') ?? 0.0,
      imageUrl: null, // CoinCap resim vermez, fallback kullanacağız
    );
  }
  
  String get iconUrl {
    if (imageUrl != null) {
      if (imageUrl!.startsWith('http')) return imageUrl!; // Tam URL ise direkt döndür
      return "https://www.cryptocompare.com$imageUrl"; // Kısmi URL ise tamamla
    }
    return "https://raw.githubusercontent.com/spothq/cryptocurrency-icons/master/128/color/${symbol.toLowerCase()}.png";
  }
}
