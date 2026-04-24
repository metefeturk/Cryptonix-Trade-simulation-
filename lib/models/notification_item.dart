class NotificationItem {
  final String id;
  final String title;
  final String message;
  final DateTime date;
  final bool isRead;

  NotificationItem({
    required this.id,
    required this.title,
    required this.message,
    required this.date,
    this.isRead = false,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'message': message,
    'date': date.toIso8601String(),
    'isRead': isRead,
  };

  factory NotificationItem.fromJson(Map<String, dynamic> json) => NotificationItem(
    id: json['id'],
    title: json['title'],
    message: json['message'],
    date: DateTime.parse(json['date']),
    isRead: json['isRead'] ?? false,
  );
}