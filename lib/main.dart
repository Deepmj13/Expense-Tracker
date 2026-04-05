import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/themes/app_theme.dart';
import 'providers/app_providers.dart';
import 'services/database_service.dart';
import 'views/auth/login_view.dart';
import 'views/auth/signup_view.dart';
import 'views/home_shell.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DatabaseService().init();
  runApp(const ProviderScope(child: ExpenseTrackerApp()));
}

final _routerProvider = Provider<GoRouter>((ref) {
  final user = ref.watch(authControllerProvider);
  return GoRouter(
    initialLocation: user == null ? '/auth' : '/home',
    routes: [
      GoRoute(
        path: '/auth',
        builder: (_, __) => const _AuthWrapper(),
      ),
      GoRoute(
        path: '/home',
        builder: (_, __) => HomeShell(user: user!),
      ),
    ],
    redirect: (_, state) {
      final inAuth = state.matchedLocation == '/auth';
      if (user == null && !inAuth) return '/auth';
      if (user != null && inAuth) return '/home';
      return null;
    },
  );
});

class _AuthWrapper extends ConsumerStatefulWidget {
  const _AuthWrapper();

  @override
  ConsumerState<_AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends ConsumerState<_AuthWrapper> {
  bool _showSignup = false;

  @override
  Widget build(BuildContext context) {
    return _showSignup
        ? SignupView(onLoginTap: () => setState(() => _showSignup = false))
        : LoginView(onSignupTap: () => setState(() => _showSignup = true));
  }
}

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
    final router = ref.watch(_routerProvider);

    return MaterialApp.router(
      title: 'Expense Tracker',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: mode,
      routerConfig: router,
    );
  }
}
