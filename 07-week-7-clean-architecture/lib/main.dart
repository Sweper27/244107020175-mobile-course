import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'firebase_options.dart';
import 'router/app_router.dart';
import 'services/notification_service.dart';

/// Top-level background message handler.
///
/// Must be a top-level function (not a class method) for Firebase Messaging.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  print('[FCM] Background message: ${message.messageId}');
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Register background message handler
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  // Initialize notification service
  await NotificationService.instance.initialize();

  runApp(const ProviderScope(child: CampusNotificationApp()));
}

class CampusNotificationApp extends ConsumerStatefulWidget {
  const CampusNotificationApp({super.key});

  @override
  ConsumerState<CampusNotificationApp> createState() =>
      _CampusNotificationAppState();
}

class _CampusNotificationAppState
    extends ConsumerState<CampusNotificationApp> {
  @override
  void initState() {
    super.initState();
    _setupNotificationNavigation();
  }

  /// Sets up notification tap handlers for navigation.
  Future<void> _setupNotificationNavigation() async {
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
        // Delay navigation to ensure router is ready
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final router = ref.read(routerProvider);
          router.push('/pengumuman/$announcementId');
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Campus Notification',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.blue,
        useMaterial3: true,
      ),
      routerConfig: router,
    );
  }
}
