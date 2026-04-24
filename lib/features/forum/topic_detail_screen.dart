import 'package:appwrite/models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../providers/app_providers.dart';
import '../../core/constants/app_colors.dart';

class TopicDetailScreen extends ConsumerStatefulWidget {
  final Document topic;
  const TopicDetailScreen({super.key, required this.topic});

  @override
  ConsumerState<TopicDetailScreen> createState() => _TopicDetailScreenState();
}

class _TopicDetailScreenState extends ConsumerState<TopicDetailScreen> {
  final _commentController = TextEditingController();
  bool _isSending = false;

  Future<void> _sendComment() async {
    if (_commentController.text.isEmpty) return;

    setState(() => _isSending = true);
    try {
      final user = await ref.read(currentUserProvider.future);
      if (user == null) return;

      await ref.read(forumServiceProvider).createComment(
        widget.topic.$id,
        _commentController.text,
        user.$id,
        user.name,
      );

      _commentController.clear();
      ref.refresh(forumCommentsProvider(widget.topic.$id)); // Yorumları yenile
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Hata: $e")));
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final commentsAsync = ref.watch(forumCommentsProvider(widget.topic.$id));
    final date = DateTime.parse(widget.topic.data['createdAt']);
    final formattedDate = DateFormat('dd MMM yyyy HH:mm').format(date);

    return Scaffold(
      appBar: AppBar(title: const Text("Konu Detayı")),
      body: Column(
        children: [
          // Konu İçeriği
          Container(
            padding: const EdgeInsets.all(16),
            color: Theme.of(context).cardColor,
            width: double.infinity,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.topic.data['title'], style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(
                  "${widget.topic.data['authorName']} • $formattedDate",
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
                const SizedBox(height: 16),
                Text(widget.topic.data['content'], style: const TextStyle(fontSize: 16)),
              ],
            ),
          ),
          const Divider(height: 1),
          
          // Yorumlar Listesi
          Expanded(
            child: commentsAsync.when(
              data: (comments) {
                if (comments.isEmpty) {
                  return const Center(child: Text("Henüz yorum yok. İlk yorumu sen yap!"));
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: comments.length,
                  itemBuilder: (context, index) {
                    final comment = comments[index];
                    final cDate = DateTime.parse(comment.data['createdAt']);
                    final cFormattedDate = DateFormat('dd MMM HH:mm').format(cDate);

                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.withOpacity(0.2)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(comment.data['authorName'], style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
                              Text(cFormattedDate, style: const TextStyle(fontSize: 10, color: Colors.grey)),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(comment.data['content']),
                        ],
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text("Yorumlar yüklenemedi: $err")),
            ),
          ),

          // Yorum Yazma Alanı
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    decoration: InputDecoration(
                      hintText: "Yorum yaz...",
                      filled: true,
                      fillColor: Theme.of(context).cardColor,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _isSending ? null : _sendComment,
                  icon: _isSending ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.send, color: AppColors.primary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}