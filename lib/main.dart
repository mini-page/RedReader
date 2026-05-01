import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'app.dart';
import 'features/stats/data/stats_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  
  final container = ProviderContainer();
  await container.read(statsRepositoryProvider).init();
  
  runApp(UncontrolledProviderScope(
    container: container,
    child: const IReaderApp(),
  ));
}
