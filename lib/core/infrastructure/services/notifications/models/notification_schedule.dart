// lib/core/infrastructure/services/notifications/models/notification_schedule.dart

/// Schedule types for notifications
enum ScheduleType {
  once,      // One-time notification
  daily,     // Daily at specific time
  weekly,    // Weekly on specific days
  custom,    // Custom dates
  interval,  // Fixed interval
}

/// Time of day for notifications
class NotificationTimeOfDay {
  final int hour;
  final int minute;
  
  NotificationTimeOfDay({
    required this.hour,
    required this.minute,
  }) : assert(hour >= 0 && hour < 24),
       assert(minute >= 0 && minute < 60);
  
  Map<String, dynamic> toJson() => {
    'hour': hour,
    'minute': minute,
  };
  
  factory NotificationTimeOfDay.fromJson(Map<String, dynamic> json) {
    return NotificationTimeOfDay(
      hour: json['hour'] as int,
      minute: json['minute'] as int,
    );
  }
  
  @override
  String toString() => '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
}

/// Notification schedule configuration
class NotificationSchedule {
  final ScheduleType type;
  final DateTime? dateTime;              // For once
  final NotificationTimeOfDay? timeOfDay; // For daily/weekly
  final List<int>? weekDays;             // For weekly (1-7, Monday-Sunday)
  final List<DateTime>? customDates;     // For custom
  final Duration? interval;              // For interval
  final bool respectQuietHours;
  final bool skipIfBatteryLow;
  
  NotificationSchedule({
    required this.type,
    this.dateTime,
    this.timeOfDay,
    this.weekDays,
    this.customDates,
    this.interval,
    this.respectQuietHours = true,
    this.skipIfBatteryLow = true,
  }) {
    // Validate based on type
    switch (type) {
      case ScheduleType.once:
        assert(dateTime != null, 'DateTime required for once schedule');
        break;
      case ScheduleType.daily:
        assert(timeOfDay != null, 'TimeOfDay required for daily schedule');
        break;
      case ScheduleType.weekly:
        assert(timeOfDay != null && weekDays != null && weekDays!.isNotEmpty,
            'TimeOfDay and weekDays required for weekly schedule');
        assert(weekDays!.every((day) => day >= 1 && day <= 7),
            'Week days must be between 1-7');
        break;
      case ScheduleType.custom:
        assert(customDates != null && customDates!.isNotEmpty,
            'Custom dates required for custom schedule');
        break;
      case ScheduleType.interval:
        assert(interval != null, 'Interval required for interval schedule');
        break;
    }
  }
  
  /// Create a one-time schedule
  factory NotificationSchedule.once(DateTime dateTime) {
    return NotificationSchedule(
      type: ScheduleType.once,
      dateTime: dateTime,
    );
  }
  
  /// Create a daily schedule
  factory NotificationSchedule.daily(NotificationTimeOfDay timeOfDay) {
    return NotificationSchedule(
      type: ScheduleType.daily,
      timeOfDay: timeOfDay,
    );
  }
  
  /// Create a weekly schedule
  factory NotificationSchedule.weekly({
    required NotificationTimeOfDay timeOfDay,
    required List<int> weekDays,
  }) {
    return NotificationSchedule(
      type: ScheduleType.weekly,
      timeOfDay: timeOfDay,
      weekDays: weekDays,
    );
  }
  
  /// Create a custom schedule
  factory NotificationSchedule.custom(List<DateTime> dates) {
    return NotificationSchedule(
      type: ScheduleType.custom,
      customDates: dates,
    );
  }
  
  /// Create an interval schedule
  factory NotificationSchedule.interval(Duration interval) {
    return NotificationSchedule(
      type: ScheduleType.interval,
      interval: interval,
    );
  }
  
  /// Get next scheduled time
  DateTime? getNextScheduledTime() {
    final now = DateTime.now();
    
    switch (type) {
      case ScheduleType.once:
        return dateTime != null && dateTime!.isAfter(now) ? dateTime : null;
        
      case ScheduleType.daily:
        if (timeOfDay == null) return null;
        var next = DateTime(
          now.year,
          now.month,
          now.day,
          timeOfDay!.hour,
          timeOfDay!.minute,
        );
        if (next.isBefore(now)) {
          next = next.add(const Duration(days: 1));
        }
        return next;
        
      case ScheduleType.weekly:
        if (timeOfDay == null || weekDays == null || weekDays!.isEmpty) return null;
        
        // Find next occurrence
        final currentWeekday = now.weekday;
        int? nextWeekday;
        int daysToAdd = 7;
        
        // Sort weekdays
        final sortedDays = List<int>.from(weekDays!)..sort();
        
        for (final day in sortedDays) {
          if (day > currentWeekday) {
            nextWeekday = day;
            daysToAdd = day - currentWeekday;
            break;
          } else if (day == currentWeekday) {
            final todayTime = DateTime(
              now.year,
              now.month,
              now.day,
              timeOfDay!.hour,
              timeOfDay!.minute,
            );
            if (todayTime.isAfter(now)) {
              return todayTime;
            }
          }
        }
        
        // If no day found this week, use first day next week
        if (nextWeekday == null && sortedDays.isNotEmpty) {
          nextWeekday = sortedDays.first;
          daysToAdd = 7 - currentWeekday + nextWeekday;
        }
        
        final nextDate = now.add(Duration(days: daysToAdd));
        return DateTime(
          nextDate.year,
          nextDate.month,
          nextDate.day,
          timeOfDay!.hour,
          timeOfDay!.minute,
        );
        
      case ScheduleType.custom:
        if (customDates == null || customDates!.isEmpty) return null;
        
        // Find next future date
        final futureDates = customDates!.where((date) => date.isAfter(now)).toList()
          ..sort();
        return futureDates.isNotEmpty ? futureDates.first : null;
        
      case ScheduleType.interval:
        if (interval == null) return null;
        return now.add(interval!);
    }
  }
  
  /// Check if should skip notification
  bool shouldSkip({
    required bool isQuietHours,
    required bool isBatteryLow,
  }) {
    if (respectQuietHours && isQuietHours) return true;
    if (skipIfBatteryLow && isBatteryLow) return true;
    return false;
  }
  
  Map<String, dynamic> toJson() {
    return {
      'type': type.index,
      'dateTime': dateTime?.toIso8601String(),
      'timeOfDay': timeOfDay?.toJson(),
      'weekDays': weekDays,
      'customDates': customDates?.map((d) => d.toIso8601String()).toList(),
      'interval': interval?.inSeconds,
      'respectQuietHours': respectQuietHours,
      'skipIfBatteryLow': skipIfBatteryLow,
    };
  }
  
  factory NotificationSchedule.fromJson(Map<String, dynamic> json) {
    return NotificationSchedule(
      type: ScheduleType.values[json['type'] as int],
      dateTime: json['dateTime'] != null 
          ? DateTime.parse(json['dateTime'] as String)
          : null,
      timeOfDay: json['timeOfDay'] != null
          ? NotificationTimeOfDay.fromJson(json['timeOfDay'])
          : null,
      weekDays: (json['weekDays'] as List?)?.cast<int>(),
      customDates: (json['customDates'] as List?)
          ?.map((d) => DateTime.parse(d as String))
          .toList(),
      interval: json['interval'] != null
          ? Duration(seconds: json['interval'] as int)
          : null,
      respectQuietHours: json['respectQuietHours'] as bool? ?? true,
      skipIfBatteryLow: json['skipIfBatteryLow'] as bool? ?? true,
    );
  }
}