import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/auth_provider.dart';
import '../../state/settings_provider.dart';
import '../auth/login_screen.dart';
import '../home/home_shell.dart';
import 'splash_screen.dart';

/// Root of the widget tree, below `MaterialApp`. Loads the tenant base URL
/// then tries to restore a stored session, and swaps between the
/// unauthenticated (login) and authenticated (home) trees based on
/// [AuthProvider.status].
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  Future<void> _bootstrap() async {
    final settings = context.read<SettingsProvider>();
    final auth = context.read<AuthProvider>();
    await settings.load();
    if (!mounted) return;
    await auth.restoreSession();
  }

  @override
  Widget build(BuildContext context) {
    final status = context.watch<AuthProvider>().status;

    return switch (status) {
      AuthStatus.unknown => const SplashScreen(),
      AuthStatus.unauthenticated => const LoginScreen(),
      AuthStatus.authenticated => const HomeShell(),
    };
  }
}
