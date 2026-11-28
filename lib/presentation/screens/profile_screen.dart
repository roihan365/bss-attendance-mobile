import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/di/injection.dart';
import '../../core/security/biometric_auth_service.dart';
import '../../core/security/secure_storage_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../components/components.dart';
import '../providers/attendance_provider.dart';
import '../providers/auth_provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final SecureStorageService _secureStorage = getIt<SecureStorageService>();
  final BiometricAuthService _biometricAuth = getIt<BiometricAuthService>();

  bool _isBiometricEnabled = false;
  bool _isLoadingBiometric = true;

  @override
  void initState() {
    super.initState();
    _loadBiometricPreference();
  }

  Future<void> _loadBiometricPreference() async {
    try {
      final enabled = await _secureStorage.isBiometricEnabled();
      if (mounted) {
        setState(() {
          _isBiometricEnabled = enabled;
          _isLoadingBiometric = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoadingBiometric = false);
      }
    }
  }

  Future<void> _handleToggleBiometric(bool value) async {
    if (value) {
      final isAvailable = await _biometricAuth.isBiometricAvailable();
      if (!isAvailable) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Sensor biometrik tidak tersedia atau belum didaftarkan di perangkat ini.'),
              backgroundColor: AppColors.errorRed,
            ),
          );
        }
        return;
      }

      final authenticated = await _biometricAuth.authenticate(
        reason: 'Pindai sidik jari atau wajah untuk mengaktifkan login biometrik',
      );

      if (!authenticated) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Verifikasi biometrik gagal.'),
              backgroundColor: AppColors.errorRed,
            ),
          );
        }
        return;
      }
    }

    await _secureStorage.setBiometricEnabled(value);
    if (mounted) {
      setState(() => _isBiometricEnabled = value);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            value
                ? 'Login Biometrik aktif. Anda dapat masuk dengan sidik jari/wajah.'
                : 'Login Biometrik dinonaktifkan.',
          ),
          backgroundColor: value ? AppColors.emeraldGreen : AppColors.steelBlue,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _handleLogout(BuildContext context, AuthProvider authProvider) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Konfirmasi Logout', style: AppTextStyles.h2),
        content: Text(
          'Apakah Anda yakin ingin keluar dari akun ini? Data antrean offline tetap aman di perangkat.',
          style: AppTextStyles.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Batal', style: AppTextStyles.buttonText.copyWith(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Keluar', style: AppTextStyles.buttonText.copyWith(color: AppColors.errorRed)),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      await authProvider.logout();
      if (context.mounted) {
        Navigator.pushReplacementNamed(context, '/login');
      }
    }
  }

  Future<void> _handleSync(BuildContext context, AttendanceProvider provider) async {
    try {
      final result = await provider.syncPending();
      if (context.mounted && result != null) {
        final message = result.totalSaved > 0
            ? 'Berhasil menyinkronkan ${result.totalSaved} presensi ke server.'
            : (result.totalSkipped > 0
                ? ' ${result.totalSkipped} data dilewati server (duplikat).'
                : ' Tidak ada antrean baru yang tersimpan.');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: result.totalSaved > 0 ? AppColors.emeraldGreen : AppColors.steelBlue,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal sinkronisasi: ${e.toString().replaceFirst('Exception: ', '')}'),
            backgroundColor: AppColors.errorRed,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _showSopBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.lightBlueBackground,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.menu_book_rounded, color: AppColors.steelBlue, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Text('SOP Presensi Karyawan', style: AppTextStyles.h2),
                ],
              ),
              const SizedBox(height: 16),
              _buildSopItem('1', 'Jam Operasional Presensi', 'Presensi Masuk dibuka mulai 06:30 hingga 08:30 WIB. Presensi Pulang dapat dilakukan setelah pukul 17:00 WIB.'),
              const SizedBox(height: 12),
              _buildSopItem('2', 'Validasi Lokasi & Fake GPS', 'Aplikasi dilengkapi proteksi Anti-Mock Location. Penggunaan Fake GPS atau simulator akan otomatis menggugurkan catatan kehadiran.'),
              const SizedBox(height: 12),
              _buildSopItem('3', 'Mode Luar Jaringan (Offline-First)', 'Di lokasi proyek tanpa sinyal internet, presensi tetap tersimpan otomatis di perangkat dan akan disinkronkan saat sinyal terdeteksi kembali.'),
              const SizedBox(height: 12),
              _buildSopItem('4', 'Kendala & Pengaduan', 'Jika mengalami kendala teknis atau pergeseran titik koordinat, segera hubungi Divisi HRD Site Operasional.'),
              const SizedBox(height: 20),
              AppButton(
                text: 'Saya Mengerti',
                onPressed: () => Navigator.pop(ctx),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSopItem(String number, String title, String description) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: const BoxDecoration(
            color: AppColors.lightBlueBackground,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              number,
              style: AppTextStyles.badgeText.copyWith(color: AppColors.steelBlue, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 2),
              Text(description, style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
            ],
          ),
        ),
      ],
    );
  }

  void _showHelpdeskDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.support_agent_rounded, color: AppColors.steelBlue),
            const SizedBox(width: 10),
            Text('Pusat Bantuan HRD', style: AppTextStyles.h2),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Silakan hubungi perwakilan HRD Site melalui kontak berikut:',
              style: AppTextStyles.bodyMedium,
            ),
            const SizedBox(height: 12),
            _buildContactRow(Icons.email_outlined, 'Email HRD', 'hr.operations@bss.co.id'),
            const SizedBox(height: 8),
            _buildContactRow(Icons.phone_outlined, 'Hotline HRD', '+62 811-2345-6789'),
            const SizedBox(height: 8),
            _buildContactRow(Icons.schedule_rounded, 'Jam Layanan', 'Senin - Jumat, 08:00 - 17:00 WIB'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Tutup', style: AppTextStyles.buttonText.copyWith(color: AppColors.steelBlue)),
          ),
        ],
      ),
    );
  }

  Widget _buildContactRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.steelBlue),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted)),
              Text(value, style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final attendanceProvider = Provider.of<AttendanceProvider>(context);

    final user = authProvider.currentUser;
    final userName = user?.name ?? 'Karyawan PT BSS';
    final userEmail = user?.email ?? 'karyawan@bss.co.id';
    final userId = user?.employeeCode ??
        (user?.id != null ? 'BSS-${user!.id.toString().padLeft(3, '0')}' : 'BSS-001');
    final initial = userName.isNotEmpty ? userName[0].toUpperCase() : 'B';

    final totalCheckIns = attendanceProvider.records.where((r) => r.type == 'checkin').length;
    final totalCheckOuts = attendanceProvider.records.where((r) => r.type == 'checkout').length;
    final pendingCount = attendanceProvider.pendingSyncCount;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.only(left: 14, top: 10, bottom: 10),
          child: Image.asset('assets/images/bss_logo.png', fit: BoxFit.contain),
        ),
        title: Text('Profil Karyawan', style: AppTextStyles.h2),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // User Header Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.borderSubtle, width: 1.2),
              ),
              child: Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: AppColors.lightBlueBackground,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.steelBlue.withValues(alpha: 0.3), width: 1.5),
                    ),
                    child: Center(
                      child: Text(
                        initial,
                        style: AppTextStyles.h1.copyWith(color: AppColors.steelBlue),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(userName, style: AppTextStyles.h2),
                        const SizedBox(height: 2),
                        Text(userEmail, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary)),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.lightBlueBackground,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            user?.effectivePositionTitle ?? 'Karyawan Operasional Lapangan',
                            style: AppTextStyles.badgeText.copyWith(color: AppColors.steelBlue, fontSize: 10),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Statistics Summary Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.borderSubtle, width: 1.2),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Statistik Kehadiran', style: AppTextStyles.h3),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatItem('Total Masuk', '$totalCheckIns', AppColors.emeraldGreen),
                      ),
                      Container(width: 1, height: 40, color: AppColors.borderSubtle),
                      Expanded(
                        child: _buildStatItem('Total Pulang', '$totalCheckOuts', AppColors.safetyAmber),
                      ),
                      Container(width: 1, height: 40, color: AppColors.borderSubtle),
                      Expanded(
                        child: _buildStatItem('Tersimpan Lokal', '$pendingCount', AppColors.steelBlue),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Section 1: Detail Kepegawaian & Pekerjaan
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.borderSubtle, width: 1.2),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.badge_outlined, size: 20, color: AppColors.steelBlue),
                      const SizedBox(width: 8),
                      Text('Data & Detail Kepegawaian', style: AppTextStyles.h3),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _buildEmploymentRow('ID Karyawan / NIP', userId),
                  const Divider(height: 18, color: AppColors.borderSubtle),
                  _buildEmploymentRow('Divisi / Departemen', user?.division?.name ?? 'Operasional & Engineering Site'),
                  const Divider(height: 18, color: AppColors.borderSubtle),
                  _buildEmploymentRow(
                    'Atasan 1',
                    user?.supervisor != null
                        ? '${user!.supervisor!.name}${user.supervisor!.positionTitle != null ? " (${user.supervisor!.positionTitle})" : ""}'
                        : '-',
                  ),
                  if (user?.supervisor2 != null) ...[
                    const Divider(height: 18, color: AppColors.borderSubtle),
                    _buildEmploymentRow(
                      'Atasan 2',
                      '${user!.supervisor2!.name}${user.supervisor2!.positionTitle != null ? " (${user.supervisor2!.positionTitle})" : ""}',
                    ),
                  ],
                  const Divider(height: 18, color: AppColors.borderSubtle),
                  _buildEmploymentRow(
                    'Mode & Lokasi Kerja',
                    (user?.isFlexibleLocation == true || attendanceProvider.effectiveIsFlexibleLocation)
                        ? 'Lokasi Fleksibel (Bebas Radius)'
                        : (attendanceProvider.effectiveWorkLocations.isNotEmpty
                            ? attendanceProvider.effectiveWorkLocations
                                .map((w) => '${w.name} (Maks ${w.radiusMeters}m)')
                                .join(', ')
                            : 'Site Operasional'),
                  ),
                  const Divider(height: 18, color: AppColors.borderSubtle),
                  _buildEmploymentRow('Status Karyawan', 'Karyawan Tetap (Aktif)', isHighlight: true),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Section 2: Pengaturan Akun & Keamanan Biometrik
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.borderSubtle, width: 1.2),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.security_rounded, size: 20, color: AppColors.steelBlue),
                      const SizedBox(width: 8),
                      Text('Keamanan & Akses Akun', style: AppTextStyles.h3),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.lightBlueBackground,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.fingerprint_rounded, color: AppColors.steelBlue, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Login Biometrik', style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
                            Text(
                              'Masuk menggunakan Sidik Jari / Face ID',
                              style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      if (_isLoadingBiometric)
                        const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      else
                        Switch(
                          value: _isBiometricEnabled,
                          activeThumbColor: AppColors.steelBlue,
                          onChanged: _handleToggleBiometric,
                        ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Section 3: Pusat Bantuan & Kebijakan HRD
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.borderSubtle, width: 1.2),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.help_outline_rounded, size: 20, color: AppColors.steelBlue),
                      const SizedBox(width: 8),
                      Text('Pusat Bantuan & Kebijakan HR', style: AppTextStyles.h3),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Material(
                    color: Colors.transparent,
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                      leading: const Icon(Icons.menu_book_outlined, color: AppColors.steelBlue),
                      title: Text('SOP & Regulasi Presensi Karyawan', style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
                      trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
                      onTap: () => _showSopBottomSheet(context),
                    ),
                  ),
                  const Divider(height: 8, color: AppColors.borderSubtle),
                  Material(
                    color: Colors.transparent,
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                      leading: const Icon(Icons.support_agent_rounded, color: AppColors.steelBlue),
                      title: Text('Hubungi Helpdesk HRD Site', style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
                      trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
                      onTap: () => _showHelpdeskDialog(context),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Offline Sync Manual Action Card (if any pending)
            if (pendingCount > 0)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.safetyAmberLight,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.safetyAmber.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.cloud_upload_outlined, color: AppColors.safetyAmber),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Antrean Offline Tersedia', style: AppTextStyles.h3.copyWith(color: AppColors.safetyAmber)),
                          Text(
                            '$pendingCount data menunggu sinkronisasi online.',
                            style: AppTextStyles.bodySmall.copyWith(color: AppColors.safetyAmber),
                          ),
                        ],
                      ),
                    ),
                    AppButton(
                      text: 'Kirim',
                      width: 80,
                      height: 36,
                      isLoading: attendanceProvider.isSyncing,
                      onPressed: () => _handleSync(context, attendanceProvider),
                      variant: AppButtonVariant.primary,
                    ),
                  ],
                ),
              ),

            // Logout Button
            AppButton(
              text: 'Keluar dari Akun',
              icon: Icons.logout_rounded,
              onPressed: () => _handleLogout(context, authProvider),
              variant: AppButtonVariant.outline,
            ),

            const SizedBox(height: 24),
            Image.asset(
              'assets/images/bss_logo.png',
              height: 36,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 8),
            Text(
              'BSS Attendance Mobile v1.0.0 (Build 1)\nPT BARITO SAMUDRA SEJAHTERA',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: AppTextStyles.h2.copyWith(color: color)),
        const SizedBox(height: 2),
        Text(label, style: AppTextStyles.bodySmall, textAlign: TextAlign.center),
      ],
    );
  }

  Widget _buildEmploymentRow(String label, String value, {bool isHighlight = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
        ),
        if (isHighlight)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.emeraldGreenLight,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              value,
              style: AppTextStyles.badgeText.copyWith(
                color: AppColors.emeraldGreen,
                fontWeight: FontWeight.w700,
              ),
            ),
          )
        else
          Flexible(
            child: Padding(
              padding: const EdgeInsets.only(left: 12),
              child: Text(
                value,
                textAlign: TextAlign.right,
                style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
          ),
      ],
    );
  }
}
