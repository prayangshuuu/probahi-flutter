import 'package:dio/dio.dart';

import '../core/api_client.dart';
import '../core/api_exception.dart';

/// Talks to `apps/payment/api.py`. See REST_API.md §4.
class PaymentService {
  PaymentService({Dio? dio}) : _dio = dio ?? ApiClient.instance.dio;

  final Dio _dio;

  /// Initiates a PayStation payment and returns the gateway URL to open in
  /// a WebView. [buyerId] must be the *currently logged-in* user's own id
  /// (see REST_API.md §4.2 — the backend doesn't enforce this itself yet).
  Future<String> initiatePayment({
    required int tenantId,
    required int courseId,
    required int buyerId,
  }) async {
    final response = await _dio.post(
      '/api/initiate/',
      data: {
        'tenant_id': tenantId,
        'course_id': courseId,
        'buyer_id': buyerId,
      },
    );
    if ((response.statusCode ?? 500) >= 400) {
      throw ApiException.fromResponse(response.statusCode, response.data);
    }
    final data = response.data as Map<String, dynamic>;
    final url = data['payment_url'] as String?;
    if (url == null || url.isEmpty) {
      throw ApiException('Payment gateway did not return a URL.');
    }
    return url;
  }
}
