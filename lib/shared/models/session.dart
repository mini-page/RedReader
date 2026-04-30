class Session {
  final String id;
  final String title;
  final String content;
  final int position;
  final int wpm;
  final DateTime updatedAt;

  const Session({required this.id, required this.title, required this.content, required this.position, required this.wpm, required this.updatedAt});

  Session copyWith({String? id, String? title, String? content, int? position, int? wpm, DateTime? updatedAt}) => Session(
        id: id ?? this.id,
        title: title ?? this.title,
        content: content ?? this.content,
        position: position ?? this.position,
        wpm: wpm ?? this.wpm,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'content': content,
        'position': position,
        'wpm': wpm,
        'updatedAt': updatedAt.toIso8601String(),
      };

  static Session fromJson(Map<dynamic, dynamic> json) => Session(
        id: json['id'] as String,
        title: json['title'] as String,
        content: json['content'] as String,
        position: json['position'] as int,
        wpm: json['wpm'] as int,
        updatedAt: DateTime.parse(json['updatedAt'] as String),
      );
}
