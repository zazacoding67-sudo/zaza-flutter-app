import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../theme/cyberpunk_theme.dart';

class BorrowingsScreen extends StatefulWidget {
  const BorrowingsScreen({super.key});

  @override
  State<BorrowingsScreen> createState() => _BorrowingsScreenState();
}

class _BorrowingsScreenState extends State<BorrowingsScreen> {
  bool isLoading = true;
  String selectedFilter = 'All';
  List<QueryDocumentSnapshot> allBorrowings = [];

  @override
  void initState() {
    super.initState();
    loadBorrowings();
  }

  Future<void> loadBorrowings() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('borrow_records')
          .orderBy('borrowedDate', descending: true)
          .get();
      if (mounted) {
        setState(() {
          allBorrowings = snapshot.docs;
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => isLoading = false);
    }
  }

  List<QueryDocumentSnapshot> getFilteredBorrowings() {
    if (selectedFilter == 'All') return allBorrowings;
    if (selectedFilter == 'Overdue') {
      return allBorrowings.where((d) {
        final data = d.data() as Map<String, dynamic>;
        final isBorrowed = data['status'] == 'Borrowed';
        final e = data['expectedReturnDate'] as Timestamp?;
        return isBorrowed && e != null && e.toDate().isBefore(DateTime.now());
      }).toList();
    }
    return allBorrowings
        .where(
          (d) => (d.data() as Map<String, dynamic>)['status'] == selectedFilter,
        )
        .toList();
  }

  Color getStatusColor(String s) {
    switch (s) {
      case 'Borrowed':
        return CyberpunkTheme.primaryBlue;
      case 'Returned':
        return CyberpunkTheme.accentGreen;
      default:
        return CyberpunkTheme.textMuted;
    }
  }

  Future<void> markAsReturned(String borrowId, String assetName) async {
    try {
      await FirebaseFirestore.instance
          .collection('borrow_records')
          .doc(borrowId)
          .update({
            'status': 'Returned',
            'actualReturnDate': FieldValue.serverTimestamp(),
          });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '✅ $assetName returned',
              style: GoogleFonts.rajdhani(),
            ),
            backgroundColor: CyberpunkTheme.surfaceLight,
          ),
        );
      }
      loadBorrowings();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error: $e', style: GoogleFonts.rajdhani()),
            backgroundColor: CyberpunkTheme.surfaceLight,
          ),
        );
      }
    }
  }

  String formatDate(Timestamp? t) =>
      t == null ? 'N/A' : DateFormat('dd MMM yyyy').format(t.toDate());
  String formatDateTime(Timestamp? t) =>
      t == null ? 'N/A' : DateFormat('dd MMM, hh:mm a').format(t.toDate());

  int getOverdueCount() {
    return allBorrowings.where((d) {
      final data = d.data() as Map<String, dynamic>;
      final isBorrowed = data['status'] == 'Borrowed';
      final e = data['expectedReturnDate'] as Timestamp?;
      return isBorrowed && e != null && e.toDate().isBefore(DateTime.now());
    }).length;
  }

  @override
  Widget build(BuildContext context) {
    final filteredBorrowings = getFilteredBorrowings();
    final overdueCount = getOverdueCount();

    return Theme(
      data: CyberpunkTheme.darkTheme,
      child: Scaffold(
        backgroundColor: CyberpunkTheme.background,
        appBar: AppBar(
          backgroundColor: CyberpunkTheme.surfaceDark,
          title: Text(
            'BORROWING RECORDS',
            style: GoogleFonts.orbitron(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: CyberpunkTheme.accentOrange,
              letterSpacing: 2,
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(
                Icons.refresh,
                color: CyberpunkTheme.primaryBlue,
              ),
              onPressed: () {
                setState(() => isLoading = true);
                loadBorrowings();
              },
            ),
          ],
        ),
        body: Column(
          children: [
            // Stats
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: CyberpunkTheme.surfaceDark,
                border: Border(
                  bottom: BorderSide(
                    color: CyberpunkTheme.primaryPurple.withOpacity(0.3),
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem(
                    'Total',
                    allBorrowings.length,
                    Icons.list,
                    CyberpunkTheme.primaryPink,
                  ),
                  _buildStatItem(
                    'Active',
                    allBorrowings
                        .where(
                          (d) =>
                              (d.data() as Map<String, dynamic>)['status'] ==
                              'Borrowed',
                        )
                        .length,
                    Icons.shopping_bag,
                    CyberpunkTheme.primaryBlue,
                  ),
                  _buildStatItem(
                    'Returned',
                    allBorrowings
                        .where(
                          (d) =>
                              (d.data() as Map<String, dynamic>)['status'] ==
                              'Returned',
                        )
                        .length,
                    Icons.check_circle,
                    CyberpunkTheme.accentGreen,
                  ),
                  _buildStatItem(
                    'Overdue',
                    overdueCount,
                    Icons.warning,
                    overdueCount > 0
                        ? CyberpunkTheme.statusMaintenance
                        : CyberpunkTheme.textMuted,
                  ),
                ],
              ),
            ),

            // Filters
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              color: CyberpunkTheme.surfaceDark,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: ['All', 'Borrowed', 'Returned', 'Overdue']
                      .map(
                        (f) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: _buildFilterChip(
                            f,
                            overdueCount: f == 'Overdue' ? overdueCount : 0,
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
            ),

            // Results count
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Text(
                    '${filteredBorrowings.length} Records',
                    style: GoogleFonts.rajdhani(
                      fontWeight: FontWeight.w600,
                      color: CyberpunkTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),

            // List
            Expanded(
              child: isLoading
                  ? _buildLoading()
                  : filteredBorrowings.isEmpty
                  ? _buildEmpty()
                  : RefreshIndicator(
                      onRefresh: loadBorrowings,
                      color: CyberpunkTheme.accentOrange,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: filteredBorrowings.length,
                        itemBuilder: (_, i) => _buildBorrowingCard(
                          filteredBorrowings[i].id,
                          filteredBorrowings[i].data() as Map<String, dynamic>,
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, int count, IconData icon, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            shape: BoxShape.circle,
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(height: 6),
        Text(
          count.toString(),
          style: GoogleFonts.orbitron(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.rajdhani(
            fontSize: 11,
            color: CyberpunkTheme.textMuted,
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String label, {int overdueCount = 0}) {
    final isSelected = selectedFilter == label;
    return GestureDetector(
      onTap: () => setState(() => selectedFilter = label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? CyberpunkTheme.accentOrange.withOpacity(0.2)
              : CyberpunkTheme.surfaceLight,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? CyberpunkTheme.accentOrange
                : CyberpunkTheme.primaryPurple.withOpacity(0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: GoogleFonts.rajdhani(
                color: isSelected
                    ? CyberpunkTheme.accentOrange
                    : CyberpunkTheme.textMuted,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
            if (overdueCount > 0) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: CyberpunkTheme.statusMaintenance,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  overdueCount.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLoading() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 50,
            height: 50,
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(
                CyberpunkTheme.accentOrange,
              ),
              strokeWidth: 2,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'LOADING...',
            style: GoogleFonts.orbitron(
              color: CyberpunkTheme.textSecondary,
              letterSpacing: 2,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: CyberpunkTheme.primaryPurple.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.assignment_outlined,
              size: 60,
              color: CyberpunkTheme.textMuted,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'NO RECORDS',
            style: GoogleFonts.orbitron(
              fontSize: 16,
              color: CyberpunkTheme.textSecondary,
              letterSpacing: 2,
            ),
          ),
          if (selectedFilter != 'All') ...[
            const SizedBox(height: 20),
            CyberButton(
              text: 'VIEW ALL',
              icon: Icons.list,
              onPressed: () => setState(() => selectedFilter = 'All'),
              gradient: CyberpunkTheme.orangeGradient,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBorrowingCard(String borrowId, Map<String, dynamic> data) {
    final borrowedDate = data['borrowedDate'] as Timestamp?;
    final expectedReturn = data['expectedReturnDate'] as Timestamp?;
    final isBorrowed = data['status'] == 'Borrowed';
    final isOverdue =
        isBorrowed &&
        expectedReturn != null &&
        expectedReturn.toDate().isBefore(DateTime.now());
    final status = data['status'] ?? 'Unknown';
    final statusColor = isOverdue
        ? CyberpunkTheme.statusMaintenance
        : getStatusColor(status);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: CyberCard(
        borderColor: statusColor,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    data['assetName'] ?? 'Unknown',
                    style: GoogleFonts.rajdhani(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: CyberpunkTheme.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: statusColor.withOpacity(0.5)),
                  ),
                  child: Text(
                    isOverdue ? 'OVERDUE' : status.toUpperCase(),
                    style: GoogleFonts.rajdhani(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${data['category'] ?? ''} • ${data['brand'] ?? ''} ${data['model'] ?? ''}'
                  .trim(),
              style: GoogleFonts.rajdhani(
                fontSize: 13,
                color: CyberpunkTheme.textMuted,
              ),
            ),
            const SizedBox(height: 12),

            // User info
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: CyberpunkTheme.primaryBlue.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: CyberpunkTheme.primaryBlue.withOpacity(0.1),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: CyberpunkTheme.primaryBlue.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.person,
                      size: 18,
                      color: CyberpunkTheme.primaryBlue,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          data['userName'] ?? 'Unknown',
                          style: GoogleFonts.rajdhani(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: CyberpunkTheme.textPrimary,
                          ),
                        ),
                        Text(
                          data['userEmail'] ?? '',
                          style: GoogleFonts.rajdhani(
                            fontSize: 12,
                            color: CyberpunkTheme.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Dates
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: CyberpunkTheme.surfaceLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'BORROWED',
                        style: GoogleFonts.rajdhani(
                          fontSize: 11,
                          color: CyberpunkTheme.textMuted,
                          letterSpacing: 1,
                        ),
                      ),
                      Text(
                        formatDateTime(borrowedDate),
                        style: GoogleFonts.rajdhani(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: CyberpunkTheme.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'DUE DATE',
                        style: GoogleFonts.rajdhani(
                          fontSize: 11,
                          color: isOverdue
                              ? CyberpunkTheme.statusMaintenance
                              : CyberpunkTheme.textMuted,
                          letterSpacing: 1,
                        ),
                      ),
                      Text(
                        formatDate(expectedReturn),
                        style: GoogleFonts.rajdhani(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isOverdue
                              ? CyberpunkTheme.statusMaintenance
                              : CyberpunkTheme.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Return button
            if (isBorrowed)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: SizedBox(
                  width: double.infinity,
                  child: CyberButton(
                    text: 'Mark Returned',
                    icon: Icons.check_circle,
                    onPressed: () =>
                        markAsReturned(borrowId, data['assetName'] ?? 'Item'),
                    gradient: CyberpunkTheme.greenGradient,
                    glowColor: CyberpunkTheme.accentGreen,
                    isSmall: true,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
