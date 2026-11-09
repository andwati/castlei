import 'dart:convert';

import 'package:dartchess/dartchess.dart';
import 'package:flutter/services.dart';

class LessonExercise {
  LessonExercise(Map<String, dynamic> data)
    : goal = data['goal'],
      hint = data['hint'],
      options = List<String>.from(data['options'] ?? []),
      correct = data['correct'] ?? 0,
      solutions = [
        for (final line in data['solutions'] ?? []) List<String>.from(line),
      ],
      initial = _initial(data);
  final String goal, hint;
  final List<String> options;
  final int correct;
  final List<List<String>> solutions;
  final Position initial;
  static Position _initial(Map<String, dynamic> data) {
    Position position = data['fen'] == null
        ? Chess.initial
        : Chess.fromSetup(Setup.parseFen(data['fen']));
    for (final uci in data['prefix'] ?? []) {
      final move = Move.parse(uci)!;
      if (!position.isLegal(move)) {
        throw FormatException('Illegal lesson setup: $uci');
      }
      position = position.play(move);
    }
    return position;
  }

  void validate() {
    if (options.isNotEmpty) {
      if (correct < 0 || correct >= options.length) {
        throw const FormatException('Invalid answer');
      }
      return;
    }
    if (solutions.isEmpty) throw const FormatException('Missing solution');
    for (final line in solutions) {
      var p = initial;
      if (line.isEmpty) throw const FormatException('Empty solution');
      for (final uci in line) {
        final move = Move.parse(uci);
        if (move == null || !p.isLegal(move)) {
          throw FormatException('Illegal exercise move $uci in ${p.fen}');
        }
        p = p.play(move);
      }
    }
  }
}

class GuidedLesson {
  GuidedLesson(Map<String, dynamic> data)
    : id = data['id'],
      module = data['module'],
      title = data['title'],
      body = data['body'],
      exercises = [
        for (final e in data['exercises'])
          LessonExercise(Map<String, dynamic>.from(e)),
      ];
  final String id, module, title, body;
  final List<LessonExercise> exercises;
}

Future<List<GuidedLesson>> loadLessons() async => [
  for (final row in jsonDecode(
    await rootBundle.loadString('assets/lessons.json', cache: false),
  ))
    GuidedLesson(Map<String, dynamic>.from(row)),
];
