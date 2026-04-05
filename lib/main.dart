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

class ExpenseTrackerApp extends ConsumerStatefulWidget {
  const ExpenseTrackerApp({super.key});

  @override
  ConsumerState<ExpenseTrackerApp> createState() => _ExpenseTrackerAppState();
}

class _ExpenseTrackerAppState extends ConsumerState<ExpenseTrackerApp> {
  bool _showSignup = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(authControllerProvider.notifier).hydrate());
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authControllerProvider);
    final mode = ref.watch(themeModeProvider);

    final router = GoRouter(
      initialLocation: user == null ? '/auth' : '/home',
      routes: [
        GoRoute(
          path: '/auth',
          builder: (_, __) => _showSignup
              ? SignupView(onLoginTap: () => setState(() => _showSignup = false))
              : LoginView(onSignupTap: () => setState(() => _showSignup = true)),
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
