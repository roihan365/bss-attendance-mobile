import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../domain/entities/attendance_record.dart';
import '../components/components.dart';
import '../providers/attendance_provider.dart';

enum DateFilterPreset { all, today, last7Days, thisMonth, custom }

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  String _selectedTypeFilter = 'all'; // 'all' | 'checkin' | 'checkout'
  DateFilterPreset _selectedDatePreset = DateFilterPreset.all;
  DateTimeRange? _customDateRange;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _pickCustomDateRange() async {
    final now = DateTime.now();
    final initialDateRange = _customDateRange ??
        DateTimeRange(
          start: now.subtract(const Duration(days: 7)),
          end: now,
        );

    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: now.add(const Duration(days: 1)),
      initialDateRange: initialDateRange,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.steelBlue,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDatePreset = DateFilterPreset.custom;
        _customDateRange = picked;
      });
    }
  }

  bool _matchesDateFilter(DateTime date) {
    final now = DateTime.now();
    final target = DateTime(date.year, date.month, date.day);
    final today = DateTime(now.year, now.month, now.day);

    switch (_selectedDatePreset) {
      case DateFilterPreset.all:
        return true;
      case DateFilterPreset.today:
        return target.isAtSameMomentAs(today);
      case DateFilterPreset.last7Days:
        final sevenDaysAgo = today.subtract(const Duration(days: 6));
        return !target.isBefore(sevenDaysAgo) && !target.isAfter(today);
      case DateFilterPreset.thisMonth:
        return date.year == now.year && date.month == now.month;
      case DateFilterPreset.custom:
        if (_customDateRange == null) return true;
        final start = DateTime(
          _customDateRange!.start.year,
          _customDateRange!.start.month,
          _customDateRange!.start.day,
        );
        final end = DateTime(
          _customDateRange!.end.year,
          _customDateRange!.end.month,
          _customDateRange!.end.day,
          23,
          59,
          59,
        );
        return !date.isBefore(start) && !date.isAfter(end);
    }
  }

  Map<String, List<AttendanceRecord>> _groupRecordsByDay(List<AttendanceRecord> records) {
    final Map<String, List<AttendanceRecord>> groups = {};

    for (final record in records) {
      final key = DateFormat('yyyy-MM-dd').format(record.timestamp);
      if (!groups.containsKey(key)) {
        groups[key] = [];
      }
      groups[key]!.add(record);
    }

    return groups;
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AttendanceProvider>(context);
    final allRecords = provider.records;

    // Filter records by type, date preset, and search query
    final filteredRecords = allRecords.where((r) {
      // 1. Type Filter
      if (_selectedTypeFilter == 'checkin' && r.type != 'checkin') return false;
      if (_selectedTypeFilter == 'checkout' && r.type != 'checkout') return false;

      // 2. Date Filter
      if (!_matchesDateFilter(r.timestamp)) return false;

      // 3. Search Query Filter
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final matchLocation = r.locationName.toLowerCase().contains(query);
        final matchType = r.type.toLowerCase().contains(query);
        return matchLocation || matchType;
      }

      return true;
    }).toList();

    // Group filtered records by date string (yyyy-MM-dd)
    final groupedRecords = _groupRecordsByDay(filteredRecords);
    final sortedDateKeys = groupedRecords.keys.toList()
      ..sort((a, b) => b.compareTo(a)); // Newest date first

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.only(left: 14, top: 10, bottom: 10),
          child: Image.asset('assets/images/bss_logo.png', fit: BoxFit.contain),
        ),
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
          // Filter & Search Controls Header
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: AppColors.borderSubtle)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
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

                // Date Filter Chips Row (Semua, Hari Ini, 7 Hari, Bulan Ini, Pilih Tanggal)
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    children: [
                      _buildDateFilterChip('Semua Waktu', DateFilterPreset.all),
                      const SizedBox(width: 6),
                      _buildDateFilterChip('Hari Ini', DateFilterPreset.today),
                      const SizedBox(width: 6),
                      _buildDateFilterChip('7 Hari Terakhir', DateFilterPreset.last7Days),
                      const SizedBox(width: 6),
                      _buildDateFilterChip('Bulan Ini', DateFilterPreset.thisMonth),
                      const SizedBox(width: 6),
                      _buildCustomDateRangeChip(),
                    ],
                  ),
                ),

                const SizedBox(height: 8),

                // Type Filter Chips Row (Semua Tipe, Masuk, Pulang)
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    children: [
                      _buildTypeFilterChip('Semua Sesi', 'all', allRecords.length),
                      const SizedBox(width: 6),
                      _buildTypeFilterChip(
                        'Masuk',
                        'checkin',
                        allRecords.where((r) => r.type == 'checkin').length,
                      ),
                      const SizedBox(width: 6),
                      _buildTypeFilterChip(
                        'Pulang',
                        'checkout',
                        allRecords.where((r) => r.type == 'checkout').length,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Grouped List of Attendance Cards
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => provider.refreshAll(),
              color: AppColors.steelBlue,
              child: sortedDateKeys.isEmpty
                  ? SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: Padding(
                        padding: const EdgeInsets.only(top: 80),
                        child: EmptyStateView(
                          title: 'Belum Ada Riwayat',
                          message: _searchQuery.isNotEmpty || _selectedDatePreset != DateFilterPreset.all
                              ? 'Tidak ditemukan riwayat yang cocok dengan filter atau tanggal yang dipilih.'
                              : 'Presensi yang Anda lakukan di lapangan akan otomatis tercatat di sini.',
                          icon: Icons.history_rounded,
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: sortedDateKeys.length,
                      itemBuilder: (context, index) {
                        final dateKey = sortedDateKeys[index];
                        final dayRecords = groupedRecords[dateKey]!;
                        final firstTimestamp = dayRecords.first.timestamp;
                        final date = DateTime(
                          firstTimestamp.year,
                          firstTimestamp.month,
                          firstTimestamp.day,
                        );

                        return DailyAttendanceGroupCard(
                          date: date,
                          records: dayRecords,
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateFilterChip(String label, DateFilterPreset preset) {
    final isSelected = _selectedDatePreset == preset;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedDatePreset = preset;
          if (preset != DateFilterPreset.custom) {
            _customDateRange = null;
          }
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.steelBlue : AppColors.background,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppColors.steelBlue : AppColors.borderSubtle,
          ),
        ),
        child: Text(
          label,
          style: AppTextStyles.badgeText.copyWith(
            color: isSelected ? Colors.white : AppColors.textSecondary,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildCustomDateRangeChip() {
    final isSelected = _selectedDatePreset == DateFilterPreset.custom && _customDateRange != null;
    final label = isSelected
        ? '${DateFormat('d MMM').format(_customDateRange!.start)} - ${DateFormat('d MMM').format(_customDateRange!.end)}'
        : 'Pilih Tanggal';

    return GestureDetector(
      onTap: _pickCustomDateRange,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
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
            Icon(
              Icons.calendar_month_rounded,
              size: 13,
              color: isSelected ? Colors.white : AppColors.textSecondary,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: AppTextStyles.badgeText.copyWith(
                color: isSelected ? Colors.white : AppColors.textSecondary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
            if (isSelected) ...[
              const SizedBox(width: 4),
              GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedDatePreset = DateFilterPreset.all;
                    _customDateRange = null;
                  });
                },
                child: const Icon(Icons.close_rounded, size: 14, color: Colors.white),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTypeFilterChip(String label, String value, int count) {
    final isSelected = _selectedTypeFilter == value;
    return GestureDetector(
      onTap: () => setState(() => _selectedTypeFilter = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.slateNavy : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected ? AppColors.slateNavy : AppColors.borderSubtle,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: AppTextStyles.badgeText.copyWith(
                color: isSelected ? Colors.white : AppColors.textSecondary,
                fontSize: 11,
              ),
            ),
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: isSelected ? Colors.white.withValues(alpha: 0.2) : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(8),
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
