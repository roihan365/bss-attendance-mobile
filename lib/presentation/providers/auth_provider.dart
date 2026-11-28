import 'package:flutter/material.dart';
import '../../core/navigation/app_navigator.dart';
import '../../core/theme/app_colors.dart';
import '../../domain/entities/user.dart';
import '../../domain/usecases/login.dart';
import '../../domain/usecases/logout.dart';
import '../../domain/usecases/get_current_user.dart';
import '../../domain/usecases/refresh_user_profile.dart';

class AuthProvider extends ChangeNotifier {
  final LoginUseCase loginUseCase;
  final LogoutUseCase logoutUseCase;
  final GetCurrentUserUseCase getCurrentUserUseCase;
  final RefreshUserProfileUseCase? refreshUserProfileUseCase;
  final Future<void> Function()? clearLocalSession;

  User? _currentUser;
  bool _isLoading = false;
  bool _isHandlingSessionExpired = false;

  User? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null && _currentUser!.token != null && _currentUser!.token!.isNotEmpty;
  bool get isLoading => _isLoading;
  String? get token => _currentUser?.token;

  AuthProvider({
    required this.loginUseCase,
    required this.logoutUseCase,
    required this.getCurrentUserUseCase,
    this.refreshUserProfileUseCase,
    this.clearLocalSession,
  }) {
    _loadUser();
  }

  Future<void> _loadUser() async {
    _isLoading = true;
    notifyListeners();
    try {
      _currentUser = await getCurrentUserUseCase();
    } catch (_) {
      _currentUser = null;
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> login(String email, String password) async {
    _isLoading = true;
    _isHandlingSessionExpired = false;
    notifyListeners();
    try {
      _currentUser = await loginUseCase(email, password);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();
    try {
      await logoutUseCase();
      _currentUser = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Dipanggil otomatis saat server mengembalikan 401 Unauthorized (token expired / tidak valid).
  Future<void> handleSessionExpired() async {
    if (_isHandlingSessionExpired || !isLoggedIn) return;
    _isHandlingSessionExpired = true;

    try {
      _currentUser = null;
      if (clearLocalSession != null) {
        await clearLocalSession!();
      }
      notifyListeners();

      // Tampilkan notifikasi sesi berakhir
      AppNavigator.scaffoldMessengerKey.currentState?.clearSnackBars();
      AppNavigator.scaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.lock_clock_rounded, color: Colors.white, size: 20),
              SizedBox(width: 10),
              Expanded(
                child: Text('Sesi Anda telah berakhir. Silakan login kembali.'),
              ),
            ],
          ),
          backgroundColor: AppColors.errorRed,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );

      // Arahkan langsung ke halaman login dan hapus seluruh stack navigasi
      AppNavigator.navigatorKey.currentState?.pushNamedAndRemoveUntil(
        '/login',
        (route) => false,
      );
    } finally {
      _isHandlingSessionExpired = false;
    }
  }

  Future<void> refreshUser() async {
    if (refreshUserProfileUseCase != null && isLoggedIn) {
      try {
        final updated = await refreshUserProfileUseCase!();
        if (updated != null) {
          _currentUser = updated;
          notifyListeners();
          return;
        }
      } catch (_) {}
    }
    await _loadUser();
  }
}
