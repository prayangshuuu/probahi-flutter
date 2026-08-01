import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../core/config.dart';

/// Shown by AuthGate while the base URL loads and a stored session is
/// being validated — before we know whether to show login or home. Renders
/// the branding logo when one has been generated (see `tool/brand_app.dart`),
/// falling back to the app name as text.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.neutral50,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (AppConfig.hasLogo)
              Image.asset(AppConfig.logoAssetPath, width: 96, height: 96)
            else
              Text(
                AppConfig.appName,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.4,
                  color: AppColors.neutral900,
                ),
              ),
            const SizedBox(height: 24),
            const CircularProgressIndicator(strokeWidth: 2.5),
          ],
        ),
      ),
    );
  }
}
