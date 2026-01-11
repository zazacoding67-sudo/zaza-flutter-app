import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../theme/cyberpunk_theme.dart';

class StaffReturnsScreen extends StatefulWidget {
  const StaffReturnsScreen({super.key});

  @override
  State<StaffReturnsScreen> createState() => _StaffReturnsScreenState();
}

class _StaffReturnsScreenState extends State<StaffReturnsScreen> {
  List<Map<String, dynamic>> borrowings = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
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
        final aDate = a['expectedReturnDate'] as Timestamp?;
        final bDate = b['expectedReturnDate'] as Timestamp?;
        if (aDate == null || bDate == null) return 0;
        return aDate.compareTo(bDate);
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

  Future<void> processReturn(Map<String, dynamic> item) async {
    DateTime selectedDate = DateTime.now();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: CyberpunkTheme.surfaceDark,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: CyberpunkTheme.accentGreen.withOpacity(0.3),
            ),
          ),
          title: Text(
            'PROCESS RETURN',
            style: GoogleFonts.orbitron(
              color: CyberpunkTheme.accentGreen,
              fontSize: 16,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: CyberpunkTheme.surfaceLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item['assetName'] ?? 'Unknown',
                      style: GoogleFonts.rajdhani(
                        color: CyberpunkTheme.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Borrower: ${item['userName']}',
                      style: GoogleFonts.rajdhani(
                        color: CyberpunkTheme.textMuted,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Return Date',
                style: GoogleFonts.rajdhani(
                  color: CyberpunkTheme.textMuted,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: selectedDate,
                    firstDate: DateTime(2024),
                    lastDate: DateTime.now(),
                    builder: (context, child) => Theme(
                      data: ThemeData.dark().copyWith(
                        colorScheme: const ColorScheme.dark(
                          primary: CyberpunkTheme.accentGreen,
                          surface: CyberpunkTheme.surfaceDark,
                        ),
                      ),
                      child: child!,
                    ),
                  );
                  if (picked != null)
                    setDialogState(() => selectedDate = picked);
                },
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: CyberpunkTheme.surfaceLight,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: CyberpunkTheme.accentGreen.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.calendar_today,
                        color: CyberpunkTheme.accentGreen,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        DateFormat('dd MMM yyyy').format(selectedDate),
                        style: GoogleFonts.rajdhani(
                          color: CyberpunkTheme.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      const Icon(
                        Icons.edit,
                        color: CyberpunkTheme.textMuted,
                        size: 16,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(
                'Cancel',
                style: GoogleFonts.rajdhani(color: CyberpunkTheme.textMuted),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: CyberpunkTheme.accentGreen,
              ),
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(
                'Confirm Return',
                style: GoogleFonts.rajdhani(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );

    if (confirmed == true) {
      try {
        await FirebaseFirestore.instance
            .collection('borrow_records')
            .doc(item['id'])
            .update({
              'status': 'Returned',
              'actualReturnDate': Timestamp.fromDate(selectedDate),
            });
        if (item['assetId'] != null) {
          await FirebaseFirestore.instance
              .collection('assets')
              .doc(item['assetId'])
              .update({'isAvailable': true});
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '✅ ${item['assetName']} returned successfully!',
                style: GoogleFonts.rajdhani(fontWeight: FontWeight.w600),
              ),
              backgroundColor: CyberpunkTheme.surfaceDark,
            ),
          );
          loadBorrowings();
        }
      } catch (e) {
        if (mounted)
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ Error: $e', style: GoogleFonts.rajdhani()),
              backgroundColor: CyberpunkTheme.surfaceDark,
            ),
          );
      }
    }
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
    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(
                  Icons.assignment_return_rounded,
                  color: CyberpunkTheme.accentGreen,
                ),
                const SizedBox(width: 10),
                Text(
                  'Process Returns',
                  style: GoogleFonts.orbitron(
                    color: CyberpunkTheme.accentGreen,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: CyberpunkTheme.accentGreen.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${borrowings.length} pending',
                    style: GoogleFonts.rajdhani(
                      color: CyberpunkTheme.accentGreen,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(
                    Icons.refresh,
                    color: CyberpunkTheme.accentGreen,
                  ),
                  onPressed: loadBorrowings,
                ),
              ],
            ),
          ),
          Expanded(
            child: isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: CyberpunkTheme.accentGreen,
                    ),
                  )
                : borrowings.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.check_circle_outline,
                          size: 60,
                          color: CyberpunkTheme.accentGreen.withOpacity(0.5),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No pending returns',
                          style: GoogleFonts.rajdhani(
                            color: CyberpunkTheme.textMuted,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          'All items have been returned',
                          style: GoogleFonts.rajdhani(
                            color: CyberpunkTheme.textMuted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: loadBorrowings,
                    color: CyberpunkTheme.accentGreen,
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: borrowings.length,
                      itemBuilder: (_, i) => _buildReturnCard(borrowings[i]),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildReturnCard(Map<String, dynamic> item) {
    final overdue = isOverdue(item['expectedReturnDate']);
    final color = overdue
        ? CyberpunkTheme.statusMaintenance
        : CyberpunkTheme.accentGreen;
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item['assetName'] ?? 'Unknown',
                      style: GoogleFonts.rajdhani(
                        color: CyberpunkTheme.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${item['category']} • ${item['serialNumber']}',
                      style: GoogleFonts.rajdhani(
                        color: CyberpunkTheme.textMuted,
                        fontSize: 11,
                      ),
                    ),
                  ],
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
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.warning,
                        size: 12,
                        color: CyberpunkTheme.statusMaintenance,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'OVERDUE',
                        style: GoogleFonts.rajdhani(
                          color: CyberpunkTheme.statusMaintenance,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
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
                const Icon(
                  Icons.person_outline,
                  size: 16,
                  color: CyberpunkTheme.primaryBlue,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item['userName'] ?? 'Unknown',
                        style: GoogleFonts.rajdhani(
                          color: CyberpunkTheme.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        item['userEmail'] ?? '',
                        style: GoogleFonts.rajdhani(
                          color: CyberpunkTheme.textMuted,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  'Due: ${formatDate(item['expectedReturnDate'])}',
                  style: GoogleFonts.rajdhani(
                    color: color,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: CyberpunkTheme.accentGreen,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () => processReturn(item),
              icon: const Icon(
                Icons.check_circle,
                size: 18,
                color: Colors.white,
              ),
              label: Text(
                'Process Return',
                style: GoogleFonts.rajdhani(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
