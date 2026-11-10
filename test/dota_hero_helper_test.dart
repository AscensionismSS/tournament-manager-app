import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tournament_creator_front/core/utils/dota_hero_helper.dart';

void main() {
  group('DotaHeroHelper - Trava de Segurança e Resolução de Assets', () {
    test('Valida IDs oficiais conhecidos na whitelist', () {
      expect(DotaHeroHelper.isValidHeroId(1), isTrue); // Anti-Mage
      expect(DotaHeroHelper.isValidHeroId(74), isTrue); // Invoker
      expect(DotaHeroHelper.isValidHeroId(138), isTrue); // Muerta
      expect(DotaHeroHelper.isValidHeroId(145), isTrue); // Ringmaster
      expect(DotaHeroHelper.isValidHeroId(155), isTrue); // Kez
    });

    test('Bloqueia IDs inválidos, negativos ou forjados (Security Lock)', () {
      expect(DotaHeroHelper.isValidHeroId(null), isFalse);
      expect(DotaHeroHelper.isValidHeroId(0), isFalse);
      expect(DotaHeroHelper.isValidHeroId(-1), isFalse);
      expect(DotaHeroHelper.isValidHeroId(-99), isFalse);
      expect(DotaHeroHelper.isValidHeroId(99999), isFalse);
      expect(DotaHeroHelper.isValidHeroId(24), isFalse); // ID não existente no Dota 2
    });

    test('resolveHeroAsset retorna o path correto para heróis válidos (ícone e horizontal)', () {
      expect(DotaHeroHelper.resolveHeroAsset(heroId: 1), 'assets/heroes/icons/1.png');
      expect(DotaHeroHelper.resolveHeroAsset(heroId: 74), 'assets/heroes/icons/74.png');
      expect(DotaHeroHelper.resolveHeroAsset(heroId: 155), 'assets/heroes/icons/155.png');
      expect(
        DotaHeroHelper.resolveHeroAsset(rawName: 'npc_dota_hero_invoker'),
        'assets/heroes/icons/74.png',
      );
      expect(
        DotaHeroHelper.resolveHeroAsset(rawName: 'kez'),
        'assets/heroes/icons/155.png',
      );
      expect(
        DotaHeroHelper.resolveHeroAsset(heroId: 1, type: DotaHeroImageType.horizontal),
        'assets/heroes/horizontal/1.png',
      );
      expect(
        DotaHeroHelper.resolveHeroAsset(rawName: 'kez', type: DotaHeroImageType.horizontal),
        'assets/heroes/horizontal/155.png',
      );
    });

    test('resolveHeroAsset rejeita entradas inválidas retornando null', () {
      expect(DotaHeroHelper.resolveHeroAsset(heroId: -10), isNull);
      expect(DotaHeroHelper.resolveHeroAsset(heroId: 0), isNull);
      expect(DotaHeroHelper.resolveHeroAsset(heroId: 99999), isNull);
      expect(DotaHeroHelper.resolveHeroAsset(rawName: 'hacker_script_attempt'), isNull);
      expect(DotaHeroHelper.resolveHeroAsset(rawName: '../../secrets'), isNull);
      expect(DotaHeroHelper.resolveHeroAsset(heroId: null, rawName: null), isNull);
    });

    test('getDisplayName retorna nomes formatados e fallback seguro', () {
      expect(DotaHeroHelper.getDisplayName(heroId: 1), 'Anti-Mage');
      expect(DotaHeroHelper.getDisplayName(heroId: 74), 'Invoker');
      expect(DotaHeroHelper.getDisplayName(heroId: 155), 'Kez');
      expect(DotaHeroHelper.getDisplayName(heroId: 99999), 'Herói #99999');
      expect(DotaHeroHelper.getDisplayName(), 'Herói');
    });

    test('rootBundle carrega o arquivo PNG de assets/heroes/icons/ e assets/heroes/horizontal/ com sucesso', () async {
      TestWidgetsFlutterBinding.ensureInitialized();
      final iconData = await rootBundle.load('assets/heroes/icons/63.png');
      expect(iconData.lengthInBytes, greaterThan(0));

      final horizData = await rootBundle.load('assets/heroes/horizontal/63.png');
      expect(horizData.lengthInBytes, greaterThan(0));
    });
  });
}

