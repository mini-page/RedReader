import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../../shared/models/session.dart';

class SessionRepository {
  static const boxName = 'sessions';
  final _uuid = const Uuid();

  Future<Box> _box() async =>
      Hive.isBoxOpen(boxName) ? Hive.box(boxName) : await Hive.openBox(boxName);

  Future<void> save(Session session) async {
    final box = await _box();
    await box.put(session.id, session.toJson());
  }

  Future<void> create({
    required String title,
    required String content,
    required int wpm,
  }) async {
    final session = Session(
      id: _uuid.v4(),
      title: title,
      content: content,
      position: 0,
      wpm: wpm,
      updatedAt: DateTime.now(),
    );
    await save(session);
  }

  Future<void> update(
    String id, {
    String? title,
    String? content,
    int? position,
    int? wpm,
  }) async {
    final box = await _box();
    final json = box.get(id);
    if (json != null) {
      final session =
          Session.fromJson(Map<dynamic, dynamic>.from(json as Map));
      final next = session.copyWith(
        title: title,
        content: content,
        position: position,
        wpm: wpm,
        updatedAt: DateTime.now(),
      );
      await save(next);
    }
  }

  Future<void> delete(String id) async {
    final box = await _box();
    await box.delete(id);
  }

  Future<List<Session>> all() async {
    final box = await _box();
    return box.values
        .map((e) => Session.fromJson(Map<dynamic, dynamic>.from(e as Map)))
        .toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  Future<Session?> latest() async {
    final items = await all();
    return items.isEmpty ? null : items.first;
  }

  Future<void> clearAll() async {
    final box = await _box();
    await box.clear();
  }
}
