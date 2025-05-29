// lib/core/services/implementations/qibla_service_impl.dart
import 'dart:async';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:adhan/adhan.dart' as adhan;
import '../../../../features/prayers/qibla_service.dart';
import '../logging/logger_service.dart';
import '../../../../app/di/service_locator.dart';

class QiblaServiceImpl implements QiblaService {
  final LoggerService _logger;

  StreamSubscription<CompassEvent>? _compassEventSubscription;
  StreamController<double>? _qiblaDirectionStreamController;
  StreamController<double>? _compassHeadingStreamController;

  // هذه الحقول تستخدم لتخزين آخر إحداثيات معروفة لحساب زاوية القبلة عند الحاجة
  // إذا كانت _qiblaAngle تُحسب دائمًا من الإحداثيات المُمررة حديثًا، فقد لا تكون هناك حاجة للاحتفاظ بها على مستوى الكلاس
  // ومع ذلك، updateUserLocation تعتمد عليها، وكذلك _calculateQiblaAngle
  double _currentLatitude = 0; // <--- تمت إعادة التسمية من _userLatitude
  double _currentLongitude = 0; // <--- تمت إعادة التسمية من _userLongitude
  double _qiblaAngleFromNorth = 0; // زاوية القبلة بالنسبة للشمال الحقيقي
  bool _isDisposed = false;

  QiblaServiceImpl({LoggerService? logger})
      : _logger = logger ?? getIt<LoggerService>() {
    _logger.debug(message: 'QiblaServiceImpl constructed');
  }

  // دالة داخلية لحساب زاوية القبلة بناءً على الإحداثيات الحالية المخزنة
  void _recalculateQiblaAngle() {
    if (_currentLatitude == 0 && _currentLongitude == 0) {
      _logger.warning(message: "Cannot calculate Qibla angle: current location is (0,0) or not set.");
      // لا تقم بتغيير _qiblaAngleFromNorth إذا لم تكن الإحداثيات صالحة
      return;
    }
    final adhan.Coordinates coordinates = adhan.Coordinates(_currentLatitude, _currentLongitude);
    _qiblaAngleFromNorth = adhan.Qibla(coordinates).direction;
    _logger.debug(message: "Qibla angle recalculated: $_qiblaAngleFromNorth for (lat: $_currentLatitude, lon: $_currentLongitude)");
  }

  @override
  Future<double> getQiblaDirection({
    required double latitude,
    required double longitude,
  }) async {
    if (_isDisposed) {
      _logger.warning(message: "getQiblaDirection called after dispose.");
      throw StateError("QiblaService disposed");
    }
    _currentLatitude = latitude;
    _currentLongitude = longitude;
    _recalculateQiblaAngle(); // قم بتحديث الزاوية بناءً على الإحداثيات الجديدة
    return _qiblaAngleFromNorth;
  }

  @override
  Stream<double> getCompassStream() {
    if (_isDisposed) {
      _logger.warning(message: "Compass stream accessed after dispose.");
      return Stream.error(StateError("QiblaService disposed"));
    }
    _compassHeadingStreamController ??= StreamController<double>.broadcast(
      onListen: () => _logger.debug(message: "Compass heading stream listener added."),
      onCancel: () => _logger.debug(message: "Compass heading stream listener cancelled."),
    );

    // بدء الاستماع فقط إذا لم يكن هناك استماع نشط بالفعل
    if (FlutterCompass.events != null && (_compassEventSubscription == null || _compassEventSubscription!.isPaused)) {
      _compassEventSubscription?.cancel(); // ألغِ أي اشتراك سابق
      _compassEventSubscription = FlutterCompass.events!.listen(
        (event) {
          if (!_isDisposed && event.heading != null) {
            _compassHeadingStreamController?.add(event.heading!);
          }
        },
        onError: (e, s) {
          _logger.error(message: 'Error in compass heading stream', error: e, stackTrace: s);
          if (!_isDisposed) {
            _compassHeadingStreamController?.addError(e);
          }
        },
      );
      _logger.debug(message: "Subscribed to FlutterCompass.events for compass heading.");
    } else if (FlutterCompass.events == null && !(_compassHeadingStreamController?.hasListener ?? false) ) {
      _logger.warning(message: 'Compass not available, adding error to compass stream.');
       if (!_isDisposed) {
         _compassHeadingStreamController?.addError(Exception('Compass hardware not available.'));
       }
    }
    return _compassHeadingStreamController!.stream;
  }

  @override
  Stream<double> getQiblaDirectionStream({
    required double latitude,
    required double longitude,
  }) {
    if (_isDisposed) {
      _logger.warning(message: "Qibla direction stream accessed after dispose.");
      return Stream.error(StateError("QiblaService disposed"));
    }

    _qiblaDirectionStreamController ??= StreamController<double>.broadcast(
      onListen: () => _logger.debug(message: "Relative Qibla direction stream listener added."),
      onCancel: () => _logger.debug(message: "Relative Qibla direction stream listener cancelled."),
    );
    
    // تحديث الموقع وحساب زاوية القبلة
    updateUserLocation(latitude, longitude); // هذا سيقوم بتحديث _currentLatitude, _currentLongitude و _qiblaAngleFromNorth

    // استمع إلى تحديثات البوصلة لحساب اتجاه القبلة النسبي
    // تأكد من أننا لا نعيد الاشتراك إذا كان هناك اشتراك نشط بالفعل
    if (FlutterCompass.events != null && (_compassEventSubscription == null || _compassEventSubscription!.isPaused)) {
      _compassEventSubscription?.cancel();
      _compassEventSubscription = FlutterCompass.events!.listen(
        (event) {
          if (!_isDisposed && event.heading != null) {
            // اتجاه القبلة النسبي = (زاوية القبلة من الشمال) - (اتجاه البوصلة من الشمال)
            double relativeQiblaDirection = (_qiblaAngleFromNorth - event.heading! + 360) % 360;
            _qiblaDirectionStreamController?.add(relativeQiblaDirection);
          }
        },
        onError: (e, s) {
          _logger.error(
              message: 'Error in Qibla direction stream (compass event error)',
              error: e,
              stackTrace: s);
          if (!_isDisposed) {
            _qiblaDirectionStreamController?.addError(e);
          }
        },
      );
       _logger.debug(message: "Subscribed to FlutterCompass.events for relative Qibla direction.");
    } else if (FlutterCompass.events == null && !(_qiblaDirectionStreamController?.hasListener ?? false)) {
       _logger.warning(message: 'Compass not available, adding error to Qibla direction stream.');
       if (!_isDisposed) {
         _qiblaDirectionStreamController?.addError(Exception('Compass hardware not available for Qibla.'));
       }
    }
    return _qiblaDirectionStreamController!.stream;
  }

  @override
  Future<bool> isCompassAvailable() async {
    if (_isDisposed) return false;
    _logger.debug(message: "Checking compass availability...");
    try {
      final events = FlutterCompass.events;
      if (events == null) {
        _logger.info(message: "Compass events stream is null. Compass likely unavailable.");
        return false;
      }
      await events.first.timeout(const Duration(seconds: 2));
      _logger.info(message: "Compass appears to be available.");
      return true;
    } on TimeoutException catch (e, s) {
      // <--- تم التعديل: تصحيح استدعاء logger.warning
      _logger.warning(
          message: 'Compass reading timed out during availability check.',
          data: {'error': e.toString(), 'stackTrace': s.toString()}); // السطر 150 تقريبًا
      return false;
    } catch (e, s) {
      _logger.error(
          message: 'Exception while checking compass availability.',
          error: e,
          stackTrace: s);
      return false;
    }
  }

  @override
  Future<void> updateUserLocation(double latitude, double longitude) async {
    if (_isDisposed) {
      _logger.warning(message: "updateUserLocation called after dispose.");
      return;
    }
    _currentLatitude = latitude;
    _currentLongitude = longitude;
    _recalculateQiblaAngle();
     _logger.info(message: "User location updated to (lat: $latitude, lon: $longitude). Qibla angle refreshed.");
  }

  @override
  void dispose() {
    if (_isDisposed) return;
    _logger.debug(message: 'Disposing QiblaServiceImpl...');
    _isDisposed = true;

    _compassEventSubscription?.cancel();
    _compassEventSubscription = null;

    _qiblaDirectionStreamController?.close();
    _qiblaDirectionStreamController = null;

    _compassHeadingStreamController?.close();
    _compassHeadingStreamController = null;
    _logger.debug(message: 'QiblaServiceImpl resources disposed.');
  }
}