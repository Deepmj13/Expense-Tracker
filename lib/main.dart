import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'core/themes/app_theme.dart';
import 'providers/app_providers.dart';
import 'services/database_service.dart';
import 'services/notification_service.dart';
import 'services/sms_background_sync_service.dart';
import 'services/sms_sync_preference_service.dart';
import 'views/auth/auth_wrapper.dart';
import 'views/home_shell.dart';
import 'views/loading_view.dart';

final navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Hive.initFlutter();
    await DatabaseService().init();
  } catch (e) {
    debugPrint('Failed to initialize database: $e');
  }

  try {
    await NotificationService.instance.init();
  } catch (e) {
    debugPrint('Failed to initialize notifications: $e');
  }

  try {
    await SmsBackgroundSyncService.instance.init();
    await _checkAndSchedulePeriodicSync();
  } catch (e) {
    debugPrint('Failed to initialize background sync: $e');
  }

  runApp(const ProviderScope(child: ExpenseTrackerApp()));
}

Future<void> _checkAndSchedulePeriodicSync() async {
  try {
    final prefsService = SmsSyncPreferenceService();
    await prefsService.init();
    final prefs = prefsService.getPreferences();

    if (prefs.periodicSyncEnabled && prefs.lastUserId != null) {
      await SmsBackgroundSyncService.instance.schedulePeriodicSync();
      debugPrint('Periodic sync scheduled on app start');
    }
  } catch (e) {
    debugPrint('Error checking periodic sync preference: $e');
  }
}

final _routerProvider = Provider<GoRouter>((ref) {
  final user = ref.watch(authControllerProvider);
  final isHydrated = ref.watch(isAuthHydratedProvider);
  return GoRouter(
    navigatorKey: navigatorKey,
    initialLocation: '/auth',
    routes: [
      GoRoute(
        path: '/auth',
        builder: (_, __) => const AuthWrapper(),
      ),
      GoRoute(
        path: '/home',
        builder: (_, __) {
          if (!isHydrated) return const LoadingView();
          if (user == null) return const AuthWrapper();
          return HomeShell(user: user);
        },
      ),
    ],
    redirect: (_, state) {
      if (!isHydrated) return null;
      final inAuth = state.matchedLocation == '/auth';
      if (user == null && !inAuth) return '/auth';
      if (user != null && inAuth) return '/home';
      return null;
    },
  );
});

class ExpenseTrackerApp extends ConsumerStatefulWidget {
  const ExpenseTrackerApp({super.key});

  @override
  ConsumerState<ExpenseTrackerApp> createState() => _ExpenseTrackerAppState();
}

class _ExpenseTrackerAppState extends ConsumerState<ExpenseTrackerApp> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(authControllerProvider.notifier).hydrate());
  }

  @override
  Widget build(BuildContext context) {
    final mode = ref.watch(themeModeProvider);
    final accentColor = ref.watch(accentColorProvider);
    final router = ref.watch(_routerProvider);

    return MaterialApp.router(
      title: 'Expense Tracker',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(accentColor),
      darkTheme: AppTheme.dark(accentColor),
      themeMode: mode,
      routerConfig: router,
    );
  }
}
