// lib/features/prayers/prayer_di.dart

import 'package:get_it/get_it.dart';
import 'data/datasources/prayer_times_calculator.dart';
import 'data/datasources/prayer_times_local_datasource.dart';
import 'data/repositories/prayer_times_repository_impl.dart';
import 'domain/repositories/prayer_times_repository.dart';
import 'domain/usecases/get_next_prayer.dart';
import 'domain/usecases/get_prayer_times.dart';
import 'domain/usecases/get_qibla_direction.dart';
import 'domain/usecases/schedule_prayer_notifications.dart';
import 'presentation/providers/prayer_times_provider.dart';

final getIt = GetIt.instance;

void setupPrayerDependencies() {
  // Data Sources
  getIt.registerLazySingleton<PrayerTimesLocalDataSource>(
    () => PrayerTimesLocalDataSourceImpl(
      storage: getIt(),
    ),
  );
  
  getIt.registerLazySingleton<PrayerTimesCalculator>(
    () => PrayerTimesCalculator(
      logger: getIt(),
      storage: getIt(),
    ),
  );
  
  // Repository
  getIt.registerLazySingleton<PrayerTimesRepository>(
    () => PrayerTimesRepositoryImpl(
      calculator: getIt(),
      localDataSource: getIt(),
      logger: getIt(),
    ),
  );
  
  // Use Cases
  getIt.registerLazySingleton(() => GetPrayerTimes(getIt()));
  getIt.registerLazySingleton(() => GetNextPrayer(getIt()));
  getIt.registerLazySingleton(() => GetQiblaDirection(getIt()));
  getIt.registerLazySingleton(() => SchedulePrayerNotifications(
    notificationManager: getIt(),
    logger: getIt(),
  ));
  
  // Provider
  getIt.registerFactory(
    () => PrayerTimesProvider(
      getPrayerTimes: getIt(),
      getNextPrayer: getIt(),
      scheduleNotifications: getIt(),
      errorHandler: getIt(),
      logger: getIt(),
    ),
  );
}