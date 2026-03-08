import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';

import 'core/bloc/app_settings/app_settings_cubit.dart';
import 'core/bloc/app_settings/app_settings_state.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

class OtlobApp extends StatelessWidget {
  const OtlobApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AppSettingsCubit>(
          create: (context) => GetIt.I<AppSettingsCubit>(),
        ),
      ],
      child: BlocBuilder<AppSettingsCubit, AppSettingsState>(
        builder: (context, state) {
          final router = GetIt.I<AppRouter>().router;

          return MaterialApp.router(
            title: 'Otlob',
            debugShowCheckedModeBanner: false,

            localizationsDelegates: context.localizationDelegates,
            supportedLocales: context.supportedLocales,
            locale: context.locale,

            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: state.themeMode,

            routerConfig: router,
          );
        },
      ),
    );
  }
}
