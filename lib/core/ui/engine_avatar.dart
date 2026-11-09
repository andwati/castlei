import 'package:flutter/material.dart';

import '../chess/engine_opponents.dart';

class EngineAvatar extends StatelessWidget {
  const EngineAvatar({super.key, required this.opponent, this.size = 48});
  final EngineOpponent opponent;
  final double size;
  @override
  Widget build(BuildContext context) => Semantics(
    image: true,
    label: '${opponent.label} engine avatar',
    child: SizedBox.square(
      dimension: size,
      child: ClipOval(
        child: Image.asset(
          opponent.asset,
          width: size,
          height: size,
          fit: BoxFit.cover,
          cacheWidth: 256,
          excludeFromSemantics: true,
        ),
      ),
    ),
  );
}
