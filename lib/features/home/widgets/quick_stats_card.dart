// lib/features/home/presentation/widgets/quick_stats_card.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../app/themes/app_theme.dart';

class QuickStatsCard extends StatelessWidget {
  final int dailyProgress;
  final String? lastReadTime;
  final Function(String) onStatTap;

  const QuickStatsCard({
    super.key,
    required this.dailyProgress,
    required this.lastReadTime,
    required this.onStatTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: ThemeConstants.space4),
      child: Row(
        children: [
          // Daily progress
          Expanded(
            child: _buildStatItem(
              context: context,
              icon: Icons.check_circle_outline,
              value: '$dailyProgress%',
              label: 'إنجاز اليوم',
              color: ThemeConstants.success,
              onTap: () => onStatTap('daily_progress'),
            ),
          ),
          
          ThemeConstants.space3.w,
          
          // Favorites count
          Expanded(
            child: _buildStatItem(
              context: context,
              icon: Icons.favorite_outline,
              value: '24',
              label: 'المفضلة',
              color: ThemeConstants.error,
              onTap: () => onStatTap('favorites'),
            ),
          ),
          
          ThemeConstants.space3.w,
          
          // Streak
          Expanded(
            child: _buildStatItem(
              context: context,
              icon: Icons.local_fire_department_outlined,
              value: '7',
              label: 'أيام متتالية',
              color: ThemeConstants.warning,
              onTap: () => onStatTap('achievements'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required BuildContext context,
    required IconData icon,
    required String value,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return AppCard.stat(
      title: label,
      value: value,
      icon: icon,
      color: color,
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      progress: label == 'إنجاز اليوم' ? dailyProgress / 100 : null,
    );
  }
}