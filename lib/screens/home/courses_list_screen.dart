import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api_exception.dart';
import '../../models/course.dart';
import '../../services/course_service.dart';
import '../../state/settings_provider.dart';
import '../../widgets/course_card.dart';
import '../../widgets/error_view.dart';
import '../../widgets/loading_view.dart';
import '../settings/settings_screen.dart';
import 'course_detail_screen.dart';

/// "Courses" tab: the active-course catalog for the current tenant
/// (`GET /api/courses/`, no pagination — see REST_API.md §3.1). The app bar
/// title doubles as the connected tenant's display name once
/// `SettingsProvider.refreshTenantInfo()` resolves.
class CoursesListScreen extends StatefulWidget {
  const CoursesListScreen({super.key});

  @override
  State<CoursesListScreen> createState() => _CoursesListScreenState();
}

class _CoursesListScreenState extends State<CoursesListScreen> {
  final _courseService = CourseService();
  late Future<List<Course>> _future;

  @override
  void initState() {
    super.initState();
    _future = _courseService.listCourses();
  }

  Future<void> _reload() async {
    final future = _courseService.listCourses();
    setState(() => _future = future);
    await future;
  }

  @override
  Widget build(BuildContext context) {
    final tenantName = context.watch<SettingsProvider>().tenantName;

    return Scaffold(
      appBar: AppBar(
        title: Text(tenantName ?? 'Courses'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Server settings',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _reload,
          child: FutureBuilder<List<Course>>(
            future: _future,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const LoadingView();
              }
              if (snapshot.hasError) {
                final message = snapshot.error is ApiException
                    ? (snapshot.error as ApiException).message
                    : 'Could not load courses. Check your connection or server address.';
                return ListView(
                  children: [
                    SizedBox(
                      height: 400,
                      child: ErrorView(message: message, onRetry: _reload),
                    ),
                  ],
                );
              }
              final courses = snapshot.data ?? [];
              if (courses.isEmpty) {
                return ListView(
                  children: const [
                    SizedBox(
                      height: 400,
                      child: Center(child: Text('No courses yet.')),
                    ),
                  ],
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: courses.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final course = courses[index];
                  return CourseCard(
                    course: course,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => CourseDetailScreen(courseId: course.id),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}
