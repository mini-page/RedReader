import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../data/stats_repository.dart';
import '../../../shared/models/reading_stats.dart';

class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsRepo = ref.watch(statsRepositoryProvider);
    final stats = statsRepo.getStats();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final onSurface = isDark ? Colors.white : Colors.black;

    return Scaffold(
      backgroundColor: isDark ? Colors.black : const Color(0xFFF6F6F6),
      appBar: AppBar(
        title: Text('Cognitive Analytics', 
          style: GoogleFonts.lexend(fontWeight: FontWeight.bold, fontSize: 20)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          _buildMainMetric(stats, onSurface),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(child: _buildSmallMetric('Time Saved', '${(stats.totalWordsRead / 250 - stats.totalTimeSeconds / 60).clamp(0, double.infinity).toStringAsFixed(1)}m', LucideIcons.zap, const Color(0xFFFF3B3B), isDark)),
              const SizedBox(width: 16),
              Expanded(child: _buildSmallMetric('Avg Speed', '${stats.averageWpm.toInt()} WPM', LucideIcons.gauge, Colors.blue, isDark)),
            ],
          ),
          const SizedBox(height: 24),
          _buildActivityCard(stats, onSurface, isDark),
          const SizedBox(height: 24),
          _buildStatRow('Total Words', stats.totalWordsRead.toString(), LucideIcons.bookOpen, onSurface),
          _buildStatRow('Sessions', stats.sessionsCount.toString(), LucideIcons.history, onSurface),
          _buildStatRow('Reading Time', '${(stats.totalTimeSeconds / 60).toStringAsFixed(1)} mins', LucideIcons.clock, onSurface),
        ],
      ),
    );
  }

  Widget _buildMainMetric(ReadingStats stats, Color onSurface) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: const Color(0xFFFF3B3B),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(color: const Color(0xFFFF3B3B).withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10))
        ],
      ),
      child: Column(
        children: [
          Text('TOTAL WORDS READ', 
            style: GoogleFonts.lexend(color: Colors.white.withOpacity(0.7), fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
          const SizedBox(height: 8),
          Text(stats.totalWordsRead.toString(), 
            style: GoogleFonts.lexend(color: Colors.white, fontSize: 48, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
            child: Text('Level: Knowledge Seeker', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _buildSmallMetric(String label, String value, IconData icon, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 12),
          Text(value, style: GoogleFonts.lexend(fontSize: 20, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)),
          Text(label, style: TextStyle(color: isDark ? Colors.white38 : Colors.black38, fontSize: 11, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildActivityCard(ReadingStats stats, Color onSurface, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('DAILY ACTIVITY', style: GoogleFonts.lexend(fontSize: 12, fontWeight: FontWeight.bold, color: onSurface.withOpacity(0.3), letterSpacing: 1.2)),
          const SizedBox(height: 20),
          SizedBox(
            height: 100,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(7, (index) {
                // Mocking last 7 days for visual
                final date = DateTime.now().subtract(Duration(days: 6 - index));
                final dateStr = date.toIso8601String().split('T')[0];
                final words = stats.dailyWords[dateStr] ?? 0;
                final heightFactor = (words / 2000).clamp(0.1, 1.0);
                
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 30,
                      height: 70 * heightFactor,
                      decoration: BoxDecoration(
                        color: index == 6 ? const Color(0xFFFF3B3B) : const Color(0xFFFF3B3B).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(dateStr.substring(8), style: TextStyle(color: onSurface.withOpacity(0.3), fontSize: 10)),
                  ],
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value, IconData icon, Color onSurface) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: onSurface.withOpacity(0.05), shape: BoxShape.circle),
            child: Icon(icon, color: onSurface.withOpacity(0.5), size: 18),
          ),
          const SizedBox(width: 16),
          Text(label, style: TextStyle(color: onSurface.withOpacity(0.6), fontWeight: FontWeight.w500)),
          const Spacer(),
          Text(value, style: GoogleFonts.lexend(color: onSurface, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
