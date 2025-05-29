// lib/core/error/exceptions.dart

/// Base application exception
class AppException implements Exception {
  final String message;
  final String? code;

  AppException(this.message, {this.code});

  @override
  String toString() => 'AppException: $message${code != null ? ' (Code: $code)' : ''}';
}

/// Data loading exception
class DataLoadException extends AppException {
  DataLoadException(super.message, {super.code});
}

/// Data update exception
class DataUpdateException extends AppException {
  DataUpdateException(super.message, {super.code});
}

/// Data not found exception
class DataNotFoundException extends AppException {
  DataNotFoundException(super.message, {super.code});
}

/// Network connection exception
class NetworkException extends AppException {
  NetworkException(super.message, {super.code});
}

/// Location service exception
class LocationException extends AppException {
  LocationException(super.message, {super.code});
}

/// Notification service exception
class NotificationException extends AppException {
  NotificationException(super.message, {super.code});
}

/// Storage service exception
class StorageException extends AppException {
  StorageException(super.message, {super.code});
}

/// Permission exception
class PermissionException extends AppException {
  PermissionException(super.message, {super.code});
}

/// Validation exception
class ValidationException extends AppException {
  final String? field;
  
  ValidationException(super.message, {this.field, super.code});
}

/// Configuration exception
class ConfigurationException extends AppException {
  ConfigurationException(super.message, {super.code});
}

/// Service unavailable exception
class ServiceUnavailableException extends AppException {
  ServiceUnavailableException(super.message, {super.code});
}

/// Timeout exception
class TimeoutException extends AppException {
  TimeoutException(super.message, {super.code});
}

/// Authentication exception
class AuthenticationException extends AppException {
  AuthenticationException(super.message, {super.code});
}

/// Authorization exception
class AuthorizationException extends AppException {
  AuthorizationException(super.message, {super.code});
}