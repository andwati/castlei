import 'package:castlei/core/ui/plural.dart';
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
}
