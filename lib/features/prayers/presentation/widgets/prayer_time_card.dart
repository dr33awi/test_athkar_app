// lib/features/prayers/presentation/widgets/prayer_time_card.dart

import 'package:athkar_app/features/home/widgets/prayer_times_card.dart';
import 'package:flutter/material.dart';
import '../../../../app/themes/app_theme.dart';
import '../../domain/entities/prayer_time.dart';

class PrayerTimeCard extends StatelessWidget {
  final PrayerTime prayerTime;
  final bool isNext;
  final bool isCurrent;
  final VoidCallback? onTap;
  final VoidCallback? onNotificationToggle;
  
  const PrayerTimeCard({
    Key? key,
    required this.prayerTime,
    this.isNext = false,
    this.isCurrent = false,
    this.onTap,
    this.onNotificationToggle,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return AppCard(
      type: CardType.normal,
      style: _getCardStyle(),
      primaryColor: _getCardColor(),
      gradientColors: _getGradientColors(),
      icon: _getPrayerIcon(),
      title: prayerTime.name,
      subtitle: prayerTime.formattedTime,
      badge: _getBadge(),
      badgeColor: _getBadgeColor(),
      onTap: onTap,
      trailing: _buildTrailing(context),
      actions: _buildActions(),
    );
  }
  
  CardStyle _getCardStyle() {
    if (isNext || isCurrent) {
      return CardStyle.gradient;
    }
    return CardStyle.normal;
  }
  
  Color _getCardColor() {
    return PrayerConstants.prayerColors[prayerTime.id] ?? 
           ThemeConstants.primary;
  }
  
  List<Color>? _getGradientColors() {
    if (!isNext && !isCurrent) return null;
    
    final baseColor = _getCardColor();
    return [baseColor, baseColor.darken(0.2)];
  }
  
  String? _getBadge() {
    if (isCurrent) return 'الحالية';
    if (isNext) return 'التالية';
    return null;
  }
  
  Color _getBadgeColor() {
    if (isCurrent) return ThemeConstants.success;
    if (isNext) return ThemeConstants.info;
    return ThemeConstants.primary;
  }
  
  IconData _getPrayerIcon() {
    return PrayerConstants.prayerIcons[prayerTime.id] ?? 
           Icons.access_time;
  }
  
  Widget? _buildTrailing(BuildContext context) {
    if (isNext) {
      return PrayerCountdownChip(
        targetTime: prayerTime.time,
      );
    }
    
    if (prayerTime.isNotificationEnabled) {
      return Icon(
        Icons.notifications_active,
        color: context.primaryColor,
        size: ThemeConstants.iconSm,
      );
    }
    
    return null;
  }
  
  List<CardAction>? _buildActions() {
    if (onNotificationToggle == null) return null;
    
    return [
      CardAction(
        icon: prayerTime.isNotificationEnabled
            ? Icons.notifications_off
            : Icons.notifications_active,
        label: prayerTime.isNotificationEnabled
            ? 'إيقاف التنبيه'
            : 'تفعيل التنبيه',
        onPressed: onNotificationToggle!,
      ),
    ];
  }
}