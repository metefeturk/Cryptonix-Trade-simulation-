import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import '../models/coin_model.dart';

// API'den dönen sonucun yapısını tanımlayan bir yardımcı sınıf.
// Verinin mock olup olmadığını ve bir hata mesajı içerip içermediğini belirtir.
class ApiMarketResult {
  final List<Coin> coins;
  final bool isMock;
  final String? error;

  ApiMarketResult({required this.coins, this.isMock = false, this.error});
}

// API endpoint'lerinin detaylarını tutan bir sınıf.
class _ApiEndpoint {
  final String name;
  final String url;
  final Map<String, dynamic> queryParameters;
  final List<Coin> Function(dynamic) parser;
  final String? dataPath; // Yanıttaki asıl veri listesinin JSON içindeki yolu

  _ApiEndpoint({
    required this.name,
    required this.url,
    required this.queryParameters,
    required this.parser,
    this.dataPath,
  });
}

class ApiService {
  late final Dio _dio;

  ApiService() {
    final options = BaseOptions(
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      sendTimeout: const Duration(seconds: 10),
      headers: {
        // Bazı API'ler veya güvenlik duvarları User-Agent başlığı olmayan istekleri engelleyebilir.
        "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36",
        "Accept": "application/json",
      },
    );
    _dio = Dio(options);
  }

  // Denenecek API'lerin sıralı listesi
  List<_ApiEndpoint> get _apiEndpoints => [
        _ApiEndpoint(
          name: 'CryptoCompare',
          url: 'https://min-api.cryptocompare.com/data/top/mktcapfull',
          queryParameters: {'limit': 50, 'tsym': 'USD'},
          parser: (data) => (data as List<dynamic>).map((e) => Coin.fromCryptoCompareJson(e)).toList(),
          dataPath: 'Data',
        ),
        _ApiEndpoint(
          name: 'CoinGecko',
          url: 'https://api.coingecko.com/api/v3/coins/markets',
          queryParameters: {
            'vs_currency': 'usd',
            'order': 'market_cap_desc',
            'per_page': 50,
            'page': 1,
            'sparkline': false,
          },
          parser: (data) => (data as List<dynamic>).map((e) => Coin.fromCoinGeckoJson(e)).toList(),
        ),
        _ApiEndpoint(
          name: 'CoinCap',
          url: 'https://api.coincap.io/v2/assets',
          queryParameters: {'limit': 50},
          parser: (data) => (data as List<dynamic>).map((e) => Coin.fromCoinCapJson(e)).toList(),
          dataPath: 'data',
        ),
      ];

  Future<ApiMarketResult> getMarketData() async {
    for (final endpoint in _apiEndpoints) {
      final List<Coin>? result = await _fetchWithRetries(endpoint);
      if (result != null) {
        debugPrint('✅ Veri başarıyla ${endpoint.name} kaynağından alındı.');
        return ApiMarketResult(coins: result);
      }
    }

    // Tüm API'ler başarısız olduysa mock veri döndür.
    debugPrint('⚠️ Tüm API kaynakları başarısız oldu. Mock (sahte) veri döndürülüyor.');
    return ApiMarketResult(
      coins: _getMockMarketData(),
      isMock: true,
      error: 'API\'lere ulaşılamıyor. Çevrimdışı veriler gösteriliyor.',
    );
  }

  // Bir API endpoint'ini tekrar deneme mantığıyla çağıran yardımcı fonksiyon.
  Future<List<Coin>?> _fetchWithRetries(_ApiEndpoint endpoint, {int retries = 2}) async {
    for (int i = 0; i <= retries; i++) {
      try {
        debugPrint('🔄 Deneme ${i + 1}/${retries + 1} - ${endpoint.name} API\'si çağrılıyor...');
        final response = await _dio.get(
          endpoint.url,
          queryParameters: endpoint.queryParameters,
        );

        if (response.statusCode == 200) {
          debugPrint('✔️ ${endpoint.name} isteği başarılı (Status: ${response.statusCode})');
          dynamic data = response.data;
          if (endpoint.dataPath != null) {
            data = data[endpoint.dataPath];
          }
          return endpoint.parser(data);
        } else {
          debugPrint('❌ ${endpoint.name} isteği başarısız oldu, status: ${response.statusCode}');
        }
      } on DioException catch (e) {
        // Sadece belirli ağ hatalarında tekrar dene.
        if (e.type == DioExceptionType.connectionTimeout ||
            e.type == DioExceptionType.sendTimeout ||
            e.type == DioExceptionType.receiveTimeout ||
            e.type == DioExceptionType.connectionError) {
          debugPrint('❌ ${endpoint.name} ağ hatası (Deneme ${i + 1}): ${e.message}');
          if (i < retries) {
            await Future.delayed(const Duration(seconds: 2)); // Tekrar denemeden önce bekle
          }
        } else {
          // 404, 500 gibi diğer hatalarda tekrar deneme, bir sonraki API'ye geç.
          debugPrint('❌ ${endpoint.name} sunucu hatası, tekrar denenmeyecek: ${e.message}');
          break;
        }
      } catch (e) {
        debugPrint('❌ ${endpoint.name} beklenmedik hata: $e');
        break; // Beklenmedik hatalarda tekrar deneme.
      }
    }
    debugPrint('↪️ ${endpoint.name} için tüm denemeler başarısız. Sonraki API\'ye geçiliyor.');
    return null;
  }

  Future<List<Map<String, String>>> getCryptoNews() async {
    // 1. Deneme: CryptoCompare v2 API
    try {
      debugPrint('🔄 Haberler API (v2) çağrılıyor...');
      final response = await _dio.get(
        'https://min-api.cryptocompare.com/data/v2/news/?lang=EN',
      );

      if (response.statusCode == 200 && response.data['Data'] != null) {
        debugPrint('✅ Haberler başarıyla v2 API\'den çekildi.');
        return _parseCryptoCompareNews(response.data['Data'] as List<dynamic>);
      }
    } catch (e) {
      debugPrint('❌ Haberler v2 API bağlantı hatası: $e');
    }

    // 2. Deneme: CryptoCompare v1 API (Yedek)
    try {
      debugPrint('🔄 Haberler API (v1) çağrılıyor...');
      final response = await _dio.get(
        'https://min-api.cryptocompare.com/data/news/?lang=EN',
      );

      if (response.statusCode == 200 && response.data is List) {
        debugPrint('✅ Haberler başarıyla v1 API\'den çekildi.');
        return _parseCryptoCompareNews(response.data as List<dynamic>);
      }
    } catch (e) {
      debugPrint('❌ Haberler v1 API bağlantı hatası: $e');
    }

    // 3. Deneme: RSS to JSON API (CoinTelegraph RSS - Neredeyse Her Zaman Çalışır)
    try {
      debugPrint('🔄 Haberler API (RSS) çağrılıyor...');
      final response = await _dio.get(
        'https://api.rss2json.com/v1/api.json?rss_url=https://cointelegraph.com/rss',
      );

      if (response.statusCode == 200 && response.data['items'] != null) {
        debugPrint('✅ Haberler başarıyla RSS API\'den çekildi.');
        final List<dynamic> items = response.data['items'];
        final List<Map<String, String>> parsedNews = [];
        
        for (var item in items.take(20)) {
          if (item is Map) {
            String body = item['description']?.toString() ?? "";
            // HTML etiketlerini temizle (RSS metinleri genelde HTML içerir)
            body = body.replaceAll(RegExp(r'<[^>]*>'), '').trim();
            
            String imageUrl = "https://images.unsplash.com/photo-1518546305927-5a555bb7020d?auto=format&fit=crop&q=80&w=500";
            if (item['thumbnail'] != null && item['thumbnail'].toString().isNotEmpty) {
              imageUrl = item['thumbnail'].toString();
            } else if (item['enclosure'] is Map && item['enclosure']['link'] != null) {
              imageUrl = item['enclosure']['link'].toString();
            }

            parsedNews.add({
              "title": item['title']?.toString() ?? "Kripto Gelişmesi",
              "description": body,
              "image": imageUrl,
              "source": "CoinTelegraph",
              "content": body,
            });
          }
        }
        if (parsedNews.isNotEmpty) return parsedNews;
      }
    } catch (e) {
      debugPrint('❌ Haberler RSS API bağlantı hatası: $e');
    }

    // Herhangi bir hata veya timeout durumunda asla patlama, güvenli statik listeyi döndür.
    debugPrint('⚠️ Haberler API başarısız. Statik yedek haberler gösteriliyor.');
    return _getMockNewsData();
  }

  // CryptoCompare API yanıtını güvenli şekilde parse eden yardımcı fonksiyon
  List<Map<String, String>> _parseCryptoCompareNews(List<dynamic> data) {
    final List<Map<String, String>> parsedNews = [];
    for (var item in data.take(20)) {
      if (item is Map) {
        String title = item['title']?.toString() ?? "Kripto Gelişmesi";
        String body = item['body']?.toString() ?? "";
        String imageUrl = item['imageurl']?.toString() ?? "https://images.unsplash.com/photo-1518546305927-5a555bb7020d?auto=format&fit=crop&q=80&w=500";
        
        String sourceName = "Kripto Haber";
        if (item['source_info'] is Map && item['source_info']['name'] != null) {
          sourceName = item['source_info']['name'].toString();
        } else if (item['source'] != null) {
          sourceName = item['source'].toString();
        }

        parsedNews.add({
          "title": title,
          "description": body,
          "image": imageUrl,
          "source": sourceName,
          "content": body,
        });
      }
    }
    return parsedNews;
  }

  // Tüm API'ler başarısız olduğunda veya sunum sırasında sorun çıkarsa kullanılacak sahte haberler.
  List<Map<String, String>> _getMockNewsData() {
    return [
      {
        "title": "Bitcoin 100.000 Dolar Yolunda mı?",
        "description": "Analistler Bitcoin'in yaklaşan yarılanma (halving) etkinliği öncesinde büyük bir ralli yapabileceğini öngörüyor.",
        "image": "https://images.unsplash.com/photo-1518546305927-5a555bb7020d?auto=format&fit=crop&q=80&w=500",
        "source": "Kripto Bülteni",
        "content": "Bitcoin (BTC) fiyatı son haftalarda gösterdiği performansla yatırımcıların yüzünü güldürüyor. BTC önemli bir direnç seviyesini aşarak güçlü bir boğa piyasası sinyali verdi. Kurumsal ilginin artması fiyatı yukarı çekiyor."
      },
      {
        "title": "Ethereum 2.0 Güncellemesi Tamamlandı",
        "description": "Ethereum ağındaki büyük güncelleme başarıyla gerçekleşti. İşlem ücretlerinde düşüş ve hızda artış bekleniyor.",
        "image": "https://images.unsplash.com/photo-1622630998477-20aa696fa405?auto=format&fit=crop&q=80&w=500",
        "source": "TeknoCoin",
        "content": "Uzun zamandır beklenen Ethereum (ETH) güncellemesi nihayet ana ağda yayına alındı. Geliştiriciler, bu adımın DeFi ve NFT ekosistemi için devrim niteliğinde olduğunu savunuyor."
      },
      {
        "title": "Solana (SOL) Yeni Ortaklıklar Kuruyor",
        "description": "SOL, teknoloji devleriyle ekosistemini genişletiyor ve fiyatını yukarı taşıyor.",
        "image": "https://images.unsplash.com/photo-1620712943543-bcc4688e7485?auto=format&fit=crop&q=80&w=500",
        "source": "TechCrypto",
        "content": "Solana (SOL) ağındaki yüksek işlem hızı ve düşük ücretler kurumsal firmaların dikkatini çekmeye devam ediyor. Son günlerde yapılan açıklamalara göre ağ üzerinde daha fazla kurumsal uygulamanın çalıştırılması hedefleniyor."
      },
      {
        "title": "Kripto Paralar İçin Yeni Düzenlemeler",
        "description": "SEC tarafından stabil coinler, BTC ve diğer büyük kriptolarla ilgili yeni düzenlemeler önerildi.",
        "image": "https://images.unsplash.com/photo-1621761191319-c6fb62004040?auto=format&fit=crop&q=80&w=500",
        "source": "Finans Gündem",
        "content": "Nakit kullanımının azalması ve kripto paraların yükselişi regülatörleri harekete geçirdi. SEC tarafından önerilen kurallar kripto piyasasını daha güvenli bir yer haline getirmeyi hedefliyor."
      },
      {
        "title": "Dogecoin (DOGE) Sosyal Medya İle Şaha Kalktı",
        "description": "Sosyal medyadaki yeni bir dalga, Dogecoin fiyatlarını bugün yukarı itti.",
        "image": "https://images.unsplash.com/photo-1620825937374-87fc7d6aaf8a?auto=format&fit=crop&q=80&w=500",
        "source": "MemeCoin Daily",
        "content": "Dogecoin (DOGE) yine sosyal medyanın gündemine oturdu. Özellikle ünlü isimlerin yaptığı son paylaşımlar sonrası fiyatta gözle görülür bir hacim ve değer artışı yaşandı."
      },
      {
        "title": "Ripple (XRP) Yasal Savaşında Sona Doğru",
        "description": "Ripple ve SEC arasındaki uzun süreli dava bir karara bağlanma sinyalleri veriyor.",
        "image": "https://images.unsplash.com/photo-1621416894569-0f39ed31d247?auto=format&fit=crop&q=80&w=500",
        "source": "CryptoLaw",
        "content": "XRP'nin arkasındaki şirket Ripple ile SEC arasındaki dava sona yaklaşıyor. Çıkacak olan kararın genel bir piyasa rallisi başlatıp başlatmayacağı büyük merak konusu."
      },
    ];
  }

  // Tüm API'ler başarısız olduğunda kullanılacak sahte veri.
  List<Coin> _getMockMarketData() {
    final random = Random();
    
    // Temel veriler (Gerçekçi başlangıç fiyatları)
    final List<Map<String, dynamic>> baseCoins = [
      {'symbol': 'BTC', 'name': 'Bitcoin', 'basePrice': 67500.0},
      {'symbol': 'ETH', 'name': 'Ethereum', 'basePrice': 3800.0},
      {'symbol': 'BNB', 'name': 'BNB', 'basePrice': 590.0},
      {'symbol': 'SOL', 'name': 'Solana', 'basePrice': 145.0},
      {'symbol': 'XRP', 'name': 'XRP', 'basePrice': 0.62},
      {'symbol': 'ADA', 'name': 'Cardano', 'basePrice': 0.45},
      {'symbol': 'DOGE', 'name': 'Dogecoin', 'basePrice': 0.16},
      {'symbol': 'AVAX', 'name': 'Avalanche', 'basePrice': 47.0},
      {'symbol': 'DOT', 'name': 'Polkadot', 'basePrice': 8.5},
      {'symbol': 'MATIC', 'name': 'Polygon', 'basePrice': 0.95},
    ];

    return baseCoins.map((coin) {
      // Fiyat Dalgalanması Simülasyonu
      // Fiyat taban fiyattan %2 aşağı veya yukarı sapabilir
      final double volatility = 0.02; 
      final double randomFactor = 1 + (random.nextDouble() * volatility * 2 - volatility);
      final double currentPrice = coin['basePrice'] * randomFactor;

      // 24 Saatlik Değişim Simülasyonu (-%5 ile +%5 arası)
      final double change24h = (random.nextDouble() * 10) - 5;

      return Coin(
        symbol: coin['symbol'],
        name: coin['name'],
        price: currentPrice,
        change24h: change24h,
        volume: 1000000000 + random.nextDouble() * 5000000000, // Rastgele yüksek hacim
        // Resim URL'leri Coin modelindeki iconUrl getter'ı tarafından fallback ile yönetilir
        imageUrl: 'https://cryptocompare.com/media/37746251/${coin['symbol'].toLowerCase()}.png', 
      );
    }).toList();
  }
}
