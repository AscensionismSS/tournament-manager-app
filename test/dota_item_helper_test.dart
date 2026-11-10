import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tournament_creator_front/core/utils/dota_item_helper.dart';

void main() {
  group('DotaItemHelper - Resolução Offline de Itens e Símbolos do Dota 2', () {
    test('resolveItemAsset resolve itens conhecidos por nome e por ID', () {
      expect(DotaItemHelper.resolveItemAsset(itemName: 'blink'), 'assets/items/blink.png');
      expect(DotaItemHelper.resolveItemAsset(itemName: 'item_blink'), 'assets/items/blink.png');
      expect(DotaItemHelper.resolveItemAsset(itemId: 1), 'assets/items/blink.png');

      // Black King Bar
      expect(
        DotaItemHelper.resolveItemAsset(itemName: 'item_black_king_bar'),
        'assets/items/black_king_bar.png',
      );

      // Aegis da Imortalidade
      expect(DotaItemHelper.resolveItemAsset(itemName: 'item_aegis'), 'assets/items/aegis.png');
      expect(DotaItemHelper.resolveItemAsset(itemId: 117), 'assets/items/aegis.png');

      // Itens Neutros da Jungle
      expect(
        DotaItemHelper.resolveItemAsset(itemName: 'item_philosophers_stone'),
        'assets/items/philosophers_stone.png',
      );
      expect(
        DotaItemHelper.resolveItemAsset(itemName: 'item_spider_legs'),
        'assets/items/spider_legs.png',
      );

      // Resolução de nomes brutos do parser de replay (sem underscores ou aliases de engine)
      expect(DotaItemHelper.resolveItemAsset(itemName: 'item_powertreads'), 'assets/items/power_treads.png');
      expect(DotaItemHelper.resolveItemAsset(itemName: 'item_blinkdagger'), 'assets/items/blink.png');
      expect(DotaItemHelper.resolveItemAsset(itemName: 'item_ultimatescepter'), 'assets/items/ultimate_scepter.png');
      expect(DotaItemHelper.resolveItemAsset(itemName: 'item_greatercritical'), 'assets/items/greater_crit.png');
      expect(DotaItemHelper.resolveItemAsset(itemName: 'item_flayersbota'), 'assets/items/flayers_bota.png');
      expect(DotaItemHelper.resolveItemAsset(itemName: 'item_gunpowdergauntlets'), 'assets/items/gunpowder_gauntlets.png');
      expect(DotaItemHelper.resolveItemAsset(itemName: 'item_guardianshell'), 'assets/items/guardian_shell.png');
      expect(DotaItemHelper.resolveItemAsset(itemName: 'item_serratedshiv'), 'assets/items/serrated_shiv.png');
      expect(DotaItemHelper.resolveItemAsset(itemName: 'item_enhancement_timelss'), 'assets/items/enhancement_timeless.png');
    });

    test('resolveItemAsset trata receitas e itens inexistentes com segurança', () {
      expect(DotaItemHelper.resolveItemAsset(itemName: 'recipe_dagon'), 'assets/items/recipe.png');
      expect(DotaItemHelper.resolveItemAsset(itemName: ''), isNull);
      expect(DotaItemHelper.resolveItemAsset(itemName: 'empty'), isNull);
      expect(DotaItemHelper.resolveItemAsset(itemName: 'item_inexistente_fake_xyz'), isNull);
      expect(DotaItemHelper.resolveItemAsset(itemId: -1), isNull);
      expect(DotaItemHelper.resolveItemAsset(itemId: 0), isNull);
      expect(DotaItemHelper.resolveItemAsset(itemId: 99999), isNull);
    });

    test('getDisplayName formata nomes de itens para Title Case e casos especiais', () {
      expect(DotaItemHelper.getDisplayName(itemName: 'blink'), 'Blink');
      expect(DotaItemHelper.getDisplayName(itemName: 'item_black_king_bar'), 'Black King Bar');
      expect(DotaItemHelper.getDisplayName(itemName: 'item_aegis'), 'Aegis of the Immortal');
      expect(DotaItemHelper.getDisplayName(itemName: 'roshan'), 'Roshan');
      expect(DotaItemHelper.getDisplayName(itemName: 'item_greatercritical'), 'Daedalus');
      expect(DotaItemHelper.getDisplayName(itemName: 'item_powertreads'), 'Power Treads');
      expect(DotaItemHelper.getDisplayName(itemName: 'item_ultimatescepter'), "Aghanim's Scepter");
      expect(DotaItemHelper.getDisplayName(itemName: 'item_invisibilityedge'), 'Shadow Blade');
      expect(DotaItemHelper.getDisplayName(itemName: 'empty'), 'Slot Vazio');
      expect(DotaItemHelper.getDisplayName(), 'Slot Vazio');
    });

    test('Ícones especiais de Aegis, Roshan e Aghanim existem e carregam via rootBundle', () async {
      TestWidgetsFlutterBinding.ensureInitialized();
      
      final aegisData = await rootBundle.load(DotaItemHelper.aegisAsset);
      expect(aegisData.lengthInBytes, greaterThan(0));

      final roshanData = await rootBundle.load(DotaItemHelper.roshanAsset);
      expect(roshanData.lengthInBytes, greaterThan(0));

      final blinkData = await rootBundle.load('assets/items/blink.png');
      expect(blinkData.lengthInBytes, greaterThan(0));
    });
  });
}

