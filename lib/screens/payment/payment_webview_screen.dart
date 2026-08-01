import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../core/app_colors.dart';
import '../../widgets/app_button.dart';
import '../../widgets/status_banner.dart';

enum _PaymentResult { none, success, failure, pending }

/// Hosts the PayStation checkout in a WebView and watches the navigation
/// URL for the tenant's server-rendered result pages
/// (`/payment/success|failure|pending/`) — see REST_API.md §4.1. The caller
/// is responsible for re-fetching course detail after this screen closes,
/// since these pages don't return JSON we can trust directly.
class PaymentWebViewScreen extends StatefulWidget {
  const PaymentWebViewScreen({super.key, required this.paymentUrl});

  final String paymentUrl;

  @override
  State<PaymentWebViewScreen> createState() => _PaymentWebViewScreenState();
}

class _PaymentWebViewScreenState extends State<PaymentWebViewScreen> {
  late final WebViewController _controller;
  bool _loading = true;
  _PaymentResult _result = _PaymentResult.none;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (url) {
            _checkUrl(url);
            if (mounted) setState(() => _loading = true);
          },
          onPageFinished: (url) {
            _checkUrl(url);
            if (mounted) setState(() => _loading = false);
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.paymentUrl));
  }

  void _checkUrl(String url) {
    final path = Uri.tryParse(url)?.path ?? '';
    _PaymentResult next = _result;
    if (path.contains('/payment/success/')) {
      next = _PaymentResult.success;
    } else if (path.contains('/payment/failure/')) {
      next = _PaymentResult.failure;
    } else if (path.contains('/payment/pending/')) {
      next = _PaymentResult.pending;
    }
    if (next != _result && mounted) {
      setState(() => _result = next);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Checkout'),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_loading) const LinearProgressIndicator(minHeight: 2),
        ],
      ),
      bottomNavigationBar: _result == _PaymentResult.none
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    StatusBanner(
                      message: switch (_result) {
                        _PaymentResult.success =>
                          'Payment confirmed. Your enrollment will unlock shortly.',
                        _PaymentResult.failure =>
                          'Payment failed. You can close this and try again.',
                        _PaymentResult.pending =>
                          'Payment is pending confirmation.',
                        _PaymentResult.none => '',
                      },
                      type: switch (_result) {
                        _PaymentResult.success => StatusBannerType.success,
                        _PaymentResult.failure => StatusBannerType.error,
                        _PaymentResult.pending => StatusBannerType.warning,
                        _PaymentResult.none => StatusBannerType.info,
                      },
                    ),
                    const SizedBox(height: 12),
                    PrimaryButton(
                      label: 'Done',
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
            ),
      backgroundColor: AppColors.white,
    );
  }
}
