import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/providers/app_settings_provider.dart'; 
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {

    final appSettings = ref.watch(appSettingsProvider);
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'Otlob',
      debugShowCheckedModeBanner: false,

      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,

      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: appSettings.themeMode,

      routerConfig: router,
    );
  }
}