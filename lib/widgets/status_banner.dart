import 'package:flutter/material.dart';

import '../core/app_colors.dart';

enum StatusBannerType { info, success, warning, error }

/// Mirrors `.auth-status-info/success/warning` from the web app, plus an
/// `error` variant (red) that the web app expresses via `errorlist`
/// instead of a full banner.
class StatusBanner extends StatelessWidget {
  const StatusBanner({super.key, required this.message, required this.type});

  final String message;
  final StatusBannerType type;

  @override
  Widget build(BuildContext context) {
    final (bg, border, fg) = switch (type) {
      StatusBannerType.info => (AppColors.sky50, AppColors.sky200, AppColors.neutral800),
      StatusBannerType.success => (
        AppColors.emerald50,
        AppColors.emerald200,
        AppColors.neutral800,
      ),
      StatusBannerType.warning => (
        AppColors.amber50,
        AppColors.amber200,
        AppColors.neutral800,
      ),
      StatusBannerType.error => (AppColors.red50, AppColors.red200, AppColors.red600),
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: bg,
        border: Border.all(color: border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: TextStyle(color: fg, fontSize: 13, height: 1.4),
      ),
    );
  }
}
