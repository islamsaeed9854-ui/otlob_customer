import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../services/navigation_service.dart';
import '../../features/auth/presentation/providers/auth_controller.dart';
import '../../features/splash/presentation/pages/splash_screen.dart';
import '../../features/onboarding/presentation/pages/onboarding_screen.dart';
import '../../features/auth/presentation/pages/login_screen.dart';
import '../../features/auth/presentation/pages/register_screen.dart';
import '../../features/auth/presentation/pages/forgot_password_screen.dart';
import '../../features/auth/presentation/pages/verify_otp_screen.dart';
import '../../features/auth/presentation/pages/new_password_screen.dart';
import '../../features/home/presentation/pages/home_screen.dart';
import '../../features/home/presentation/pages/restaurant_detail_screen.dart';
import '../../features/home/presentation/pages/all_vendors_screen.dart';
import '../../features/cart/presentation/pages/cart_screen.dart';
import '../../features/cart/presentation/pages/checkout_screen.dart';
import '../../features/orders/presentation/pages/orders_screen.dart';
import '../../features/profile/presentation/pages/profile_screen.dart';
import '../../features/profile/presentation/pages/notifications_screen.dart';
import '../../features/profile/presentation/pages/addresses_screen.dart';
import '../../features/home/presentation/pages/custom_delivery_screen.dart';
import '../../features/chat/presentation/pages/chat_screen.dart';
import '../providers/app_settings_provider.dart';
import 'route_paths.dart';
import 'route_names.dart';

part 'app_router.g.dart';

class RouterNotifier extends ChangeNotifier {
  final Ref _ref;

  RouterNotifier(this._ref) {
    _ref.listen<AuthStatus>(
      authControllerProvider,
      (_, _) => notifyListeners(),
    );
    _ref.listen<AppSettingsState>(
      appSettingsProvider,
      (_, _) => notifyListeners(),
    );
  }

  String? redirect(BuildContext context, GoRouterState state) {
    final authStatus = _ref.read(authControllerProvider);
    final hasSeenOnboarding = _ref.read(appSettingsProvider).hasSeenOnboarding;

    final path = state.uri.path;
    final isGoingToSplash = path == RoutePaths.splash;
    final isGoingToOnboarding = path == RoutePaths.onboarding;

    final isAuthRoute =
        path == RoutePaths.login ||
        path == RoutePaths.register ||
        path == RoutePaths.forgotPassword ||
        path == RoutePaths.verifyOtp ||
        path == RoutePaths.newPassword;

    if (authStatus == AuthStatus.initial) {
      return isGoingToSplash ? null : RoutePaths.splash;
    }

    if (authStatus == AuthStatus.unauthenticated) {
      if (!hasSeenOnboarding)
        return isGoingToOnboarding ? null : RoutePaths.onboarding;
      if (!isAuthRoute) return '${RoutePaths.login}?redirect=${state.uri.path}';
      return null;
    }

    if (authStatus == AuthStatus.unverified) {
      if (path != RoutePaths.verifyOtp && path != RoutePaths.login) {
        return RoutePaths.verifyOtp;
      }
      return null;
    }

    if (authStatus == AuthStatus.authenticated) {
      if (isAuthRoute || isGoingToSplash || isGoingToOnboarding) {
        return RoutePaths.home;
      }
    }

    return null;
  }
}

@Riverpod(keepAlive: true)
GoRouter appRouter(Ref ref) {
  final navigationService = ref.read(navigationServiceProvider);
  final routerNotifier = RouterNotifier(ref);

  return GoRouter(
    navigatorKey: navigationService.navigatorKey,
    initialLocation: RoutePaths.splash,
    debugLogDiagnostics: kDebugMode,
    refreshListenable: routerNotifier,
    redirect: routerNotifier.redirect,
    routes: [
      GoRoute(
        path: RoutePaths.splash,
        name: RouteNames.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: RoutePaths.onboarding,
        name: RouteNames.onboarding,
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: RoutePaths.login,
        name: RouteNames.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: RoutePaths.register,
        name: RouteNames.register,
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: RoutePaths.forgotPassword,
        name: RouteNames.forgotPassword,
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: RoutePaths.verifyOtp,
        name: RouteNames.verifyOtp,
        builder: (context, state) {
          final args = state.extra as Map<String, dynamic>? ?? {};
          return VerifyOtpScreen(
            email: args['email'] ?? '',
            isPasswordReset: args['isPasswordReset'] ?? false,
          );
        },
      ),
      GoRoute(
        path: RoutePaths.newPassword,
        name: RouteNames.newPassword,
        builder: (context, state) {
          final args = state.extra as Map<String, dynamic>? ?? {};
          return NewPasswordScreen(
            email: args['email'] ?? '',
            otp: args['otp'] ?? '',
          );
        },
      ),
      GoRoute(
        path: RoutePaths.home,
        name: RouteNames.home,
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/restaurant',
        name: 'restaurant',
        builder: (context, state) {
          final restaurant = state.extra as Map<String, dynamic>;
          return RestaurantDetailScreen(restaurant: restaurant);
        },
      ),
      GoRoute(
        path: '/all-vendors',
        name: 'all-vendors',
        builder: (context, state) {
          final type = state.extra as String? ?? 'restaurant';
          return AllVendorsScreen(type: type);
        },
      ),
      GoRoute(
        path: '/cart',
        name: 'cart',
        builder: (context, state) => const CartScreen(),
      ),
      GoRoute(
        path: '/checkout',
        name: 'checkout',
        builder: (context, state) {
          final vendorId = state.extra as String?;
          return CheckoutScreen(vendorId: vendorId);
        },
      ),
      GoRoute(
        path: '/profile',
        name: 'profile',
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: '/orders',
        name: 'orders',
        builder: (context, state) => const OrdersScreen(),
      ),
      GoRoute(
        path: '/custom-delivery',
        name: 'custom-delivery',
        builder: (context, state) => const CustomDeliveryScreen(),
      ),
      GoRoute(
        path: '/chat/:type/:id',
        name: 'chat',
        builder: (context, state) {
          final type = state.pathParameters['type'] ?? 'support';
          final id = state.pathParameters['id'] ?? '0';
          final extra = state.extra as Map<String, dynamic>?;
          final title = extra?['title'] as String? ?? (type == 'support' ? 'Support' : 'Vendor');
          return ChatScreen(conversationId: id, type: type, title: title);
        },
      ),
      GoRoute(
        path: '/notifications',
        name: 'notifications',
        builder: (context, state) => const NotificationsScreen(),
      ),
      GoRoute(
        path: '/addresses',
        name: 'addresses',
        builder: (context, state) => const AddressesScreen(),
      ),
    ],
  );
}
