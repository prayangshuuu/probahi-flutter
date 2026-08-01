import 'lesson.dart';

/// A course module: an ordered group of [Lesson]s. See REST_API.md §3.3.
class CourseModule {
  const CourseModule({
    required this.id,
    required this.title,
    required this.description,
    required this.order,
    required this.lessons,
  });

  final int id;
  final String title;
  final String? description;
  final int order;
  final List<Lesson> lessons;

  factory CourseModule.fromJson(Map<String, dynamic> json) {
    final lessonsJson = json['lessons'] as List<dynamic>? ?? [];
    return CourseModule(
      id: json['id'] as int,
      title: (json['title'] ?? '').toString(),
      description: json['description'] as String?,
      order: json['order'] as int? ?? 0,
      lessons: lessonsJson
          .map((e) => Lesson.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
