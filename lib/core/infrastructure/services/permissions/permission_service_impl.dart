// lib/core/infrastructure/services/permissions/permission_service_impl.dart

import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart' as handler;
import '../logging/logger_service.dart';
import '../storage/storage_service.dart';
import 'permission_service.dart';
import 'widgets/permission_dialog.dart';

/// تنفيذ موحد ومحسّن لخدمة الأذونات
class PermissionServiceImpl implements PermissionService {
  final LoggerService _logger;
  final StorageService _storage;
  final BuildContext? _context;
  
  // Analytics Keys
  static const String _statsKey = 'permission_stats';
  
  // Cache
  final Map<AppPermissionType, AppPermissionStatus> _statusCache = {};
  DateTime? _lastCacheUpdate;
  static const Duration _cacheExpiration = Duration(seconds: 30);
  
  // Stream controller
  final StreamController<PermissionChange> _permissionChangeController = 
      StreamController<PermissionChange>.broadcast();
  
  // Permission descriptions
  static const Map<AppPermissionType, String> _permissionDescriptions = {
    AppPermissionType.location: 'نحتاج موقعك لحساب أوقات الصلاة بدقة حسب منطقتك',
    AppPermissionType.notification: 'نحتاج إذن الإشعارات لتذكيرك بالأذكار وأوقات الصلاة',
    AppPermissionType.doNotDisturb: 'نحتاج إذن عدم الإزعاج لتخصيص أوقات التذكير المناسبة لك',
    AppPermissionType.batteryOptimization: 'نحتاج إذن تحسين البطارية لضمان عمل التذكيرات في الخلفية',
    AppPermissionType.storage: 'نحتاج إذن التخزين لحفظ وتصدير الأذكار المفضلة لديك',
    AppPermissionType.unknown: 'إذن مطلوب لتحسين تجربة الاستخدام',
  };
  
  // Permission names
  static const Map<AppPermissionType, String> _permissionNames = {
    AppPermissionType.location: 'الموقع',
    AppPermissionType.notification: 'الإشعارات',
    AppPermissionType.doNotDisturb: 'عدم الإزعاج',
    AppPermissionType.batteryOptimization: 'تحسين البطارية',
    AppPermissionType.storage: 'التخزين',
    AppPermissionType.unknown: 'غير معروف',
  };
  
  // Permission icons
  static const Map<AppPermissionType, String> _permissionIcons = {
    AppPermissionType.location: '📍',
    AppPermissionType.notification: '🔔',
    AppPermissionType.doNotDisturb: '🔕',
    AppPermissionType.batteryOptimization: '🔋',
    AppPermissionType.storage: '💾',
    AppPermissionType.unknown: '❓',
  };
  
  PermissionServiceImpl({
    required LoggerService logger,
    required StorageService storage,
    BuildContext? context,
  }) : _logger = logger,
       _storage = storage,
       _context = context {
    _initializeService();
  }
  
  void _initializeService() {
    _logger.debug(message: '[PermissionService] تهيئة خدمة الأذونات');
    _loadCachedStatuses();
    _startPermissionMonitoring();
  }
  
  @override
  Future<AppPermissionStatus> requestPermission(AppPermissionType permission) async {
    final stopwatch = Stopwatch()..start();
    
    _logger.info(message: '[PermissionService] طلب إذن', data: {'type': permission.toString()});
    _trackPermissionRequest(permission);
    
    // التحقق من الكاش أولاً
    final cachedStatus = _getCachedStatus(permission);
    if (cachedStatus != null && cachedStatus == AppPermissionStatus.granted) {
      _logger.debug(message: '[PermissionService] الإذن ممنوح مسبقاً من الكاش');
      return cachedStatus;
    }
    
    final nativePermission = _mapToNativePermission(permission);
    if (nativePermission == null) {
      _logger.warning(message: '[PermissionService] نوع الإذن غير مدعوم', data: {'type': permission.toString()});
      return AppPermissionStatus.unknown;
    }
    
    try {
      // معالجة خاصة للأذونات المختلفة
      final AppPermissionStatus status;
      
      switch (permission) {
        case AppPermissionType.location:
          status = await _requestLocationPermission(nativePermission);
          break;
        case AppPermissionType.storage:
          status = await _requestStoragePermission();
          break;
        case AppPermissionType.batteryOptimization:
          status = await _requestBatteryOptimization();
          break;
        case AppPermissionType.doNotDisturb:
          status = await _requestDoNotDisturb();
          break;
        case AppPermissionType.notification:
        case AppPermissionType.unknown:
          final nativeStatus = await nativePermission.request();
          status = _mapFromNativeStatus(nativeStatus);
          break;
      }
      
      // تحديث الكاش
      _updateCache(permission, status);
      
      // تتبع النتيجة
      stopwatch.stop();
      _trackPermissionResult(
        permission: permission,
        status: status,
        duration: stopwatch.elapsed,
      );
      
      // إشعار المستمعين
      _notifyPermissionChange(
        permission, 
        cachedStatus ?? AppPermissionStatus.unknown,
        status
      );
      
      _logger.info(
        message: '[PermissionService] نتيجة طلب الإذن',
        data: {
          'type': permission.toString(),
          'status': status.toString(),
          'duration': stopwatch.elapsedMilliseconds,
        }
      );
      
      return status;
    } catch (e, s) {
      _logger.error(message: '[PermissionService] خطأ في طلب الإذن', error: e, stackTrace: s);
      _trackPermissionError(permission, e.toString());
      return AppPermissionStatus.unknown;
    }
  }
  
  @override
  Future<PermissionBatchResult> requestMultiplePermissions({
    required List<AppPermissionType> permissions,
    Function(PermissionProgress)? onProgress,
    bool showExplanationDialog = true,
  }) async {
    _logger.info(
      message: '[PermissionService] طلب أذونات متعددة',
      data: {'permissions': permissions.map((p) => p.toString()).toList()}
    );
    
    // عرض dialog توضيحي
    if (showExplanationDialog && _context != null) {
      final shouldContinue = await PermissionExplanationDialog.show(
        context: _context!,
        permissions: permissions,
        descriptions: _permissionDescriptions,
        names: _permissionNames,
        icons: _permissionIcons,
      );
      
      if (!shouldContinue) {
        _logger.info(message: '[PermissionService] المستخدم ألغى طلب الأذونات');
        return PermissionBatchResult.cancelled();
      }
    }
    
    // طلب الأذونات مع تتبع التقدم
    final results = <AppPermissionType, AppPermissionStatus>{};
    
    for (int i = 0; i < permissions.length; i++) {
      final permission = permissions[i];
      
      // إرسال تحديث التقدم
      onProgress?.call(PermissionProgress(
        current: i + 1,
        total: permissions.length,
        currentPermission: permission,
      ));
      
      // طلب الإذن
      results[permission] = await requestPermission(permission);
      
      // تأخير صغير بين الطلبات
      if (i < permissions.length - 1) {
        await Future.delayed(const Duration(milliseconds: 500));
      }
    }
    
    // حساب النتائج
    final deniedPermissions = results.entries
        .where((e) => e.value != AppPermissionStatus.granted)
        .map((e) => e.key)
        .toList();
    
    final batchResult = PermissionBatchResult(
      results: results,
      allGranted: deniedPermissions.isEmpty,
      deniedPermissions: deniedPermissions,
    );
    
    _logger.info(
      message: '[PermissionService] نتائج طلب الأذونات المتعددة',
      data: {
        'total': permissions.length,
        'granted': permissions.length - deniedPermissions.length,
        'denied': deniedPermissions.length,
      }
    );
    
    return batchResult;
  }
  
  @override
  Future<AppPermissionStatus> checkPermissionStatus(AppPermissionType permission) async {
    // التحقق من الكاش أولاً
    final cachedStatus = _getCachedStatus(permission);
    if (cachedStatus != null && _isCacheValid()) {
      return cachedStatus;
    }
    
    final nativePermission = _mapToNativePermission(permission);
    if (nativePermission == null) {
      _logger.warning(message: '[PermissionService] نوع الإذن غير مدعوم للفحص', data: {'type': permission.toString()});
      return AppPermissionStatus.unknown;
    }
    
    try {
      final AppPermissionStatus status;
      
      // معالجة خاصة للأذونات
      switch (permission) {
        case AppPermissionType.storage:
          status = await _checkStoragePermission();
          break;
        case AppPermissionType.batteryOptimization:
          status = await _checkBatteryOptimization();
          break;
        case AppPermissionType.doNotDisturb:
          status = await _checkDoNotDisturb();
          break;
        case AppPermissionType.location:
        case AppPermissionType.notification:
        case AppPermissionType.unknown:
          final nativeStatus = await nativePermission.status;
          status = _mapFromNativeStatus(nativeStatus);
          break;
      }
      
      // تحديث الكاش
      _updateCache(permission, status);
      
      _logger.debug(
        message: '[PermissionService] حالة الإذن',
        data: {
          'type': permission.toString(),
          'status': status.toString(),
          'from_cache': false,
        }
      );
      
      return status;
    } catch (e) {
      _logger.error(message: '[PermissionService] خطأ في فحص حالة الإذن', error: e);
      return AppPermissionStatus.unknown;
    }
  }
  
  @override
  Future<Map<AppPermissionType, AppPermissionStatus>> checkAllPermissions() async {
    final permissions = AppPermissionType.values
        .where((p) => p != AppPermissionType.unknown)
        .toList();
    
    _logger.info(message: '[PermissionService] فحص جميع الأذونات');
    
    final results = <AppPermissionType, AppPermissionStatus>{};
    
    // استخدام الطلبات المتوازية لتحسين الأداء
    await Future.wait(
      permissions.map((permission) async {
        results[permission] = await checkPermissionStatus(permission);
      }),
    );
    
    _logger.info(
      message: '[PermissionService] نتائج فحص جميع الأذونات',
      data: results.map((k, v) => MapEntry(k.toString(), v.toString()))
    );
    
    return results;
  }
  
  @override
  Future<bool> openAppSettings([AppSettingsType? settingsPage]) async {
    _logger.info(
      message: '[PermissionService] فتح الإعدادات',
      data: {'settingsPage': settingsPage?.toString() ?? 'app'}
    );
    
    _trackSettingsOpened(settingsPage);
    
    try {
      if (settingsPage == null) {
        return await handler.openAppSettings();
      }
      
      // معالجة خاصة لصفحات الإعدادات المحددة
      switch (settingsPage) {
        case AppSettingsType.location:
          if (Platform.isIOS) {
            return await handler.openAppSettings();
          }
          // Android - محاولة فتح إعدادات الموقع مباشرة
          return await handler.openAppSettings();
          
        case AppSettingsType.notification:
          if (Platform.isAndroid && await _canOpenNotificationSettings()) {
            return await handler.openAppSettings();
          }
          return await handler.openAppSettings();
          
        case AppSettingsType.battery:
          if (Platform.isAndroid) {
            return await handler.openAppSettings();
          }
          _logger.warning(message: '[PermissionService] إعدادات البطارية غير متوفرة على iOS');
          return false;
          
        case AppSettingsType.storage:
          return await handler.openAppSettings();
          
        default:
          return await handler.openAppSettings();
      }
    } catch (e) {
      _logger.error(message: '[PermissionService] خطأ في فتح الإعدادات', error: e);
      return false;
    }
  }
  
  @override
  Future<bool> shouldShowPermissionRationale(AppPermissionType permission) async {
    if (!Platform.isAndroid) {
      _logger.debug(message: '[PermissionService] shouldShowPermissionRationale متوفر فقط على Android');
      return false;
    }
    
    final nativePermission = _mapToNativePermission(permission);
    if (nativePermission == null) return false;
    
    try {
      final status = await nativePermission.status;
      final shouldShow = status.isDenied && !status.isPermanentlyDenied;
      
      _logger.debug(
        message: '[PermissionService] shouldShowPermissionRationale',
        data: {
          'type': permission.toString(),
          'shouldShow': shouldShow
        }
      );
      
      return shouldShow;
    } catch (e) {
      _logger.error(message: '[PermissionService] خطأ في فحص shouldShowPermissionRationale', error: e);
      return false;
    }
  }
  
  @override
  Future<bool> isPermissionPermanentlyDenied(AppPermissionType permission) async {
    final nativePermission = _mapToNativePermission(permission);
    if (nativePermission == null) return false;
    
    try {
      final status = await nativePermission.status;
      final isPermanentlyDenied = status.isPermanentlyDenied;
      
      _logger.debug(
        message: '[PermissionService] فحص الرفض الدائم',
        data: {
          'type': permission.toString(),
          'isPermanentlyDenied': isPermanentlyDenied
        }
      );
      
      return isPermanentlyDenied;
    } catch (e) {
      _logger.error(message: '[PermissionService] خطأ في فحص الرفض الدائم', error: e);
      return false;
    }
  }
  
  @override
  String getPermissionDescription(AppPermissionType permission) {
    return _permissionDescriptions[permission] ?? _permissionDescriptions[AppPermissionType.unknown]!;
  }
  
  @override
  String getPermissionName(AppPermissionType permission) {
    return _permissionNames[permission] ?? _permissionNames[AppPermissionType.unknown]!;
  }
  
  @override
  String getPermissionIcon(AppPermissionType permission) {
    return _permissionIcons[permission] ?? _permissionIcons[AppPermissionType.unknown]!;
  }
  
  @override
  bool isPermissionAvailable(AppPermissionType permission) {
    switch (permission) {
      case AppPermissionType.location:
      case AppPermissionType.notification:
      case AppPermissionType.storage:
        return true;
        
      case AppPermissionType.doNotDisturb:
      case AppPermissionType.batteryOptimization:
        return Platform.isAndroid;
        
      case AppPermissionType.unknown:
        return false;
    }
  }
  
  @override
  Stream<PermissionChange> get permissionChanges => _permissionChangeController.stream;
  
  @override
  Future<PermissionStats> getPermissionStats() async {
    try {
      final data = _storage.getMap(_statsKey) ?? {};
      
      final totalRequests = data['total_requests'] as int? ?? 0;
      final grantedCount = data['granted_count'] as int? ?? 0;
      final deniedCount = data['denied_count'] as int? ?? 0;
      
      // حساب الأذونات الأكثر رفضاً
      final deniedByType = data['denied_by_type'] as Map<String, dynamic>? ?? {};
      String? mostDenied;
      int maxDenied = 0;
      
      deniedByType.forEach((key, value) {
        if (value as int > maxDenied) {
          maxDenied = value;
          mostDenied = key;
        }
      });
      
      return PermissionStats(
        totalRequests: totalRequests,
        grantedCount: grantedCount,
        deniedCount: deniedCount,
        acceptanceRate: totalRequests > 0 ? (grantedCount / totalRequests) * 100 : 0,
        mostDeniedPermission: mostDenied,
      );
    } catch (e) {
      _logger.error(message: '[PermissionService] خطأ في الحصول على إحصائيات الأذونات', error: e);
      return PermissionStats(
        totalRequests: 0,
        grantedCount: 0,
        deniedCount: 0,
        acceptanceRate: 0,
      );
    }
  }
  
  @override
  void clearPermissionCache() {
    _statusCache.clear();
    _lastCacheUpdate = null;
    _logger.debug(message: '[PermissionService] تم مسح ذاكرة التخزين المؤقت للأذونات');
  }
  
  @override
  Future<void> dispose() async {
    await _permissionChangeController.close();
    clearPermissionCache();
    _logger.debug(message: '[PermissionService] تم إيقاف خدمة الأذونات');
  }
  
  // ==================== Private Methods ====================
  
  // تحويل من أنواع الأذونات الخاصة بنا إلى أذونات المكتبة
  handler.Permission? _mapToNativePermission(AppPermissionType permission) {
    switch (permission) {
      case AppPermissionType.location:
        return handler.Permission.locationWhenInUse;
        
      case AppPermissionType.notification:
        return handler.Permission.notification;
        
      case AppPermissionType.doNotDisturb:
        return Platform.isAndroid ? handler.Permission.accessNotificationPolicy : null;
        
      case AppPermissionType.batteryOptimization:
        return Platform.isAndroid ? handler.Permission.ignoreBatteryOptimizations : null;
        
      case AppPermissionType.storage:
        // Android 13+ لا يحتاج إذن للصور والفيديو
        if (Platform.isAndroid) {
          return handler.Permission.storage;
        }
        return handler.Permission.photos; // iOS
        
      case AppPermissionType.unknown:
        return null;
    }
  }
  
  // تحويل من حالات المكتبة إلى حالاتنا
  AppPermissionStatus _mapFromNativeStatus(handler.PermissionStatus status) {
    if (status.isGranted) {
      return AppPermissionStatus.granted;
    } else if (status.isDenied) {
      return AppPermissionStatus.denied;
    } else if (status.isPermanentlyDenied) {
      return AppPermissionStatus.permanentlyDenied;
    } else if (status.isRestricted) {
      return AppPermissionStatus.restricted;
    } else if (status.isLimited) {
      return AppPermissionStatus.limited;
    } else if (status.isProvisional) {
      return AppPermissionStatus.provisional;
    } else {
      return AppPermissionStatus.unknown;
    }
  }
  
  // معالجة خاصة لإذن الموقع
  Future<AppPermissionStatus> _requestLocationPermission(handler.Permission permission) async {
    // التحقق من خدمات الموقع
    const serviceStatus = handler.ServiceStatus.enabled; // تصحيح مؤقت
    if (serviceStatus != handler.ServiceStatus.enabled) {
      _logger.warning(message: '[PermissionService] خدمات الموقع غير مفعلة');
      
      // عرض dialog لتفعيل خدمات الموقع
      if (_context != null) {
        final shouldOpen = await _showLocationServiceDialog();
        if (shouldOpen) {
          await handler.openAppSettings();
        }
      }
      
      return AppPermissionStatus.denied;
    }
    
    final status = await permission.request();
    return _mapFromNativeStatus(status);
  }
  
  // معالجة خاصة لإذن التخزين
  Future<AppPermissionStatus> _requestStoragePermission() async {
    if (Platform.isAndroid) {
      // Android 13+ (API 33+) لا يحتاج إذن storage
      const androidInfo = 29; // تصحيح مؤقت
      if (androidInfo >= 33) {
        _logger.info(message: '[PermissionService] Android 13+: لا يحتاج إذن تخزين منفصل');
        return AppPermissionStatus.granted;
      }
    }
    
    final permission = _mapToNativePermission(AppPermissionType.storage);
    if (permission == null) return AppPermissionStatus.unknown;
    
    final status = await permission.request();
    return _mapFromNativeStatus(status);
  }
  
  // معالجة خاصة لإذن تحسين البطارية
  Future<AppPermissionStatus> _requestBatteryOptimization() async {
    if (!Platform.isAndroid) return AppPermissionStatus.unknown;
    
    const permission = handler.Permission.ignoreBatteryOptimizations;
    final status = await permission.request();
    
    if (status.isGranted) {
      _logger.info(message: '[PermissionService] تم منح إذن تحسين البطارية');
    }
    
    return _mapFromNativeStatus(status);
  }
  
  // معالجة خاصة لإذن عدم الإزعاج
  Future<AppPermissionStatus> _requestDoNotDisturb() async {
    if (!Platform.isAndroid) return AppPermissionStatus.unknown;
    
    const permission = handler.Permission.accessNotificationPolicy;
    final status = await permission.request();
    
    if (status.isGranted) {
      _logger.info(message: '[PermissionService] تم منح إذن عدم الإزعاج');
    }
    
    return _mapFromNativeStatus(status);
  }
  
  // فحص حالة إذن التخزين
  Future<AppPermissionStatus> _checkStoragePermission() async {
    if (Platform.isAndroid) {
      const androidVersion = 29; // تصحيح مؤقت
      if (androidVersion >= 33) {
        return AppPermissionStatus.granted;
      }
    }
    
    final permission = _mapToNativePermission(AppPermissionType.storage);
    if (permission == null) return AppPermissionStatus.unknown;
    
    final status = await permission.status;
    return _mapFromNativeStatus(status);
  }
  
  // فحص حالة إذن تحسين البطارية
  Future<AppPermissionStatus> _checkBatteryOptimization() async {
    if (!Platform.isAndroid) return AppPermissionStatus.unknown;
    
    const permission = handler.Permission.ignoreBatteryOptimizations;
    final status = await permission.status;
    return _mapFromNativeStatus(status);
  }
  
  // فحص حالة إذن عدم الإزعاج
  Future<AppPermissionStatus> _checkDoNotDisturb() async {
    if (!Platform.isAndroid) return AppPermissionStatus.unknown;
    
    const permission = handler.Permission.accessNotificationPolicy;
    final status = await permission.status;
    return _mapFromNativeStatus(status);
  }
  
  // التحقق من إمكانية فتح إعدادات الإشعارات
  Future<bool> _canOpenNotificationSettings() async {
    try {
      // Android 8.0+ (API 26+)
      const androidVersion = 29; // تصحيح مؤقت
      return androidVersion >= 26;
    } catch (e) {
      return false;
    }
  }
  
  // عرض dialog لتفعيل خدمات الموقع
  Future<bool> _showLocationServiceDialog() async {
    if (_context == null) return false;
    
    return await showDialog<bool>(
      context: _context!,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('خدمات الموقع مطلوبة'),
        content: const Text(
          'يجب تفعيل خدمات الموقع في جهازك لحساب أوقات الصلاة بدقة.\n\n'
          'هل تريد الذهاب إلى الإعدادات لتفعيلها؟'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('لاحقاً'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('فتح الإعدادات'),
          ),
        ],
      ),
    ) ?? false;
  }
  
  // إدارة الكاش
  AppPermissionStatus? _getCachedStatus(AppPermissionType permission) {
    if (!_isCacheValid()) {
      clearPermissionCache();
      return null;
    }
    return _statusCache[permission];
  }
  
  bool _isCacheValid() {
    if (_lastCacheUpdate == null) return false;
    return DateTime.now().difference(_lastCacheUpdate!) < _cacheExpiration;
  }
  
  void _updateCache(AppPermissionType permission, AppPermissionStatus status) {
    _statusCache[permission] = status;
    _lastCacheUpdate = DateTime.now();
  }
  
  // تحميل الحالات المحفوظة
  void _loadCachedStatuses() {
    try {
      final cached = _storage.getMap('permission_cache');
      if (cached != null) {
        cached.forEach((key, value) {
          try {
            final permission = AppPermissionType.values.firstWhere(
              (p) => p.toString() == key,
            );
            final status = AppPermissionStatus.values.firstWhere(
              (s) => s.toString() == value,
            );
            _statusCache[permission] = status;
          } catch (e) {
            // تجاهل الأخطاء في البيانات المحفوظة
          }
        });
        _lastCacheUpdate = DateTime.now();
      }
    } catch (e) {
      _logger.warning(message: '[PermissionService] خطأ في تحميل كاش الأذونات', data: {'error': e.toString()});
    }
  }
  
  // مراقبة تغييرات الأذونات
  void _startPermissionMonitoring() {
    // يمكن إضافة timer دوري للتحقق من تغييرات الأذونات
    Timer.periodic(const Duration(minutes: 5), (_) async {
      // فحص الأذونات الحرجة
      const criticalPermissions = [
        AppPermissionType.notification,
        AppPermissionType.location,
      ];
      
      for (final permission in criticalPermissions) {
        final currentStatus = await checkPermissionStatus(permission);
        final cachedStatus = _statusCache[permission];
        
        if (cachedStatus != null && currentStatus != cachedStatus) {
          _notifyPermissionChange(permission, cachedStatus, currentStatus);
        }
      }
    });
  }
  
  // إشعار المستمعين بالتغييرات
  void _notifyPermissionChange(
    AppPermissionType permission,
    AppPermissionStatus oldStatus,
    AppPermissionStatus newStatus,
  ) {
    if (oldStatus != newStatus) {
      _permissionChangeController.add(PermissionChange(
        permission: permission,
        oldStatus: oldStatus,
        newStatus: newStatus,
        timestamp: DateTime.now(),
      ));
    }
  }
  
  // ==================== Analytics Methods ====================
  
  void _trackPermissionRequest(AppPermissionType permission) {
    try {
      _logger.logEvent('permission_requested', parameters: {
        'permission_type': permission.toString(),
        'timestamp': DateTime.now().toIso8601String(),
      });
      
      // تحديث الإحصائيات
      final stats = _storage.getMap(_statsKey) ?? {};
      stats['total_requests'] = (stats['total_requests'] as int? ?? 0) + 1;
      
      final requestsByType = stats['requests_by_type'] as Map<String, dynamic>? ?? {};
      requestsByType[permission.toString()] = 
          (requestsByType[permission.toString()] as int? ?? 0) + 1;
      stats['requests_by_type'] = requestsByType;
      
      _storage.setMap(_statsKey, stats);
    } catch (e) {
      _logger.warning(message: '[PermissionService] خطأ في تتبع طلب الإذن', data: {'error': e.toString()});
    }
  }
  
  void _trackPermissionResult({
    required AppPermissionType permission,
    required AppPermissionStatus status,
    required Duration duration,
  }) {
    try {
      _logger.logEvent('permission_result', parameters: {
        'permission_type': permission.toString(),
        'status': status.toString(),
        'duration_ms': duration.inMilliseconds,
        'is_granted': status == AppPermissionStatus.granted,
        'is_permanently_denied': status == AppPermissionStatus.permanentlyDenied,
      });
      
      // تحديث الإحصائيات
      final stats = _storage.getMap(_statsKey) ?? {};
      
      if (status == AppPermissionStatus.granted) {
        stats['granted_count'] = (stats['granted_count'] as int? ?? 0) + 1;
      } else {
        stats['denied_count'] = (stats['denied_count'] as int? ?? 0) + 1;
        
        // تتبع الأذونات المرفوضة حسب النوع
        final deniedByType = stats['denied_by_type'] as Map<String, dynamic>? ?? {};
        deniedByType[permission.toString()] = 
            (deniedByType[permission.toString()] as int? ?? 0) + 1;
        stats['denied_by_type'] = deniedByType;
      }
      
      _storage.setMap(_statsKey, stats);
    } catch (e) {
      _logger.warning(message: '[PermissionService] خطأ في تتبع نتيجة الإذن', data: {'error': e.toString()});
    }
  }
  
  void _trackPermissionError(AppPermissionType permission, String error) {
    _logger.logEvent('permission_error', parameters: {
      'permission_type': permission.toString(),
      'error': error,
    });
  }
  
  void _trackSettingsOpened(AppSettingsType? settingsType) {
    _logger.logEvent('permission_settings_opened', parameters: {
      'settings_type': settingsType?.toString() ?? 'app',
      'timestamp': DateTime.now().toIso8601String(),
    });
  }
}