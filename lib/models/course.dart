import 'module.dart';

/// Backs both `CourseListSerializer` (list view — `description`,
/// `isEnrolled` and `modules` are absent) and `CourseDetailSerializer`
/// (detail view). See REST_API.md §3.1-3.2.
class Course {
  const Course({
    required this.id,
    required this.name,
    required this.smallDescription,
    required this.priceRaw,
    required this.currency,
    this.description,
    this.isEnrolled,
    this.modules,
  });

  final int id;
  final String name;
  final String? smallDescription;
  final String? description;

  /// Raw decimal-as-string from the API, e.g. `"1500.00"`.
  final String priceRaw;
  final String currency;

  /// Only populated by the detail endpoint; `null` from the list endpoint.
  final bool? isEnrolled;
  final List<CourseModule>? modules;

  double get priceValue => double.tryParse(priceRaw) ?? 0;
  bool get isFree => priceValue <= 0;

  String get formattedPrice =>
      isFree ? 'Free' : '${_trimTrailingZeros(priceRaw)} $currency';

  static String _trimTrailingZeros(String raw) {
    final value = double.tryParse(raw);
    if (value == null) return raw;
    if (value == value.roundToDouble()) {
      return value.toStringAsFixed(0);
    }
    return value.toStringAsFixed(2);
  }

  factory Course.fromJson(Map<String, dynamic> json) {
    final modulesJson = json['modules'] as List<dynamic>?;
    return Course(
      id: json['id'] as int,
      name: (json['name'] ?? '').toString(),
      smallDescription: json['small_description'] as String?,
      description: json['description'] as String?,
      priceRaw: (json['price'] ?? '0').toString(),
      currency: (json['currency'] ?? 'BDT').toString(),
      isEnrolled: json['is_enrolled'] as bool?,
      modules: modulesJson
          ?.map((e) => CourseModule.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
