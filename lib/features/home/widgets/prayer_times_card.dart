// lib/features/home/presentation/widgets/prayer_times_card.dart
// تصميم مبتكر وعصري - Timeline Style

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;
import '../../../../app/themes/app_theme.dart';
import '../../../../app/routes/app_router.dart';

class PrayerTimesCard extends StatefulWidget {
  const PrayerTimesCard({super.key});

  @override
  State<PrayerTimesCard> createState() => _PrayerTimesCardState();
}

class _PrayerTimesCardState extends State<PrayerTimesCard> {
  // بيانات أوقات الصلاة مع النسب المئوية لليوم
  final List<PrayerTime> _prayerTimes = [
    PrayerTime(
      name: 'الفجر',
      time: '04:35',
      timeInMinutes: 275, // 4:35 AM
      icon: Icons.dark_mode,
      gradient: [Color(0xFF1A237E), Color(0xFF3949AB)],
      isPassed: true,
    ),
    PrayerTime(
      name: 'الظهر',
      time: '12:15',
      timeInMinutes: 735, // 12:15 PM
      icon: Icons.light_mode,
      gradient: [Color(0xFFFF6F00), Color(0xFFFFCA28)],
      isPassed: true,
    ),
    PrayerTime(
      name: 'العصر',
      time: '15:45',
      timeInMinutes: 945, // 3:45 PM
      icon: Icons.wb_cloudy,
      gradient: [Color(0xFF00897B), Color(0xFF4DB6AC)],
      isPassed: false,
      isNext: true,
    ),
    PrayerTime(
      name: 'المغرب',
      time: '18:30',
      timeInMinutes: 1110, // 6:30 PM
      icon: Icons.wb_twilight,
      gradient: [Color(0xFFE65100), Color(0xFFFF6E40)],
      isPassed: false,
    ),
    PrayerTime(
      name: 'العشاء',
      time: '20:00',
      timeInMinutes: 1200, // 8:00 PM
      icon: Icons.bedtime,
      gradient: [Color(0xFF4A148C), Color(0xFF7B1FA2)],
      isPassed: false,
    ),
  ];

  void _navigateToPrayerTimes() {
    HapticFeedback.lightImpact();
    Navigator.pushNamed(context, AppRouter.prayerTimes);
  }

  // حساب الوقت المتبقي للصلاة القادمة
  String _getTimeRemaining() {
    final now = DateTime.now();
    final currentMinutes = now.hour * 60 + now.minute;
    
    final nextPrayer = _prayerTimes.firstWhere(
      (prayer) => prayer.isNext,
      orElse: () => _prayerTimes.first,
    );
    
    var remainingMinutes = nextPrayer.timeInMinutes - currentMinutes;
    if (remainingMinutes < 0) remainingMinutes += 1440; // إضافة يوم كامل
    
    final hours = remainingMinutes ~/ 60;
    final minutes = remainingMinutes % 60;
    
    if (hours > 0) {
      return '$hours س $minutes د';
    } else {
      return '$minutes دقيقة';
    }
  }

  // حساب نسبة التقدم في اليوم
  double _getDayProgress() {
    final now = DateTime.now();
    final currentMinutes = now.hour * 60 + now.minute;
    return currentMinutes / 1440; // 1440 دقيقة في اليوم
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final nextPrayer = _prayerTimes.firstWhere(
      (prayer) => prayer.isNext,
      orElse: () => _prayerTimes.first,
    );

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: ThemeConstants.space4),
      height: 300, // زيادة الارتفاع قليلاً
      child: Stack(
        children: [
          // الخلفية المتدرجة
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  nextPrayer.gradient[0].withOpacity(isDark ? 0.3 : 0.2),
                  nextPrayer.gradient[1].withOpacity(isDark ? 0.2 : 0.1),
                ],
              ),
            ),
          ),
          
          // النمط الدائري في الخلفية
          Positioned(
            right: -80,
            top: -80,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Colors.white.withOpacity(0.1),
                    Colors.white.withOpacity(0.0),
                  ],
                ),
              ),
            ),
          ),
          
          // المحتوى الرئيسي
          Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(28),
            child: InkWell(
              onTap: _navigateToPrayerTimes,
              borderRadius: BorderRadius.circular(28),
              child: Container(
                padding: const EdgeInsets.all(ThemeConstants.space4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // الهيدر
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.mosque,
                                    color: isDark ? Colors.white : nextPrayer.gradient[0],
                                    size: 20,
                                  ),
                                  ThemeConstants.space2.w,
                                  Flexible(
                                    child: Text(
                                      'مواقيت الصلاة',
                                      style: context.titleMedium?.copyWith(
                                        fontWeight: ThemeConstants.bold,
                                        color: isDark ? Colors.white : nextPrayer.gradient[0],
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              ThemeConstants.space1.h,
                              Text(
                                'الجمعة، ٢٤ رجب',
                                style: context.labelSmall?.copyWith(
                                  color: (isDark ? Colors.white : nextPrayer.gradient[0])
                                      .withOpacity(0.7),
                                ),
                              ),
                            ],
                          ),
                        ),
                        // ساعة رقمية
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: ThemeConstants.space2,
                            vertical: ThemeConstants.space1,
                          ),
                          decoration: BoxDecoration(
                            color: (isDark ? Colors.white : Colors.black)
                                .withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.access_time,
                                size: 14,
                                color: isDark ? Colors.white : nextPrayer.gradient[0],
                              ),
                              ThemeConstants.space1.w,
                              Text(
                                '${DateTime.now().hour.toString().padLeft(2, '0')}:${DateTime.now().minute.toString().padLeft(2, '0')}',
                                style: context.labelMedium?.copyWith(
                                  fontWeight: ThemeConstants.bold,
                                  color: isDark ? Colors.white : nextPrayer.gradient[0],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    
                    ThemeConstants.space3.h,
                    
                    // بطاقة الصلاة القادمة
                    Container(
                      padding: const EdgeInsets.all(ThemeConstants.space3),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: nextPrayer.gradient,
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: nextPrayer.gradient[0].withOpacity(0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          // الأيقونة
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Icon(
                              nextPrayer.icon,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                          
                          ThemeConstants.space3.w,
                          
                          // المعلومات
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'الصلاة القادمة',
                                  style: context.labelSmall?.copyWith(
                                    color: Colors.white.withOpacity(0.8),
                                    fontSize: 11,
                                  ),
                                ),
                                Text(
                                  nextPrayer.name,
                                  style: context.titleMedium?.copyWith(
                                    fontWeight: ThemeConstants.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          
                          // الوقت
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                nextPrayer.time,
                                style: context.headlineSmall?.copyWith(
                                  fontWeight: ThemeConstants.bold,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                'بعد ${_getTimeRemaining()}',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.white.withOpacity(0.8),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    
                    ThemeConstants.space3.h,
                    
                    // Timeline للصلوات - محدث
                    Expanded(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final availableWidth = constraints.maxWidth;
                          final progressWidth = availableWidth * _getDayProgress();
                          
                          return Stack(
                            alignment: Alignment.center,
                            clipBehavior: Clip.none,
                            children: [
                              // خط الزمن
                              Positioned(
                                top: 16,
                                left: 0,
                                right: 0,
                                child: Container(
                                  height: 2,
                                  decoration: BoxDecoration(
                                    color: context.dividerColor.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(1),
                                  ),
                                ),
                              ),
                              
                              // مؤشر التقدم
                              Positioned(
                                top: 16,
                                left: 0,
                                child: Container(
                                  width: progressWidth.clamp(0.0, availableWidth),
                                  height: 2,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        nextPrayer.gradient[0],
                                        nextPrayer.gradient[1],
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(1),
                                  ),
                                ),
                              ),
                              
                              // الصلوات
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 10),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: _prayerTimes
                                      .map((prayer) => _buildTimelineItem(
                                            context,
                                            prayer,
                                          ))
                                      .toList(),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineItem(BuildContext context, PrayerTime prayer) {
    final isDark = context.isDarkMode;
    final isActive = prayer.isNext;
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // النقطة على الخط
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: prayer.isPassed || isActive
                ? LinearGradient(
                    colors: prayer.gradient,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color: !prayer.isPassed && !isActive
                ? context.dividerColor.withOpacity(0.3)
                : null,
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: prayer.gradient[0].withOpacity(0.5),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Icon(
            prayer.isPassed && !isActive
                ? Icons.check
                : prayer.icon,
            color: prayer.isPassed || isActive
                ? Colors.white
                : context.textSecondaryColor.withOpacity(0.5),
            size: 16,
          ),
        ),
        
        ThemeConstants.space1.h,
        
        // اسم الصلاة
        Text(
          prayer.name,
          style: TextStyle(
            fontSize: 11,
            color: isActive
                ? (isDark ? Colors.white : prayer.gradient[0])
                : prayer.isPassed
                    ? context.textSecondaryColor
                    : context.textSecondaryColor.withOpacity(0.5),
            fontWeight: isActive ? ThemeConstants.semiBold : null,
          ),
          textAlign: TextAlign.center,
          overflow: TextOverflow.visible,
        ),
        
        // الوقت
        Text(
          prayer.time,
          style: TextStyle(
            fontSize: 10,
            color: isActive
                ? prayer.gradient[0]
                : prayer.isPassed
                    ? context.textSecondaryColor.withOpacity(0.7)
                    : context.textSecondaryColor.withOpacity(0.5),
            fontWeight: ThemeConstants.bold,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class PrayerTime {
  final String name;
  final String time;
  final int timeInMinutes;
  final IconData icon;
  final List<Color> gradient;
  final bool isPassed;
  final bool isNext;

  PrayerTime({
    required this.name,
    required this.time,
    required this.timeInMinutes,
    required this.icon,
    required this.gradient,
    this.isPassed = false,
    this.isNext = false,
  });
}