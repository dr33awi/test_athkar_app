// lib/features/prayers/infrastructure/services/qibla_service_impl.dart

import 'dart:async';
import 'dart:math' as math;
import 'package:flutter_compass/flutter_compass.dart';
import 'package:geolocator/geolocator.dart';
import '../../core/infrastructure/services/logging/logger_service.dart';
import '../../core/infrastructure/services/permissions/permission_service.dart';
import 'qibla_service.dart';

/// Implementation of Qibla service
class QiblaServiceImpl implements QiblaService {
  final LoggerService? _logger;
  final PermissionService _permissionService;
  
  // Kaaba coordinates
  static const double _kaabaLatitude = 21.4225;
  static const double _kaabaLongitude = 39.8262;
  
  StreamSubscription<CompassEvent>? _compassSubscription;
  final StreamController<double> _compassController = StreamController<double>.broadcast();
  
  QiblaServiceImpl({
    LoggerService? logger,
    required PermissionService permissionService,
  })  : _logger = logger,
        _permissionService = permissionService;
  
  @override
  Future<double> getQiblaDirection({
    required double latitude,
    required double longitude,
  }) async {
    try {
      _logger?.debug(
        message: 'Calculating Qibla direction',
        data: {
          'latitude': latitude,
          'longitude': longitude,
        },
      );
      
      // Convert to radians
      final lat1 = latitude * (math.pi / 180);
      final lon1 = longitude * (math.pi / 180);
      final lat2 = _kaabaLatitude * (math.pi / 180);
      final lon2 = _kaabaLongitude * (math.pi / 180);
      
      // Calculate bearing
      final dLon = lon2 - lon1;
      final y = math.sin(dLon) * math.cos(lat2);
      final x = math.cos(lat1) * math.sin(lat2) - 
                math.sin(lat1) * math.cos(lat2) * math.cos(dLon);
      
      // Convert to degrees
      final bearing = math.atan2(y, x) * (180 / math.pi);
      final qiblaDirection = (bearing + 360) % 360;
      
      _logger?.info(
        message: 'Qibla direction calculated',
        data: {'direction': qiblaDirection},
      );
      
      return qiblaDirection;
    } catch (e, s) {
      _logger?.error(
        message: 'Error calculating Qibla direction',
        error: e,
        stackTrace: s,
      );
      rethrow;
    }
  }
  
  @override
  Stream<double> getCompassStream() {
    _compassSubscription?.cancel();
    
    _compassSubscription = FlutterCompass.events?.listen(
      (event) {
        final heading = event.heading;
        if (heading != null) {
          _compassController.add(heading);
        }
      },
      onError: (error) {
        _logger?.error(
          message: 'Compass stream error',
          error: error,
        );
      },
    );
    
    return _compassController.stream;
  }
  
  @override
  Future<bool> hasCompassSensor() async {
    try {
      final events = await FlutterCompass.events?.take(1).toList();
      return events != null && events.isNotEmpty;
    } catch (e) {
      _logger?.warning(
        message: 'Error checking compass sensor',
        data: {'error': e.toString()},
      );
      return false;
    }
  }
  
  @override
  Future<bool> hasLocationPermission() async {
    final status = await _permissionService.checkPermissionStatus(
      AppPermissionType.location,
    );
    return status == AppPermissionStatus.granted;
  }
  
  @override
  Future<bool> requestLocationPermission() async {
    final status = await _permissionService.requestPermission(
      AppPermissionType.location,
    );
    return status == AppPermissionStatus.granted;
  }
  
  @override
  Future<QiblaLocation?> getCurrentLocation() async {
    try {
      final hasPermission = await hasLocationPermission();
      if (!hasPermission) {
        _logger?.warning(message: 'Location permission not granted');
        return null;
      }
      
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      
      return QiblaLocation(
        latitude: position.latitude,
        longitude: position.longitude,
        accuracy: position.accuracy,
        timestamp: position.timestamp ?? DateTime.now(),
      );
    } catch (e) {
      _logger?.error(
        message: 'Error getting current location',
        error: e,
      );
      return null;
    }
  }
  
  @override
  double calculateDistanceToKaaba({
    required double latitude,
    required double longitude,
  }) {
    return Geolocator.distanceBetween(
      latitude,
      longitude,
      _kaabaLatitude,
      _kaabaLongitude,
    ) / 1000; // Convert to kilometers
  }
  
  @override
  void dispose() {
    _logger?.debug(message: 'Disposing QiblaService');
    _compassSubscription?.cancel();
    _compassController.close();
  }
}