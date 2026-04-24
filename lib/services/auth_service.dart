import 'package:flutter/foundation.dart';
import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart' as models;

class AuthService {
  final Client client = Client();
  late final Account account;

  // Appwrite Ayarları
  // NOT: Bu değerleri kendi Appwrite konsolundan aldığın değerlerle değiştir.
  static const String _endpoint = 'https://fra.cloud.appwrite.io/v1';
  static const String _projectId = '69a791fa002d1b9cbef8';

  AuthService() {
    client
        .setEndpoint(_endpoint)
        .setProject(_projectId)
        .setSelfSigned(status: true); // Sadece geliştirme aşamasında true yap
    account = Account(client);
  }

  Future<bool> login(String email, String password) async {
    try {
      await account.createEmailPasswordSession(
        email: email,
        password: password,
      );
      return true;
    } catch (e) {
      debugPrint("Login Error: $e");
      return false;
    }
  }

  Future<bool> register(String name, String email, String password) async {
    try {
      await account.create(
        userId: ID.unique(),
        email: email,
        password: password,
        name: name,
      );
      return true;
    } catch (e) {
      debugPrint("Register Error: $e");
      return false;
    }
  }

  Future<void> logout() async {
    try {
      await account.deleteSession(sessionId: 'current');
    } catch (e) {
      debugPrint("Logout Error: $e");
    }
  }

  Future<models.User?> getCurrentUser() async {
    try {
      return await account.get();
    } catch (e) {
      return null;
    }
  }

  Future<bool> updateName(String name) async {
    try {
      await account.updateName(name: name);
      return true;
    } catch (e) {
      debugPrint("Update Name Error: $e");
      return false;
    }
  }

  // Profil fotoğrafı yolunu 'prefs' içinde saklayacağız
  Future<bool> updateAvatar(String path) async {
    try {
      final user = await getCurrentUser();
      final prefs = Map<String, dynamic>.from(user?.prefs.data ?? {});
      prefs['avatar'] = path;
      prefs['setup_complete'] = true; // Fotoğraf yüklenince tamamlandı olarak işaretle
      await account.updatePrefs(prefs: prefs);
      return true;
    } catch (e) {
      debugPrint("Update Prefs Error: $e");
      return false;
    }
  }

  // Setup adımını sadece atlamak/tamamlamak isteyenler için
  Future<bool> markSetupComplete() async {
    try {
      final user = await getCurrentUser();
      final prefs = Map<String, dynamic>.from(user?.prefs.data ?? {});
      prefs['setup_complete'] = true;
      await account.updatePrefs(prefs: prefs);
      return true;
    } catch (e) {
      return false;
    }
  }
}
