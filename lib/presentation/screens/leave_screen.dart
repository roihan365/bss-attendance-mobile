import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../domain/entities/leave_request.dart';
import '../../domain/entities/leave_type.dart';
import '../components/components.dart';
import '../providers/leave_provider.dart';

class LeaveScreen extends StatefulWidget {
  const LeaveScreen({super.key});

  @override
  State<LeaveScreen> createState() => _LeaveScreenState();
}

class _LeaveScreenState extends State<LeaveScreen> {
  int _activeTab = 0; // 0 = Pengajuan Saya, 1 = Persetujuan Bawahan

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<LeaveProvider>(context, listen: false);
      if (provider.leaveTypes.isEmpty && provider.myRequests.isEmpty && !provider.isLoading) {
        provider.loadInitialData();
      }
    });
  }

  void _showSnackBar(String message, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<void> _openAttachment(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      _showSnackBar('Tidak dapat membuka lampiran.', AppColors.errorRed);
    }
  }

  void _showSubmitLeaveModal(BuildContext context, LeaveProvider provider) {
    if (provider.leaveTypes.isEmpty) {
      _showSnackBar('Daftar jenis izin sedang dimuat atau belum tersedia.', AppColors.safetyAmber);
      provider.refreshAll();
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _SubmitLeaveBottomSheet(
        leaveTypes: provider.leaveTypes,
        onSubmitted: (typeId, startDate, endDate, reason, attachmentPath) async {
          await provider.submitLeaveRequest(
            leaveTypeId: typeId,
            startDate: startDate,
            endDate: endDate,
            reason: reason,
            attachmentPath: attachmentPath,
          );
          if (mounted) {
            _showSnackBar('Pengajuan izin berhasil dikirim dan menunggu persetujuan.', AppColors.emeraldGreen);
          }
        },
      ),
    );
  }

  Future<void> _handleCancelRequest(LeaveProvider provider, LeaveRequest req) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Batalkan Pengajuan?', style: AppTextStyles.h2),
        content: Text(
          'Pengajuan ${req.leaveTypeName} (${req.startDate} s/d ${req.endDate}) akan dibatalkan.',
          style: AppTextStyles.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Kembali', style: AppTextStyles.buttonText.copyWith(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Ya, Batalkan', style: AppTextStyles.buttonText.copyWith(color: AppColors.errorRed)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await provider.cancelLeaveRequest(req.id);
        _showSnackBar('Pengajuan izin berhasil dibatalkan.', AppColors.steelBlue);
      } catch (e) {
        _showSnackBar(e.toString().replaceFirst('Exception: ', ''), AppColors.errorRed);
      }
    }
  }

  Future<void> _handleProcessApproval(
    LeaveProvider provider,
    LeaveRequest req,
    String action,
  ) async {
    final isApprove = action == 'approve';
    final notesController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          isApprove ? 'Setujui Pengajuan?' : 'Tolak Pengajuan?',
          style: AppTextStyles.h2,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${req.requesterName ?? "Karyawan"} • ${req.leaveTypeName} (${req.totalDays} hari)',
              style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: notesController,
              maxLines: 3,
              maxLength: 500,
              decoration: InputDecoration(
                hintText: isApprove ? 'Catatan persetujuan (opsional)...' : 'Alasan penolakan (opsional)...',
                hintStyle: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted),
                filled: true,
                fillColor: AppColors.background,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColors.borderSubtle),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Batal', style: AppTextStyles.buttonText.copyWith(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: isApprove ? AppColors.emeraldGreen : AppColors.errorRed,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(isApprove ? 'Setujui' : 'Tolak'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await provider.processApproval(
          leaveRequestId: req.id,
          action: action,
          notes: notesController.text,
        );
        _showSnackBar(
          isApprove ? 'Pengajuan berhasil disetujui.' : 'Pengajuan berhasil ditolak.',
          isApprove ? AppColors.emeraldGreen : AppColors.steelBlue,
        );
      } catch (e) {
        _showSnackBar(e.toString().replaceFirst('Exception: ', ''), AppColors.errorRed);
      }
    }
    notesController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<LeaveProvider>(context);
    final isApprover = provider.canApproveLeave;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.only(left: 14, top: 10, bottom: 10),
          child: Image.asset('assets/images/bss_logo.png', fit: BoxFit.contain),
        ),
        title: Text('Izin & Cuti', style: AppTextStyles.h2),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          AppIconButton(
            icon: Icons.refresh_rounded,
            onPressed: provider.isLoading ? null : () => provider.refreshAll(),
            tooltip: 'Segarkan Data',
            color: AppColors.steelBlue,
          ),
          const SizedBox(width: 12),
        ],
      ),
      floatingActionButton: _activeTab == 0
          ? FloatingActionButton.extended(
              onPressed: () => _showSubmitLeaveModal(context, provider),
              backgroundColor: AppColors.steelBlue,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Ajukan Izin', style: TextStyle(fontWeight: FontWeight.w600)),
            )
          : null,
      body: Column(
        children: [
          if (isApprover)
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
              child: Row(
                children: [
                  Expanded(
                    child: _buildTabButton(
                      label: 'Pengajuan Saya',
                      isSelected: _activeTab == 0,
                      onTap: () => setState(() => _activeTab = 0),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildTabButton(
                      label: 'Persetujuan',
                      badgeCount: provider.pendingApprovalCount,
                      isSelected: _activeTab == 1,
                      onTap: () => setState(() => _activeTab = 1),
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => provider.refreshAll(),
              color: AppColors.steelBlue,
              child: provider.isLoading && provider.myRequests.isEmpty && provider.pendingApprovals.isEmpty
                  ? const Center(child: CircularProgressIndicator(color: AppColors.steelBlue))
                  : (_activeTab == 0 || !isApprover)
                      ? _buildMyRequestsList(provider)
                      : _buildPendingApprovalsList(provider),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    int badgeCount = 0,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.steelBlue : AppColors.background,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? AppColors.steelBlue : AppColors.borderSubtle,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: AppTextStyles.bodySmall.copyWith(
                color: isSelected ? Colors.white : AppColors.textSecondary,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (badgeCount > 0) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white : AppColors.safetyAmber,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$badgeCount',
                  style: AppTextStyles.badgeText.copyWith(
                    fontSize: 10,
                    color: isSelected ? AppColors.steelBlue : Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMyRequestsList(LeaveProvider provider) {
    if (provider.myRequests.isEmpty) {
      return SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.only(top: 80),
          child: EmptyStateView(
            title: 'Belum Ada Pengajuan Izin',
            message: 'Tekan tombol "+ Ajukan Izin" di bawah untuk mengajukan cuti, sakit, atau izin dinas.',
            icon: Icons.event_note_rounded,
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
      itemCount: provider.myRequests.length,
      itemBuilder: (context, index) {
        final req = provider.myRequests[index];
        return _buildLeaveRequestCard(req, provider);
      },
    );
  }

  Widget _buildPendingApprovalsList(LeaveProvider provider) {
    if (provider.pendingApprovals.isEmpty) {
      return SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.only(top: 80),
          child: EmptyStateView(
            title: 'Tidak Ada Antrean Persetujuan',
            message: 'Semua pengajuan izin bawahan yang menjadi giliran Anda sudah diproses.',
            icon: Icons.verified_outlined,
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: provider.pendingApprovals.length,
      itemBuilder: (context, index) {
        final req = provider.pendingApprovals[index];
        return _buildApprovalCard(req, provider);
      },
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bg;
    Color fg;
    String label;

    switch (status.toLowerCase()) {
      case 'approved':
        bg = AppColors.emeraldGreenLight;
        fg = AppColors.emeraldGreen;
        label = 'Disetujui';
        break;
      case 'rejected':
        bg = AppColors.errorRedLight;
        fg = AppColors.errorRed;
        label = 'Ditolak';
        break;
      case 'cancelled':
        bg = Colors.grey.shade200;
        fg = AppColors.textSecondary;
        label = 'Dibatalkan';
        break;
      default:
        bg = AppColors.safetyAmberLight;
        fg = AppColors.safetyAmber;
        label = 'Menunggu';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
      child: Text(
        label,
        style: AppTextStyles.badgeText.copyWith(color: fg, fontWeight: FontWeight.w700),
      ),
    );
  }

  Widget _buildLeaveRequestCard(LeaveRequest req, LeaveProvider provider) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.lightBlueBackground,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        req.leaveTypeName,
                        style: AppTextStyles.badgeText.copyWith(
                          color: AppColors.steelBlue,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${req.totalDays} Hari',
                      style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              _buildStatusBadge(req.status),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.date_range_rounded, size: 15, color: AppColors.textSecondary),
              const SizedBox(width: 6),
              Text(
                req.startDate == req.endDate
                    ? req.startDate
                    : '${req.startDate} s/d ${req.endDate}',
                style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            req.reason,
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
          ),
          if (req.attachmentUrl != null && req.attachmentUrl!.isNotEmpty) ...[
            const SizedBox(height: 10),
            InkWell(
              onTap: () => _openAttachment(req.attachmentUrl!),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.borderSubtle),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.attach_file_rounded, size: 15, color: AppColors.steelBlue),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        req.attachmentName ?? 'Lihat Lampiran',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.steelBlue,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          if (req.approvals.isNotEmpty) ...[
            const Divider(height: 20, color: AppColors.borderSubtle),
            Text(
              'Alur Persetujuan',
              style: AppTextStyles.badgeText.copyWith(color: AppColors.textMuted),
            ),
            const SizedBox(height: 6),
            ...req.approvals.map((step) {
              IconData stepIcon = Icons.hourglass_top_rounded;
              Color stepColor = AppColors.safetyAmber;
              if (step.status == 'approved') {
                stepIcon = Icons.check_circle_rounded;
                stepColor = AppColors.emeraldGreen;
              } else if (step.status == 'rejected') {
                stepIcon = Icons.cancel_rounded;
                stepColor = AppColors.errorRed;
              }
              return Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(stepIcon, size: 15, color: stepColor),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Tahap ${step.stepLevel}: ${step.approverName}${step.approverPosition != null ? " (${step.approverPosition})" : ""}',
                            style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w600),
                          ),
                          if (step.notes != null && step.notes!.isNotEmpty)
                            Text(
                              'Catatan: "${step.notes}"',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.textSecondary,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
          if (req.isPending) ...[
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: provider.isSubmitting ? null : () => _handleCancelRequest(provider, req),
                icon: const Icon(Icons.close_rounded, size: 16, color: AppColors.errorRed),
                label: Text(
                  'Batalkan Pengajuan',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.errorRed,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildApprovalCard(LeaveRequest req, LeaveProvider provider) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      req.requesterName ?? 'Karyawan',
                      style: AppTextStyles.h3,
                    ),
                    if (req.requesterPosition != null || req.requesterDivision != null)
                      Text(
                        [req.requesterPosition, req.requesterDivision]
                            .where((e) => e != null && e.isNotEmpty)
                            .join(' • '),
                        style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                      ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.lightBlueBackground,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  req.leaveTypeName,
                  style: AppTextStyles.badgeText.copyWith(
                    color: AppColors.steelBlue,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.date_range_rounded, size: 15, color: AppColors.textSecondary),
              const SizedBox(width: 6),
              Text(
                '${req.startDate == req.endDate ? req.startDate : "${req.startDate} s/d ${req.endDate}"} (${req.totalDays} Hari)',
                style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            req.reason,
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
          ),
          if (req.attachmentUrl != null && req.attachmentUrl!.isNotEmpty) ...[
            const SizedBox(height: 10),
            InkWell(
              onTap: () => _openAttachment(req.attachmentUrl!),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.attach_file_rounded, size: 15, color: AppColors.steelBlue),
                  const SizedBox(width: 4),
                  Text(
                    req.attachmentName ?? 'Buka Lampiran',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.steelBlue,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 14),
          Builder(
            builder: (context) {
              final currentUser = provider.authProvider?.currentUser;
              final isSelfRequest = req.requesterId != null &&
                  currentUser != null &&
                  req.requesterId == currentUser.id;
              final isBlockedSelfApproval = isSelfRequest && !(currentUser.isSuperadmin);

              if (isBlockedSelfApproval) {
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.safetyAmberLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    'Pengajuan pribadi tidak dapat disetujui sendiri.',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.safetyAmber,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                );
              }

              return Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: provider.isSubmitting
                          ? null
                          : () => _handleProcessApproval(provider, req, 'reject'),
                      icon: const Icon(Icons.close_rounded, size: 16),
                      label: const Text('Tolak'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.errorRed,
                        side: const BorderSide(color: AppColors.errorRed),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: provider.isSubmitting
                          ? null
                          : () => _handleProcessApproval(provider, req, 'approve'),
                      icon: const Icon(Icons.check_rounded, size: 16),
                      label: const Text('Setujui'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.emeraldGreen,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _SubmitLeaveBottomSheet extends StatefulWidget {
  final List<LeaveType> leaveTypes;
  final Future<void> Function(
    int leaveTypeId,
    String startDate,
    String endDate,
    String reason,
    String? attachmentPath,
  ) onSubmitted;

  const _SubmitLeaveBottomSheet({
    required this.leaveTypes,
    required this.onSubmitted,
  });

  @override
  State<_SubmitLeaveBottomSheet> createState() => _SubmitLeaveBottomSheetState();
}

class _SubmitLeaveBottomSheetState extends State<_SubmitLeaveBottomSheet> {
  late LeaveType _selectedType;
  DateTimeRange? _selectedRange;
  final TextEditingController _reasonController = TextEditingController();
  String? _attachmentPath;
  String? _attachmentName;
  bool _isSubmitting = false;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _selectedType = widget.leaveTypes.first;
    final today = DateTime.now();
    _selectedRange = DateTimeRange(start: today, end: today);
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _pickDateRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: now.subtract(const Duration(days: 30)),
      lastDate: now.add(const Duration(days: 365)),
      initialDateRange: _selectedRange,
    );
    if (picked != null) {
      setState(() => _selectedRange = picked);
    }
  }

  Future<void> _pickAttachment() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
    );
    if (result.isNotEmpty && result.first.path != null) {
      setState(() {
        _attachmentPath = result.first.path;
        _attachmentName = result.first.name;
        _errorText = null;
      });
    }
  }

  Future<void> _submit() async {
    final reason = _reasonController.text.trim();
    if (_selectedRange == null) {
      setState(() => _errorText = 'Pilih rentang tanggal terlebih dahulu.');
      return;
    }
    if (reason.isEmpty) {
      setState(() => _errorText = 'Alasan pengajuan wajib diisi.');
      return;
    }
    if (_selectedType.requiresAttachment && (_attachmentPath == null || _attachmentPath!.isEmpty)) {
      setState(() => _errorText = 'Jenis izin "${_selectedType.name}" wajib melampirkan dokumen pendukung.');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorText = null;
    });

    try {
      final fmt = DateFormat('yyyy-MM-dd');
      await widget.onSubmitted(
        _selectedType.id,
        fmt.format(_selectedRange!.start),
        fmt.format(_selectedRange!.end),
        reason,
        _attachmentPath,
      );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _errorText = e.toString().replaceFirst('Exception: ', '');
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final fmt = DateFormat('dd MMM yyyy');
    final rangeText = _selectedRange == null
        ? 'Pilih Tanggal'
        : '${fmt.format(_selectedRange!.start)} - ${fmt.format(_selectedRange!.end)}';

    return Container(
      padding: EdgeInsets.fromLTRB(20, 16, 20, 20 + bottomInset),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
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
            Text('Form Pengajuan Izin / Cuti', style: AppTextStyles.h2),
            const SizedBox(height: 16),

            // Leave Type Dropdown
            Text('Jenis Izin', style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            DropdownButtonFormField<LeaveType>(
              initialValue: _selectedType,
              decoration: InputDecoration(
                filled: true,
                fillColor: AppColors.background,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColors.borderSubtle),
                ),
              ),
              items: widget.leaveTypes
                  .map((t) => DropdownMenuItem(value: t, child: Text(t.name)))
                  .toList(),
              onChanged: (val) {
                if (val != null) setState(() => _selectedType = val);
              },
            ),
            if (_selectedType.approvalSteps.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.lightBlueBackground,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Alur Persetujuan: ${_selectedType.approvalSteps.map((s) => '${s.stepLevel}. ${s.approverTypeLabel}').join(' → ')}',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.steelBlue,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 14),

            // Date Range Picker
            Text('Rentang Tanggal', style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            InkWell(
              onTap: _pickDateRange,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.borderSubtle),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today_rounded, size: 18, color: AppColors.steelBlue),
                    const SizedBox(width: 10),
                    Text(rangeText, style: AppTextStyles.bodyMedium),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Reason
            Text('Alasan / Keterangan', style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            TextField(
              controller: _reasonController,
              maxLines: 3,
              maxLength: 1000,
              decoration: InputDecoration(
                hintText: 'Tuliskan alasan pengajuan izin...',
                hintStyle: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted),
                filled: true,
                fillColor: AppColors.background,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColors.borderSubtle),
                ),
              ),
            ),
            const SizedBox(height: 8),

            // Attachment Picker
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Lampiran (${_selectedType.requiresAttachment ? "Wajib" : "Opsional"})',
                    style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'JPG, PNG, PDF (maks 5MB)',
                  style: AppTextStyles.badgeText.copyWith(color: AppColors.textMuted),
                ),
              ],
            ),
            const SizedBox(height: 6),
            OutlinedButton.icon(
              onPressed: _pickAttachment,
              icon: const Icon(Icons.upload_file_rounded, size: 18),
              label: Text(
                _attachmentName ?? 'Pilih File Lampiran',
                overflow: TextOverflow.ellipsis,
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.steelBlue,
                side: const BorderSide(color: AppColors.borderSubtle),
                minimumSize: const Size(double.infinity, 44),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),

            if (_errorText != null) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.errorRedLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _errorText!,
                  style: AppTextStyles.bodySmall.copyWith(color: AppColors.errorRed),
                ),
              ),
            ],

            const SizedBox(height: 18),
            AppButton(
              text: 'Kirim Pengajuan',
              isLoading: _isSubmitting,
              onPressed: _isSubmitting ? null : _submit,
            ),
          ],
        ),
      ),
    );
  }
}
