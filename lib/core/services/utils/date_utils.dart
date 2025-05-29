// lib/core/services/utils/date_utils.dart
import 'package:intl/intl.dart';
import 'package:hijri/hijri_calendar.dart';

class AppDateUtils {
  /// تنسيق التاريخ الميلادي بالتنسيق المحدد
  static String formatDate(DateTime date, {String format = 'yyyy-MM-dd'}) {
    final dateFormat = DateFormat(format);
    return dateFormat.format(date);
  }

  /// تنسيق الوقت بتنسيق 12 ساعة (مثال: 10:30 AM)
  static String formatTime12(DateTime dateTime) {
    final timeFormat = DateFormat.jm(); // Uses locale-specific time format (AM/PM)
    return timeFormat.format(dateTime);
  }

  /// تنسيق الوقت بتنسيق 24 ساعة (مثال: 22:30)
  static String formatTime24(DateTime dateTime) {
    final timeFormat = DateFormat.Hm(); // HH:mm
    return timeFormat.format(dateTime);
  }

  /// تحويل التاريخ الميلادي إلى هجري
  static HijriCalendar convertToHijri(DateTime gregorianDate) {
    return HijriCalendar.fromDate(gregorianDate);
  }

  /// تنسيق التاريخ الهجري بالتنسيق المحدد
  static String formatHijriDate(
    HijriCalendar hijriDate, {
    String format = 'dd MMMM yyyy', // Adjusted default format for clarity
    String locale = 'ar',
  }) {
    // الشهور الهجرية بالعربية
    const List<String> hijriMonthsAr = [
      'محرم', 'صفر', 'ربيع الأول', 'ربيع الثاني',
      'جمادى الأولى', 'جمادى الآخرة', 'رجب', 'شعبان',
      'رمضان', 'شوال', 'ذو القعدة', 'ذو الحجة'
    ];

    // الشهور الهجرية بالإنجليزية
    const List<String> hijriMonthsEn = [
      'Muharram', 'Safar', 'Rabi\' al-Awwal', 'Rabi\' al-Thani',
      'Jumada al-Awwal', 'Jumada al-Thani', 'Rajab', 'Sha\'ban',
      'Ramadan', 'Shawwal', 'Dhu al-Qi\'dah', 'Dhu al-Hijjah'
    ];

    String result = format;

    // استبدال السنة
    result = result.replaceAll('yyyy', hijriDate.hYear.toString()); // <--- تم التعديل
    result = result.replaceAll('yy', hijriDate.hYear.toString().substring(2)); // <--- تم التعديل

    // استبدال الشهر
    if (result.contains('MMMM')) {
      result = result.replaceAll(
        'MMMM',
        locale == 'ar' ? hijriMonthsAr[hijriDate.hMonth - 1] : hijriMonthsEn[hijriDate.hMonth - 1], // <--- تم التعديل
      );
    } else if (result.contains('MMM')) {
      result = result.replaceAll(
        'MMM',
        locale == 'ar'
            ? hijriMonthsAr[hijriDate.hMonth - 1].split(' ')[0] // <--- تم التعديل
            : hijriMonthsEn[hijriDate.hMonth - 1].substring(0, 3),
      );
    } else if (result.contains('MM')) {
      result = result.replaceAll(
        'MM',
        hijriDate.hMonth.toString().padLeft(2, '0'), // <--- تم التعديل
      );
    } else if (result.contains('M')) {
      result = result.replaceAll('M', hijriDate.hMonth.toString()); // <--- تم التعديل
    }

    // استبدال اليوم
    result = result.replaceAll('dd', hijriDate.hDay.toString().padLeft(2, '0')); // <--- تم التعديل
    result = result.replaceAll('d', hijriDate.hDay.toString()); // <--- تم التعديل

    return result;
  }

  /// حساب المدة المتبقية حتى تاريخ محدد
  static String getRemainingTime(DateTime targetTime) {
    final now = DateTime.now();
    final difference = targetTime.difference(now);

    if (difference.isNegative) {
      return 'انتهى الوقت';
    }

    final days = difference.inDays;
    final hours = difference.inHours % 24;
    final minutes = difference.inMinutes % 60;
    final seconds = difference.inSeconds % 60;

    if (days > 0) {
      return '$days يوم، $hours ساعة';
    } else if (hours > 0) {
      return '$hours ساعة، $minutes دقيقة';
    } else if (minutes > 0) {
      return '$minutes دقيقة، $seconds ثانية';
    } else if (seconds > 0) {
      return '$seconds ثانية';
    } else {
      return 'الآن'; // Handle case where difference is less than a second
    }
  }
}