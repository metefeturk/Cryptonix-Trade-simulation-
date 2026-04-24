import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/app_providers.dart';
import '../../core/constants/app_colors.dart';

class CreateTopicScreen extends ConsumerStatefulWidget {
  const CreateTopicScreen({super.key});

  @override
  ConsumerState<CreateTopicScreen> createState() => _CreateTopicScreenState();
}

class _CreateTopicScreenState extends ConsumerState<CreateTopicScreen> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  bool _isLoading = false;

  Future<void> _submit() async {
    if (_titleController.text.isEmpty || _contentController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Lütfen tüm alanları doldurun")));
      return;
    }

    setState(() => _isLoading = true);

    try {
      // .value yerine .future kullanarak verinin gelmesini bekliyoruz
      final user = await ref.read(currentUserProvider.future);
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Oturum açmanız gerekiyor")));
        return;
      }

      await ref.read(forumServiceProvider).createTopic(
        _titleController.text,
        _contentController.text,
        user.$id,
        user.name,
      );

      ref.refresh(forumTopicsProvider); // Listeyi yenile
      if (mounted) {
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Konu oluşturuldu!")));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Hata: $e")));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Yeni Konu Oluştur")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: "Konu Başlığı", border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _contentController,
              decoration: const InputDecoration(labelText: "İçerik", border: OutlineInputBorder(), alignLabelWithHint: true),
              maxLines: 8,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, padding: const EdgeInsets.all(16)),
                child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text("OLUŞTUR"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}