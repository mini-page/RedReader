import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/bookmark.dart';
import '../data/bookmark_repository.dart';

final bookmarkRepositoryProvider = Provider((ref) => BookmarkRepository());

final bookmarksProvider = AsyncNotifierProvider<BookmarksNotifier, List<Bookmark>>(BookmarksNotifier.new);

class BookmarksNotifier extends AsyncNotifier<List<Bookmark>> {
  @override
  Future<List<Bookmark>> build() async {
    return ref.watch(bookmarkRepositoryProvider).getAll();
  }

  Future<void> addBookmark(Bookmark b) async {
    await ref.read(bookmarkRepositoryProvider).add(b);
    state = AsyncData(await ref.read(bookmarkRepositoryProvider).getAll());
  }

  Future<void> deleteBookmark(String id) async {
    await ref.read(bookmarkRepositoryProvider).delete(id);
    state = AsyncData(await ref.read(bookmarkRepositoryProvider).getAll());
  }

  Future<void> clearAll() async {
    await ref.read(bookmarkRepositoryProvider).clearAll();
    state = const AsyncData([]);
  }
}
