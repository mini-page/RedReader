import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../library/data/session_repository.dart';
import '../../../shared/models/session.dart';

final sessionRepositoryProvider = Provider<SessionRepository>((ref) => SessionRepository());

final sessionsProvider = AsyncNotifierProvider<SessionsNotifier, List<Session>>(SessionsNotifier.new);

class SessionsNotifier extends AsyncNotifier<List<Session>> {
  @override
  Future<List<Session>> build() async {
    return ref.watch(sessionRepositoryProvider).all();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => ref.read(sessionRepositoryProvider).all());
  }

  Future<void> deleteSession(String id) async {
    await ref.read(sessionRepositoryProvider).delete(id);
    await refresh();
  }
}
