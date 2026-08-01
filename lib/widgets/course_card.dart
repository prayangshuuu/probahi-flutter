import 'package:flutter/material.dart';

import '../core/app_colors.dart';
import '../models/course.dart';

/// Mirrors `templates/cotton/course.html` — white card, neutral-200
/// border, name + small_description + price row with a chevron.
class CourseCard extends StatelessWidget {
  const CourseCard({super.key, required this.course, required this.onTap});

  final Course course;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.neutral200),
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                course.name,
                style: Theme.of(context).textTheme.titleMedium,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if ((course.smallDescription ?? '').isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  course.smallDescription!,
                  style: Theme.of(context).textTheme.bodyMedium,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    course.formattedPrice,
                    style: TextStyle(
                      fontSize: course.isFree ? 13 : 16,
                      fontWeight: course.isFree ? FontWeight.w500 : FontWeight.w600,
                      color: course.isFree
                          ? AppColors.neutral600
                          : AppColors.neutral900,
                    ),
                  ),
                  const Icon(
                    Icons.arrow_forward_rounded,
                    size: 18,
                    color: AppColors.neutral400,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
