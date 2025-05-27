class Announcement {
  final String id;
  final String title;
  final String content;
  final DateTime publishDate;
  final String authorId;
  final String authorName;
  final String type;
  final List<String> targetAudience;
  final DateTime? expiryDate;

  Announcement({
    required this.id,
    required this.title,
    required this.content,
    required this.publishDate,
    required this.authorId,
    required this.authorName,
    required this.type,
    required this.targetAudience,
    this.expiryDate,
  });

  String get date => publishDate.toIso8601String();
  String get author => authorName;

  factory Announcement.fromMap(Map<String, dynamic> map) {
    return Announcement(
      id: map['id'],
      title: map['title'],
      content: map['content'],
      publishDate: DateTime.parse(map['publishDate']),
      authorId: map['authorId'],
      authorName: map['authorName'],
      type: map['type'],
      targetAudience: List<String>.from(map['targetAudience']),
      expiryDate: map['expiryDate'] != null
          ? DateTime.parse(map['expiryDate'])
          : null,
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
      'type': type,
      'targetAudience': targetAudience,
      'expiryDate': expiryDate?.toIso8601String(),
    };
  }
}