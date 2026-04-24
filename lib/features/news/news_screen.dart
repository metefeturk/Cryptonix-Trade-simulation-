import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';
import '../../providers/app_providers.dart';

class NewsScreen extends ConsumerWidget {
  const NewsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final newsAsync = ref.watch(newsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text("Kripto Haberler")),
      body: newsAsync.when(
        data: (newsList) {
          return ListView.builder(
            itemCount: newsList.length,
            itemBuilder: (context, index) {
              final news = newsList[index];
              return Card(
              margin: const EdgeInsets.all(12),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () {
                  context.push('/news-detail', extra: news);
                },
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CachedNetworkImage(
                      imageUrl: news['image']!,
                      height: 180,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(height: 180, color: Colors.grey[300]),
                      errorWidget: (context, url, error) => Container(height: 180, color: Colors.grey[300], child: const Icon(Icons.error)),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                                child: Text(news['source']!, style: const TextStyle(color: Colors.blue, fontSize: 12, fontWeight: FontWeight.bold)),
                              ),
                              const Spacer(),
                              const Text("Bugün", style: TextStyle(color: Colors.grey, fontSize: 12)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(news['title']!, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          Text(
                            news['description']!,
                            style: const TextStyle(color: Colors.grey),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    )
                  ],
                ),
              ),
            );
        },
          );
        },
        loading: () => _buildLoadingSkeleton(),
        error: (err, stack) => Center(child: Text("Hata: $err")),
      ),
    );
  }

  Widget _buildLoadingSkeleton() {
    return ListView.builder(
      itemCount: 5,
      itemBuilder: (_, __) => Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: Card(
          margin: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(height: 180, width: double.infinity, color: Colors.white),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(height: 14, width: 80, color: Colors.white),
                    const SizedBox(height: 12),
                    Container(height: 20, width: double.infinity, color: Colors.white),
                    const SizedBox(height: 8),
                    Container(height: 20, width: 250, color: Colors.white),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
