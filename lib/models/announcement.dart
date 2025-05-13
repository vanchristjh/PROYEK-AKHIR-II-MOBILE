import 'package:intl/intl.dart';

class Announcement {
  final String id;
  final String title;
  final String content;
  final DateTime publishDate;
  final String authorId;
  final String authorName;
  final List<String> targetAudience; // "all", "teachers", "students", "class_id"
  final DateTime? expiryDate;
  final String type; // "urgent", "important", "academic", "event", etc.

  Announcement({
    required this.id,
    required this.title,
    required this.content,
    required this.publishDate,
    required this.authorId,
    required this.authorName,
    required this.targetAudience,
    this.expiryDate,
    this.type = 'normal',
  });
  factory Announcement.fromMap(Map<String, dynamic> map) {
    return Announcement(
      id: map['id'],
      title: map['title'],
      content: map['content'],
      publishDate: DateTime.parse(map['publishDate']),
      authorId: map['authorId'],
      authorName: map['authorName'],
      targetAudience: List<String>.from(map['targetAudience']),
      expiryDate: map['expiryDate'] != null
          ? DateTime.parse(map['expiryDate'])
          : null,
      type: map['type'] ?? 'normal',
    );
  }
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'publishDate': publishDate.toIso8601String(),
      'authorId': authorId,
      'authorName': authorName,
      'targetAudience': targetAudience,
      'expiryDate': expiryDate?.toIso8601String(),
      'type': type,
    };
  }

  String get formattedPublishDate {
    return DateFormat('dd MMMM yyyy').format(publishDate);
  }

  bool get isExpired {
    if (expiryDate == null) return false;
    return DateTime.now().isAfter(expiryDate!);
  }
}
