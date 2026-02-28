import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'presentation/router/app_router.dart';

class OtlobApp extends StatelessWidget {
  const OtlobApp({super.key});

  @override
  Widget build(BuildContext context) {
    // 1. Retrieve the router instance from your GetIt container
    final appRouter = GetIt.I<AppRouter>();

    return MaterialApp.router(
      title: 'Otlob Customer',
      debugShowCheckedModeBanner: false,

      // --- Localization ---
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,

      // --- Router Configuration ---
      // This bridges the router we defined to the MaterialApp
      routerConfig: appRouter.router,

      // --- Theming: Centralized Design System ---
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFFF5A00), // Talabat Brand Orange
          primary: const Color(0xFFFF5A00),
        ),
        // Ensure typography adjusts based on locale
        fontFamily: context.locale.languageCode == 'ar' ? 'Cairo' : 'Roboto',
        appBarTheme: const AppBarTheme(centerTitle: true, elevation: 0),
      ),

      // --- Global Builder (Enterprise Standard) ---
      // Forces text to ignore system font scaling for consistent layout
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.noScaling),
          child: child!,
        );
      },
    );
  }
}
