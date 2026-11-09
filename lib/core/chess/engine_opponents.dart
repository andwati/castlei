/// Visual identities for the existing Stockfish skill settings.
/// These are fictional portraits; they do not change engine behavior or ratings.
class EngineOpponent {
  const EngineOpponent(this.skill, this.label, this.asset);
  final int skill;
  final String label, asset;
  static const all = [
    EngineOpponent(0, 'Gentle', 'assets/avatars/gentle.png'),
    EngineOpponent(5, 'Easy', 'assets/avatars/easy.png'),
    EngineOpponent(10, 'Medium', 'assets/avatars/medium.png'),
    EngineOpponent(15, 'Hard', 'assets/avatars/hard.png'),
    EngineOpponent(20, 'Maximum', 'assets/avatars/maximum.png'),
  ];
  static EngineOpponent forSkill(int skill) => all[(skill.clamp(0, 20) ~/ 5)];
  static EngineOpponent fromSettings(Map<String, dynamic> settings) {
    final skill = settings['skill'];
    if (skill is num) return forSkill(skill.toInt());
    return all
            .where((opponent) => opponent.label == settings['level'])
            .firstOrNull ??
        all[2];
  }
}
