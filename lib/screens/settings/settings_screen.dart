import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_colors.dart';
import '../../core/config.dart';
import '../../state/auth_provider.dart';
import '../../state/settings_provider.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/status_banner.dart';

/// Lets the user point the app at a different tenant subdomain at runtime
/// — the "easily editable base URL" surface described in REST_API.md §1.
/// The built-in default lives in [AppConfig.defaultBaseUrl].
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final TextEditingController _controller;
  bool _saving = false;
  String? _error;
  String? _info;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: context.read<SettingsProvider>().baseUrl,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() {
      _error = null;
      _info = null;
    });
    final value = _controller.text.trim();
    if (value.isEmpty) {
      setState(() => _error = 'Enter a server URL.');
      return;
    }

    setState(() => _saving = true);
    final settings = context.read<SettingsProvider>();
    final auth = context.read<AuthProvider>();
    final wasAuthenticated = auth.isAuthenticated;
    final changed = value != settings.baseUrl;

    try {
      await settings.setBaseUrl(value);
      if (changed && wasAuthenticated) {
        // A session token is only valid for the tenant schema it was
        // issued on — switching academies means starting a fresh session.
        await auth.logout();
        if (mounted) Navigator.of(context).popUntil((r) => r.isFirst);
        return;
      }
      setState(() => _info = 'Saved.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _resetDefault() async {
    _controller.text = AppConfig.defaultBaseUrl;
    await _save();
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Academy / server')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text(
              'Each academy is served from its own subdomain. Point the '
              'app at a different one by changing the server URL below.',
              style: TextStyle(color: AppColors.neutral600, fontSize: 13.5, height: 1.5),
            ),
            const SizedBox(height: 20),
            if (_error != null) ...[
              StatusBanner(message: _error!, type: StatusBannerType.error),
              const SizedBox(height: 14),
            ],
            if (_info != null) ...[
              StatusBanner(message: _info!, type: StatusBannerType.success),
              const SizedBox(height: 14),
            ],
            AppTextField(
              label: 'Server URL',
              controller: _controller,
              keyboardType: TextInputType.url,
              textInputAction: TextInputAction.done,
              helperText: 'e.g. https://daniel.probahi.com',
              onSubmitted: (_) => _save(),
            ),
            const SizedBox(height: 8),
            if (settings.tenantName != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, size: 16, color: AppColors.emerald600),
                    const SizedBox(width: 6),
                    Text(
                      'Connected: ${settings.tenantName}',
                      style: const TextStyle(fontSize: 12.5, color: AppColors.neutral600),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 24),
            PrimaryButton(label: 'Save', loading: _saving, onPressed: _save),
            const SizedBox(height: 12),
            if (!settings.isDefaultUrl)
              SecondaryButton(
                label: 'Reset to default (${AppConfig.defaultBaseUrl})',
                onPressed: _resetDefault,
              ),
          ],
        ),
      ),
    );
  }
}
