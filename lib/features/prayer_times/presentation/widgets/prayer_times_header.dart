// lib/features/prayer_times/presentation/widgets/prayer_times_header.dart
import 'package:flutter/material.dart';
import '../../../../app/themes/app_theme.dart';

class PrayerTimesHeader extends StatelessWidget {
  final VoidCallback onSettingsTap;
  final VoidCallback onLocationTap;

  const PrayerTimesHeader({
    super.key,
    required this.onSettingsTap,
    required this.onLocationTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(ThemeConstants.space4),
      child: Column(
        children: [
          // شريط العنوان
          Row(
            children: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back_ios),
              ),
              
              Expanded(
                child: Text(
                  'مواقيت الصلاة',
                  style: context.headlineSmall?.copyWith(
                    fontWeight: ThemeConstants.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              
              IconButton(
                onPressed: onSettingsTap,
                icon: const Icon(Icons.settings_outlined),
              ),
            ],
          ),
          
          ThemeConstants.space3.h,
          
          // معلومات الموقع
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: ThemeConstants.space4,
              vertical: ThemeConstants.space3,
            ),
            decoration: BoxDecoration(
              color: context.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(ThemeConstants.radiusMd),
              border: Border.all(
                color: context.primaryColor.withOpacity(0.2),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.location_on,
                  color: context.primaryColor,
                  size: ThemeConstants.iconMd,
                ),
                
                ThemeConstants.space2.w,
                
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'الرياض، المملكة العربية السعودية',
                        style: context.titleSmall?.copyWith(
                          fontWeight: ThemeConstants.semiBold,
                        ),
                      ),
                      Text(
                        'آخر تحديث: اليوم ${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}',
                        style: context.labelSmall?.copyWith(
                          color: context.textSecondaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
                
                TextButton.icon(
                  onPressed: onLocationTap,
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text('تحديث'),
                  style: TextButton.styleFrom(
                    foregroundColor: context.primaryColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
