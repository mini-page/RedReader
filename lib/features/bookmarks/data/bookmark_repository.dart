import 'package:hive_flutter/hive_flutter.dart';
import '../domain/bookmark.dart';

class BookmarkRepository {
  static const boxName = 'bookmarks_v2';

  Future<Box> _box() async =>
      Hive.isBoxOpen(boxName) ? Hive.box(boxName) : await Hive.openBox(boxName);

  Future<void> add(Bookmark b) async {
    final box = await _box();
    await box.put(b.id, b.toJson());
  }

  Future<void> delete(String id) async {
    final box = await _box();
    await box.delete(id);
  }

  Future<List<Bookmark>> getAll() async {
    final box = await _box();
    return box.values
        .map((e) => Bookmark.fromJson(Map<dynamic, dynamic>.from(e as Map)))
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  Future<List<Bookmark>> bySession(String sessionId) async {
    final all = await getAll();
    return all.where((b) => b.sessionId == sessionId).toList();
  }

  Future<void> clearAll() async {
    final box = await _box();
    await box.clear();
  }
}
