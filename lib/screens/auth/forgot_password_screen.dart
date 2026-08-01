import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api_exception.dart';
import '../../state/auth_provider.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/status_banner.dart';
import 'auth_scaffold.dart';

/// Two steps: request a reset email, then paste the `key` from the emailed
/// link (`.../reset/?key=...`) along with a new password. The app has no
/// deep-link handling configured, so the key is entered manually — see
/// REST_API.md §2.7.
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  final _keyController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _emailSent = false;
  String? _error;
  String? _info;

  @override
  void dispose() {
    _emailController.dispose();
    _keyController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _requestReset() async {
    setState(() {
      _error = null;
      _info = null;
    });
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      setState(() => _error = 'Enter your email.');
      return;
    }
    try {
      await context.read<AuthProvider>().requestPasswordReset(email);
      setState(() => _emailSent = true);
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = 'Could not reach the server. Check your connection.');
    }
  }

  Future<void> _submitReset() async {
    setState(() {
      _error = null;
      _info = null;
    });
    final key = _keyController.text.trim();
    final password = _passwordController.text;
    if (key.isEmpty || password.isEmpty) {
      setState(() => _error = 'Enter the reset key and a new password.');
      return;
    }
    try {
      await context.read<AuthProvider>().resetPassword(key: key, password: password);
      if (mounted) {
        setState(() => _info = 'Password reset. You can sign in now.');
      }
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = 'Could not reach the server. Check your connection.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final busy = context.watch<AuthProvider>().busy;

    return AuthScaffold(
      chip: 'Reset password',
      title: 'Forgot your password?',
      subtitle: _emailSent
          ? 'Open the email we sent, copy the "key" from the reset link, and set a new password below.'
          : "Enter your account email and we'll send a reset link.",
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_error != null) ...[
            StatusBanner(message: _error!, type: StatusBannerType.error),
            const SizedBox(height: 16),
          ],
          if (_info != null) ...[
            StatusBanner(message: _info!, type: StatusBannerType.success),
            const SizedBox(height: 16),
          ],
          if (!_emailSent) ...[
            AppTextField(
              label: 'Email',
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _requestReset(),
            ),
            const SizedBox(height: 20),
            PrimaryButton(
              label: 'Send reset link',
              loading: busy,
              onPressed: _requestReset,
            ),
          ] else ...[
            AppTextField(
              label: 'Reset key',
              controller: _keyController,
              helperText: 'From the link in the email, e.g. .../reset/?key=THIS',
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 14),
            AppTextField(
              label: 'New password',
              controller: _passwordController,
              obscureText: true,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _submitReset(),
            ),
            const SizedBox(height: 20),
            PrimaryButton(
              label: 'Reset password',
              loading: busy,
              onPressed: _submitReset,
            ),
          ],
          const SizedBox(height: 16),
          Center(
            child: TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Back to sign in'),
            ),
          ),
        ],
      ),
    );
  }
}
