import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../components/components.dart';
import '../providers/attendance_provider.dart';
import '../providers/auth_provider.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

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

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final attendanceProvider = Provider.of<AttendanceProvider>(context);

    final user = authProvider.currentUser;
    final userName = user?.name ?? 'Karyawan PT BSS';
    final userEmail = user?.email ?? 'karyawan@bss.co.id';
    final initial = userName.isNotEmpty ? userName[0].toUpperCase() : 'B';

    final totalCheckIns = attendanceProvider.records.where((r) => r.type == 'checkin').length;
    final totalCheckOuts = attendanceProvider.records.where((r) => r.type == 'checkout').length;
    final pendingCount = attendanceProvider.pendingSyncCount;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
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
                            'Karyawan Operasional Lapangan',
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

            // Security & Integrity Info Card
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
                  Text('Integritas & Keamanan Perangkat', style: AppTextStyles.h3),
                  const SizedBox(height: 12),
                  _buildSecurityRow(Icons.gps_fixed_rounded, 'Anti-Mock GPS (Fake GPS)', 'Aktif & Terproteksi'),
                  const Divider(height: 16, color: AppColors.borderSubtle),
                  _buildSecurityRow(Icons.vpn_key_rounded, 'Penyimpanan Enkripsi Keystore', 'Aktif'),
                  const Divider(height: 16, color: AppColors.borderSubtle),
                  _buildSecurityRow(Icons.storage_rounded, 'Database Lokal SQLite', 'Aktif (Offline-First)'),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Offline Sync Manual Action Card
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
                      onPressed: () => attendanceProvider.syncPending(),
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
            Text(
              'BSS Attendance Mobile v1.0.0 (Build 1)\nPT Bumi Sukses Sinergi',
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

  Widget _buildSecurityRow(IconData icon, String title, String subtitle) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.steelBlue),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
              Text(subtitle, style: AppTextStyles.bodySmall.copyWith(color: AppColors.emeraldGreen)),
            ],
          ),
        ),
        const Icon(Icons.check_circle_rounded, size: 16, color: AppColors.emeraldGreen),
      ],
    );
  }
}
