/// "1 game", "2 games". Pass [many] for irregular plurals.
String plural(int n, String one, [String? many]) =>
    '$n ${n == 1 ? one : (many ?? '${one}s')}';

/// Turns an internal id such as `mateIn1` or `middle-game` into words:
/// "Mate in 1", "Middle game".
String humanize(String id) {
  final spaced = id
      .replaceAllMapped(RegExp(r'([a-z])([A-Z])'), (m) => '${m[1]} ${m[2]}')
      .replaceAllMapped(RegExp(r'([a-zA-Z])(\d)'), (m) => '${m[1]} ${m[2]}')
      .replaceAll(RegExp(r'[-_]+'), ' ')
      .trim()
      .toLowerCase();
  return spaced.isEmpty ? id : spaced[0].toUpperCase() + spaced.substring(1);
}
