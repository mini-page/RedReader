class Bookmark {
  final String id;
  final String word;
  final int index;
  final String sessionId;
  final String sessionTitle;
  final DateTime createdAt;

  Bookmark({
    required this.id,
    required this.word,
    required this.index,
    required this.sessionId,
    required this.sessionTitle,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'word': word,
        'index': index,
        'sessionId': sessionId,
        'sessionTitle': sessionTitle,
        'createdAt': createdAt.toIso8601String(),
      };

  static Bookmark fromJson(Map<dynamic, dynamic> json) => Bookmark(
        id: json['id'] as String,
        word: json['word'] as String,
        index: json['index'] as int,
        sessionId: json['sessionId'] as String,
        sessionTitle: json['sessionTitle'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}
