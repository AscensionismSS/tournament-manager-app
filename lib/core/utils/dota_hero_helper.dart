/// Tipos de imagem de herói disponíveis no catálogo de assets locais.
enum DotaHeroImageType {
  /// Ícones de minimapa / avatares compactos 32x32 px (para picks/bans rápidos e chips)
  icon,

  /// Imagens widescreen / horizontais oficiais 256x144 px (para modais de detalhes e estatísticas)
  horizontal,
}

/// Utilitário puro para resolução de heróis do Dota 2 e seus assets locais (offline / 0ms de latência).
class DotaHeroHelper {
  DotaHeroHelper._();

  /// Diretório base onde estão armazenados os ícones compactos (32x32)
  static const String heroIconsDirectory = 'assets/heroes/icons';

  /// Diretório base onde estão armazenadas as imagens horizontais widescreen (256x144)
  static const String heroHorizontalDirectory = 'assets/heroes/horizontal';

  /// Diretório legado de ícones (compatibilidade retroativa)
  static const String heroAssetsDirectory = heroIconsDirectory;

  /// Validação de segurança (Whitelist): confere se o ID pertence aos heróis oficiais catalogados
  static bool isValidHeroId(int? heroId) =>
      heroId != null && _heroNames.containsKey(heroId);

  /// Retorna o caminho do asset local conforme a variante desejada (ícone ou horizontal)
  static String getHeroAssetPath(
    int heroId, {
    DotaHeroImageType type = DotaHeroImageType.icon,
  }) {
    final dir = type == DotaHeroImageType.horizontal
        ? heroHorizontalDirectory
        : heroIconsDirectory;
    return '$dir/$heroId.png';
  }

  /// Retorna o caminho do ícone compacto (32x32)
  static String getHeroIconPath(int heroId) =>
      getHeroAssetPath(heroId, type: DotaHeroImageType.icon);

  /// Retorna o caminho da imagem horizontal widescreen (256x144)
  static String getHeroHorizontalPath(int heroId) =>
      getHeroAssetPath(heroId, type: DotaHeroImageType.horizontal);

  /// Mapeamento de Hero ID para o identificador canônico do herói
  static const Map<int, String> _heroNames = {
    1: 'antimage',
    2: 'axe',
    3: 'bane',
    4: 'bloodseeker',
    5: 'crystal_maiden',
    6: 'drow_ranger',
    7: 'earthshaker',
    8: 'juggernaut',
    9: 'mirana',
    10: 'morphling',
    11: 'nevermore',
    12: 'phantom_lancer',
    13: 'puck',
    14: 'pudge',
    15: 'razor',
    16: 'sand_king',
    17: 'storm_spirit',
    18: 'sven',
    19: 'tiny',
    20: 'vengefulspirit',
    21: 'windrunner',
    22: 'zuus',
    23: 'kunkka',
    25: 'lina',
    26: 'lion',
    27: 'shadow_shaman',
    28: 'slardar',
    29: 'tidehunter',
    30: 'witch_doctor',
    31: 'lich',
    32: 'riki',
    33: 'enigma',
    34: 'tinker',
    35: 'sniper',
    36: 'necrolyte',
    37: 'warlock',
    38: 'beastmaster',
    39: 'queenofpain',
    40: 'venomancer',
    41: 'faceless_void',
    42: 'skeleton_king',
    43: 'death_prophet',
    44: 'phantom_assassin',
    45: 'pugna',
    46: 'templar_assassin',
    47: 'viper',
    48: 'luna',
    49: 'dragon_knight',
    50: 'dazzle',
    51: 'clockwerk',
    52: 'leshrac',
    53: 'furion',
    54: 'life_stealer',
    55: 'dark_seer',
    56: 'clinkz',
    57: 'omniknight',
    58: 'enchantress',
    59: 'huskar',
    60: 'night_stalker',
    61: 'broodmother',
    62: 'bounty_hunter',
    63: 'weaver',
    64: 'jakiro',
    65: 'batrider',
    66: 'chen',
    67: 'spectre',
    68: 'ancient_apparition',
    69: 'doom_bringer',
    70: 'ursa',
    71: 'spirit_breaker',
    72: 'gyrocopter',
    73: 'alchemist',
    74: 'invoker',
    75: 'silencer',
    76: 'obsidian_destroyer',
    77: 'lycan',
    78: 'brewmaster',
    79: 'shadow_demon',
    80: 'lone_druid',
    81: 'chaos_knight',
    82: 'meepo',
    83: 'treant',
    84: 'ogre_magi',
    85: 'undying',
    86: 'rubick',
    87: 'disruptor',
    88: 'nyx_assassin',
    89: 'naga_siren',
    90: 'keeper_of_the_light',
    91: 'wisp',
    92: 'visage',
    93: 'slark',
    94: 'medusa',
    95: 'troll_warlord',
    96: 'centaur',
    97: 'magnataur',
    98: 'shredder',
    99: 'bristleback',
    100: 'tusk',
    101: 'skywrath_mage',
    102: 'abaddon',
    103: 'elder_titan',
    104: 'legion_commander',
    105: 'techies',
    106: 'ember_spirit',
    107: 'earth_spirit',
    108: 'abyssal_underlord',
    109: 'terrorblade',
    110: 'phoenix',
    111: 'oracle',
    112: 'winter_wyvern',
    113: 'arc_warden',
    114: 'monkey_king',
    119: 'dark_willow',
    120: 'pangolier',
    121: 'grimstroke',
    123: 'hoodwink',
    126: 'void_spirit',
    128: 'snapfire',
    129: 'mars',
    131: 'ringmaster',
    135: 'dawnbreaker',
    136: 'marci',
    137: 'primal_beast',
    138: 'muerta',
    145: 'ringmaster',
    155: 'kez',
  };

  /// Mapeamento reverso nome -> ID
  static final Map<String, int> _nameToId = {
    for (final entry in _heroNames.entries) entry.value: entry.key,
  };

  /// Nomes amigáveis e canônicos para exibição na UI
  static const Map<String, String> _displayNames = {
    'antimage': 'Anti-Mage',
    'axe': 'Axe',
    'bane': 'Bane',
    'bloodseeker': 'Bloodseeker',
    'crystal_maiden': 'Crystal Maiden',
    'drow_ranger': 'Drow Ranger',
    'earthshaker': 'Earthshaker',
    'juggernaut': 'Juggernaut',
    'mirana': 'Mirana',
    'morphling': 'Morphling',
    'nevermore': 'Shadow Fiend',
    'phantom_lancer': 'Phantom Lancer',
    'puck': 'Puck',
    'pudge': 'Pudge',
    'razor': 'Razor',
    'sand_king': 'Sand King',
    'storm_spirit': 'Storm Spirit',
    'sven': 'Sven',
    'tiny': 'Tiny',
    'vengefulspirit': 'Vengeful Spirit',
    'windrunner': 'Windranger',
    'zuus': 'Zeus',
    'kunkka': 'Kunkka',
    'lina': 'Lina',
    'lion': 'Lion',
    'shadow_shaman': 'Shadow Shaman',
    'slardar': 'Slardar',
    'tidehunter': 'Tidehunter',
    'witch_doctor': 'Witch Doctor',
    'lich': 'Lich',
    'riki': 'Riki',
    'enigma': 'Enigma',
    'tinker': 'Tinker',
    'sniper': 'Sniper',
    'necrolyte': 'Necrophos',
    'warlock': 'Warlock',
    'beastmaster': 'Beastmaster',
    'queenofpain': 'Queen of Pain',
    'venomancer': 'Venomancer',
    'faceless_void': 'Faceless Void',
    'skeleton_king': 'Wraith King',
    'death_prophet': 'Death Prophet',
    'phantom_assassin': 'Phantom Assassin',
    'pugna': 'Pugna',
    'templar_assassin': 'Templar Assassin',
    'viper': 'Viper',
    'luna': 'Luna',
    'dragon_knight': 'Dragon Knight',
    'dazzle': 'Dazzle',
    'clockwerk': 'Clockwerk',
    'leshrac': 'Leshrac',
    'furion': "Nature's Prophet",
    'life_stealer': 'Lifestealer',
    'dark_seer': 'Dark Seer',
    'clinkz': 'Clinkz',
    'omniknight': 'Omniknight',
    'enchantress': 'Enchantress',
    'huskar': 'Huskar',
    'night_stalker': 'Night Stalker',
    'broodmother': 'Broodmother',
    'bounty_hunter': 'Bounty Hunter',
    'weaver': 'Weaver',
    'jakiro': 'Jakiro',
    'batrider': 'Batrider',
    'chen': 'Chen',
    'spectre': 'Spectre',
    'ancient_apparition': 'Ancient Apparition',
    'doom_bringer': 'Doom',
    'ursa': 'Ursa',
    'spirit_breaker': 'Spirit Breaker',
    'gyrocopter': 'Gyrocopter',
    'alchemist': 'Alchemist',
    'invoker': 'Invoker',
    'silencer': 'Silencer',
    'obsidian_destroyer': 'Outworld Destroyer',
    'lycan': 'Lycan',
    'brewmaster': 'Brewmaster',
    'shadow_demon': 'Shadow Demon',
    'lone_druid': 'Lone Druid',
    'chaos_knight': 'Chaos Knight',
    'meepo': 'Meepo',
    'treant': 'Treant Protector',
    'ogre_magi': 'Ogre Magi',
    'undying': 'Undying',
    'rubick': 'Rubick',
    'disruptor': 'Disruptor',
    'nyx_assassin': 'Nyx Assassin',
    'naga_siren': 'Naga Siren',
    'keeper_of_the_light': 'Keeper of the Light',
    'wisp': 'Io',
    'visage': 'Visage',
    'slark': 'Slark',
    'medusa': 'Medusa',
    'troll_warlord': 'Troll Warlord',
    'centaur': 'Centaur Warrunner',
    'magnataur': 'Magnus',
    'shredder': 'Timbersaw',
    'bristleback': 'Bristleback',
    'tusk': 'Tusk',
    'skywrath_mage': 'Skywrath Mage',
    'abaddon': 'Abaddon',
    'elder_titan': 'Elder Titan',
    'legion_commander': 'Legion Commander',
    'techies': 'Techies',
    'ember_spirit': 'Ember Spirit',
    'earth_spirit': 'Earth Spirit',
    'abyssal_underlord': 'Underlord',
    'terrorblade': 'Terrorblade',
    'phoenix': 'Phoenix',
    'oracle': 'Oracle',
    'winter_wyvern': 'Winter Wyvern',
    'arc_warden': 'Arc Warden',
    'monkey_king': 'Monkey King',
    'dark_willow': 'Dark Willow',
    'pangolier': 'Pangolier',
    'grimstroke': 'Grimstroke',
    'hoodwink': 'Hoodwink',
    'void_spirit': 'Void Spirit',
    'snapfire': 'Snapfire',
    'mars': 'Mars',
    'dawnbreaker': 'Dawnbreaker',
    'marci': 'Marci',
    'primal_beast': 'Primal Beast',
    'muerta': 'Muerta',
    'ringmaster': 'Ringmaster',
    'kez': 'Kez',
  };

  /// Trava de Segurança Estrita: Resolve o caminho de asset local apenas se for um herói oficial catalogado.
  /// Rejeita números negativos, IDs fora da lista oficial (ex: 99999, -1, 0) ou strings forjadas.
  /// Suporta resolução de ícones compactos (padrão) ou imagens horizontais widescreen.
  static String? resolveHeroAsset({
    int? heroId,
    String? rawName,
    DotaHeroImageType type = DotaHeroImageType.icon,
  }) {
    // Trava 1: Se heroId for fornecido, valida estritamente na whitelist de heróis oficiais
    if (heroId != null && _heroNames.containsKey(heroId)) {
      return getHeroAssetPath(heroId, type: type);
    }

    // Trava 2: Se heroName for fornecido, sanitiza e valida contra o catálogo
    if (rawName != null && rawName.isNotEmpty) {
      final clean = rawName.toLowerCase().replaceAll('npc_dota_hero_', '').trim();
      final id = _nameToId[clean];
      if (id != null && _heroNames.containsKey(id)) {
        return getHeroAssetPath(id, type: type);
      }
    }

    // Se o ID for inexistente, negativo ou não catalogado, retorna null com segurança
    return null;
  }

  /// Retorna o nome canônico do herói
  static String? getHeroName({int? heroId, String? rawName}) {
    if (rawName != null && rawName.isNotEmpty) {
      return rawName.toLowerCase().replaceAll('npc_dota_hero_', '').trim();
    }
    if (heroId != null) {
      return _heroNames[heroId];
    }
    return null;
  }

  /// Retorna o nome amigável e estilizado para exibição (ex: 'Shadow Fiend', 'Anti-Mage')
  static String getDisplayName({int? heroId, String? rawName}) {
    final canonical = getHeroName(heroId: heroId, rawName: rawName);
    if (canonical == null || canonical.isEmpty) {
      return heroId != null ? 'Herói #$heroId' : 'Herói';
    }
    return _displayNames[canonical] ?? canonical.replaceAll('_', ' ').toUpperCase();
  }

  /// Mapeamento público de todos os heróis para testes e catálogo
  static Map<int, String> get allHeroes => Map.unmodifiable(_heroNames);
}
