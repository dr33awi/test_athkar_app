// lib/features/prayer_times/presentation/widgets/next_prayer_card.dart
import 'package:flutter/material.dart';
import '../../../../app/themes/app_theme.dart';
import '../../domain/models/prayer_time_model.dart';

class NextPrayerCard extends StatelessWidget {
  final PrayerTimeModel prayer;
  final VoidCallback onNotificationToggle;

  const NextPrayerCard({
    super.key,
    required this.prayer,
    required this.onNotificationToggle,
  });

  @override
  Widget build(BuildContext context) {
    final timeRemaining = prayer.timeRemaining;
    final hours = timeRemaining.inHours;
    final minutes = timeRemaining.inMinutes % 60;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: prayer.gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(ThemeConstants.radiusXl),
        boxShadow: [
          BoxShadow(
            color: prayer.gradientColors[0].withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(ThemeConstants.radiusXl),
        child: InkWell(
          onTap: onNotificationToggle,
          borderRadius: BorderRadius.circular(ThemeConstants.radiusXl),
          child: Padding(
            padding: const EdgeInsets.all(ThemeConstants.space5),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'الصلاة القادمة',
                      style: context.labelMedium?.copyWith(
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                    Icon(
                      prayer.isNotificationEnabled
                          ? Icons.notifications_active
                          : Icons.notifications_off,
                      color: Colors.white,
                      size: ThemeConstants.iconMd,
                    ),
                  ],
                ),
                
                ThemeConstants.space4.h,
                
                // الأيقونة والاسم
                Icon(
                  prayer.icon,
                  color: Colors.white,
                  size: 48,
                ),
                
                ThemeConstants.space2.h,
                
                Text(
                  prayer.arabicName,
                  style: context.headlineMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: ThemeConstants.bold,
                  ),
                ),
                
                ThemeConstants.space1.h,
                
                // الوقت
                Text(
                  prayer.time,
                  style: context.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: ThemeConstants.semiBold,
                  ),
                ),
                
                ThemeConstants.space3.h,
                
                // المتبقي
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: ThemeConstants.space4,
                    vertical: ThemeConstants.space2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(ThemeConstants.radiusFull),
                  ),
                  child: Text(
                    hours > 0
                        ? 'بعد $hours ساعة و $minutes دقيقة'
                        : 'بعد $minutes دقيقة',
                    style: context.labelLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: ThemeConstants.semiBold,
                    ),
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