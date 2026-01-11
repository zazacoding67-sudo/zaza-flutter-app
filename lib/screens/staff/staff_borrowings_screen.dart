import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../theme/cyberpunk_theme.dart';

class StaffBorrowingsScreen extends StatefulWidget {
  final bool filterOverdue;
  const StaffBorrowingsScreen({super.key, this.filterOverdue = false});

  @override
  State<StaffBorrowingsScreen> createState() => _StaffBorrowingsScreenState();
}

class _StaffBorrowingsScreenState extends State<StaffBorrowingsScreen> {
  List<Map<String, dynamic>> borrowings = [];
  bool isLoading = true;
  String filter = 'All';

  @override
  void initState() {
    super.initState();
    if (widget.filterOverdue) filter = 'Overdue';
    loadBorrowings();
  }

  Future<void> loadBorrowings() async {
    setState(() => isLoading = true);
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('borrow_records')
          .where('status', isEqualTo: 'Borrowed')
          .get();
      final items = snapshot.docs
          .map((doc) => {'id': doc.id, ...doc.data()})
          .toList();
      items.sort((a, b) {
        final aDate = a['borrowedDate'] as Timestamp?;
        final bDate = b['borrowedDate'] as Timestamp?;
        if (aDate == null || bDate == null) return 0;
        return bDate.compareTo(aDate);
      });
      if (mounted)
        setState(() {
          borrowings = items;
          isLoading = false;
        });
    } catch (e) {
      if (mounted) setState(() => isLoading = false);
    }
  }

  List<Map<String, dynamic>> get filteredBorrowings {
    if (filter == 'All') return borrowings;
    if (filter == 'Overdue') {
      return borrowings.where((b) {
        final exp = b['expectedReturnDate'];
        if (exp == null) return false;
        if (exp is Timestamp) return exp.toDate().isBefore(DateTime.now());
        return false;
      }).toList();
    }
    return borrowings;
  }

  bool isOverdue(dynamic date) {
    if (date == null) return false;
    if (date is Timestamp) return date.toDate().isBefore(DateTime.now());
    return false;
  }

  String formatDate(dynamic date) {
    if (date == null) return 'N/A';
    if (date is Timestamp)
      return DateFormat('dd MMM yyyy').format(date.toDate());
    return 'N/A';
  }

  @override
  Widget build(BuildContext context) {
    final overdueCount = borrowings
        .where((b) => isOverdue(b['expectedReturnDate']))
        .length;

    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Text(
                      'Active Borrowings',
                      style: GoogleFonts.orbitron(
                        color: CyberpunkTheme.primaryBlue,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(
                        Icons.refresh,
                        color: CyberpunkTheme.primaryBlue,
                      ),
                      onPressed: loadBorrowings,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _buildFilterChip('All', borrowings.length),
                    const SizedBox(width: 8),
                    _buildFilterChip(
                      'Overdue',
                      overdueCount,
                      isAlert: overdueCount > 0,
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: CyberpunkTheme.primaryBlue,
                    ),
                  )
                : filteredBorrowings.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.assignment_outlined,
                          size: 50,
                          color: CyberpunkTheme.textMuted,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No borrowings found',
                          style: GoogleFonts.rajdhani(
                            color: CyberpunkTheme.textMuted,
                          ),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: loadBorrowings,
                    color: CyberpunkTheme.primaryBlue,
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: filteredBorrowings.length,
                      itemBuilder: (_, i) =>
                          _buildBorrowingCard(filteredBorrowings[i]),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, int count, {bool isAlert = false}) {
    final isSelected = filter == label;
    final color = isAlert
        ? CyberpunkTheme.statusMaintenance
        : CyberpunkTheme.primaryBlue;
    return GestureDetector(
      onTap: () => setState(() => filter = label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withOpacity(0.2)
              : CyberpunkTheme.surfaceDark,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? color : CyberpunkTheme.surfaceLight,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: GoogleFonts.rajdhani(
                color: isSelected ? color : CyberpunkTheme.textMuted,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: color.withOpacity(0.3),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                count.toString(),
                style: GoogleFonts.rajdhani(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBorrowingCard(Map<String, dynamic> item) {
    final overdue = isOverdue(item['expectedReturnDate']);
    final color = overdue
        ? CyberpunkTheme.statusMaintenance
        : CyberpunkTheme.primaryBlue;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: CyberpunkTheme.surfaceDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  item['assetName'] ?? 'Unknown',
                  style: GoogleFonts.rajdhani(
                    color: CyberpunkTheme.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (overdue)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: CyberpunkTheme.statusMaintenance.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'OVERDUE',
                    style: GoogleFonts.rajdhani(
                      color: CyberpunkTheme.statusMaintenance,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                Icons.person_outline,
                size: 14,
                color: CyberpunkTheme.textMuted,
              ),
              const SizedBox(width: 4),
              Text(
                item['userName'] ?? 'Unknown',
                style: GoogleFonts.rajdhani(
                  color: CyberpunkTheme.textSecondary,
                  fontSize: 13,
                ),
              ),
              const SizedBox(width: 12),
              Icon(
                Icons.email_outlined,
                size: 14,
                color: CyberpunkTheme.textMuted,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  item['userEmail'] ?? '',
                  style: GoogleFonts.rajdhani(
                    color: CyberpunkTheme.textMuted,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: CyberpunkTheme.surfaceLight,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Borrowed',
                        style: GoogleFonts.rajdhani(
                          color: CyberpunkTheme.textMuted,
                          fontSize: 10,
                        ),
                      ),
                      Text(
                        formatDate(item['borrowedDate']),
                        style: GoogleFonts.rajdhani(
                          color: CyberpunkTheme.textPrimary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 1,
                  height: 30,
                  color: CyberpunkTheme.primaryPurple.withOpacity(0.3),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Due Date',
                        style: GoogleFonts.rajdhani(color: color, fontSize: 10),
                      ),
                      Text(
                        formatDate(item['expectedReturnDate']),
                        style: GoogleFonts.rajdhani(
                          color: color,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
