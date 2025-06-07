// lib/features/prayer_times/presentation/widgets/prayer_time_item.dart
import 'package:flutter/material.dart';
import '../../../../app/themes/app_theme.dart';
import '../../domain/models/prayer_time_model.dart';

class PrayerTimeItem extends StatelessWidget {
  final PrayerTimeModel prayer;
  final bool isNext;
  final VoidCallback onTap;
  final VoidCallback onNotificationToggle;

  const PrayerTimeItem({
    super.key,
    required this.prayer,
    required this.isNext,
    required this.onTap,
    required this.onNotificationToggle,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    
    return Container(
      decoration: BoxDecoration(
        color: isNext
            ? prayer.gradientColors[0].withOpacity(0.1)
            : context.cardColor,
        borderRadius: BorderRadius.circular(ThemeConstants.radiusLg),
        border: Border.all(
          color: isNext
              ? prayer.gradientColors[0].withOpacity(0.3)
              : context.dividerColor.withOpacity(0.2),
          width: isNext ? 2 : 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(ThemeConstants.radiusLg),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(ThemeConstants.radiusLg),
          child: Padding(
            padding: const EdgeInsets.all(ThemeConstants.space4),
            child: Row(
              children: [
                // الأيقونة
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: prayer.gradientColors,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(ThemeConstants.radiusMd),
                  ),
                  child: Icon(
                    prayer.icon,
                    color: Colors.white,
                    size: ThemeConstants.iconMd,
                  ),
                ),
                
                ThemeConstants.space3.w,
                
                // الاسم والحالة
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        prayer.arabicName,
                        style: context.titleMedium?.copyWith(
                          fontWeight: isNext ? ThemeConstants.bold : ThemeConstants.semiBold,
                          color: isNext ? prayer.gradientColors[0] : null,
                        ),
                      ),
                      if (prayer.isPassed && !isNext)
                        Text(
                          'انتهى',
                          style: context.labelSmall?.copyWith(
                            color: context.textSecondaryColor,
                          ),
                        )
                      else if (isNext)
                        Text(
                          'القادمة',
                          style: context.labelSmall?.copyWith(
                            color: prayer.gradientColors[0],
                            fontWeight: ThemeConstants.semiBold,
                          ),
                        ),
                    ],
                  ),
                ),
                
                // الوقت
                Text(
                  prayer.time,
                  style: context.headlineSmall?.copyWith(
                    fontWeight: ThemeConstants.semiBold,
                    color: isNext ? prayer.gradientColors[0] : null,
                  ),
                ),
                
                ThemeConstants.space2.w,
                
                // زر الإشعارات
                IconButton(
                  onPressed: onNotificationToggle,
                  icon: Icon(
                    prayer.isNotificationEnabled
                        ? Icons.notifications_active
                        : Icons.notifications_off_outlined,
                    color: prayer.isNotificationEnabled
                        ? prayer.gradientColors[0]
                        : context.textSecondaryColor.withOpacity(0.5),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}