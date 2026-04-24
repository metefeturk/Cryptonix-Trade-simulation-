import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';
import '../../providers/app_providers.dart';
import '../../core/constants/app_colors.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  Future<void> _showEditProfileDialog(BuildContext context, WidgetRef ref, String currentName) async {
    final nameController = TextEditingController(text: currentName);
    
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Profili Düzenle"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: "İsim Soyisim",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () async {
                final ImagePicker picker = ImagePicker();
                final XFile? image = await picker.pickImage(source: ImageSource.gallery);
                if (image != null) {
                  await ref.read(authServiceProvider).updateAvatar(image.path);
                  ref.refresh(currentUserProvider); // UI'ı güncelle
                }
              },
              icon: const Icon(Icons.camera_alt),
              label: const Text("Fotoğraf Değiştir"),
            )
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("İptal")),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isNotEmpty) {
                await ref.read(authServiceProvider).updateName(nameController.text);
                ref.refresh(currentUserProvider);
                if (context.mounted) Navigator.pop(context);
              }
            },
            child: const Text("Kaydet"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = ref.watch(themeProvider);
    final userAsync = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Profil"),
        actions: [
          userAsync.when(
            data: (user) => IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => _showEditProfileDialog(context, ref, user?.name ?? ""),
            ),
            loading: () => const SizedBox(),
            error: (_, __) => const SizedBox(),
          )
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    const SizedBox(height: 30),
                    userAsync.when(
                      data: (user) {
                        final avatarPath = user?.prefs.data['avatar'];
                        return Column(
                          children: [
                            CircleAvatar(
                              radius: 50,
                              backgroundColor: Colors.grey.shade300,
                              backgroundImage: avatarPath != null ? FileImage(File(avatarPath)) : null,
                              child: avatarPath == null ? const Icon(Icons.person, size: 50, color: Colors.white) : null,
                            ),
                            const SizedBox(height: 10),
                            Text(user?.name ?? "Kullanıcı", style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                            Text(user?.email ?? "", style: const TextStyle(color: Colors.grey)),
                          ],
                        );
                      },
                      loading: () => const CircularProgressIndicator(),
                      error: (err, _) => const Text("Kullanıcı bilgisi alınamadı"),
                    ),
                    const SizedBox(height: 30),
                    ListTile(
                      leading: const Icon(Icons.dark_mode),
                      title: const Text("Karanlık Mod"),
                      trailing: Switch(
                        value: isDark,
                        onChanged: (val) => ref.read(themeProvider.notifier).toggleTheme(),
                      ),
                    ),
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.history),
                      title: const Text("Geçmiş İşlemler"),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () => context.push('/transaction-history'),
                    ),
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.security),
                      title: const Text("Güvenlik Ayarları"),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Güvenlik sayfası yakında..."))),
                    ),
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.help),
                      title: const Text("Yardım & Destek"),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () => context.go('/news'), // Örnek yönlendirme
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    ref.read(authProvider.notifier).logout();
                  },
                  icon: const Icon(Icons.logout),
                  label: const Text("Çıkış Yap"),
                  style: OutlinedButton.styleFrom(padding: const EdgeInsets.all(16)),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
