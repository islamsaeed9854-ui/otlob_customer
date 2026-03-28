import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:jwt_decoder/jwt_decoder.dart';

import '../providers/secure_storage_provider.dart';

part 'token_service.g.dart';

@Riverpod(keepAlive: true)
TokenService tokenService(Ref ref) {
  final storage = ref.read(secureStorageProvider);
  return TokenService(storage);
}

class TokenService {
  final FlutterSecureStorage _storage;

  TokenService(this._storage);

  static const _accessTokenKey = 'access_token';
  static const _refreshTokenKey = 'refresh_token';
  static const _userEmailKey = 'user_email';
  static const _userNameKey = 'user_name';
  static const _userPhoneKey = 'user_phone';
  static const _userAvatarKey = 'user_avatar';

  Future<String?> getAccessToken() async {
    return await _storage.read(key: _accessTokenKey);
  }

  Future<String?> getUserEmail() async {
    return await _storage.read(key: _userEmailKey);
  }

  Future<String?> getUserName() async {
    return await _storage.read(key: _userNameKey);
  }

  Future<String?> getUserPhone() async {
    return await _storage.read(key: _userPhoneKey);
  }

  Future<String?> getUserAvatar() async {
    return await _storage.read(key: _userAvatarKey);
  }

  Future<String?> getRefreshToken() async {
    return await _storage.read(key: _refreshTokenKey);
  }

  Future<Map<String, String?>> getTokens() async {
    final access = await getAccessToken();
    final refresh = await getRefreshToken();

    return {
      'access_token': access,
      'refresh_token': refresh,
    };
  }

  Future<void> saveAccessToken(String token) async {
    await _storage.write(key: _accessTokenKey, value: token);
  }

  Future<void> saveUserEmail(String email) async {
    await _storage.write(key: _userEmailKey, value: email);
  }

  Future<void> saveUserName(String name) async {
    await _storage.write(key: _userNameKey, value: name);
  }

  Future<void> saveUserPhone(String phone) async {
    await _storage.write(key: _userPhoneKey, value: phone);
  }

  Future<void> saveUserAvatar(String avatar) async {
    await _storage.write(key: _userAvatarKey, value: avatar);
  }

  Future<void> saveRefreshToken(String token) async {
    await _storage.write(key: _refreshTokenKey, value: token);
  }

  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await Future.wait([
      saveAccessToken(accessToken),
      saveRefreshToken(refreshToken),
    ]);
  }

  Future<void> deleteAccessToken() async {
    await _storage.delete(key: _accessTokenKey);
  }

  Future<void> deleteUserEmail() async {
    await _storage.delete(key: _userEmailKey);
  }

  Future<void> deleteRefreshToken() async {
    await _storage.delete(key: _refreshTokenKey);
  }

  Future<void> clearTokens() async {
    await Future.wait([
      deleteAccessToken(),
      deleteRefreshToken(),
      deleteUserEmail(),
      _storage.delete(key: _userNameKey),
      _storage.delete(key: _userPhoneKey),
      _storage.delete(key: _userAvatarKey),
    ]);
  }

  Future<bool> isAccessTokenExpired() async {
    final access = await getAccessToken();
    
    if (access == null) return true; 

    return JwtDecoder.isExpired(access);
  }

  Future<bool> isUserVerified() async {
    final access = await getAccessToken();
    if (access == null) return false;
    
    try {
      final decodedToken = JwtDecoder.decode(access);
      return decodedToken['verified'] == true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> hasValidTokens() async {
    final access = await getAccessToken();
    final refresh = await getRefreshToken();

    if (access == null || refresh == null) return false;

    if (JwtDecoder.isExpired(refresh)) {
      return false; 
    }

    return true;
  }
}