import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';
import '../../providers/app_providers.dart';
import '../../core/constants/app_colors.dart';

class ProfileSetupScreen extends ConsumerStatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  ConsumerState<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends ConsumerState<ProfileSetupScreen> {
  final _nameController = TextEditingController();
  String? _avatarPath;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = ref.read(currentUserProvider).value;
      if (user != null) {
        _nameController.text = user.name;
      }
    });
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _avatarPath = image.path;
      });
    }
  }

  Future<void> _saveProfile() async {
    setState(() => _isLoading = true);
    final authService = ref.read(authServiceProvider);
    
    if (_nameController.text.isNotEmpty) {
      await authService.updateName(_nameController.text);
    }
    
    if (_avatarPath != null) {
      await authService.updateAvatar(_avatarPath!);
    } else {
      await authService.markSetupComplete();
    }

    ref.invalidate(currentUserProvider); // Kullanıcıyı yeniden yükle, UI'yi uyar
    
    if (mounted) {
      setState(() => _isLoading = false);
      context.pop(); // Yönlendirmeyi kapatıp Ana Uygulamaya dön
    }
  }

  Future<void> _skipSetup() async {
    setState(() => _isLoading = true);
    await ref.read(authServiceProvider).markSetupComplete();
    ref.invalidate(currentUserProvider);
    if (mounted) {
      setState(() => _isLoading = false);
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // Telefonun geri tuşuyla atlanmasını engelliyoruz
      child: Scaffold(
        appBar: AppBar(title: const Text("Profilinizi Tamamlayın"), automaticallyImplyLeading: false),
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text("Cryptonix'e hoşgeldiniz! Devam etmeden önce eksik profil bilgilerinizi tamamlayın.", textAlign: TextAlign.center, style: TextStyle(fontSize: 16)),
                const SizedBox(height: 30),
                GestureDetector(
                  onTap: _pickImage,
                  child: CircleAvatar(
                    radius: 60,
                    backgroundColor: AppColors.primary.withOpacity(0.1),
                    backgroundImage: _avatarPath != null ? FileImage(File(_avatarPath!)) : null,
                    child: _avatarPath == null ? const Icon(Icons.add_a_photo, size: 40, color: AppColors.primary) : null,
                  ),
                ),
                const SizedBox(height: 10),
                TextButton(onPressed: _pickImage, child: const Text("Fotoğraf Seç", style: TextStyle(fontWeight: FontWeight.bold))),
                const SizedBox(height: 20),
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: "Kullanıcı Adı", border: OutlineInputBorder(), prefixIcon: Icon(Icons.person)),
                ),
                const SizedBox(height: 40),
                SizedBox(width: double.infinity, child: ElevatedButton(onPressed: _isLoading ? null : _saveProfile, style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16)), child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text("KAYDET VE DEVAM ET"))),
                const SizedBox(height: 16),
                TextButton(onPressed: _isLoading ? null : _skipSetup, child: const Text("Daha Sonra Belirle", style: TextStyle(color: Colors.grey))),
              ],
            ),
          ),
        ),
      ),
    );
  }
}