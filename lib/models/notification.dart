class AppNotification {
  final String id;
  final String type;
  final String title;
  final String content;
  final String? relatedId;
  final String? deepLink;
  final DateTime? readAt;
  final DateTime createdAt;

  AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.content,
    this.relatedId,
    this.deepLink,
    this.readAt,
    required this.createdAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'] ?? '',
      type: json['type'] ?? '',
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      relatedId: json['related_id'],
      deepLink: json['deep_link'],
      readAt: json['read_at'] != null ? DateTime.tryParse(json['read_at']) : null,
      createdAt: json['created_at'] != null 
          ? (DateTime.tryParse(json['created_at']) ?? DateTime.now()) 
          : DateTime.now(),
    );
  }
}
