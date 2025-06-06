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
              progress: dailyProgress / 100,
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
    double? progress,
  }) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(ThemeConstants.radiusLg),
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        borderRadius: BorderRadius.circular(ThemeConstants.radiusLg),
        child: Container(
          padding: const EdgeInsets.all(ThemeConstants.space4),
          decoration: BoxDecoration(
            color: context.cardColor,
            borderRadius: BorderRadius.circular(ThemeConstants.radiusLg),
            border: Border.all(
              color: context.dividerColor.withOpacity(0.5),
              width: ThemeConstants.borderThin,
            ),
            boxShadow: ThemeConstants.shadowSm,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: ThemeConstants.iconMd,
                ),
              ),
              
              ThemeConstants.space3.h,
              
              // Value
              Text(
                value,
                style: context.headlineSmall?.copyWith(
                  color: color,
                  fontWeight: ThemeConstants.bold,
                ),
              ),
              
              ThemeConstants.space1.h,
              
              // Label
              Text(
                label,
                style: context.bodySmall?.copyWith(
                  color: context.textSecondaryColor,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              
              // Progress bar if needed
              if (progress != null) ...[
                ThemeConstants.space3.h,
                ClipRRect(
                  borderRadius: BorderRadius.circular(ThemeConstants.radiusFull),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 4,
                    backgroundColor: context.dividerColor.withOpacity(0.3),
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}