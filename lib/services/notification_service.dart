import 'package:flutter/services.dart';

class NotificationService {
  // =========================================================
  // METHOD CHANNEL
  // =========================================================

  static const MethodChannel _channel =
      MethodChannel('mynotifier/notification');

  // =========================================================
  // EVENT CHANNEL
  // =========================================================

  static const EventChannel _eventChannel =
      EventChannel('mynotifier/notification_stream');

  // =========================================================
  // CEK STATUS NOTIFICATION LISTENER
  // =========================================================

  static Future<bool> isNotificationListenerEnabled() async {
    try {
      final result =
          await _channel.invokeMethod<bool>(
        'isNotificationListenerEnabled',
      );

      return result ?? false;
    } catch (e) {
      print(
        'NotificationService - Error cek permission: $e',
      );

      return false;
    }
  }

  // =========================================================
  // BUKA PENGATURAN NOTIFICATION ACCESS
  // =========================================================

  static Future<void> openNotificationSettings() async {
    try {
      await _channel.invokeMethod(
        'openNotificationSettings',
      );
    } catch (e) {
      print(
        'NotificationService - Error membuka settings: $e',
      );
    }
  }

  // =========================================================
  // STREAM NOTIFIKASI ANDROID
  // =========================================================

  static Stream<Map<dynamic, dynamic>>
      get notificationStream {
    return _eventChannel
        .receiveBroadcastStream()
        .where(
          (event) => event != null,
        )
        .map(
          (event) {
            try {
              return Map<dynamic, dynamic>.from(
                event as Map,
              );
            } catch (e) {
              print(
                'NotificationService - '
                'Error parsing event: $e',
              );

              return <dynamic, dynamic>{};
            }
          },
        )
        .where(
          (data) => data.isNotEmpty,
        );
  }
}