import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';

@module
abstract class NetworkModule {
  @lazySingleton
  Dio get dio {
    final baseUrl = dotenv.env['API_URL'] ?? 'http://10.0.2.2:3000';

    final dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    dio.interceptors.add(LogInterceptor(requestBody: true, responseBody: true));
    return dio;
  }

  @lazySingleton
  InternetConnection get internetConnection => InternetConnection();
}
