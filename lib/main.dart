import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/app_theme.dart';
import 'core/config.dart';
import 'screens/common/auth_gate.dart';
import 'state/auth_provider.dart';
import 'state/settings_provider.dart';

void main() {
  runApp(const ProbahiApp());
}

/// App root: provides the two app-wide `ChangeNotifier`s (see
/// `lib/state/`) above `MaterialApp`, then hands off to [AuthGate], which
/// owns the login-vs-home decision. See `README.md` for the overall
/// architecture.
class ProbahiApp extends StatelessWidget {
  const ProbahiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
      ],
      child: MaterialApp(
        title: AppConfig.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        home: const AuthGate(),
      ),
    );
  }
}
