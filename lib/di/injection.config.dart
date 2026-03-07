// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:dio/dio.dart' as _i361;
import 'package:get_it/get_it.dart' as _i174;
import 'package:injectable/injectable.dart' as _i526;
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart'
    as _i161;
import 'package:shared_preferences/shared_preferences.dart' as _i460;

import '../core/bloc/app_settings/app_settings_cubit.dart' as _i0;
import '../core/network/dio_client.dart' as _i393;
import '../core/network/network_info.dart' as _i6;
import '../core/router/app_router.dart' as _i877;
import '../core/services/location_service.dart' as _i848;
import '../core/services/media_service.dart' as _i202;
import '../core/services/navigation_service.dart' as _i340;
import '../core/services/notification_service.dart' as _i570;
import '../core/services/permission_service.dart' as _i65;
import '../core/services/socket_service.dart' as _i862;
import 'register_module.dart' as _i291;

extension GetItInjectableX on _i174.GetIt {
  // initializes the registration of main-scope dependencies inside of GetIt
  Future<_i174.GetIt> init({
    String? environment,
    _i526.EnvironmentFilter? environmentFilter,
  }) async {
    final gh = _i526.GetItHelper(this, environment, environmentFilter);
    final registerModule = _$RegisterModule();
    final networkModule = _$NetworkModule();
    await gh.factoryAsync<_i460.SharedPreferences>(
      () => registerModule.prefs,
      preResolve: true,
    );
    gh.lazySingleton<_i361.Dio>(() => networkModule.dio);
    gh.lazySingleton<_i161.InternetConnection>(
      () => networkModule.internetConnection,
    );
    gh.lazySingleton<_i848.LocationService>(() => _i848.LocationService());
    gh.lazySingleton<_i202.MediaService>(() => _i202.MediaService());
    gh.lazySingleton<_i340.NavigationService>(() => _i340.NavigationService());
    gh.lazySingleton<_i570.NotificationService>(
      () => _i570.NotificationService(),
    );
    gh.lazySingleton<_i65.PermissionService>(() => _i65.PermissionService());
    gh.lazySingleton<_i862.SocketService>(() => _i862.SocketService());
    gh.lazySingleton<_i6.INetworkInfo>(
      () => _i6.NetworkInfo(gh<_i161.InternetConnection>()),
    );
    gh.lazySingleton<_i877.AppRouter>(
      () => _i877.AppRouter(gh<_i340.NavigationService>()),
    );
    gh.singleton<_i0.AppSettingsCubit>(
      () => _i0.AppSettingsCubit(gh<_i460.SharedPreferences>()),
    );
    return this;
  }
}

class _$RegisterModule extends _i291.RegisterModule {}

class _$NetworkModule extends _i393.NetworkModule {}
