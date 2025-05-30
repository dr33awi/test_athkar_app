// lib/core/infrastructure/services/logging/logger_service.dart

/// Abstract logger service interface
/// Provides logging functionality across the application
abstract class LoggerService {
  /// Log debug information
  /// Used for detailed debugging information
  void debug({required String message, dynamic data});
  
  /// Log general information
  /// Used for general app flow information
  void info({required String message, dynamic data});
  
  /// Log warning messages
  /// Used for potentially harmful situations
  void warning({required String message, dynamic data});
  
  /// Log error messages
  /// Used for error events with optional stack trace
  void error({required String message, dynamic error, StackTrace? stackTrace});
  
  /// Log analytics event
  /// Used for tracking user actions and app events
  void logEvent(String eventName, {Map<String, dynamic>? parameters});
  
  /// Set user property for analytics
  void setUserProperty(String name, String value);
  
  /// Clear all logs (if applicable)
  Future<void> clearLogs();
}