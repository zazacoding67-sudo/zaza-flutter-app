// Save this as: lib/screens/admin/pending_requests_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../theme/cyberpunk_theme.dart';
import '../../services/borrowing_service.dart';
import '../../models/borrowing.dart';

class PendingRequestsScreen extends ConsumerStatefulWidget {
  const PendingRequestsScreen({super.key});

  @override
  ConsumerState<PendingRequestsScreen> createState() =>
      _PendingRequestsScreenState();
}

class _PendingRequestsScreenState extends ConsumerState<PendingRequestsScreen> {
  bool _isLoading = true;
  List<Borrowing> _pendingRequests = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadPendingRequests();
  }

  Future<void> _loadPendingRequests() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final service = BorrowingService();
      final requests = await service.getPendingRequests();

      if (mounted) {
        setState(() {
          _pendingRequests = requests;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _approveRequest(Borrowing borrowing) async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: CyberpunkTheme.cardDark,
        title: Text('Approve Request', style: CyberpunkTheme.heading3),
        content: Text(
          'Approve borrow request for "${borrowing.assetName}" by ${borrowing.userName}?',
          style: CyberpunkTheme.bodyText,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: CyberpunkTheme.bodyText.copyWith(
                color: CyberpunkTheme.textMuted,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: CyberpunkTheme.neonGreen,
            ),
            child: Text('Approve', style: CyberpunkTheme.buttonText),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final service = BorrowingService();
      await service.approveBorrowRequest(borrowing.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Request approved successfully!',
                    style: CyberpunkTheme.bodyText,
                  ),
                ),
              ],
            ),
            backgroundColor: CyberpunkTheme.neonGreen,
            behavior: SnackBarBehavior.floating,
          ),
        );

        // Reload the list
        _loadPendingRequests();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _rejectRequest(Borrowing borrowing) async {
    final reasonController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: CyberpunkTheme.cardDark,
        title: Text('Reject Request', style: CyberpunkTheme.heading3),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Reject borrow request for "${borrowing.assetName}"?',
              style: CyberpunkTheme.bodyText,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              style: CyberpunkTheme.bodyText,
              decoration: InputDecoration(
                labelText: 'Reason for rejection',
                labelStyle: CyberpunkTheme.bodyText.copyWith(
                  color: CyberpunkTheme.textSecondary,
                ),
                border: const OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: CyberpunkTheme.bodyText.copyWith(
                color: CyberpunkTheme.textMuted,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Reject', style: CyberpunkTheme.buttonText),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final service = BorrowingService();
      await service.rejectBorrowRequest(
        borrowing.id,
        reasonController.text.trim().isEmpty
            ? 'No reason provided'
            : reasonController.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Request rejected', style: CyberpunkTheme.bodyText),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );

        _loadPendingRequests();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CyberpunkTheme.deepBlack,
      appBar: AppBar(
        title: Text(
          'PENDING REQUESTS',
          style: CyberpunkTheme.heading3.copyWith(
            fontSize: 18,
            letterSpacing: 2,
          ),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: CyberpunkTheme.pinkCyanGradient,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadPendingRequests,
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              CyberpunkTheme.cardDark.withOpacity(0.3),
              CyberpunkTheme.deepBlack,
            ],
          ),
        ),
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: CyberpunkTheme.primaryPink),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 64),
              const SizedBox(height: 16),
              Text('Error loading requests', style: CyberpunkTheme.heading3),
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                style: CyberpunkTheme.bodyText,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadPendingRequests,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_pendingRequests.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox, size: 64, color: CyberpunkTheme.textMuted),
            const SizedBox(height: 16),
            Text(
              'No pending requests',
              style: CyberpunkTheme.heading3.copyWith(
                color: CyberpunkTheme.textMuted,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadPendingRequests,
      color: CyberpunkTheme.primaryPink,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _pendingRequests.length,
        itemBuilder: (context, index) {
          final request = _pendingRequests[index];
          return _buildRequestCard(request);
        },
      ),
    );
  }

  Widget _buildRequestCard(Borrowing borrowing) {
    final dateFormat = DateFormat('dd MMM yyyy');

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: CyberpunkTheme.glassCard(),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: CyberpunkTheme.primaryPink.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
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
                        style: CyberpunkTheme.heading3.copyWith(fontSize: 16),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Requested by ${borrowing.userName}',
                        style: CyberpunkTheme.bodyText.copyWith(
                          fontSize: 12,
                          color: CyberpunkTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Details
            _buildDetailRow(
              Icons.calendar_today,
              'Requested',
              dateFormat.format(borrowing.requestedDate),
            ),
            const SizedBox(height: 8),
            _buildDetailRow(
              Icons.event,
              'Return Date',
              dateFormat.format(borrowing.expectedReturnDate),
            ),
            const SizedBox(height: 8),
            _buildDetailRow(Icons.notes, 'Purpose', borrowing.purpose),
            if (borrowing.notes != null && borrowing.notes!.isNotEmpty) ...[
              const SizedBox(height: 8),
              _buildDetailRow(Icons.info_outline, 'Notes', borrowing.notes!),
            ],
            const SizedBox(height: 16),

            // Actions
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _rejectRequest(borrowing),
                    icon: const Icon(Icons.close, size: 18),
                    label: const Text('Reject'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red, width: 2),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _approveRequest(borrowing),
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text('Approve'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: CyberpunkTheme.neonGreen,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 12),
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

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: CyberpunkTheme.primaryCyan),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: CyberpunkTheme.bodyText.copyWith(
                  fontSize: 11,
                  color: CyberpunkTheme.textMuted,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: CyberpunkTheme.bodyText.copyWith(fontSize: 13),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
