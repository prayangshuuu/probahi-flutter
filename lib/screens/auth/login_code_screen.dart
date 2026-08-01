import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api_exception.dart';
import '../../state/auth_provider.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/status_banner.dart';
import 'auth_scaffold.dart';

/// Passwordless login: request a one-time code by email, then confirm it.
/// Enabled server-side via `ACCOUNT_LOGIN_BY_CODE_ENABLED` (REST_API.md §2.5).
class LoginCodeScreen extends StatefulWidget {
  const LoginCodeScreen({super.key});

  @override
  State<LoginCodeScreen> createState() => _LoginCodeScreenState();
}

class _LoginCodeScreenState extends State<LoginCodeScreen> {
  final _emailController = TextEditingController();
  final _codeController = TextEditingController();
  bool _codeSent = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _requestCode() async {
    setState(() => _error = null);
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      setState(() => _error = 'Enter your email.');
      return;
    }
    try {
      await context.read<AuthProvider>().requestLoginCode(email);
      setState(() => _codeSent = true);
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = 'Could not reach the server. Check your connection.');
    }
  }

  Future<void> _confirmCode() async {
    setState(() => _error = null);
    final code = _codeController.text.trim();
    if (code.isEmpty) {
      setState(() => _error = 'Enter the code we emailed you.');
      return;
    }
    try {
      await context.read<AuthProvider>().confirmLoginCode(code);
      if (mounted) Navigator.of(context).popUntil((r) => r.isFirst);
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
      chip: 'Sign in with a code',
      title: _codeSent ? 'Enter your code' : 'Sign in with a code',
      subtitle: _codeSent
          ? 'We emailed a one-time code to ${_emailController.text.trim()}.'
          : "We'll email you a one-time code — no password needed.",
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_error != null) ...[
            StatusBanner(message: _error!, type: StatusBannerType.error),
            const SizedBox(height: 16),
          ],
          if (!_codeSent) ...[
            AppTextField(
              label: 'Email',
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.email],
              onSubmitted: (_) => _requestCode(),
            ),
            const SizedBox(height: 20),
            PrimaryButton(label: 'Send code', loading: busy, onPressed: _requestCode),
          ] else ...[
            AppTextField(
              label: 'One-time code',
              controller: _codeController,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.done,
              autofocus: true,
              onSubmitted: (_) => _confirmCode(),
            ),
            const SizedBox(height: 20),
            PrimaryButton(label: 'Confirm', loading: busy, onPressed: _confirmCode),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => setState(() {
                _codeSent = false;
                _codeController.clear();
              }),
              child: const Text('Use a different email'),
            ),
          ],
        ],
      ),
    );
  }
}
