import 'package:image_picker/image_picker.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/services/token_service.dart';
import '../../domain/repositories/profile_repository.dart';
import '../../data/repositories/profile_repository_impl.dart';

part 'profile_controller.g.dart';

class ProfileState {
  final String name;
  final String email;
  final String phone;
  final String avatar;
  final bool isArabic;
  final bool notificationsEnabled;
  final List<Map<String, dynamic>> addresses;

  const ProfileState({
    required this.name,
    required this.email,
    required this.phone,
    required this.avatar,
    required this.isArabic,
    required this.notificationsEnabled,
    this.addresses = const [],
  });

  ProfileState copyWith({
    String? name,
    String? email,
    String? phone,
    String? avatar,
    bool? isArabic,
    bool? notificationsEnabled,
    List<Map<String, dynamic>>? addresses,
  }) {
    return ProfileState(
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      avatar: avatar ?? this.avatar,
      isArabic: isArabic ?? this.isArabic,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      addresses: addresses ?? this.addresses,
    );
  }
}

@Riverpod(keepAlive: true)
class Profile extends _$Profile {
  @override
  ProfileState build() {
    // Initial placeholder state
    final initialState = const ProfileState(
      name: '',
      email: '',
      phone: '',
      avatar: '',
      isArabic: true,
      notificationsEnabled: true,
      addresses: [],
    );
    
    // Asynchronously load real data
    _init();
    
    return initialState;
  }

  Future<void> _init() async {
    final repository = ref.read(profileRepositoryProvider);
    final tokenService = ref.read(tokenServiceProvider);

    // 1. Try to load from local storage first for instant UI
    final localName = await tokenService.getUserName() ?? '';
    final localEmail = await tokenService.getUserEmail() ?? '';
    final localPhone = await tokenService.getUserPhone() ?? '';
    final localAvatar = await tokenService.getUserAvatar() ?? '';
    
    state = state.copyWith(
      name: localName,
      email: localEmail,
      phone: localPhone,
      avatar: localAvatar,
    );

    // 2. Fetch latest from backend to ensure accuracy (Fixes "only showing gmail" issue)
    final profileResult = await repository.getProfile();
    profileResult.fold(
      (data) async {
        final name = data['name'] ?? '';
        final email = data['email'] ?? '';
        final phone = data['phone'] ?? '';
        final avatar = data['avatar'] ?? '';
        
        // Sync to local storage
        await tokenService.saveUserName(name);
        await tokenService.saveUserEmail(email);
        await tokenService.saveUserPhone(phone);
        await tokenService.saveUserAvatar(avatar);

        state = state.copyWith(
          name: name, 
          email: email, 
          phone: phone,
          avatar: avatar,
        );
      },
      (failure) => print('Failed to fetch profile: ${failure.message}'),
    );

    // 3. Fetch addresses
    final addressResult = await repository.getAddresses();
    addressResult.fold(
      (data) => state = state.copyWith(addresses: data),
      (failure) => print('Failed to fetch addresses: ${failure.message}'),
    );
  }

  Future<void> updateProfileData({required String name, required String email, required String phone}) async {
    final repository = ref.read(profileRepositoryProvider);
    final tokenService = ref.read(tokenServiceProvider);

    final result = await repository.updateProfile({
      'name': name,
      'email': email,
      'phone': phone,
    });

    await result.fold(
      (data) async {
        await tokenService.saveUserName(name);
        await tokenService.saveUserEmail(email);
        await tokenService.saveUserPhone(phone);
        state = state.copyWith(name: name, email: email, phone: phone);
      },
      (failure) async => throw Exception(failure.message),
    );
  }

  void toggleLanguage() {
    state = state.copyWith(isArabic: !state.isArabic);
  }

  void toggleNotifications() {
    state = state.copyWith(notificationsEnabled: !state.notificationsEnabled);
  }

  Future<void> addAddress(Map<String, dynamic> addressData) async {
    try {
      final repository = ref.read(profileRepositoryProvider);
      final result = await repository.createAddress(addressData);
      
      result.fold(
        (address) => state = state.copyWith(addresses: [...state.addresses, address]),
        (failure) => throw Exception(failure.message),
      );
    } catch (e) {
      print('Add Address Error: $e');
      rethrow;
    }
  }

  Future<void> removeAddress(String id) async {
    final repository = ref.read(profileRepositoryProvider);
    final result = await repository.deleteAddress(id);

    result.fold(
      (_) => state = state.copyWith(
        addresses: state.addresses.where((a) => a['id'] != id).toList(),
      ),
      (failure) => throw Exception(failure.message),
    );
  }

  Future<void> pickAndUploadAvatar() async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );

    if (image != null) {
      final repository = ref.read(profileRepositoryProvider);
      final tokenService = ref.read(tokenServiceProvider);
      
      final result = await repository.uploadAvatar(image.path);
      
      await result.fold(
        (data) async {
          final avatarUrl = data['avatar'];
          if (avatarUrl != null) {
            await tokenService.saveUserAvatar(avatarUrl);
            state = state.copyWith(avatar: avatarUrl);
          }
        },
        (failure) async => throw Exception(failure.message),
      );
    }
  }
}

