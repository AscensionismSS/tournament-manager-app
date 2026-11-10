import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'core/navigation/app_router.dart';
import 'core/theme/theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  usePathUrlStrategy();
  runApp(const TournamentApp());
}

/// Aplicação raiz do Tsurus Plus+
class TournamentApp extends StatelessWidget {
  const TournamentApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Tsurus Plus+',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      routerConfig: AppRouter.router,
    );
  }
}
