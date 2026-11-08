import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
part 'database.g.dart';

@DriftDatabase(include: {'schema.drift'})
class AppDatabase extends _$AppDatabase {
  AppDatabase(File file) : super(NativeDatabase.createInBackground(file));
  AppDatabase.memory() : super(NativeDatabase.memory());
  @override
  int get schemaVersion => 1;
  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    beforeOpen: (_) async => customStatement('PRAGMA foreign_keys = ON'),
  );
  Future<List<Map<String, dynamic>>> rows(
    String sql, [
    List<Object> args = const [],
  ]) async => (await customSelect(
    sql,
    variables: args.map((e) => Variable(e)).toList(),
  ).get()).map((e) => e.data).toList();
  Future<void> execute(String sql, [List<Object?> args = const []]) =>
      customStatement(sql, args);
}
