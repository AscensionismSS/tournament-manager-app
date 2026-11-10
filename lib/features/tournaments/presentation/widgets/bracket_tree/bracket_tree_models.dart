import 'package:flutter/material.dart';
import '../../../models/bracket_slot_dto.dart';
import '../../../models/match_series_dto.dart';

/// Representa um Nó posicionado na árvore de chaveamento.
class BracketNode {
  final BracketSlotDto slot;
  final MatchSeriesDto? match;
  final double x;
  final double y;
  final double width;
  final double height;
  final int column;

  const BracketNode({
    required this.slot,
    this.match,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    required this.column,
  });

  /// Ponto central de saída da borda direita (onde a linha de conexão começa)
  Offset get rightCenter => Offset(x + width, y + (height / 2));

  /// Ponto central de entrada da borda esquerda (onde a linha de conexão termina)
  Offset get leftCenter => Offset(x, y + (height / 2));

  Rect get rect => Rect.fromLTWH(x, y, width, height);
}

/// Representa uma linha de conexão direcionada entre dois confrontos.
class BracketConnection {
  final String sourceCode;
  final String targetCode;
  final Offset from;
  final Offset to;
  final bool isCompleted;
  final bool isWinnerPath;

  const BracketConnection({
    required this.sourceCode,
    required this.targetCode,
    required this.from,
    required this.to,
    this.isCompleted = false,
    this.isWinnerPath = false,
  });
}

/// Banner de identificação de etapa no canvas (Upper, Lower, Grand Final)
class BracketStageBanner {
  final String title;
  final double x;
  final double y;
  final Color color;
  final IconData icon;

  const BracketStageBanner({
    required this.title,
    required this.x,
    required this.y,
    required this.color,
    required this.icon,
  });
}

/// Representa o Nó do Troféu do Campeão posicionado após a Grande Final.
class BracketChampionNode {
  final double x;
  final double y;
  final double width;
  final double height;
  final String? championTeamName;
  final bool isDecided;

  const BracketChampionNode({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    this.championTeamName,
    this.isDecided = false,
  });

  /// Ponto central de entrada da borda esquerda (onde a linha da Grande Final se conecta)
  Offset get leftCenter => Offset(x, y + (height / 2));
}
