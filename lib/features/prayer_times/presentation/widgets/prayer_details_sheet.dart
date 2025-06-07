// lib/features/prayer_times/presentation/widgets/prayer_details_sheet.dart
import 'package:flutter/material.dart';
import '../../../../app/themes/app_theme.dart';
import '../../domain/models/prayer_time_model.dart';

class PrayerDetailsSheet extends StatefulWidget {
  final PrayerTimeModel prayer;
  final Function(bool enabled, int minutesBefore) onSettingsChanged;

  const PrayerDetailsSheet({
    super.key,
    required this.prayer,
    required this.onSettingsChanged,
  });

  @override
  State<PrayerDetailsSheet> createState() => _PrayerDetailsSheetState();
}

class _PrayerDetailsSheetState extends State<PrayerDetailsSheet> {
  late bool _notificationEnabled;
  late int _minutesBefore;

  @override
  void initState() {
    super.initState();
    _notificationEnabled = widget.prayer.isNotificationEnabled;
    _minutesBefore = widget.prayer.notificationMinutesBefore;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: BoxDecoration(
        color: context.backgroundColor,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(ThemeConstants.radiusXl),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // المقبض
          Container(
            margin: const EdgeInsets.only(top: ThemeConstants.space2),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: context.dividerColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // الهيدر
          Padding(
            padding: const EdgeInsets.all(ThemeConstants.space4),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: widget.prayer.gradientColors,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(ThemeConstants.radiusLg),
                  ),
                  child: Icon(
                    widget.prayer.icon,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
                
                ThemeConstants.space3.w,
                
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.prayer.arabicName,
                        style: context.headlineSmall?.copyWith(
                          fontWeight: ThemeConstants.bold,
                        ),
                      ),
                      Text(
                        'الوقت: ${widget.prayer.time}',
                        style: context.bodyMedium?.copyWith(
                          color: context.textSecondaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          const Divider(),
          
          // إعدادات الإشعارات
          Padding(
            padding: const EdgeInsets.all(ThemeConstants.space4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'إعدادات التنبيه',
                  style: context.titleMedium?.copyWith(
                    fontWeight: ThemeConstants.semiBold,
                  ),
                ),
                
                ThemeConstants.space3.h,
                
                // تفعيل الإشعارات
                SwitchListTile(
                  value: _notificationEnabled,
                  onChanged: (value) {
                    setState(() {
                      _notificationEnabled = value;
                    });
                  },
                  title: const Text('تفعيل التنبيه'),
                  subtitle: const Text('سيتم تنبيهك عند دخول وقت الصلاة'),
                  contentPadding: EdgeInsets.zero,
                ),
                
                // وقت التنبيه المسبق
                if (_notificationEnabled) ...[
                  ThemeConstants.space3.h,
                  
                  Text(
                    'التنبيه المسبق',
                    style: context.titleSmall?.copyWith(
                      fontWeight: ThemeConstants.semiBold,
                    ),
                  ),
                  
                  ThemeConstants.space2.h,
                  
                  Wrap(
                    spacing: ThemeConstants.space2,
                    children: [0, 5, 10, 15, 30].map((minutes) {
                      final isSelected = _minutesBefore == minutes;
                      return ChoiceChip(
                        label: Text(
                          minutes == 0 ? 'عند الأذان' : '$minutes دقيقة',
                        ),
                        selected: isSelected,
                        onSelected: (selected) {
                          if (selected) {
                            setState(() {
                              _minutesBefore = minutes;
                            });
                          }
                        },
                      );
                    }).toList(),
                  ),
                ],
                
                ThemeConstants.space4.h,
                
                // أزرار الإجراءات
                Row(
                  children: [
                    Expanded(
                      child: AppButton.outline(
                        text: 'إلغاء',
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                    
                    ThemeConstants.space3.w,
                    
                    Expanded(
                      child: AppButton.primary(
                        text: 'حفظ',
                        onPressed: () {
                          widget.onSettingsChanged(_notificationEnabled, _minutesBefore);
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}