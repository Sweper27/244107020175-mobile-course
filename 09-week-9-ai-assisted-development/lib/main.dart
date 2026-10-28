import 'dart:developer' as developer;

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'firebase_options.dart';
import 'routes.dart';
import 'services/notification_service.dart';

/// Top-level background message handler for FCM.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    developer.log('Background message: ${message.messageId}', name: 'FCM');
  } catch (e) {
    developer.log('Background handler error: $e', name: 'FCM');
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase and Notification safely to ensure runApp is always reached
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Register background message handler
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // Initialize notification service
    await NotificationService.instance.initialize();
  } catch (e, stackTrace) {
    developer.log(
      'Gagal menginisialisasi Firebase/Notification: $e',
      error: e,
      stackTrace: stackTrace,
      name: 'MainInit',
    );
  }

  runApp(const ProviderScope(child: CampusNotificationApp()));
}

class CampusNotificationApp extends ConsumerStatefulWidget {
  const CampusNotificationApp({super.key});

  @override
  ConsumerState<CampusNotificationApp> createState() =>
      _CampusNotificationAppState();
}

class _CampusNotificationAppState extends ConsumerState<CampusNotificationApp> {
  @override
  void initState() {
    super.initState();
    _setupNotificationNavigation();
  }

  /// Sets up notification tap handlers for navigation.
  Future<void> _setupNotificationNavigation() async {
    try {
      final notificationService = NotificationService.instance;

      // Handle notification tap callback
      notificationService.onNotificationTap = (announcementId) {
        final router = ref.read(routerProvider);
        router.push('/pengumuman/$announcementId');
      };

      // Handle terminated state — app opened from notification
      final initialMessage = await notificationService.getInitialMessage();
      if (initialMessage != null) {
        final announcementId = initialMessage.data['announcementId'];
        if (announcementId != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            final router = ref.read(routerProvider);
            router.push('/pengumuman/$announcementId');
          });
        }
      }
    } catch (e) {
      developer.log('Notification navigation setup error: $e', name: 'AppInit');
    }
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Campus Notification',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: Colors.blue, useMaterial3: true),
      routerConfig: router,
    );
  }
}
