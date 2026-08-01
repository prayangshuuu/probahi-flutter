/// Normalized error surfaced to the UI, parsed from whichever of the
/// backend's three response shapes came back (see REST_API.md §6):
///
/// 1. allauth headless: `{"status": 400, "errors": [{"message": "...", "param": "email"}]}`
/// 2. Plain DRF serializer: `{"field": ["error", ...]}` or `{"detail": "..."}`
/// 3. Payment API: `{"status_code": 404, "error": "...", "message": "..."}`
class ApiException implements Exception {
  ApiException(this.message, {this.statusCode, this.fieldErrors});

  final String message;
  final int? statusCode;

  /// Field name -> error messages, when the backend returned per-field
  /// validation errors (allauth `param` or DRF field keys).
  final Map<String, List<String>>? fieldErrors;

  static ApiException fromResponse(int? statusCode, dynamic data) {
    if (data is Map<String, dynamic>) {
      // Shape 1: allauth headless.
      final errors = data['errors'];
      if (errors is List && errors.isNotEmpty) {
        final fieldErrors = <String, List<String>>{};
        final messages = <String>[];
        for (final e in errors) {
          if (e is Map) {
            final msg = e['message']?.toString();
            final param = e['param']?.toString();
            if (msg != null) {
              messages.add(msg);
              if (param != null) {
                fieldErrors.putIfAbsent(param, () => []).add(msg);
              }
            }
          }
        }
        return ApiException(
          messages.isNotEmpty ? messages.join('\n') : 'Something went wrong.',
          statusCode: statusCode,
          fieldErrors: fieldErrors.isEmpty ? null : fieldErrors,
        );
      }

      // allauth headless "pending flow" response: no `errors`, just
      // `data.flows` indicating what the client should do next (e.g. verify
      // email, complete 2FA). Not a validation error, but still not the
      // success the caller expected.
      final innerData = data['data'];
      if (innerData is Map && innerData['flows'] is List) {
        final flowIds = (innerData['flows'] as List)
            .whereType<Map>()
            .map((f) => f['id']?.toString())
            .whereType<String>()
            .toList();
        if (flowIds.isNotEmpty) {
          return ApiException(
            'Additional step required: ${flowIds.join(', ')}',
            statusCode: statusCode,
          );
        }
      }

      // Shape 3: payment API custom error envelope.
      if (data.containsKey('error') && data.containsKey('message')) {
        return ApiException(
          data['message']?.toString() ?? data['error'].toString(),
          statusCode: statusCode,
        );
      }

      // Shape 2b: DRF `{"detail": "..."}`.
      if (data['detail'] != null) {
        return ApiException(data['detail'].toString(), statusCode: statusCode);
      }

      // Shape 2a: DRF per-field serializer errors, e.g.
      // {"tenant_id": ["This field is required."]}.
      final fieldErrors = <String, List<String>>{};
      final messages = <String>[];
      data.forEach((key, value) {
        if (value is List) {
          final strings = value.map((e) => e.toString()).toList();
          fieldErrors[key] = strings;
          messages.addAll(strings);
        } else if (value is String) {
          fieldErrors[key] = [value];
          messages.add(value);
        }
      });
      if (messages.isNotEmpty) {
        return ApiException(
          messages.join('\n'),
          statusCode: statusCode,
          fieldErrors: fieldErrors,
        );
      }
    }

    if (data is String && data.trim().isNotEmpty) {
      return ApiException(data, statusCode: statusCode);
    }

    return ApiException(
      'Something went wrong. Please try again.',
      statusCode: statusCode,
    );
  }

  @override
  String toString() => message;
}
