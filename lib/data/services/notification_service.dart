import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart';

@lazySingleton
class NotificationService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final Logger _logger = Logger();

  Future<void> init() async {
    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      _logger.i('Push notifications authorized.');
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        _logger.i(
          'Received foreground message: ${message.notification?.title}',
        );
      });
    }
  }

  Future<String?> getDeviceToken() async {
    return await _fcm.getToken();
  }
}
