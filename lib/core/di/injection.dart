import 'package:get_it/get_it.dart';
import '../../core/database/database_helper.dart';
import '../../core/sync/sync_manager.dart';
import '../../data/datasources/attendance_remote_data_source.dart';
import '../../data/datasources/auth_remote_data_source.dart';
import '../../data/datasources/connectivity_service.dart';
import '../../data/datasources/geolocator_location_service.dart';
import '../../data/datasources/i_attendance_local_data_source.dart';
import '../../data/datasources/i_location_service.dart';
import '../../data/datasources/sqlite_attendance_local_data_source.dart';
import '../../data/repositories/attendance_repository_impl.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/repositories/i_attendance_repository.dart';
import '../../domain/repositories/i_auth_repository.dart';
import '../../domain/usecases/check_in.dart';
import '../../domain/usecases/check_out.dart';
import '../../domain/usecases/get_all_records.dart';
import '../../domain/usecases/get_attendance_history.dart';
import '../../domain/usecases/get_current_location.dart';
import '../../domain/usecases/get_current_user.dart';
import '../../domain/usecases/get_today_records.dart';
import '../../domain/usecases/get_today_status.dart';
import '../../domain/usecases/login.dart';
import '../../domain/usecases/logout.dart';
import '../../domain/usecases/refresh_user_profile.dart';
import '../../domain/usecases/sync_attendance.dart';
import '../../domain/usecases/sync_batch_offline.dart';
import '../../presentation/providers/attendance_provider.dart';
import '../../presentation/providers/auth_provider.dart';
import '../network/dio_client.dart';

final getIt = GetIt.instance;

Future<void> initDependencies() async {
  // 1. External, Network Client & Database
  getIt.registerLazySingleton<DatabaseHelper>(
    () => DatabaseHelper(),
  );

  getIt.registerLazySingleton<DioClient>(
    () => DioClient(
      getToken: () => getIt<IAuthRepository>().getToken(),
      onUnauthorized: () {
        getIt<IAuthRepository>().clearUser();
      },
    ),
  );

  // 2. Data Sources (SQLite Local Data Source as SSOT)
  getIt.registerLazySingleton<IAttendanceLocalDataSource>(
    () => SqliteAttendanceLocalDataSource(databaseHelper: getIt()),
  );
  getIt.registerLazySingleton<IAuthRemoteDataSource>(
    () => AuthRemoteDataSource(dioClient: getIt()),
  );
  getIt.registerLazySingleton<IAttendanceRemoteDataSourceNew>(
    () => AttendanceRemoteDataSource(dioClient: getIt()),
  );
  getIt.registerLazySingleton<ILocationService>(
    () => GeolocatorLocationService(),
  );
  getIt.registerLazySingleton<ConnectivityService>(
    () => ConnectivityService(),
  );

  // 3. Repositories
  getIt.registerLazySingleton<IAuthRepository>(
    () => AuthRepositoryImpl(remoteDataSource: getIt()),
  );
  getIt.registerLazySingleton<IAttendanceRepository>(
    () => AttendanceRepositoryImpl(
      localDataSource: getIt(),
      locationService: getIt(),
      remoteDataSource: getIt(),
      connectivityService: getIt(),
      getUserId: () async => (await getIt<IAuthRepository>().getCurrentUser())?.id,
    ),
  );

  // 4. Use Cases - Auth
  getIt.registerLazySingleton(() => LoginUseCase(getIt()));
  getIt.registerLazySingleton(() => LogoutUseCase(getIt()));
  getIt.registerLazySingleton(() => GetCurrentUserUseCase(getIt()));
  getIt.registerLazySingleton(() => RefreshUserProfileUseCase(getIt()));

  // 5. Use Cases - Attendance
  getIt.registerLazySingleton(() => CheckInUseCase(getIt()));
  getIt.registerLazySingleton(() => CheckOutUseCase(getIt()));
  getIt.registerLazySingleton(() => GetTodayStatusUseCase(getIt()));
  getIt.registerLazySingleton(() => GetTodayRecordsUseCase(getIt()));
  getIt.registerLazySingleton(() => GetAllRecordsUseCase(getIt()));
  getIt.registerLazySingleton(() => GetAttendanceHistoryUseCase(getIt()));
  getIt.registerLazySingleton(() => GetCurrentLocationUseCase(getIt()));
  getIt.registerLazySingleton(() => SyncBatchOfflineUseCase(getIt()));
  getIt.registerLazySingleton(() => SyncAttendanceUseCase(getIt()));

  // 6. Sync Manager
  getIt.registerLazySingleton(
    () => SyncManager(
      connectivityService: getIt(),
      syncBatchOfflineUseCase: getIt(),
    ),
  );

  // 7. Presentation Providers
  getIt.registerFactory(
    () => AuthProvider(
      loginUseCase: getIt(),
      logoutUseCase: getIt(),
      getCurrentUserUseCase: getIt(),
      refreshUserProfileUseCase: getIt(),
    ),
  );
  getIt.registerFactoryParam<AttendanceProvider, AuthProvider?, void>(
    (authProvider, _) => AttendanceProvider(
      checkInUseCase: getIt(),
      checkOutUseCase: getIt(),
      getTodayStatusUseCase: getIt(),
      getAttendanceHistoryUseCase: getIt(),
      getCurrentLocationUseCase: getIt(),
      syncBatchOfflineUseCase: getIt(),
      connectivityService: getIt(),
      authProvider: authProvider,
    ),
  );
}
