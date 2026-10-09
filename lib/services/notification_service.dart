import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/hotel_model.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static const String _prefKeyBookingNotifications = 'booking_notifications_enabled';
  bool _isInitialized = false;

  /// Initialize local notifications configuration
  Future<void> initialize() async {
    if (_isInitialized) return;

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const WindowsInitializationSettings initializationSettingsWindows =
        WindowsInitializationSettings(
      appName: 'StayEase',
      appUserModelId: 'com.stayease.hotel_booking_app',
      guid: '3bb1db42-fca1-4566-b333-33bc076fe9f3',
    );

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
      macOS: initializationSettingsDarwin,
      windows: initializationSettingsWindows,
    );

    try {
      await _notificationsPlugin.initialize(
        settings: initializationSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          debugPrint('Notification tapped: ${response.payload}');
        },
      );
      _isInitialized = true;
    } catch (e) {
      debugPrint('Failed to initialize notifications: $e');
    }
  }

  /// Request permissions for Android 13+ and iOS
  Future<bool> requestPermissions() async {
    try {
      final androidImplementation = _notificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      if (androidImplementation != null) {
        final granted =
            await androidImplementation.requestNotificationsPermission();
        return granted ?? false;
      }
      return true;
    } catch (e) {
      debugPrint('Error requesting notification permissions: $e');
      return false;
    }
  }

  /// Check whether booking notifications are enabled in settings
  Future<bool> areBookingNotificationsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_prefKeyBookingNotifications) ?? true;
  }

  /// Save booking notifications preference
  Future<void> setBookingNotificationsEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefKeyBookingNotifications, enabled);
  }

  /// Show a notification for a confirmed booking
  Future<void> showBookingConfirmationNotification(Booking booking) async {
    final bool enabled = await areBookingNotificationsEnabled();
    if (!enabled) return;

    await initialize();

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'booking_channel',
      'Booking Notifications',
      channelDescription: 'Notifications for your hotel bookings and trip updates',
      importance: Importance.max,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const DarwinNotificationDetails darwinDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const WindowsNotificationDetails windowsDetails = WindowsNotificationDetails();

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: darwinDetails,
      macOS: darwinDetails,
      windows: windowsDetails,
    );

    final String checkInStr =
        '${booking.checkInDate.year}-${booking.checkInDate.month.toString().padLeft(2, '0')}-${booking.checkInDate.day.toString().padLeft(2, '0')}';

    try {
      await _notificationsPlugin.show(
        id: booking.id.hashCode,
        title: 'Booking Confirmed! 🎉',
        body: 'Your stay at ${booking.hotel.name} is confirmed for $checkInStr.',
        notificationDetails: notificationDetails,
        payload: booking.id,
      );
    } catch (e) {
      debugPrint('Error showing booking notification: $e');
    }
  }
}
