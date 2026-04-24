import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:appwrite/models.dart' as models;
import 'package:uuid/uuid.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import '../services/auth_service.dart';
import '../services/forum_service.dart';
import '../models/coin_model.dart';
import '../models/portfolio_item.dart';
import '../models/transaction_item.dart';
import '../models/notification_item.dart';

// Services
final apiServiceProvider = Provider((ref) => ApiService());
final storageServiceProvider = Provider((ref) => StorageService());
final authServiceProvider = Provider((ref) => AuthService());
final forumServiceProvider = Provider((ref) => ForumService());

// Currency State
enum AppCurrency { USD, EUR, TRY }

class CurrencyHelper {
  static String getSymbol(AppCurrency currency) {
    switch (currency) {
      case AppCurrency.EUR: return "€";
      case AppCurrency.TRY: return "₺";
      case AppCurrency.USD: default: return "\$";
    }
  }
  static double getRate(AppCurrency currency) {
    switch (currency) {
      case AppCurrency.EUR: return 0.92; // Örnek Euro Kuru
      case AppCurrency.TRY: return 32.5; // Örnek TL Kuru
      case AppCurrency.USD: default: return 1.0;
    }
  }
}

class CurrencyNotifier extends StateNotifier<AppCurrency> {
  CurrencyNotifier() : super(AppCurrency.USD);

  void setCurrency(AppCurrency currency) {
    state = currency;
  }
}

final currencyProvider = StateNotifierProvider<CurrencyNotifier, AppCurrency>((ref) {
  return CurrencyNotifier();
});

// API Hata Durumu
// API'ler başarısız olduğunda bir hata mesajı tutar.
// UI bu provider'ı dinleyerek bir uyarı banner'ı gösterebilir.
final apiErrorProvider = StateNotifierProvider<ApiErrorNotifier, String?>((ref) => ApiErrorNotifier());

// Auth State
class AuthNotifier extends StateNotifier<bool> {
  final AuthService _authService;

  AuthNotifier(this._authService) : super(false) {
    _checkSession();
  }

  Future<void> _checkSession() async {
    final user = await _authService.getCurrentUser();
    if (user != null) {
      state = true;
    } else {
      state = false;
    }
  }

  Future<bool> login(String email, String password) async {
    final success = await _authService.login(email, password);
    if (success) state = true;
    return success;
  }

  Future<void> logout() async {
    await _authService.logout();
    state = false;
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, bool>((ref) {
  return AuthNotifier(ref.watch(authServiceProvider));
});

// Current User Provider
final currentUserProvider = FutureProvider<models.User?>((ref) async {
  // Auth state değişikliklerini dinle (Giriş/Çıkış yapıldığında tetiklenir)
  // Bu satır sayesinde login/logout olunca kullanıcı bilgisi tazeletilir.
  ref.watch(authProvider);
  
  final auth = ref.watch(authServiceProvider);
  return auth.getCurrentUser();
});

// Theme State
class ThemeNotifier extends StateNotifier<bool> {
  final StorageService _storage;
  ThemeNotifier(this._storage) : super(false) {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    state = await _storage.getDarkMode();
  }

  void toggleTheme() {
    state = !state;
    _storage.setDarkMode(state);
  }
}

final themeProvider = StateNotifierProvider<ThemeNotifier, bool>((ref) {
  return ThemeNotifier(ref.watch(storageServiceProvider));
});

// API Error Notifier
class ApiErrorNotifier extends StateNotifier<String?> {
  ApiErrorNotifier() : super(null);

  void setError(String? message) {
    state = message;
  }
}

// Market Data (Real API - Live Stream)
final marketDataProvider = StreamProvider<List<Coin>>((ref) async* {
  final api = ref.watch(apiServiceProvider);

  // Veriyi getiren ve state'leri güncelleyen yardımcı fonksiyon
  Future<List<Coin>> fetchData() async {
    final result = await api.getMarketData();
    // Hata durumunu merkezi state'e yaz
    ref.read(apiErrorProvider.notifier).setError(result.error);
    return result.coins;
  }

  // İlk veriyi hemen getir.
  yield await fetchData();

  // Periyodik olarak veriyi güncelle.
  while (true) {
    await Future.delayed(const Duration(seconds: 10));
    try {
      yield await fetchData();
    } catch (e) {
      debugPrint("marketDataProvider döngüsünde beklenmedik hata: $e");
      // Bu hata sadece provider'ın kendi içindeki bir sorundan kaynaklanır.
      // getMarketData artık exception fırlatmadığı için bu blok nadiren çalışır.
      // Akışın devam etmesi için hata yutulur.
    }
  }
});

// Home Filter State
enum SortOption { rank, priceDesc, priceAsc, gainers, losers }

class FilterNotifier extends StateNotifier<SortOption> {
  FilterNotifier() : super(SortOption.rank);

  void setFilter(SortOption option) {
    state = option;
  }
}

final filterProvider = StateNotifierProvider<FilterNotifier, SortOption>((ref) {
  return FilterNotifier();
});

// Search Query Provider (Arama Kutusu için)
final searchQueryProvider = StateProvider<String>((ref) => '');

// Notification Logic
class NotificationState {
  final List<NotificationItem> notifications;
  NotificationState(this.notifications);
}

class NotificationNotifier extends StateNotifier<NotificationState> {
  final StorageService _storage;
  final String _userId;

  NotificationNotifier(this._storage, this._userId) : super(NotificationState([])) {
    _loadData();
  }

  Future<void> _loadData() async {
    final notifications = await _storage.getNotifications(_userId);
    if (notifications.isEmpty) {
      // İlk kayıtta gelen hoş geldin bildirimi
      final welcomeNotif = NotificationItem(id: const Uuid().v4(), title: "Hoş Geldiniz!", message: "Cryptonix'e hoş geldiniz! Başlangıç olarak hesabınıza 10.000 \$ deneme bakiyesi tanımlanmıştır.", date: DateTime.now());
      state = NotificationState([welcomeNotif]);
      await _storage.saveNotifications(_userId, state.notifications);
    } else {
      state = NotificationState(notifications);
    }
  }

  Future<void> addNotification(String title, String message) async {
    final notif = NotificationItem(id: const Uuid().v4(), title: title, message: message, date: DateTime.now());
    final updatedList = [notif, ...state.notifications];
    state = NotificationState(updatedList);
    await _storage.saveNotifications(_userId, updatedList);
  }

  Future<void> markAsRead(String id) async {
    final updatedList = state.notifications.map((n) => n.id == id ? NotificationItem(id: n.id, title: n.title, message: n.message, date: n.date, isRead: true) : n).toList();
    state = NotificationState(updatedList);
    await _storage.saveNotifications(_userId, updatedList);
  }
}

final notificationProvider = StateNotifierProvider<NotificationNotifier, NotificationState>((ref) {
  final userAsync = ref.watch(currentUserProvider);
  final userId = userAsync.value?.$id ?? 'guest_user';
  return NotificationNotifier(ref.watch(storageServiceProvider), userId);
});

// News Data
final newsProvider = FutureProvider.autoDispose<List<Map<String, String>>>((ref) async {
  final api = ref.watch(apiServiceProvider);
  return api.getCryptoNews();
});

// Forum Providers
final forumTopicsProvider = FutureProvider.autoDispose<List<models.Document>>((ref) async {
  final service = ref.watch(forumServiceProvider);
  return service.getTopics();
});

final forumCommentsProvider = FutureProvider.family<List<models.Document>, String>((ref, topicId) async {
  final service = ref.watch(forumServiceProvider);
  return service.getComments(topicId);
});

// Portfolio State Logic
class PortfolioState {
  final double balance;
  final List<PortfolioItem> holdings;
  final List<TransactionItem> transactions;

  PortfolioState({required this.balance, required this.holdings, required this.transactions});
}

class PortfolioNotifier extends StateNotifier<PortfolioState> {
  final StorageService _storage;
  final String _userId;
  final Ref _ref; // Bildirim servisine ulaşmak için referansı alıyoruz

  PortfolioNotifier(this._storage, this._userId, this._ref) : super(PortfolioState(balance: 0, holdings: [], transactions: [])) {
    _loadData();
  }

  Future<void> _loadData() async {
    final balance = await _storage.getBalance(_userId);
    final holdings = await _storage.getPortfolio(_userId);
    final transactions = await _storage.getTransactions(_userId);
    state = PortfolioState(balance: balance, holdings: holdings, transactions: transactions);
  }

  Future<void> buyCoin(String symbol, double price, double amountUSD) async {
    if (state.balance < amountUSD) return; // Insufficient funds

    final double coinAmount = amountUSD / price;
    final double newBalance = state.balance - amountUSD;

    // Update holdings
    List<PortfolioItem> currentHoldings = [...state.holdings];
    int index = currentHoldings.indexWhere((element) => element.symbol == symbol);

    if (index != -1) {
      // Average down logic
      var item = currentHoldings[index];
      double totalCost = (item.amount * item.averageBuyPrice) + amountUSD;
      double totalAmount = item.amount + coinAmount;
      currentHoldings[index] = PortfolioItem(
        symbol: symbol,
        amount: totalAmount,
        averageBuyPrice: totalCost / totalAmount,
      );
    } else {
      currentHoldings.add(PortfolioItem(symbol: symbol, amount: coinAmount, averageBuyPrice: price));
    }

    final newTx = TransactionItem(
      id: const Uuid().v4(),
      type: 'buy',
      symbol: symbol,
      amount: coinAmount,
      price: price,
      date: DateTime.now(),
    );
    final newTransactions = [newTx, ...state.transactions];

    state = PortfolioState(balance: newBalance, holdings: currentHoldings, transactions: newTransactions);
    await _storage.saveBalance(_userId, newBalance);
    await _storage.savePortfolio(_userId, currentHoldings);
    await _storage.saveTransactions(_userId, newTransactions);
    _ref.read(notificationProvider.notifier).addNotification("Alım İşlemi", "\$${amountUSD.toStringAsFixed(2)} ödeyerek ${coinAmount.toStringAsFixed(6)} $symbol satın aldınız.");
  }
  
  // Sell logic with amount
  Future<void> sellCoin(String symbol, double currentPrice, double amountToSell) async {
    List<PortfolioItem> currentHoldings = [...state.holdings];
    int index = currentHoldings.indexWhere((element) => element.symbol == symbol);
    
    if (index == -1) return;
    
    var item = currentHoldings[index];
    
    // Miktar kontrolü
    if (amountToSell > item.amount) amountToSell = item.amount;
    if (amountToSell <= 0) return;

    double returnUSD = amountToSell * currentPrice;
    double newBalance = state.balance + returnUSD;
    double remainingAmount = item.amount - amountToSell;
    
    if (remainingAmount <= 0.000001) {
      currentHoldings.removeAt(index);
    } else {
      currentHoldings[index] = PortfolioItem(
        symbol: item.symbol,
        amount: remainingAmount,
        averageBuyPrice: item.averageBuyPrice,
      );
    }
    
    final newTx = TransactionItem(
      id: const Uuid().v4(),
      type: 'sell',
      symbol: symbol,
      amount: amountToSell,
      price: currentPrice,
      date: DateTime.now(),
    );
    final newTransactions = [newTx, ...state.transactions];

    state = PortfolioState(balance: newBalance, holdings: currentHoldings, transactions: newTransactions);
    await _storage.saveBalance(_userId, newBalance);
    await _storage.savePortfolio(_userId, currentHoldings);
    await _storage.saveTransactions(_userId, newTransactions);
  }

  Future<void> deposit(double amount) async {
    final newBalance = state.balance + amount;
    state = PortfolioState(balance: newBalance, holdings: state.holdings, transactions: state.transactions);
    await _storage.saveBalance(_userId, newBalance);
  }

  Future<bool> withdraw(double amount) async {
    if (state.balance < amount) return false;
    final newBalance = state.balance - amount;
    state = PortfolioState(balance: newBalance, holdings: state.holdings, transactions: state.transactions);
    await _storage.saveBalance(_userId, newBalance);
    return true;
  }
}

final portfolioProvider = StateNotifierProvider<PortfolioNotifier, PortfolioState>((ref) {
  final userAsync = ref.watch(currentUserProvider);
  // Kullanıcı giriş yapmamışsa veya yükleniyorsa geçici bir ID kullan
  // Appwrite User ID'si benzersizdir ($id).
  final userId = userAsync.value?.$id ?? 'guest_user';
  return PortfolioNotifier(ref.watch(storageServiceProvider), userId, ref);
});
