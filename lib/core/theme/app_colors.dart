import 'package:flutter/material.dart';

class AppColors {
  AppColors._(); // Prática profissional: Evita instanciar a classe

  // 1. Camadas de Fundo e Superfície (Contraste e Hierarquia Visual Profissional)
  static const Color background = Color(0xFF0B0C11); // Fundo escuro aveludado profundo (Scaffold)
  static const Color navSurface = Color(0xFF0F111A); // TopBar e Sidebar: Painéis de navegação sólidos
  static const Color canvasSurface = Color(0xFF141622); // Container principal isolado (área do conteúdo)
  static const Color surface = Color(0xFF1C1F2E); // Superfície padrão dos cards (alto contraste contra o canvas)
  static const Color cardSurface = surface; // Alias semântico para cards de membros e torneios
  static const Color surfaceHighlight = Color(0xFF0A0C13); // Fundo rebaixado de alto contraste para inputs
  static const Color border = Color(0xFF272A3C); // Borda nítida de 1px para separação de elementos
  static const Color borderHighlight = Color(0xFF3B415C); // Borda de realce sutil para itens ativos ou concluídos

  // 2. Cores de Ação e Destaque
  static const Color primary = Color(0xFFC23C2A); // Vermelho da arena para o botão de ação
  static const Color primaryNeon = Color(0xFFFF3B30); // Vermelho fluorescente para efeitos luminosos
  static const Color secondary = Color(0xFFE2E8F0); // Branco Gelo nítido para foco de input

  // 3. Cores de Sobreposição / Textos
  static const Color onBackground = Color(0xFFFFFFFF); // Branco puro para títulos e destaque
  static const Color onSurface = Color(0xFF8D92A3); // Cinza da referência para labels e dicas
  static const Color onPrimary = Color(0xFFFFFFFF); // Branco puro em cima do botão vermelho

  // 4. Cores Semânticas de Feedback (Paleta Gamer / Arena de Alto Contraste)
  static const Color feedbackError = Color(0xFFFF3B30); // Vermelho Neon Vivo
  static const Color feedbackSuccess = Color(0xFF00E676); // Verde Neon / Esmeralda Elétrico
  static const Color feedbackWarning = Color(0xFFFFB300); // Âmbar Dourado Vibrante
  static const Color feedbackInfo = Color(0xFF00D2FF); // Ciano Elétrico Neon

  // 5. Cores Oficiais Dota 2 / Prestígio Aegis & Compendium
  static const Color dotaGold = Color(0xFFE5A93C); // Ouro metálico Aegis / The International
  static const Color dotaGoldLight = Color(0xFFFFD269); // Brilho âmbar luminoso para textos de destaque
  static const Color dotaGoldDark = Color(0xFFD69424); // Ouro âmbar profundo para gradientes
  static const Color dotaGoldSurface = Color(0x24E5A93C); // Superfície translúcida para badges douradas
  static const Color dotaRoleHardSupport = Color(0xFF4FC3F7); // Azul Celeste para Suporte Total (Pos 5)
  static const Color dotaRoleFlex = Color(0xFFBA68C8); // Roxo Orquídea para Coringa / Flexível
  static const Color medalBadgeBg = Color(0xFF0A0C12); // Fundo escuro profundo para número de medalha

  // 6. Tokens de Integração Externa (Steam Platform)
  static const Color steamSurface = Color(0xFF1B2838); // Fundo azul marinho escuro oficial Steam
  static const Color steamBlue = Color(0xFF66C0F4); // Azul ciano neon oficial Steam

  // 7. Tokens de Ação Especiais
  static const Color buttonDarkText = Color(0xFF0F1117); // Texto escuro de alto contraste sobre botão claro

  // Aliases semânticos para compatibilidade universal
  static const Color textPrimary = onBackground;
  static const Color textSecondary = onSurface;
  static const Color error = feedbackError;
  static const Color success = feedbackSuccess;
  static const Color secondaryNeon = feedbackInfo;
}

