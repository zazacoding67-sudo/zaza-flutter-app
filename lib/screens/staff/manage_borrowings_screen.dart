// lib/screens/staff/manage_borrowings_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../theme/cyberpunk_theme.dart';
import '../../services/staff_service.dart';
import '../../models/borrowing.dart';

class ManageBorrowingsScreen extends StatefulWidget {
  const ManageBorrowingsScreen({super.key});

  @override
  State<ManageBorrowingsScreen> createState() => _ManageBorrowingsScreenState();
}

class _ManageBorrowingsScreenState extends State<ManageBorrowingsScreen>
    with SingleTickerProviderStateMixin {
  final StaffService _staffService = StaffService();
  late TabController _tabController;

  List<Borrowing> _pendingRequests = [];
  List<Borrowing> _activeBorrowings = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadBorrowings();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadBorrowings() async {
    setState(() => _isLoading = true);
    try {
      final pending = await _staffService.getPendingRequests();
      final active = await _staffService.getActiveBorrowings();

      setState(() {
        _pendingRequests = pending;
        _activeBorrowings = active;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading borrowings: $e'),
            backgroundColor: CyberpunkTheme.warningYellow,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showApprovalDialog(Borrowing borrowing) {
    final notesController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: CyberpunkTheme.surfaceDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.check_circle, color: CyberpunkTheme.neonGreen),
            const SizedBox(width: 12),
            Text(
              'Approve Request',
              style: GoogleFonts.rajdhani(
                color: CyberpunkTheme.neonGreen,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: CyberpunkTheme.cardDark,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Asset: ${borrowing.assetName}',
                    style: GoogleFonts.rajdhani(
                      color: CyberpunkTheme.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Requested by: ${borrowing.userName}',
                    style: GoogleFonts.rajdhani(
                      color: CyberpunkTheme.textMuted,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Purpose: ${borrowing.purpose}',
                    style: GoogleFonts.rajdhani(
                      color: CyberpunkTheme.textMuted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Approval Notes (Optional)',
              style: GoogleFonts.rajdhani(
                color: CyberpunkTheme.textMuted,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: notesController,
              maxLines: 3,
              style: GoogleFonts.rajdhani(color: CyberpunkTheme.textPrimary),
              decoration: InputDecoration(
                hintText: 'Add any special conditions or notes...',
                hintStyle: GoogleFonts.rajdhani(
                  color: CyberpunkTheme.textMuted,
                ),
                filled: true,
                fillColor: CyberpunkTheme.cardDark,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: CyberpunkTheme.neonGreen.withAlpha(77),
                  ),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.rajdhani(color: CyberpunkTheme.textMuted),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await _staffService.approveBorrowingRequest(
                  borrowing.id,
                  borrowing.assetId,
                  notes: notesController.text.isEmpty
                      ? null
                      : notesController.text,
                );

                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Request approved successfully'),
                      backgroundColor: CyberpunkTheme.neonGreen,
                    ),
                  );
                  _loadBorrowings();
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: $e'),
                      backgroundColor: CyberpunkTheme.warningYellow,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: CyberpunkTheme.neonGreen,
            ),
            child: Text(
              'Approve',
              style: GoogleFonts.rajdhani(
                color: CyberpunkTheme.deepBlack,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showRejectionDialog(Borrowing borrowing) {
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: CyberpunkTheme.surfaceDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.cancel, color: CyberpunkTheme.primaryPink),
            const SizedBox(width: 12),
            Text(
              'Reject Request',
              style: GoogleFonts.rajdhani(
                color: CyberpunkTheme.primaryPink,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: CyberpunkTheme.cardDark,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Asset: ${borrowing.assetName}',
                    style: GoogleFonts.rajdhani(
                      color: CyberpunkTheme.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Requested by: ${borrowing.userName}',
                    style: GoogleFonts.rajdhani(
                      color: CyberpunkTheme.textMuted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Rejection Reason *',
              style: GoogleFonts.rajdhani(
                color: CyberpunkTheme.textMuted,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: reasonController,
              maxLines: 3,
              style: GoogleFonts.rajdhani(color: CyberpunkTheme.textPrimary),
              decoration: InputDecoration(
                hintText: 'Please provide a reason for rejection...',
                hintStyle: GoogleFonts.rajdhani(
                  color: CyberpunkTheme.textMuted,
                ),
                filled: true,
                fillColor: CyberpunkTheme.cardDark,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: CyberpunkTheme.primaryPink.withAlpha(77),
                  ),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.rajdhani(color: CyberpunkTheme.textMuted),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              if (reasonController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please provide a reason')),
                );
                return;
              }

              try {
                await _staffService.rejectBorrowingRequest(
                  borrowing.id,
                  reasonController.text,
                );

                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Request rejected'),
                      backgroundColor: CyberpunkTheme.primaryPink,
                    ),
                  );
                  _loadBorrowings();
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: $e'),
                      backgroundColor: CyberpunkTheme.warningYellow,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: CyberpunkTheme.primaryPink,
            ),
            child: Text(
              'Reject',
              style: GoogleFonts.rajdhani(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CyberpunkTheme.deepBlack,
      appBar: AppBar(
        backgroundColor: CyberpunkTheme.surfaceDark,
        title: Text(
          'MANAGE BORROWINGS',
          style: GoogleFonts.rajdhani(
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadBorrowings,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelStyle: GoogleFonts.rajdhani(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
          unselectedLabelStyle: GoogleFonts.rajdhani(fontSize: 12),
          labelColor: CyberpunkTheme.primaryPink,
          unselectedLabelColor: CyberpunkTheme.textMuted,
          indicatorColor: CyberpunkTheme.primaryPink,
          tabs: [
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('PENDING'),
                  if (_pendingRequests.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: CyberpunkTheme.primaryPink,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${_pendingRequests.length}',
                        style: GoogleFonts.rajdhani(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('ACTIVE'),
                  if (_activeBorrowings.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: CyberpunkTheme.primaryCyan,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${_activeBorrowings.length}',
                        style: GoogleFonts.rajdhani(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: CyberpunkTheme.deepBlack,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: CyberpunkTheme.primaryCyan,
              ),
            )
          : TabBarView(
              controller: _tabController,
              children: [_buildPendingTab(), _buildActiveTab()],
            ),
    );
  }

  Widget _buildPendingTab() {
    if (_pendingRequests.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle_outline,
              size: 64,
              color: CyberpunkTheme.textMuted,
            ),
            const SizedBox(height: 16),
            Text(
              'No pending requests',
              style: GoogleFonts.rajdhani(
                color: CyberpunkTheme.textMuted,
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _pendingRequests.length,
      itemBuilder: (context, index) {
        final borrowing = _pendingRequests[index];
        return _buildPendingRequestCard(borrowing);
      },
    );
  }

  Widget _buildActiveTab() {
    if (_activeBorrowings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox, size: 64, color: CyberpunkTheme.textMuted),
            const SizedBox(height: 16),
            Text(
              'No active borrowings',
              style: GoogleFonts.rajdhani(
                color: CyberpunkTheme.textMuted,
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _activeBorrowings.length,
      itemBuilder: (context, index) {
        final borrowing = _activeBorrowings[index];
        return _buildActiveBorrowingCard(borrowing);
      },
    );
  }

  Widget _buildPendingRequestCard(Borrowing borrowing) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: CyberpunkTheme.surfaceDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: CyberpunkTheme.primaryPink.withAlpha(77)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: CyberpunkTheme.primaryPink.withAlpha(51),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.pending_actions,
                    color: CyberpunkTheme.primaryPink,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        borrowing.assetName,
                        style: GoogleFonts.rajdhani(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: CyberpunkTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.person,
                            size: 12,
                            color: CyberpunkTheme.textMuted,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            borrowing.userName,
                            style: GoogleFonts.rajdhani(
                              fontSize: 12,
                              color: CyberpunkTheme.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Divider(color: CyberpunkTheme.textMuted.withAlpha(51)),
            const SizedBox(height: 12),
            _buildInfoRow('Purpose', borrowing.purpose),
            _buildInfoRow(
              'Requested',
              DateFormat('MMM dd, yyyy').format(borrowing.requestedDate),
            ),
            _buildInfoRow(
              'Expected Return',
              DateFormat('MMM dd, yyyy').format(borrowing.expectedReturnDate),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showRejectionDialog(borrowing),
                    icon: const Icon(Icons.cancel, size: 16),
                    label: Text('Reject', style: GoogleFonts.rajdhani()),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: CyberpunkTheme.primaryPink,
                      side: BorderSide(color: CyberpunkTheme.primaryPink),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _showApprovalDialog(borrowing),
                    icon: const Icon(Icons.check_circle, size: 16),
                    label: Text(
                      'Approve',
                      style: GoogleFonts.rajdhani(fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: CyberpunkTheme.neonGreen,
                      foregroundColor: CyberpunkTheme.deepBlack,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveBorrowingCard(Borrowing borrowing) {
    final isOverdue = borrowing.isOverdue;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: CyberpunkTheme.surfaceDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isOverdue
              ? CyberpunkTheme.warningYellow
              : CyberpunkTheme.primaryCyan.withAlpha(77),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: CyberpunkTheme.primaryCyan.withAlpha(51),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.sync,
                    color: CyberpunkTheme.primaryCyan,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        borrowing.assetName,
                        style: GoogleFonts.rajdhani(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: CyberpunkTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.person,
                            size: 12,
                            color: CyberpunkTheme.textMuted,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            borrowing.userName,
                            style: GoogleFonts.rajdhani(
                              fontSize: 12,
                              color: CyberpunkTheme.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (isOverdue)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: CyberpunkTheme.warningYellow.withAlpha(51),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'OVERDUE',
                      style: GoogleFonts.rajdhani(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: CyberpunkTheme.warningYellow,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Divider(color: CyberpunkTheme.textMuted.withAlpha(51)),
            const SizedBox(height: 12),
            _buildInfoRow(
              'Expected Return',
              DateFormat('MMM dd, yyyy').format(borrowing.expectedReturnDate),
            ),
            if (isOverdue)
              _buildInfoRow(
                'Overdue By',
                '${borrowing.daysOverdue} days',
                isWarning: true,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isWarning = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.rajdhani(
              fontSize: 12,
              color: CyberpunkTheme.textMuted,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.rajdhani(
              fontSize: 12,
              color: isWarning
                  ? CyberpunkTheme.warningYellow
                  : CyberpunkTheme.textPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
