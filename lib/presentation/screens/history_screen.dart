import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../components/components.dart';
import '../providers/attendance_provider.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  String _selectedFilter = 'all'; // 'all' | 'checkin' | 'checkout'
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AttendanceProvider>(context);
    final allRecords = provider.records;

    // Filter data berdasarkan tipe dan query pencarian
    final filteredRecords = allRecords.where((r) {
      if (_selectedFilter == 'checkin' && r.type != 'checkin') return false;
      if (_selectedFilter == 'checkout' && r.type != 'checkout') return false;

      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final matchLocation = r.locationName.toLowerCase().contains(query);
        final matchType = r.type.toLowerCase().contains(query);
        return matchLocation || matchType;
      }
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Riwayat Presensi', style: AppTextStyles.h2),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          AppIconButton(
            icon: Icons.refresh_rounded,
            onPressed: () => provider.refreshAll(),
            tooltip: 'Segarkan Riwayat',
            color: AppColors.steelBlue,
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Column(
        children: [
          // Filter & Search Header
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: AppColors.borderSubtle)),
            ),
            child: Column(
              children: [
                // Search Input
                TextField(
                  controller: _searchController,
                  onChanged: (val) => setState(() => _searchQuery = val.trim()),
                  style: AppTextStyles.bodyMedium,
                  decoration: InputDecoration(
                    hintText: 'Cari lokasi site atau catatan...',
                    hintStyle: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted),
                    prefixIcon: const Icon(Icons.search_rounded, size: 20, color: AppColors.textSecondary),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: AppColors.background,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppColors.borderSubtle),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppColors.borderSubtle),
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                // Filter Chips (Semua, Masuk, Pulang)
                Row(
                  children: [
                    _buildFilterChip('Semua', 'all', allRecords.length),
                    const SizedBox(width: 8),
                    _buildFilterChip(
                      'Presensi Masuk',
                      'checkin',
                      allRecords.where((r) => r.type == 'checkin').length,
                    ),
                    const SizedBox(width: 8),
                    _buildFilterChip(
                      'Presensi Pulang',
                      'checkout',
                      allRecords.where((r) => r.type == 'checkout').length,
                    ),
                  ],
                ),
              ],
            ),
          ),

          // List Riwayat
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => provider.refreshAll(),
              color: AppColors.steelBlue,
              child: filteredRecords.isEmpty
                  ? SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: Padding(
                        padding: const EdgeInsets.only(top: 80),
                        child: EmptyStateView(
                          title: 'Belum Ada Riwayat',
                          message: _searchQuery.isNotEmpty
                              ? 'Tidak ditemukan riwayat yang cocok dengan pencarian Anda.'
                              : 'Presensi yang Anda lakukan di lapangan akan otomatis tercatat di sini.',
                          icon: Icons.history_rounded,
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: filteredRecords.length,
                      itemBuilder: (context, index) {
                        final record = filteredRecords[index];
                        return AttendanceHistoryCard(
                          type: record.type,
                          timestamp: record.timestamp,
                          locationName: record.locationName,
                          isSynced: record.syncStatus,
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value, int count) {
    final isSelected = _selectedFilter == value;
    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.steelBlue : AppColors.background,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppColors.steelBlue : AppColors.borderSubtle,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: AppTextStyles.badgeText.copyWith(
                color: isSelected ? Colors.white : AppColors.textSecondary,
              ),
            ),
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: isSelected ? Colors.white.withValues(alpha: 0.2) : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: AppTextStyles.badgeText.copyWith(
                  fontSize: 10,
                  color: isSelected ? Colors.white : AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
