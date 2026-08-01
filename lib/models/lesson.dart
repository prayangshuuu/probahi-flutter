enum LessonType { youtube, link, unknown }

/// A polymorphic `Lesson` (`YoutubeLesson` | `LinkLesson`), see
/// REST_API.md §3.2. The gated content field (`video_id`/`url`) is simply
/// absent from the JSON when the caller isn't allowed to see it yet, so
/// [videoId]/[url] are nullable even for a lesson's "own" type.
class Lesson {
  const Lesson({
    required this.id,
    required this.title,
    required this.description,
    required this.isFree,
    required this.order,
    required this.type,
    this.videoId,
    this.url,
  });

  final int id;
  final String title;
  final String? description;
  final bool isFree;
  final int order;
  final LessonType type;
  final String? videoId;
  final String? url;

  /// True once the gated content field is actually present in the payload
  /// (i.e. this lesson is free, or the caller is authenticated+enrolled).
  bool get isUnlocked => videoId != null || url != null;

  factory Lesson.fromJson(Map<String, dynamic> json) {
    final typeName =
        (json['resourcetype'] ?? json['model_name'] ?? '').toString();
    final type = switch (typeName) {
      'YoutubeLesson' => LessonType.youtube,
      'LinkLesson' => LessonType.link,
      _ => LessonType.unknown,
    };
    return Lesson(
      id: json['id'] as int,
      title: (json['title'] ?? '').toString(),
      description: json['description'] as String?,
      isFree: json['is_free'] as bool? ?? false,
      order: json['order'] as int? ?? 0,
      type: type,
      videoId: json['video_id'] as String?,
      url: json['url'] as String?,
    );
  }
}
