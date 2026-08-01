import 'package:flutter/material.dart';

/// Standard full-space loading state for `FutureBuilder`s across screens —
/// use this instead of a bare `CircularProgressIndicator()` so loading
/// states look consistent app-wide.
class LoadingView extends StatelessWidget {
  const LoadingView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator());
  }
}
