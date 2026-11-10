import '../../draft/models/draft_player_dto.dart';
import '../../draft/models/draft_team_dto.dart';

/// Par imutável de Item Neutro + Encantamento/Buff da Jungle para um Tier específico.
class NeutralTierEntry {
  final int tierNumber;
  final String? neutralItem;
  final String? jungleBuff;
  final bool isLatest;

  const NeutralTierEntry({
    required this.tierNumber,
    this.neutralItem,
    this.jungleBuff,
    this.isLatest = false,
  });

  bool get hasAny =>
      (neutralItem != null && neutralItem!.trim().isNotEmpty) ||
      (jungleBuff != null && jungleBuff!.trim().isNotEmpty);
}

/// DTO de estatísticas de um jogador no mapa (Tournaments.Contracts/Replay/PlayerMatchStatsDto).
class PlayerGameStatsDto {
  final String playerId;
  final String teamId;
  final int heroId;
  final String? heroName;
  final int kills;
  final int deaths;
  final int assists;
  final int netWorth;
  final int goldPerMinute;
  final int experiencePerMinute;
  final List<int> itemIds;
  final List<String> itemNames;
  final List<String> backpackNames;
  final String? neutralItem;
  final List<String>? _neutralItems;
  final String? jungleBuff;
  final List<String>? _jungleBuffs;
  final bool hasAghanimScepter;
  final bool hasAghanimShard;
  final int wardsPlaced;
  final int wardsDestroyed;
  final int towerDamage;
  final int heroDamage;
  final int heroHealing;
  final String? playerName;
  final String? steamName;
  final String? steamId;

  List<String> get neutralItems => _neutralItems ?? const [];
  List<String> get jungleBuffs => _jungleBuffs ?? const [];

  const PlayerGameStatsDto({
    required this.playerId,
    required this.teamId,
    required this.heroId,
    this.heroName,
    this.kills = 0,
    this.deaths = 0,
    this.assists = 0,
    this.netWorth = 0,
    this.goldPerMinute = 0,
    this.experiencePerMinute = 0,
    this.itemIds = const [],
    this.itemNames = const [],
    this.backpackNames = const [],
    this.neutralItem,
    List<String>? neutralItems = const [],
    this.jungleBuff,
    List<String>? jungleBuffs = const [],
    this.hasAghanimScepter = false,
    this.hasAghanimShard = false,
    this.wardsPlaced = 0,
    this.wardsDestroyed = 0,
    this.towerDamage = 0,
    this.heroDamage = 0,
    this.heroHealing = 0,
    this.playerName,
    this.steamName,
    this.steamId,
  })  : _neutralItems = neutralItems,
        _jungleBuffs = jungleBuffs;

  factory PlayerGameStatsDto.fromJson(Map<String, dynamic> json) {
    // 1. Parser de itens do inventário (pode vir no objeto raiz ou dentro de 'inventario')
    final invMap = json['inventario'] is Map<String, dynamic>
        ? json['inventario'] as Map<String, dynamic>
        : (json['inventory'] is Map<String, dynamic>
            ? json['inventory'] as Map<String, dynamic>
            : null);

    final parsedItemIds = ((json['itemIds'] ?? json['item_ids']) as List<dynamic>?)
            ?.map((e) => (e as num).toInt())
            .toList() ??
        const <int>[];

    final rawItemNames = json['itemNames'] ??
        json['item_names'] ??
        json['items'] ??
        invMap?['itens_principais'] ??
        invMap?['itensPrincipais'] ??
        invMap?['main_items'] ??
        json['itensPrincipais'] ??
        json['itens_principais'];

    final List<String> parsedItemNames = rawItemNames is List
        ? rawItemNames.map((dynamic e) => e.toString()).toList()
        : const <String>[];

    final rawBackpack = json['backpackNames'] ??
        json['backpack_names'] ??
        json['backpack'] ??
        invMap?['mochila'] ??
        invMap?['backpack'] ??
        json['mochila'];

    final List<String> parsedBackpack = rawBackpack is List
        ? rawBackpack.map((dynamic e) => e.toString()).toList()
        : const <String>[];

    final parsedNeutral = (json['neutralItem'] ??
            json['neutral_item'] ??
            json['itemNeutro'] ??
            json['item_neutro'] ??
            invMap?['item_neutro'] ??
            invMap?['itemNeutro'] ??
            invMap?['neutral_item'])
        ?.toString();

    final parsedNeutralItems = ((json['neutralItems'] ??
            json['neutral_items'] ??
            json['itensNeutros'] ??
            json['itens_neutros'] ??
            invMap?['itens_neutros'] ??
            invMap?['itensNeutros'] ??
            invMap?['neutral_items'] ??
            invMap?['neutralItems']) as List<dynamic>?)
        ?.map((e) => e.toString())
        .toList() ??
        const <String>[];

    final parsedJungleBuff = (json['jungleBuff'] ??
            json['jungle_buff'] ??
            json['JungleBuff'] ??
            json['buffJungle'] ??
            json['buff_jungle'] ??
            json['BuffJungle'] ??
            json['neutralEnhancement'] ??
            json['neutral_enhancement'] ??
            json['itemEnhancement'] ??
            json['enhancement'] ??
            invMap?['buff_jungle'] ??
            invMap?['buffJungle'] ??
            invMap?['BuffJungle'] ??
            invMap?['jungleBuff'] ??
            invMap?['JungleBuff'] ??
            invMap?['neutralEnhancement'] ??
            invMap?['neutral_enhancement'] ??
            invMap?['enhancement'])
        ?.toString();

    final parsedJungleBuffs = ((json['jungleBuffs'] ??
            json['jungle_buffs'] ??
            json['buffsJungle'] ??
            json['buffs_jungle'] ??
            invMap?['buffs_jungle'] ??
            invMap?['buffsJungle'] ??
            invMap?['jungle_buffs'] ??
            invMap?['jungleBuffs']) as List<dynamic>?)
        ?.map((e) => e.toString())
        .toList() ??
        const <String>[];

    // 2. Upgrades de Aghanim
    final upgradesMap = json['upgrades'] is Map<String, dynamic>
        ? json['upgrades'] as Map<String, dynamic>
        : null;
    final bool scepter = (upgradesMap?['aghanim_cetro'] ??
            upgradesMap?['aghanimScepter'] ??
            json['aghanimCetro'] ??
            json['hasAghanimScepter']) as bool? ??
        false;
    final bool shard = (upgradesMap?['aghanim_shard'] ??
            upgradesMap?['aghanimShard'] ??
            json['aghanimShard'] ??
            json['hasAghanimShard']) as bool? ??
        false;

    // 3. Visão e Danos de Objetivos
    final obsBought = (json['wardsObsCompradas'] ??
            json['wards_obs_compradas'] ??
            json['wardsPlaced'] ??
            json['wards']) as num? ??
        0;
    final senBought = (json['wardsSenCompradas'] ??
            json['wards_sen_compradas']) as num? ??
        0;

    return PlayerGameStatsDto(
      playerId: json['playerId']?.toString() ?? '',
      teamId: json['teamId']?.toString() ?? '',
      heroId: json['heroId'] as int? ?? 0,
      heroName: json['heroName']?.toString() ?? json['heroi']?.toString(),
      kills: json['kills'] as int? ?? 0,
      deaths: json['deaths'] as int? ?? 0,
      assists: json['assists'] as int? ?? 0,
      netWorth: json['netWorth'] as int? ?? 0,
      goldPerMinute: (json['goldPerMinute'] ?? json['gpm']) as int? ?? 0,
      experiencePerMinute: (json['experiencePerMinute'] ?? json['xpm']) as int? ?? 0,
      itemIds: parsedItemIds,
      itemNames: parsedItemNames,
      backpackNames: parsedBackpack,
      neutralItem: parsedNeutral,
      neutralItems: parsedNeutralItems,
      jungleBuff: parsedJungleBuff,
      jungleBuffs: parsedJungleBuffs,
      hasAghanimScepter: scepter,
      hasAghanimShard: shard,
      wardsPlaced: (obsBought + senBought).toInt(),
      wardsDestroyed: ((json['wardsObsDestruidas'] ??
              json['wards_obs_destruidas'] ??
              json['wardsDestroyed']) as num? ??
          0)
          .toInt(),
      towerDamage: ((json['danoEstruturas'] ??
              json['dano_estruturas'] ??
              json['towerDamage']) as num? ??
          0)
          .toInt(),
      heroDamage: ((json['danoHerois'] ??
              json['dano_herois'] ??
              json['heroDamage']) as num? ??
          0)
          .toInt(),
      heroHealing: ((json['curaHerois'] ??
              json['cura_herois'] ??
              json['heroHealing'] ??
              json['healing']) as num? ??
          0)
          .toInt(),
      playerName: json['playerName']?.toString() ?? json['nome']?.toString(),
      steamName: json['steamName']?.toString() ??
          json['nomeSteam']?.toString() ??
          json['steamNickname']?.toString() ??
          json['steam_name']?.toString() ??
          json['dotaPersonaName']?.toString() ??
          json['personaName']?.toString() ??
          json['persona_name']?.toString(),
      steamId: json['steamId']?.toString() ??
          json['steam_id']?.toString() ??
          json['steamId64']?.toString(),
    );
  }

  String get kdaFormatted => '$kills / $deaths / $assists';

  /// Retorna o Net Worth formatado sem sufixo (ex: 16.380 ou 25.545)
  String get formattedNetWorth => _formatIntWithDots(netWorth);

  /// Dano a heróis formatado com separador de milhar
  String get formattedHeroDamage => _formatIntWithDots(heroDamage);

  /// Dano a torres formatado com separador de milhar
  String get formattedTowerDamage => _formatIntWithDots(towerDamage);

  /// Cura formatada com separador de milhar
  String get formattedHeroHealing => _formatIntWithDots(heroHealing);

  static String _formatIntWithDots(int value) {
    if (value <= 0) return '0';
    final str = value.toString();
    final buffer = StringBuffer();
    for (int i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) {
        buffer.write('.');
      }
      buffer.write(str[i]);
    }
    return buffer.toString();
  }

  double get kdaRatio => deaths == 0 ? (kills + assists).toDouble() : (kills + assists) / deaths;

  /// Retorna o item neutro ativo mais recente (com fallback para a lista histórica)
  String? get effectiveNeutralItem =>
      (neutralItem != null && neutralItem!.isNotEmpty)
          ? neutralItem
          : (neutralItems.isNotEmpty ? neutralItems.last : null);

  /// Retorna o encantamento/buff de jungle ativo mais recente (com fallback para a lista histórica)
  String? get effectiveJungleBuff =>
      (jungleBuff != null && jungleBuff!.isNotEmpty)
          ? jungleBuff
          : (jungleBuffs.isNotEmpty ? jungleBuffs.last : null);

  /// Sequência cronológica completa dos 4 Tiers da Jungle (Item Neutro + Buff casados por Tier).
  /// Exibe sempre os 4 slots canônicos (ou 5 se chegar ao Tier 5), mantendo consistência com os 6 slots do inventário e 3 da mochila.
  List<NeutralTierEntry> get neutralTierProgression {
    final List<String> neutrals = neutralItems.isNotEmpty
        ? neutralItems
        : (effectiveNeutralItem != null ? [effectiveNeutralItem!] : const []);
    final List<String> buffs = jungleBuffs.isNotEmpty
        ? jungleBuffs
        : (effectiveJungleBuff != null ? [effectiveJungleBuff!] : const []);

    final int dataCount =
        neutrals.length > buffs.length ? neutrals.length : buffs.length;
    final int totalSlots = dataCount > 4 ? dataCount : 4;

    return List.generate(totalSlots, (idx) {
      final String? nItem = idx < neutrals.length ? neutrals[idx] : null;
      final String? jBuff = idx < buffs.length ? buffs[idx] : null;
      return NeutralTierEntry(
        tierNumber: idx + 1,
        neutralItem: nItem,
        jungleBuff: jBuff,
        isLatest: dataCount > 0 && idx == dataCount - 1,
      );
    });
  }

  /// Resolve o nome de exibição do jogador conforme o modo ativo (Torneio vs Steam)
  String resolveDisplayName({
    List<DraftTeamDto>? draftTeams,
    required String? teamId,
    required int playerIndex,
    required bool useSteamName,
  }) {
    DraftPlayerDto? draftPlayer;
    if (draftTeams != null && draftTeams.isNotEmpty) {
      for (final team in draftTeams) {
        for (final starter in team.starters) {
          if (starter.id == playerId) {
            draftPlayer = starter;
            break;
          }
        }
        if (draftPlayer != null) break;
        for (final reserve in team.reserves) {
          if (reserve.id == playerId) {
            draftPlayer = reserve;
            break;
          }
        }
        if (draftPlayer != null) break;
      }

      if (draftPlayer == null && teamId != null) {
        for (final t in draftTeams) {
          if (t.id == teamId) {
            if (playerIndex >= 0 && playerIndex < t.starters.length) {
              draftPlayer = t.starters[playerIndex];
            } else {
              final rIdx = playerIndex - t.starters.length;
              if (rIdx >= 0 && rIdx < t.reserves.length) {
                draftPlayer = t.reserves[rIdx];
              }
            }
            break;
          }
        }
      }
    }

    if (useSteamName) {
      if (steamName != null && steamName!.trim().isNotEmpty) {
        return steamName!;
      }
      if (draftPlayer != null && draftPlayer.name.trim().isNotEmpty) {
        return draftPlayer.name;
      }
      if (playerName != null && playerName!.trim().isNotEmpty) {
        return playerName!;
      }
      return 'Jogador ${playerIndex + 1}';
    }

    if (playerName != null && playerName!.trim().isNotEmpty) {
      return playerName!;
    }
    if (draftPlayer != null && draftPlayer.name.trim().isNotEmpty) {
      return draftPlayer.name;
    }
    return 'Jogador ${playerIndex + 1}';
  }
}

