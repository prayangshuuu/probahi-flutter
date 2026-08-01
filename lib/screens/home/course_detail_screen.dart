import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api_exception.dart';
import '../../core/app_colors.dart';
import '../../models/course.dart';
import '../../models/lesson.dart';
import '../../models/module.dart';
import '../../services/course_service.dart';
import '../../services/payment_service.dart';
import '../../state/auth_provider.dart';
import '../../state/settings_provider.dart';
import '../../widgets/app_button.dart';
import '../../widgets/error_view.dart';
import '../../widgets/loading_view.dart';
import '../../widgets/status_banner.dart';
import '../payment/payment_webview_screen.dart';
import 'lesson_player_screen.dart';

/// Course detail: description, enroll/buy action, and the module/lesson
/// tree with lock icons for gated content (REST_API.md §3.2). Free courses
/// (`price <= 0`) enroll instantly via the API; paid courses go through
/// [PaymentWebViewScreen] instead — see REST_API.md §3.4/§4 for why the
/// free-enroll endpoint alone isn't a safe purchase path.
class CourseDetailScreen extends StatefulWidget {
  const CourseDetailScreen({super.key, required this.courseId});

  final int courseId;

  @override
  State<CourseDetailScreen> createState() => _CourseDetailScreenState();
}

class _CourseDetailScreenState extends State<CourseDetailScreen> {
  final _courseService = CourseService();
  late Future<Course> _future;
  bool _actionBusy = false;

  @override
  void initState() {
    super.initState();
    _future = _courseService.getCourse(widget.courseId);
  }

  Future<void> _reload() async {
    final future = _courseService.getCourse(widget.courseId);
    setState(() => _future = future);
    await future;
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _enrollFree() async {
    setState(() => _actionBusy = true);
    try {
      await _courseService.enroll(widget.courseId);
      await _reload();
      _showSnack("You're enrolled!");
    } on ApiException catch (e) {
      _showSnack(e.message);
    } catch (_) {
      _showSnack('Could not enroll. Check your connection.');
    } finally {
      if (mounted) setState(() => _actionBusy = false);
    }
  }

  Future<void> _buyCourse() async {
    final auth = context.read<AuthProvider>();
    final buyerId = auth.user?.id;
    if (buyerId == null) {
      _showSnack('Please sign in again.');
      return;
    }

    setState(() => _actionBusy = true);
    try {
      var tenantId = context.read<SettingsProvider>().tenantId;
      tenantId ??= (await _courseService.tenantInfo())['tenant_id'] as int?;
      if (tenantId == null) {
        _showSnack('Could not determine this academy. Try again.');
        return;
      }

      final paymentUrl = await PaymentService().initiatePayment(
        tenantId: tenantId,
        courseId: widget.courseId,
        buyerId: buyerId,
      );

      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => PaymentWebViewScreen(paymentUrl: paymentUrl),
        ),
      );
      await _reload();
    } on ApiException catch (e) {
      _showSnack(e.message);
    } catch (_) {
      _showSnack('Could not start payment. Check your connection.');
    } finally {
      if (mounted) setState(() => _actionBusy = false);
    }
  }

  void _openLesson(Lesson lesson, String courseName) {
    if (!lesson.isUnlocked) {
      _showSnack('Enroll in this course to unlock this lesson.');
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => LessonPlayerScreen(lesson: lesson, courseName: courseName),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Course')),
      body: SafeArea(
        child: FutureBuilder<Course>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const LoadingView();
            }
            if (snapshot.hasError || !snapshot.hasData) {
              final message = snapshot.error is ApiException
                  ? (snapshot.error as ApiException).message
                  : 'Could not load this course.';
              return ErrorView(message: message, onRetry: _reload);
            }
            final course = snapshot.data!;
            return RefreshIndicator(
              onRefresh: _reload,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Text(course.name, style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 10),
                  if ((course.description ?? course.smallDescription ?? '').isNotEmpty)
                    Text(
                      course.description ?? course.smallDescription!,
                      style: const TextStyle(
                        color: AppColors.neutral600,
                        fontSize: 14,
                        height: 1.6,
                      ),
                    ),
                  const SizedBox(height: 20),
                  _buildActionArea(course),
                  const SizedBox(height: 28),
                  Text('Modules', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 12),
                  if ((course.modules ?? []).isEmpty)
                    const Text(
                      'No modules published yet.',
                      style: TextStyle(color: AppColors.neutral500),
                    )
                  else
                    ...course.modules!.map(
                      (module) => _ModuleTile(
                        module: module,
                        onLessonTap: (lesson) => _openLesson(lesson, course.name),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildActionArea(Course course) {
    if (course.isEnrolled == true) {
      return const StatusBanner(
        message: "You're enrolled in this course.",
        type: StatusBannerType.success,
      );
    }
    return Row(
      children: [
        Expanded(
          child: Text(
            course.formattedPrice,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.neutral900,
            ),
          ),
        ),
        SizedBox(
          width: 170,
          child: PrimaryButton(
            label: course.isFree ? 'Enroll for free' : 'Buy now',
            loading: _actionBusy,
            onPressed: course.isFree ? _enrollFree : _buyCourse,
          ),
        ),
      ],
    );
  }
}

class _ModuleTile extends StatelessWidget {
  const _ModuleTile({required this.module, required this.onLessonTap});

  final CourseModule module;
  final ValueChanged<Lesson> onLessonTap;

  @override
  Widget build(BuildContext context) {
    final lessonCount = module.lessons.length;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border.all(color: AppColors.neutral200),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16),
          title: Text(
            module.title,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14.5),
          ),
          subtitle: Text(
            '$lessonCount lesson${lessonCount == 1 ? '' : 's'}',
            style: const TextStyle(color: AppColors.neutral500, fontSize: 12.5),
          ),
          childrenPadding: const EdgeInsets.only(bottom: 8),
          children: module.lessons
              .map((lesson) => _LessonRow(lesson: lesson, onTap: () => onLessonTap(lesson)))
              .toList(),
        ),
      ),
    );
  }
}

class _LessonRow extends StatelessWidget {
  const _LessonRow({required this.lesson, required this.onTap});

  final Lesson lesson;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final icon = !lesson.isUnlocked
        ? Icons.lock_outline_rounded
        : lesson.type == LessonType.youtube
        ? Icons.play_circle_outline_rounded
        : Icons.link_rounded;

    return ListTile(
      onTap: onTap,
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      leading: Icon(
        icon,
        size: 20,
        color: lesson.isUnlocked ? AppColors.neutral700 : AppColors.neutral400,
      ),
      title: Text(
        lesson.title,
        style: TextStyle(
          fontSize: 13.5,
          color: lesson.isUnlocked ? AppColors.neutral900 : AppColors.neutral500,
        ),
      ),
      trailing: lesson.isFree
          ? const _FreeChip()
          : (!lesson.isUnlocked
                ? const Icon(Icons.lock, size: 14, color: AppColors.neutral400)
                : null),
    );
  }
}

class _FreeChip extends StatelessWidget {
  const _FreeChip();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.neutral50,
        border: Border.all(color: AppColors.neutral200),
        borderRadius: BorderRadius.circular(999),
      ),
      child: const Text(
        'FREE',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.4,
          color: AppColors.neutral600,
        ),
      ),
    );
  }
}
