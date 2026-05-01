import 'package:hive/hive.dart';

@HiveType(typeId: 2)
class ReadingStats {
  @HiveField(0)
  final int totalWordsRead;
  
  @HiveField(1)
  final int totalTimeSeconds;
  
  @HiveField(2)
  final int sessionsCount;
  
  @HiveField(3)
  final double averageWpm;
  
  @HiveField(4)
  final DateTime lastSessionDate;
  
  @HiveField(5)
  final Map<String, int> dailyWords; // "yyyy-MM-dd" -> words

  const ReadingStats({
    required this.totalWordsRead,
    required this.totalTimeSeconds,
    required this.sessionsCount,
    required this.averageWpm,
    required this.lastSessionDate,
    required this.dailyWords,
  });

  factory ReadingStats.initial() => ReadingStats(
    totalWordsRead: 0,
    totalTimeSeconds: 0,
    sessionsCount: 0,
    averageWpm: 0,
    lastSessionDate: DateTime.now(),
    dailyWords: {},
  );

  ReadingStats copyWith({
    int? totalWordsRead,
    int? totalTimeSeconds,
    int? sessionsCount,
    double? averageWpm,
    DateTime? lastSessionDate,
    Map<String, int>? dailyWords,
  }) => ReadingStats(
    totalWordsRead: totalWordsRead ?? this.totalWordsRead,
    totalTimeSeconds: totalTimeSeconds ?? this.totalTimeSeconds,
    sessionsCount: sessionsCount ?? this.sessionsCount,
    averageWpm: averageWpm ?? this.averageWpm,
    lastSessionDate: lastSessionDate ?? this.lastSessionDate,
    dailyWords: dailyWords ?? this.dailyWords,
  );
}
