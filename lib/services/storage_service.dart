import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/portfolio_item.dart';
import '../models/transaction_item.dart';
import '../models/notification_item.dart';

class StorageService {
  static const String _themeKey = 'is_dark_mode';

  Future<void> saveBalance(String userId, double balance) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('balance_$userId', balance);
  }

  Future<double> getBalance(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble('balance_$userId') ?? 10000.0; // Varsayılan 10.000$
  }

  Future<void> savePortfolio(String userId, List<PortfolioItem> items) async {
    final prefs = await SharedPreferences.getInstance();
    final String encoded = jsonEncode(items.map((e) => e.toJson()).toList());
    await prefs.setString('portfolio_$userId', encoded);
  }

  Future<List<PortfolioItem>> getPortfolio(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final String? encoded = prefs.getString('portfolio_$userId');
    if (encoded == null) return [];
    final List<dynamic> decoded = jsonDecode(encoded);
    return decoded.map((e) => PortfolioItem.fromJson(e)).toList();
  }

  Future<void> saveTransactions(String userId, List<TransactionItem> items) async {
    final prefs = await SharedPreferences.getInstance();
    final String encoded = jsonEncode(items.map((e) => e.toJson()).toList());
    await prefs.setString('transactions_$userId', encoded);
  }

  Future<List<TransactionItem>> getTransactions(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final String? encoded = prefs.getString('transactions_$userId');
    if (encoded == null) return [];
    final List<dynamic> decoded = jsonDecode(encoded);
    return decoded.map((e) => TransactionItem.fromJson(e)).toList();
  }

  Future<void> saveNotifications(String userId, List<NotificationItem> items) async {
    final prefs = await SharedPreferences.getInstance();
    final String encoded = jsonEncode(items.map((e) => e.toJson()).toList());
    await prefs.setString('notifications_$userId', encoded);
  }

  Future<List<NotificationItem>> getNotifications(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final String? encoded = prefs.getString('notifications_$userId');
    if (encoded == null) return [];
    final List<dynamic> decoded = jsonDecode(encoded);
    return decoded.map((e) => NotificationItem.fromJson(e)).toList();
  }

  Future<void> setDarkMode(bool isDark) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_themeKey, isDark);
  }

  Future<bool> getDarkMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_themeKey) ?? false;
  }
}
