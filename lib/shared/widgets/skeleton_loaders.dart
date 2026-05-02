import 'package:flutter/material.dart';
import 'package:skeleton_text/skeleton_text.dart';

class SkeletonCard extends StatelessWidget {
  final bool isDark;
  const SkeletonCard({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final color = isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SkeletonAnimation(
            shimmerColor: isDark ? Colors.white10 : Colors.grey[200]!,
            child: Container(
              height: 20,
              width: MediaQuery.of(context).size.width * 0.6,
              decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4)),
            ),
          ),
          const SizedBox(height: 12),
          SkeletonAnimation(
            shimmerColor: isDark ? Colors.white10 : Colors.grey[200]!,
            child: Container(
              height: 14,
              width: double.infinity,
              decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4)),
            ),
          ),
          const SizedBox(height: 8),
          SkeletonAnimation(
            shimmerColor: isDark ? Colors.white10 : Colors.grey[200]!,
            child: Container(
              height: 14,
              width: MediaQuery.of(context).size.width * 0.4,
              decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4)),
            ),
          ),
        ],
      ),
    );
  }
}

class SkeletonList extends StatelessWidget {
  final int count;
  final bool isDark;
  const SkeletonList({super.key, this.count = 5, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: count,
      itemBuilder: (context, index) => SkeletonCard(isDark: isDark),
    );
  }
}
