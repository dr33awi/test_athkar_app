// lib/features/prayers/domain/services/qibla_service.dart

/// Qibla service interface
abstract class QiblaService {
  /// Get Qibla direction in degrees from North
  Future<double> getQiblaDirection({
    required double latitude,
    required double longitude,
  });
  
  /// Get compass heading stream
  Stream<double> getCompassStream();
  
  /// Check if device has compass sensor
  Future<bool> hasCompassSensor();
  
  /// Check if location permission is granted
  Future<bool> hasLocationPermission();
  
  /// Request location permission
  Future<bool> requestLocationPermission();
  
  /// Get current location
  Future<QiblaLocation?> getCurrentLocation();
  
  /// Calculate distance to Kaaba in kilometers
  double calculateDistanceToKaaba({
    required double latitude,
    required double longitude,
  });
  
  /// Dispose resources
  void dispose();
}

/// Location data for Qibla calculation
class QiblaLocation {
  final double latitude;
  final double longitude;
  final double? accuracy;
  final DateTime timestamp;
  
  QiblaLocation({
    required this.latitude,
    required this.longitude,
    this.accuracy,
    required this.timestamp,
  });
}