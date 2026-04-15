import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/app_providers.dart';
import '../loading_view.dart';
import 'signup_view.dart';

class AuthWrapper extends ConsumerWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isHydrated = ref.watch(isAuthHydratedProvider);
    final user = ref.watch(authControllerProvider);

    if (!isHydrated) {
      return const LoadingView();
    }

    if (user != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.go('/home');
      });
      return const LoadingView();
    }

    return const SignupView();
  }
}
