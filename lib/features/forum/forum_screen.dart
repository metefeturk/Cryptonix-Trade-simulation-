import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../providers/app_providers.dart';
import '../../core/constants/app_colors.dart';

class ForumScreen extends ConsumerStatefulWidget {
  const ForumScreen({super.key});

  @override
  ConsumerState<ForumScreen> createState() => _ForumScreenState();
}

class _ForumScreenState extends ConsumerState<ForumScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";

  @override
  Widget build(BuildContext context) {
    final topicsAsync = ref.watch(forumTopicsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Kripto Forum"),
      ),
      body: Column(
        children: [
          // Arama Çubuğu
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              onChanged: (val) {
                setState(() {
                  _searchQuery = val.toLowerCase();
                });
              },
              decoration: InputDecoration(
                hintText: "Konu başlığı ara...",
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Theme.of(context).cardColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          // Konu Listesi
          Expanded(
            child: topicsAsync.when(
              data: (topics) {
                final filteredTopics = topics.where((doc) {
                  final title = (doc.data['title'] as String).toLowerCase();
                  return title.contains(_searchQuery);
                }).toList();

                if (filteredTopics.isEmpty) {
                  return const Center(child: Text("Henüz bir konu yok veya arama sonucu bulunamadı."));
                }

                return ListView.builder(
                  itemCount: filteredTopics.length,
                  itemBuilder: (context, index) {
                    final topic = filteredTopics[index];
                    final date = DateTime.parse(topic.data['createdAt']);
                    final formattedDate = DateFormat('dd MMM yyyy HH:mm').format(date);

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: ListTile(
                        onTap: () {
                          context.push('/forum-detail', extra: topic);
                        },
                        leading: CircleAvatar(
                          backgroundColor: AppColors.primary.withOpacity(0.2),
                          child: Text(
                            (topic.data['authorName'] as String)[0].toUpperCase(),
                            style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                          ),
                        ),
                        title: Text(
                          topic.data['title'],
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text(topic.data['content'], maxLines: 2, overflow: TextOverflow.ellipsis),
                            const SizedBox(height: 4),
                            Text("${topic.data['authorName']} • $formattedDate", style: const TextStyle(fontSize: 11, color: Colors.grey)),
                          ],
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text("Hata: $err")),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          context.push('/create-topic');
        },
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}