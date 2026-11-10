import 'dart:math' as math;
import '../../../../../core/theme/theme.dart';
import 'package:flutter/material.dart';
import '../../../models/bracket_slot_dto.dart';
import '../../../models/match_series_dto.dart';
import 'bracket_tree_models.dart';

/// Resultado do cálculo geométrico da árvore de chaveamento.
class BracketTreeLayoutResult {
  final List<BracketNode> nodes;
  final List<BracketConnection> connections;
  final Map<int, String> columnTitles;
  final List<BracketStageBanner> stageBanners;
  final BracketChampionNode? championNode;
  final double totalWidth;
  final double totalHeight;

  const BracketTreeLayoutResult({
    required this.nodes,
    required this.connections,
    required this.columnTitles,
    this.stageBanners = const [],
    this.championNode,
    required this.totalWidth,
    required this.totalHeight,
  });
}

/// Motor de Layout Dinâmico para Árvores de Chaveamento de E-sports.
/// Suporta tanto o Layout Unificado de Eliminação Dupla (Upper + Lower com Grande Final à direita)
/// quanto árvores simples ou isoladas por etapa.
class BracketTreeLayoutEngine {
  final double cardWidth;
  final double cardHeight;
  final double columnGap;
  final double baseRowGap;

  const BracketTreeLayoutEngine({
    this.cardWidth = 280.0,
    this.cardHeight = 120.0,
    this.columnGap = 44.0,
    this.baseRowGap = 24.0,
  });

  BracketTreeLayoutResult computeLayout({
    required List<BracketSlotDto> slots,
    required Map<String, MatchSeriesDto> matchesByCode,
    String? stageName,
  }) {
    if (slots.isEmpty) {
      return const BracketTreeLayoutResult(
        nodes: [],
        connections: [],
        columnTitles: {},
        stageBanners: [],
        totalWidth: 0,
        totalHeight: 0,
      );
    }

    final hasUpper = slots.any((s) => s.stage == 'Upper');
    final hasLower =
        slots.any((s) => s.stage == 'Lower' || s.stage == 'PlayIn');

    // Se for exibição de todas as chaves em Eliminação Dupla, gera o layout unificado com GF à direita:
    final isDoubleEliminationUnified = hasUpper &&
        hasLower &&
        (stageName == null || stageName.toUpperCase().contains('TODAS'));

    if (isDoubleEliminationUnified) {
      return _computeDoubleEliminationUnifiedLayout(
        slots: slots,
        matchesByCode: matchesByCode,
      );
    }

    // Caso contrário (Mata-Mata Simples ou aba isolada de etapa), gera layout de árvore direta:
    return _computeSingleTreeLayout(
      slots: slots,
      matchesByCode: matchesByCode,
      stageName: stageName,
    );
  }

  /// Layout Unificado de Eliminação Dupla:
  /// - Topo: Chave Superior (Upper Bracket)
  /// - Base: Chave Inferior (Lower Bracket)
  /// - Extrema Direita: Grande Final no ponto médio vertical exato entre a Final da Upper e da Lower!
  BracketTreeLayoutResult _computeDoubleEliminationUnifiedLayout({
    required List<BracketSlotDto> slots,
    required Map<String, MatchSeriesDto> matchesByCode,
  }) {
    final upperSlots = slots.where((s) => s.stage == 'Upper').toList();
    final lowerSlots =
        slots.where((s) => s.stage == 'Lower' || s.stage == 'PlayIn').toList();
    final gfSlots = slots.where((s) => s.stage == 'GrandFinal').toList();

    // 1. Layout da Chave Superior (inicia em Y = 36 para dar espaço ao banner da Upper)
    final upperLayout = _computeSingleTreeLayout(
      slots: upperSlots,
      matchesByCode: matchesByCode,
      stageName: 'UPPER',
      offsetY: 36.0,
    );

    // 2. Layout da Chave Inferior (posicionado abaixo da Upper com espaçamento generoso)
    final double lowerOffsetY = upperLayout.totalHeight + 56.0;
    final lowerLayout = _computeSingleTreeLayout(
      slots: lowerSlots,
      matchesByCode: matchesByCode,
      stageName: 'LOWER',
      offsetY: lowerOffsetY + 36.0,
    );

    final allNodes = <BracketNode>[...upperLayout.nodes, ...lowerLayout.nodes];
    final allConnections = <BracketConnection>[
      ...upperLayout.connections,
      ...lowerLayout.connections,
    ];

    // 3. Coluna da Grande Final (posicionada na coluna seguinte ao maior avanço de Upper e Lower)
    int maxCol = 0;
    for (final node in allNodes) {
      if (node.column > maxCol) maxCol = node.column;
    }
    final int gfColumn = maxCol + 1;
    final double gfX = gfColumn * (cardWidth + columnGap);

    // Encontra os nós finais que alimentam a Grande Final
    final ufNode = upperLayout.nodes.cast<BracketNode?>().firstWhere(
          (n) => n != null && n.slot.code == 'UF',
          orElse: () =>
              upperLayout.nodes.isNotEmpty ? upperLayout.nodes.last : null,
        );

    final lfNode = lowerLayout.nodes.cast<BracketNode?>().firstWhere(
          (n) => n != null && n.slot.code == 'LF',
          orElse: () =>
              lowerLayout.nodes.isNotEmpty ? lowerLayout.nodes.last : null,
        );

    // Ponto Médio Vertical exato da Grande Final entre a Final Upper e a Final Lower!
    const double gfHeight = 96.0;
    double gfY;
    if (ufNode != null && lfNode != null) {
      final double targetCenterY =
          (ufNode.rightCenter.dy + lfNode.rightCenter.dy) / 2;
      gfY = targetCenterY - (gfHeight / 2);
    } else if (ufNode != null) {
      gfY = ufNode.rightCenter.dy - (gfHeight / 2);
    } else {
      gfY = lowerOffsetY;
    }

    BracketChampionNode? championNode;
    int champColumn = gfColumn;
    double champX = gfX;
    double champWidth = cardWidth;
    double champHeight = 0.0;
    double champY = gfY;

    if (gfSlots.isNotEmpty) {
      final gfSlot = gfSlots.first;
      final gfMatch = matchesByCode[gfSlot.code];

      final gfNode = BracketNode(
        slot: gfSlot,
        match: gfMatch,
        x: gfX,
        y: gfY,
        width: cardWidth,
        height: gfHeight,
        column: gfColumn,
      );
      allNodes.add(gfNode);

      // Conexão da Final da Upper para a Grande Final
      if (ufNode != null) {
        final isUFDone = ufNode.match?.isCompleted ?? false;
        allConnections.add(BracketConnection(
          sourceCode: ufNode.slot.code,
          targetCode: gfSlot.code,
          from: ufNode.rightCenter,
          to: gfNode.leftCenter,
          isCompleted: isUFDone,
          isWinnerPath: isUFDone && ufNode.match?.winnerTeamId != null,
        ));
      }

      // Conexão da Final da Lower para a Grande Final
      if (lfNode != null) {
        final isLFDone = lfNode.match?.isCompleted ?? false;
        allConnections.add(BracketConnection(
          sourceCode: lfNode.slot.code,
          targetCode: gfSlot.code,
          from: lfNode.rightCenter,
          to: gfNode.leftCenter,
          isCompleted: isLFDone,
          isWinnerPath: isLFDone && lfNode.match?.winnerTeamId != null,
        ));
      }

      // 3.1. Nó do Troféu / Campeão (Aegis Tsurus) posicionado à direita da Grande Final!
      final isGfDone = gfMatch?.isCompleted ?? false;
      final championTeamName = gfMatch?.winnerTeamName;
      final bool isDecided =
          isGfDone && championTeamName != null && championTeamName.isNotEmpty;

      champWidth = 280.0;
      champHeight = 280.0;
      champColumn = gfColumn + 1;
      champX = champColumn * (cardWidth + columnGap) + 32.0;
      champY = math.max(12.0, gfNode.rightCenter.dy - (champHeight / 2));

      championNode = BracketChampionNode(
        x: champX,
        y: champY,
        width: champWidth,
        height: champHeight,
        championTeamName: championTeamName,
        isDecided: isDecided,
      );

      // Conexão direta horizontal da Grande Final para o Troféu do Campeão!
      allConnections.add(BracketConnection(
        sourceCode: gfSlot.code,
        targetCode: 'CHAMPION',
        from: gfNode.rightCenter,
        to: championNode.leftCenter,
        isCompleted: isGfDone,
        isWinnerPath: isDecided,
      ));
    }

    // 4. Banners de Etapa no Canvas (Títulos limpos sem subtítulos)
    final stageBanners = <BracketStageBanner>[
      const BracketStageBanner(
        title: 'CHAVE SUPERIOR (UPPER BRACKET)',
        x: 0,
        y: 4,
        color: AppColors.feedbackSuccess,
        icon: Icons.keyboard_double_arrow_up_rounded,
      ),
      BracketStageBanner(
        title: 'CHAVE INFERIOR & REPESCAGEM (LOWER BRACKET)',
        x: 0,
        y: lowerOffsetY + 4,
        color: AppColors.primaryNeon,
        icon: Icons.keyboard_arrow_right_rounded,
      ),
      if (gfSlots.isNotEmpty)
        BracketStageBanner(
          title: 'GRANDE FINAL (DECISÃO DO TÍTULO)',
          x: gfX,
          y: math.max(4.0, gfY - 32.0),
          color: AppColors.dotaGold,
          icon: Icons.emoji_events_rounded,
        ),
    ];

    // 5. Cabeçalhos de Colunas
    final columnTitles = <int, String>{};
    for (int i = 0; i <= maxCol; i++) {
      columnTitles[i] = 'RODADA ${i + 1}';
    }
    if (gfSlots.isNotEmpty) {
      columnTitles[gfColumn] = 'GRANDE FINAL';
      columnTitles[champColumn] = 'CAMPEÃO DO TORNEIO';
    }

    // 6. Dimensões Finais (estendidas até o Troféu do Campeão)
    final double totalWidth = championNode != null
        ? champX + champWidth + 32.0
        : (gfSlots.isNotEmpty
            ? gfX + cardWidth + 32.0
            : maxCol * (cardWidth + columnGap) + cardWidth + 32.0);

    double maxY = 0.0;
    for (final node in allNodes) {
      if (node.y + node.height > maxY) maxY = node.y + node.height;
    }
    if (championNode != null && champY + champHeight > maxY) {
      maxY = champY + champHeight;
    }

    return BracketTreeLayoutResult(
      nodes: allNodes,
      connections: allConnections,
      columnTitles: columnTitles,
      stageBanners: stageBanners,
      championNode: championNode,
      totalWidth: totalWidth,
      totalHeight: maxY + 24.0,
    );
  }

  /// Layout para uma única árvore/etapa
  BracketTreeLayoutResult _computeSingleTreeLayout({
    required List<BracketSlotDto> slots,
    required Map<String, MatchSeriesDto> matchesByCode,
    String? stageName,
    double offsetY = 0.0,
  }) {
    if (slots.isEmpty) {
      return const BracketTreeLayoutResult(
        nodes: [],
        connections: [],
        columnTitles: {},
        stageBanners: [],
        totalWidth: 0,
        totalHeight: 0,
      );
    }

    final roundsMap = <int, List<BracketSlotDto>>{};
    for (final slot in slots) {
      roundsMap.putIfAbsent(slot.round, () => []).add(slot);
    }
    final sortedRounds = roundsMap.keys.toList()..sort();

    final roundToColumn = <int, int>{};
    for (int i = 0; i < sortedRounds.length; i++) {
      roundToColumn[sortedRounds[i]] = i;
    }

    int anchorRound = sortedRounds.first;
    int maxSlotsCount = 0;
    for (final r in sortedRounds) {
      if (roundsMap[r]!.length > maxSlotsCount) {
        maxSlotsCount = roundsMap[r]!.length;
        anchorRound = r;
      }
    }
    final int anchorColumnIndex = roundToColumn[anchorRound]!;

    final yCoordinates = <String, double>{};
    final anchorSlots = roundsMap[anchorRound]!;
    final double stepY = cardHeight + baseRowGap;
    for (int i = 0; i < anchorSlots.length; i++) {
      yCoordinates[anchorSlots[i].code] = offsetY + (i * stepY);
    }

    // Propaga para frente (semi -> final)
    for (int colIdx = anchorColumnIndex + 1;
        colIdx < sortedRounds.length;
        colIdx++) {
      final r = sortedRounds[colIdx];
      final currentSlots = roundsMap[r]!;

      for (int i = 0; i < currentSlots.length; i++) {
        final slot = currentSlots[i];
        final feederSlots =
            slots.where((s) => s.winnerTargetSlotCode == slot.code).toList();
        final feederYs = feederSlots
            .map((s) => yCoordinates[s.code])
            .whereType<double>()
            .toList();

        if (feederYs.isNotEmpty) {
          final sum = feederYs.reduce((a, b) => a + b);
          yCoordinates[slot.code] = sum / feederYs.length;
        } else {
          yCoordinates[slot.code] = offsetY + (i * stepY);
        }
      }
    }

    // Propaga para trás (ex: Play-In -> Lower R1)
    for (int colIdx = anchorColumnIndex - 1; colIdx >= 0; colIdx--) {
      final r = sortedRounds[colIdx];
      final currentSlots = roundsMap[r]!;

      for (int i = 0; i < currentSlots.length; i++) {
        final slot = currentSlots[i];
        if (slot.winnerTargetSlotCode != null &&
            yCoordinates.containsKey(slot.winnerTargetSlotCode)) {
          yCoordinates[slot.code] = yCoordinates[slot.winnerTargetSlotCode]!;
        } else {
          yCoordinates[slot.code] = offsetY + (i * stepY);
        }
      }
    }

    final nodes = <BracketNode>[];
    final nodesByCode = <String, BracketNode>{};
    final columnTitles = <int, String>{};

    for (final slot in slots) {
      final colIndex = roundToColumn[slot.round]!;
      final x = colIndex * (cardWidth + columnGap);
      final y = yCoordinates[slot.code] ?? offsetY;
      final match = matchesByCode[slot.code];

      final hasTargets =
          slot.winnerTargetSlotCode != null || slot.loserTargetSlotCode != null;
      final double nodeHeight = hasTargets ? cardHeight : 96.0;

      final node = BracketNode(
        slot: slot,
        match: match,
        x: x,
        y: y,
        width: cardWidth,
        height: nodeHeight,
        column: colIndex,
      );

      nodes.add(node);
      nodesByCode[slot.code] = node;

      if (!columnTitles.containsKey(colIndex)) {
        final roundSlots = roundsMap[slot.round]!;
        final isLastRound = colIndex == sortedRounds.length - 1;
        String title;
        if (isLastRound && roundSlots.length == 1) {
          title =
              (stageName != null && stageName.toUpperCase().contains('UPPER'))
                  ? 'FINAL DA UPPER'
                  : ((stageName != null &&
                          stageName.toUpperCase().contains('LOWER'))
                      ? 'FINAL DA LOWER'
                      : 'GRANDE FINAL');
        } else if (slot.stage == 'PlayIn') {
          title = 'PLAY-IN';
        } else {
          title = 'RODADA ${colIndex + 1}';
        }
        columnTitles[colIndex] = title;
      }
    }

    final connections = <BracketConnection>[];
    for (final node in nodes) {
      final targetCode = node.slot.winnerTargetSlotCode;
      if (targetCode != null && nodesByCode.containsKey(targetCode)) {
        final targetNode = nodesByCode[targetCode]!;
        final match = node.match;
        final isCompleted = match?.isCompleted ?? false;

        connections.add(BracketConnection(
          sourceCode: node.slot.code,
          targetCode: targetCode,
          from: node.rightCenter,
          to: targetNode.leftCenter,
          isCompleted: isCompleted,
          isWinnerPath: isCompleted && match?.winnerTeamId != null,
        ));
      }
    }

    // Se houver confronto de Grande Final, posiciona o Troféu do Campeão após ela
    BracketChampionNode? championNode;
    final gfNode = nodes.cast<BracketNode?>().firstWhere(
          (n) => n != null && n.slot.stage == 'GrandFinal',
          orElse: () => null,
        );

    if (gfNode != null) {
      final gfMatch = gfNode.match;
      final isGfDone = gfMatch?.isCompleted ?? false;
      final championTeamName = gfMatch?.winnerTeamName;
      final bool isDecided =
          isGfDone && championTeamName != null && championTeamName.isNotEmpty;

      const double champWidth = 280.0;
      const double champHeight = 280.0;
      final int champColIndex = sortedRounds.length;
      final double champX = champColIndex * (cardWidth + columnGap) + 32.0;
      double champY = gfNode.rightCenter.dy - (champHeight / 2);

      // Se champY for menor que 12px, desloca verticalmente todos os nós para que o Aegis não seja cortado
      if (champY < 12.0) {
        final double shiftY = 12.0 - champY;
        for (int i = 0; i < nodes.length; i++) {
          final n = nodes[i];
          nodes[i] = BracketNode(
            slot: n.slot,
            match: n.match,
            x: n.x,
            y: n.y + shiftY,
            width: n.width,
            height: n.height,
            column: n.column,
          );
        }
        for (int i = 0; i < connections.length; i++) {
          final c = connections[i];
          connections[i] = BracketConnection(
            sourceCode: c.sourceCode,
            targetCode: c.targetCode,
            from: Offset(c.from.dx, c.from.dy + shiftY),
            to: Offset(c.to.dx, c.to.dy + shiftY),
            isCompleted: c.isCompleted,
            isWinnerPath: c.isWinnerPath,
          );
        }
        champY = 12.0;
      }

      // Atualiza a referência de gfNode após o shift vertical
      final updatedGfNode =
          nodes.firstWhere((n) => n.slot.stage == 'GrandFinal');

      championNode = BracketChampionNode(
        x: champX,
        y: champY,
        width: champWidth,
        height: champHeight,
        championTeamName: championTeamName,
        isDecided: isDecided,
      );

      connections.add(BracketConnection(
        sourceCode: updatedGfNode.slot.code,
        targetCode: 'CHAMPION',
        from: updatedGfNode.rightCenter,
        to: championNode.leftCenter,
        isCompleted: isGfDone,
        isWinnerPath: isDecided,
      ));

      columnTitles[champColIndex] = 'CAMPEÃO DO TORNEIO';
    }

    final double totalWidth = championNode != null
        ? championNode.x + championNode.width + 32.0
        : (sortedRounds.length * cardWidth +
            (sortedRounds.length - 1) * columnGap +
            32.0);

    double maxY = 0.0;
    for (final node in nodes) {
      if (node.y + node.height > maxY) maxY = node.y + node.height;
    }
    if (championNode != null && championNode.y + championNode.height > maxY) {
      maxY = championNode.y + championNode.height;
    }

    return BracketTreeLayoutResult(
      nodes: nodes,
      connections: connections,
      columnTitles: columnTitles,
      stageBanners: const [],
      championNode: championNode,
      totalWidth: totalWidth,
      totalHeight: maxY + 24.0,
    );
  }
}
