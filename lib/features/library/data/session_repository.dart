import 'package:hive_flutter/hive_flutter.dart';

import '../../../shared/models/session.dart';

class SessionRepository {
  static const boxName = 'sessions';

  Future<Box> _box() async => Hive.isBoxOpen(boxName) ? Hive.box(boxName) : await Hive.openBox(boxName);

  Future<void> save(Session session) async {
    final box = await _box();
    await box.put(session.id, session.toJson());
  }

  Future<List<Session>> all() async {
    final box = await _box();
    return box.values.map((e) => Session.fromJson(Map<dynamic, dynamic>.from(e as Map))).toList()
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
