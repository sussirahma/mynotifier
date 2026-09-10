class NotificationModel {
  final String packageName;
  final String title;
  final String text;
  final String timestamp;

  NotificationModel({
    required this.packageName,
    required this.title,
    required this.text,
    required this.timestamp,
  });

  factory NotificationModel.fromMap(
    Map<dynamic, dynamic> map,
  ) {
    return NotificationModel(
      packageName: map['packageName']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      text: map['text']?.toString() ?? '',
      timestamp: map['timestamp']?.toString() ?? '',
    );
  }
}