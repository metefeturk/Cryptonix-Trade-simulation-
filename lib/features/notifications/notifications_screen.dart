import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../../providers/app_providers.dart';
import '../../core/constants/app_colors.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationState = ref.watch(notificationProvider);

    return Scaffold(
      appBar: AppBar(title: const Text("Bildirimler")),
      body: notificationState.notifications.isEmpty
          ? const Center(child: Text("Henüz bir bildiriminiz yok.", style: TextStyle(color: Colors.grey)))
          : ListView.builder(
              itemCount: notificationState.notifications.length,
              itemBuilder: (context, index) {
                final notif = notificationState.notifications[index];
                final date = DateFormat('dd MMM HH:mm').format(notif.date);

                return ListTile(
                  onTap: () {
                    if (!notif.isRead) {
                      ref.read(notificationProvider.notifier).markAsRead(notif.id);
                    }
                    context.go('/portfolio');
                  },
                  tileColor: notif.isRead ? null : AppColors.primary.withOpacity(0.05),
                  leading: CircleAvatar(
                    backgroundColor: AppColors.primary.withOpacity(0.1),
                    child: Icon(
                      notif.isRead ? Icons.notifications_none : Icons.notifications_active,
                      color: AppColors.primary,
                    ),
                  ),
                  title: Text(notif.title, style: TextStyle(fontWeight: notif.isRead ? FontWeight.normal : FontWeight.bold)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text(notif.message, style: const TextStyle(fontSize: 13)),
                      const SizedBox(height: 4),
                      Text(date, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                    ],
                  ),
                  trailing: notif.isRead ? null : const CircleAvatar(radius: 4, backgroundColor: AppColors.primary),
                );
              },
            ),
    );
  }
}
