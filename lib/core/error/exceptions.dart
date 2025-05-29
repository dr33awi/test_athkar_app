// lib/core/error/exceptions.dart
/// استثناء حدوث خطأ عام
class AppException implements Exception {
  final String message;

  AppException(this.message);

  @override
  String toString() => message;
}

/// استثناء فشل تحميل البيانات
class DataLoadException extends AppException {
  DataLoadException(super.message); // <--- تم التعديل: استخدام super parameters
}

/// استثناء فشل تحديث البيانات
class DataUpdateException extends AppException {
  DataUpdateException(super.message); // <--- تم التعديل: استخدام super parameters
}

/// استثناء البيانات غير موجودة
class DataNotFoundException extends AppException {
  DataNotFoundException(super.message); // <--- تم التعديل: استخدام super parameters
}

/// استثناء فشل تحديد الموقع
class LocationException extends AppException {
  LocationException(super.message); // <--- تم التعديل: استخدام super parameters
}

/// استثناء فشل خدمة الإشعارات
class NotificationException extends AppException {
  NotificationException(super.message); // <--- تم التعديل: استخدام super parameters
}

/// استثناء فشل حساب مواقيت الصلاة
class PrayerTimesException extends AppException {
  PrayerTimesException(super.message); // <--- تم التعديل: استخدام super parameters
}

/// استثناء فشل حساب اتجاه القبلة
class QiblaException extends AppException {
  QiblaException(super.message); // <--- تم التعديل: استخدام super parameters
}

/// استثناء فشل خدمة التخزين المحلي
class StorageException extends AppException {
  StorageException(super.message); // <--- تم التعديل: استخدام super parameters
}