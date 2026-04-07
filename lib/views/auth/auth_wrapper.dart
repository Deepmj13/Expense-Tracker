import 'package:flutter/material.dart';

import 'login_view.dart';
import 'signup_view.dart';

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _showSignup = false;

  @override
  Widget build(BuildContext context) {
    return _showSignup
        ? SignupView(onLoginTap: () => setState(() => _showSignup = false))
        : LoginView(onSignupTap: () => setState(() => _showSignup = true));
  }
}
