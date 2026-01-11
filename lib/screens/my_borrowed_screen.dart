import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/cyberpunk_theme.dart';
import '../services/borrowing_service.dart';

class MyBorrowedScreen extends StatefulWidget {
  const MyBorrowedScreen({super.key});

  @override
  State<MyBorrowedScreen> createState() => _MyBorrowedScreenState();
}

class _MyBorrowedScreenState extends State<MyBorrowedScreen> {
  final BorrowingService _borrowingService = BorrowingService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  int _selectedTab = 0;

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;
    if (user == null) {
      return const Center(child: Text('Please login'));
    }

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'My Borrowed Items',
            style: GoogleFonts.rajdhani(
              fontWeight: FontWeight.bold,
              color: CyberpunkTheme.textPrimary,
            ),
          ),
          backgroundColor: CyberpunkTheme.surfaceDark,
          bottom: TabBar(
            labelStyle: GoogleFonts.rajdhani(fontWeight: FontWeight.w600),
            indicatorColor: CyberpunkTheme.primaryPink,
            tabs: const [
              Tab(text: 'PENDING'),
              Tab(text: 'ACTIVE'),
              Tab(text: 'HISTORY'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // PENDING TAB
            StreamBuilder<QuerySnapshot>(
              stream: _borrowingService.getUserPendingRequestsStream(user.uid),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return _buildEmptyState('No pending requests');
                }
                return _buildPendingList(snapshot.data!.docs);
              },
            ),

            // ACTIVE TAB
            StreamBuilder<QuerySnapshot>(
              stream: _borrowingService.getUserActiveLoansStream(user.uid),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return _buildEmptyState('No active loans');
                }
                return _buildActiveList(snapshot.data!.docs);
              },
            ),

            // HISTORY TAB (Returned & Rejected) - FIXED: No orderBy
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('borrowings')
                  .where('userId', isEqualTo: user.uid)
                  .where('status', whereIn: ['returned', 'rejected'])
                  .snapshots(), // REMOVED: .orderBy('updatedAt', descending: true)
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return _buildEmptyState('No history');
                }
                return _buildHistoryList(snapshot.data!.docs);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPendingList(List<QueryDocumentSnapshot> docs) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: docs.length,
      itemBuilder: (context, index) {
        final data = docs[index].data() as Map<String, dynamic>;
        return _buildBorrowingCard(
          data,
          status: 'PENDING',
          statusColor: Colors.orange,
          showReturnButton: false,
        );
      },
    );
  }

  Widget _buildActiveList(List<QueryDocumentSnapshot> docs) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: docs.length,
      itemBuilder: (context, index) {
        final data = docs[index].data() as Map<String, dynamic>;
        final expectedReturn = (data['expectedReturnDate'] as Timestamp?)
            ?.toDate();
        final isOverdue =
            expectedReturn != null && DateTime.now().isAfter(expectedReturn);

        return _buildBorrowingCard(
          data,
          status: isOverdue ? 'OVERDUE' : 'ACTIVE',
          statusColor: isOverdue ? Colors.red : CyberpunkTheme.accentGreen,
          showReturnButton: true,
          borrowingId: docs[index].id,
          assetId: data['assetId'],
        );
      },
    );
  }

  Widget _buildHistoryList(List<QueryDocumentSnapshot> docs) {
    // Sort by date (newest first)
    docs.sort((a, b) {
      final aData = a.data() as Map<String, dynamic>;
      final bData = b.data() as Map<String, dynamic>;

      // Get appropriate date for sorting
      DateTime? getDate(Map<String, dynamic> data) {
        if (data['status'] == 'rejected') {
          final rejected = data['rejectedDate'] as Timestamp?;
          return rejected?.toDate();
        } else if (data['status'] == 'returned') {
          final returned = data['actualReturnDate'] as Timestamp?;
          return returned?.toDate();
        }
        // Fallback to updatedAt or createdAt
        final updated = data['updatedAt'] as Timestamp?;
        if (updated != null) return updated.toDate();
        final created = data['createdAt'] as Timestamp?;
        return created?.toDate();
      }

      final aDate = getDate(aData);
      final bDate = getDate(bData);

      if (aDate == null && bDate == null) return 0;
      if (aDate == null) return 1;
      if (bDate == null) return -1;

      return bDate.compareTo(aDate); // Descending
    });

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: docs.length,
      itemBuilder: (context, index) {
        final data = docs[index].data() as Map<String, dynamic>;
        final isRejected = data['status'] == 'rejected';

        return _buildBorrowingCard(
          data,
          status: isRejected ? 'REJECTED' : 'RETURNED',
          statusColor: isRejected ? Colors.red : Colors.grey,
          showReturnButton: false,
          showReason: isRejected,
        );
      },
    );
  }

  Widget _buildBorrowingCard(
    Map<String, dynamic> data, {
    required String status,
    required Color statusColor,
    required bool showReturnButton,
    String? borrowingId,
    String? assetId,
    bool showReason = false,
  }) {
    // Safely get values with defaults
    final assetName = data['assetName'] ?? 'Unknown Item';
    final category = data['category'] ?? 'Unknown';
    final serialNumber = data['serialNumber'] ?? 'N/A';
    final assetCode = data['assetCode'] ?? serialNumber;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CyberpunkTheme.surfaceDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  assetName,
                  style: GoogleFonts.rajdhani(
                    color: CyberpunkTheme.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  status,
                  style: GoogleFonts.rajdhani(
                    color: statusColor,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '$category • $assetCode',
            style: GoogleFonts.rajdhani(
              color: CyberpunkTheme.textMuted,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),

          if (data['requestedDate'] != null)
            _buildInfoRow(
              'Requested:',
              _formatDate((data['requestedDate'] as Timestamp).toDate()),
            ),

          if (data['approvedDate'] != null)
            _buildInfoRow(
              'Approved:',
              _formatDate((data['approvedDate'] as Timestamp).toDate()),
            ),

          if (data['expectedReturnDate'] != null)
            _buildInfoRow(
              'Due Date:',
              _formatDate((data['expectedReturnDate'] as Timestamp).toDate()),
            ),

          if (data['actualReturnDate'] != null)
            _buildInfoRow(
              'Returned:',
              _formatDate((data['actualReturnDate'] as Timestamp).toDate()),
            ),

          if (showReason && data['rejectionReason'] != null)
            _buildInfoRow(
              'Reason:',
              data['rejectionReason'].toString(),
              color: Colors.red,
            ),

          const SizedBox(height: 12),

          if (showReturnButton && borrowingId != null && assetId != null)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: CyberpunkTheme.primaryPink,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () => _returnItem(borrowingId, assetId),
                child: Text(
                  'Return Item',
                  style: GoogleFonts.rajdhani(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Text(
            label,
            style: GoogleFonts.rajdhani(
              color: CyberpunkTheme.textMuted,
              fontSize: 12,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.rajdhani(
                color: color ?? CyberpunkTheme.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inventory_outlined,
            size: 60,
            color: CyberpunkTheme.textMuted.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: GoogleFonts.rajdhani(
              color: CyberpunkTheme.textMuted,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _returnItem(String borrowingId, String assetId) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Confirm Return',
          style: GoogleFonts.rajdhani(fontWeight: FontWeight.bold),
        ),
        content: const Text('Are you sure you want to return this item?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: CyberpunkTheme.primaryPink,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Return'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await _borrowingService.returnAsset(
        borrowingId: borrowingId,
        assetId: assetId,
        returnedBy: user.uid,
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '✅ Item returned successfully!',
              style: GoogleFonts.rajdhani(fontWeight: FontWeight.w600),
            ),
            backgroundColor: CyberpunkTheme.accentGreen,
          ),
        );
      }
    }
  }
}
