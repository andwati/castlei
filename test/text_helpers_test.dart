import 'package:castlei/core/ui/plural.dart';
import 'package:castlei/features/statistics/statistics.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('plural handles one and many', () {
    expect(plural(1, 'game'), '1 game');
    expect(plural(0, 'game'), '0 games');
    expect(plural(2, 'repertoire card'), '2 repertoire cards');
    expect(plural(2, 'story', 'stories'), '2 stories');
  });

  test('humanize turns ids into words', () {
    expect(humanize('mateIn1'), 'Mate in 1');
    expect(humanize('oneMove'), 'One move');
    expect(humanize('middlegame'), 'Middlegame');
    expect(humanize('mixed-01'), 'Mixed 01');
    expect(humanize(''), '');
  });

  test('milestones unlock from lifetime totals', () {
    final none = milestones(
      finishedGames: 0,
      puzzles: 0,
      lessons: 0,
      drills: 0,
    );
    expect(none.any((m) => m.earned), isFalse);
    final some = milestones(
      finishedGames: 1,
      puzzles: 30,
      lessons: 0,
      drills: 0,
    );
    expect(some.where((m) => m.earned).map((m) => m.label), [
      'First game finished',
      'First puzzle solved',
      '25 puzzles solved',
    ]);
  });
}
