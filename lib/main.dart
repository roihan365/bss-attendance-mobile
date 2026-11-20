import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'core/config/app_config.dart';
import 'core/theme/app_colors.dart';
import 'data/datasources/shared_prefs_data_source.dart';
import 'data/datasources/geolocator_location_service.dart';
import 'data/datasources/attendance_api_data_source.dart';
import 'data/datasources/auth_api_data_source.dart';
import 'data/datasources/connectivity_service.dart';
import 'data/repositories/attendance_repository_impl.dart';
import 'data/repositories/auth_repository_impl.dart';
import 'domain/usecases/check_in.dart';
import 'domain/usecases/check_out.dart';
import 'domain/usecases/get_today_records.dart';
import 'domain/usecases/get_all_records.dart';
import 'domain/usecases/get_current_location.dart';
import 'domain/usecases/sync_attendance.dart';
import 'domain/usecases/login.dart';
import 'domain/usecases/logout.dart';
import 'domain/usecases/get_current_user.dart';
import 'presentation/providers/attendance_provider.dart';
import 'presentation/providers/auth_provider.dart';
import 'presentation/screens/login_screen.dart';
import 'presentation/screens/home_screen.dart';
import 'presentation/screens/history_screen.dart';
import 'presentation/screens/profile_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppConfig.initialize();

  final baseUrl = AppConfig.baseUrl;

  // Data Sources
  final localDataSource = SharedPrefsDataSource();
  final locationService = GeolocatorLocationService();
  final connectivityService = ConnectivityService();
  final authApiDataSource = AuthApiDataSource(baseUrl: baseUrl);

  // Auth Repository
  final authRepository = AuthRepositoryImpl(
    remoteDataSource: authApiDataSource,
  );

  // Attendance API Data Source with token getter
  final attendanceApiDataSource = AttendanceApiDataSource(
    baseUrl: baseUrl,
    getToken: () => authRepository.getToken(),
  );

  // Attendance Repository
  final attendanceRepository = AttendanceRepositoryImpl(
    localDataSource: localDataSource,
    locationService: locationService,
    remoteDataSource: attendanceApiDataSource,
    connectivityService: connectivityService,
    getUserId: () async => (await authRepository.getCurrentUser())?.id,
  );

  // Use Cases - Auth
  final loginUseCase = LoginUseCase(authRepository);
  final logoutUseCase = LogoutUseCase(authRepository);
  final getCurrentUserUseCase = GetCurrentUserUseCase(authRepository);

  // Use Cases - Attendance
  final checkInUseCase = CheckInUseCase(attendanceRepository);
  final checkOutUseCase = CheckOutUseCase(attendanceRepository);
  final getTodayRecordsUseCase = GetTodayRecordsUseCase(attendanceRepository);
  final getAllRecordsUseCase = GetAllRecordsUseCase(attendanceRepository);
  final getCurrentLocationUseCase = GetCurrentLocationUseCase(
    attendanceRepository,
  );
  final syncAttendanceUseCase = SyncAttendanceUseCase(attendanceRepository);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (context) => AuthProvider(
            loginUseCase: loginUseCase,
            logoutUseCase: logoutUseCase,
            getCurrentUserUseCase: getCurrentUserUseCase,
          ),
        ),
        ChangeNotifierProxyProvider<AuthProvider, AttendanceProvider>(
          create: (context) => AttendanceProvider(
            checkInUseCase: checkInUseCase,
            checkOutUseCase: checkOutUseCase,
            getTodayRecordsUseCase: getTodayRecordsUseCase,
            getAllRecordsUseCase: getAllRecordsUseCase,
            getCurrentLocationUseCase: getCurrentLocationUseCase,
            syncAttendanceUseCase: syncAttendanceUseCase,
            connectivityService: connectivityService,
            authProvider: null,
          ),
          update: (context, authProvider, attendanceProvider) {
            return AttendanceProvider(
              checkInUseCase: checkInUseCase,
              checkOutUseCase: checkOutUseCase,
              getTodayRecordsUseCase: getTodayRecordsUseCase,
              getAllRecordsUseCase: getAllRecordsUseCase,
              getCurrentLocationUseCase: getCurrentLocationUseCase,
              syncAttendanceUseCase: syncAttendanceUseCase,
              connectivityService: connectivityService,
              authProvider: authProvider,
            );
          },
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return MaterialApp(
      title: 'BSS Attendance',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.background,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.steelBlue,
          primary: AppColors.steelBlue,
          surface: Colors.white,
          brightness: Brightness.light,
        ),
        textTheme: GoogleFonts.plusJakartaSansTextTheme(
          Theme.of(context).textTheme,
        ),
        appBarTheme: const AppBarTheme(
          elevation: 0,
          centerTitle: true,
          backgroundColor: Colors.transparent,
          systemOverlayStyle: SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.dark,
          ),
        ),
      ),
      home: authProvider.isLoggedIn
          ? const AttendanceHomePage()
          : const LoginScreen(),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/home': (context) => const AttendanceHomePage(),
      },
    );
  }
}

class AttendanceHomePage extends StatefulWidget {
  const AttendanceHomePage({super.key});

  @override
  AttendanceHomePageState createState() => AttendanceHomePageState();
}

class AttendanceHomePageState extends State<AttendanceHomePage> {
  int _selectedIndex = 0;

  void setSelectedIndex(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: IndexedStack(
          index: _selectedIndex,
          children: const [HomeScreen(), HistoryScreen(), ProfileScreen()],
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: AppColors.borderSubtle, width: 1)),
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (index) {
            setState(() {
              _selectedIndex = index;
            });
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          elevation: 0,
          selectedItemColor: AppColors.steelBlue,
          unselectedItemColor: AppColors.textMuted,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_rounded),
              label: 'Beranda',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.history_rounded),
              label: 'Riwayat',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline_rounded),
              activeIcon: Icon(Icons.person_rounded),
              label: 'Profil',
            ),
          ],
        ),
      ),
    );
  }
}
