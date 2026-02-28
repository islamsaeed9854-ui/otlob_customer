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

import '../core/network/dio_client.dart' as _i393;
import '../core/network/network_info.dart' as _i6;
import '../data/services/location_service.dart' as _i475;
import '../data/services/media_service.dart' as _i476;
import '../data/services/notification_service.dart' as _i770;
import '../data/services/permission_service.dart' as _i96;
import '../data/services/socket_service.dart' as _i657;

extension GetItInjectableX on _i174.GetIt {
  // initializes the registration of main-scope dependencies inside of GetIt
  _i174.GetIt init({
    String? environment,
    _i526.EnvironmentFilter? environmentFilter,
  }) {
    final gh = _i526.GetItHelper(this, environment, environmentFilter);
    final networkModule = _$NetworkModule();
    gh.lazySingleton<_i361.Dio>(() => networkModule.dio);
    gh.lazySingleton<_i161.InternetConnection>(
      () => networkModule.internetConnection,
    );
    gh.lazySingleton<_i475.LocationService>(() => _i475.LocationService());
    gh.lazySingleton<_i476.MediaService>(() => _i476.MediaService());
    gh.lazySingleton<_i770.NotificationService>(
      () => _i770.NotificationService(),
    );
    gh.lazySingleton<_i96.PermissionService>(() => _i96.PermissionService());
    gh.lazySingleton<_i657.SocketService>(() => _i657.SocketService());
    gh.lazySingleton<_i6.INetworkInfo>(
      () => _i6.NetworkInfo(gh<_i161.InternetConnection>()),
    );
    return this;
  }
}

class _$NetworkModule extends _i393.NetworkModule {}
