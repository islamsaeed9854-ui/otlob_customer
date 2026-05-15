import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
  static const _savedEmailKey = 'saved_email';
  static const _savedPasswordKey = 'saved_password';
  static const _savedNameKey = 'saved_name';
  static const _savedRoleKey = 'saved_role';

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

  Future<void> saveSavedProfile({
    required String email,
    required String password,
    required String name,
    required String role,
  }) async {
    await _storage.write(key: _savedEmailKey, value: email);
    await _storage.write(key: _savedPasswordKey, value: password);
    await _storage.write(key: _savedNameKey, value: name);
    await _storage.write(key: _savedRoleKey, value: role);
  }

  Future<Map<String, String>?> getSavedProfile() async {
    final email = await _storage.read(key: _savedEmailKey);
    final password = await _storage.read(key: _savedPasswordKey);
    final name = await _storage.read(key: _savedNameKey);
    final role = await _storage.read(key: _savedRoleKey);

    if (email != null) {
      return {
        'email': email,
        'password': password ?? '',
        'name': name ?? '',
        'role': role ?? '',
      };
    }
    return null;
  }

  Future<void> deleteSavedProfile() async {
    await _storage.delete(key: _savedEmailKey);
    await _storage.delete(key: _savedPasswordKey);
    await _storage.delete(key: _savedNameKey);
    await _storage.delete(key: _savedRoleKey);
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
    // Save these before deleting all
    final savedEmail = await _storage.read(key: _savedEmailKey);
    final savedPassword = await _storage.read(key: _savedPasswordKey);
    final savedName = await _storage.read(key: _savedNameKey);
    final savedRole = await _storage.read(key: _savedRoleKey);

    await _storage.deleteAll();

    // Restore saved profile if it existed
    if (savedEmail != null) {
      await saveSavedProfile(
        email: savedEmail,
        password: savedPassword ?? '',
        name: savedName ?? '',
        role: savedRole ?? '',
      );
    }
  }

  Future<bool> isAccessTokenExpired() async {
    final access = await getAccessToken();
    
    if (access == null) return true; 

    return JwtDecoder.isExpired(access);
  }

  Future<String?> getUserId() async {
    final access = await getAccessToken();
    if (access == null) return null;
    try {
      final decodedToken = JwtDecoder.decode(access);
      return decodedToken['sub'] as String?;
    } catch (_) {
      return null;
    }
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

final accessTokenProvider = FutureProvider<String?>((ref) async {
  return ref.watch(tokenServiceProvider).getAccessToken();
});