// lib/features/home/presentation/widgets/daily_reminder_card.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../app/themes/app_theme.dart';
import '../../../../app/di/service_locator.dart';
import '../../../../core/infrastructure/services/notifications/notification_manager.dart';

class DailyReminderCard extends StatefulWidget {
  const DailyReminderCard({super.key});

  @override
  State<DailyReminderCard> createState() => _DailyReminderCardState();
}

class _DailyReminderCardState extends State<DailyReminderCard> {
  bool _morningEnabled = true;
  bool _eveningEnabled = true;
  bool _isUpdating = false;

  Future<void> _toggleReminder(String type, bool value) async {
    HapticFeedback.lightImpact();
    
    setState(() {
      _isUpdating = true;
      if (type == 'morning') {
        _morningEnabled = value;
      } else {
        _eveningEnabled = value;
      }
    });

    try {
      final notificationManager = NotificationManager.instance;
      
      if (value) {
        // جدولة التذكير
        await notificationManager.scheduleAthkarReminder(
          categoryId: type == 'morning' ? 'morning_athkar' : 'evening_athkar',
          categoryName: type == 'morning' ? 'أذكار الصباح' : 'أذكار المساء',
          time: TimeOfDay(
            hour: type == 'morning' ? 6 : 18,
            minute: 0,
          ),
        );
        
        if (mounted) {
          context.showSuccessSnackBar(
            'تم تفعيل تذكير ${type == 'morning' ? 'أذكار الصباح' : 'أذكار المساء'}',
          );
        }
      } else {
        // إلغاء التذكير
        await notificationManager.cancelAthkarReminder(
          type == 'morning' ? 'morning_athkar' : 'evening_athkar',
        );
        
        if (mounted) {
          context.showInfoSnackBar(
            'تم إيقاف تذكير ${type == 'morning' ? 'أذكار الصباح' : 'أذكار المساء'}',
          );
        }
      }
    } catch (e) {
      if (mounted) {
        context.showErrorSnackBar('حدث خطأ في تحديث التذكير');
      }
    } finally {
      if (mounted) {
        setState(() => _isUpdating = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(ThemeConstants.space4),
      child: AppCard(
        type: CardType.info,
        style: CardStyle.glassmorphism,
        backgroundColor: context.primaryColor.withOpacity(0.05),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(ThemeConstants.space2),
                  decoration: BoxDecoration(
                    color: context.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(ThemeConstants.radiusMd),
                  ),
                  child: Icon(
                    Icons.notifications_active_outlined,
                    color: context.primaryColor,
                    size: ThemeConstants.iconMd,
                  ),
                ),
                ThemeConstants.space3.w,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'التذكيرات اليومية',
                        style: context.titleMedium?.semiBold,
                      ),
                      ThemeConstants.space1.h,
                      Text(
                        'فعّل التذكيرات لتلقي إشعارات الأذكار',
                        style: context.bodySmall?.copyWith(
                          color: context.textSecondaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            ThemeConstants.space4.h,
            
            // Morning reminder
            _buildReminderRow(
              context: context,
              icon: Icons.wb_sunny_outlined,
              title: 'أذكار الصباح',
              subtitle: 'الساعة 6:00 صباحاً',
              value: _morningEnabled,
              onChanged: (value) => _toggleReminder('morning', value),
            ),
            
            ThemeConstants.space3.h,
            
            // Evening reminder
            _buildReminderRow(
              context: context,
              icon: Icons.nights_stay_outlined,
              title: 'أذكار المساء',
              subtitle: 'الساعة 6:00 مساءً',
              value: _eveningEnabled,
              onChanged: (value) => _toggleReminder('evening', value),
            ),
            
            ThemeConstants.space3.h,
            
            // Settings button
            SizedBox(
              width: double.infinity,
              child: AppButton.text(
                text: 'إعدادات التذكيرات المتقدمة',
                onPressed: _isUpdating
                    ? null
                    : () {
                        HapticFeedback.lightImpact();
                        Navigator.pushNamed(context, '/reminder-settings');
                      },
                icon: Icons.settings_outlined,
                size: ButtonSize.small,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReminderRow({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(ThemeConstants.space2),
          decoration: BoxDecoration(
            color: value
                ? context.primaryColor.withOpacity(0.1)
                : context.dividerColor.withOpacity(0.3),
            borderRadius: BorderRadius.circular(ThemeConstants.radiusSm),
          ),
          child: Icon(
            icon,
            color: value ? context.primaryColor : context.textSecondaryColor,
            size: ThemeConstants.iconSm,
          ),
        ),
        ThemeConstants.space3.w,
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: context.bodyLarge?.copyWith(
                  fontWeight: ThemeConstants.medium,
                ),
              ),
              Text(
                subtitle,
                style: context.bodySmall?.copyWith(
                  color: context.textSecondaryColor,
                ),
              ),
            ],
          ),
        ),
        Switch(
          value: value,
          onChanged: _isUpdating ? null : onChanged,
        ),
      ],
    );
  }
}