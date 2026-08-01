import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../core/app_colors.dart';
import '../../models/lesson.dart';

/// Renders a `YoutubeLesson` (embedded nocookie player, matching the web
/// app's `youtubeplayer.js` use of Plyr in nocookie mode) or a `LinkLesson`
/// (opened in the device's browser — the underlying URL can point to
/// anything, so we don't force it into an in-app WebView).
class LessonPlayerScreen extends StatefulWidget {
  const LessonPlayerScreen({super.key, required this.lesson, required this.courseName});

  final Lesson lesson;
  final String courseName;

  @override
  State<LessonPlayerScreen> createState() => _LessonPlayerScreenState();
}

class _LessonPlayerScreenState extends State<LessonPlayerScreen> {
  WebViewController? _controller;

  @override
  void initState() {
    super.initState();
    if (widget.lesson.type == LessonType.youtube && widget.lesson.videoId != null) {
      final uri = Uri.parse(
        'https://www.youtube-nocookie.com/embed/${widget.lesson.videoId}'
        '?playsinline=1&modestbranding=1&rel=0',
      );
      _controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setBackgroundColor(Colors.black)
        ..loadRequest(uri);
    }
  }

  Future<void> _openLink() async {
    final url = widget.lesson.url;
    if (url == null) return;
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final lesson = widget.lesson;
    return Scaffold(
      appBar: AppBar(
        title: Text(lesson.title, maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
      body: SafeArea(
        child: ListView(
          children: [
            if (_controller != null)
              AspectRatio(
                aspectRatio: 16 / 9,
                child: WebViewWidget(controller: _controller!),
              )
            else if (lesson.type == LessonType.link)
              _LinkCard(lesson: lesson, onOpen: _openLink)
            else
              const Padding(
                padding: EdgeInsets.all(32),
                child: Text(
                  'This lesson type is not supported yet.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.neutral500),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.courseName,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.3,
                      color: AppColors.neutral500,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(lesson.title, style: Theme.of(context).textTheme.titleLarge),
                  if ((lesson.description ?? '').isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(
                      lesson.description!,
                      style: const TextStyle(
                        color: AppColors.neutral600,
                        fontSize: 14,
                        height: 1.6,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LinkCard extends StatelessWidget {
  const _LinkCard({required this.lesson, required this.onOpen});

  final Lesson lesson;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.neutral50,
        border: Border.all(color: AppColors.neutral200),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Icon(Icons.link_rounded, size: 32, color: AppColors.neutral500),
          const SizedBox(height: 12),
          const Text(
            'This lesson links to an external resource.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.neutral600, fontSize: 13.5),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: onOpen,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.neutral900,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Text('Open resource'),
            ),
          ),
        ],
      ),
    );
  }
}
