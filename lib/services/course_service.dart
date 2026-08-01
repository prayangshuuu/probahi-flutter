import 'package:dio/dio.dart';

import '../core/api_client.dart';
import '../core/api_exception.dart';
import '../models/course.dart';
import '../models/module.dart';

/// Talks to `apps/course/api.py` under `/api/`. See REST_API.md §3.
class CourseService {
  CourseService({Dio? dio}) : _dio = dio ?? ApiClient.instance.dio;

  final Dio _dio;

  void _throwIfError(Response response) {
    if ((response.statusCode ?? 500) >= 400) {
      throw ApiException.fromResponse(response.statusCode, response.data);
    }
  }

  Future<List<Course>> listCourses() async {
    final response = await _dio.get('/api/courses/');
    _throwIfError(response);
    final data = response.data as List<dynamic>;
    return data
        .map((e) => Course.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Course> getCourse(int id) async {
    final response = await _dio.get('/api/courses/$id/');
    _throwIfError(response);
    return Course.fromJson(response.data as Map<String, dynamic>);
  }

  Future<List<CourseModule>> listModules(int courseId) async {
    final response = await _dio.get('/api/courses/$courseId/modules/');
    _throwIfError(response);
    final data = response.data as List<dynamic>;
    return data
        .map((e) => CourseModule.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<CourseModule> getModule(int id) async {
    final response = await _dio.get('/api/modules/$id/');
    _throwIfError(response);
    return CourseModule.fromJson(response.data as Map<String, dynamic>);
  }

  /// Enrolls the current user in a course. Only meant for free
  /// (`price <= 0`) courses — see REST_API.md §3.4 for why paid courses
  /// must go through the payment flow instead.
  Future<void> enroll(int courseId) async {
    final response = await _dio.post('/api/courses/$courseId/enroll/');
    _throwIfError(response);
  }

  Future<Map<String, dynamic>> tenantInfo() async {
    final response = await _dio.get('/api/tenant-info/');
    _throwIfError(response);
    return Map<String, dynamic>.from(response.data as Map);
  }
}
