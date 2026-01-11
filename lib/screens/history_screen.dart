import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../theme/cyberpunk_theme.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  bool isLoading = true;
  List<Map<String, dynamic>> historyItems = [];

  @override
  void initState() {
    super.initState();
    loadHistory();
  }

  Future<void> loadHistory() async {
    setState(() => isLoading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() => isLoading = false);
        return;
      }
      final snapshot = await FirebaseFirestore.instance
          .collection('borrow_records')
          .where('userId', isEqualTo: user.uid)
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
          historyItems = items;
          isLoading = false;
        });
    } catch (e) {
      if (mounted) setState(() => isLoading = false);
    }
  }

  String formatDate(dynamic date) {
    if (date == null) return 'N/A';
    if (date is Timestamp)
      return DateFormat('dd MMM yyyy').format(date.toDate());
    return 'N/A';
  }

  IconData _getCategoryIcon(String? category) {
    switch ((category ?? '').toLowerCase()) {
      case 'computer':
      case 'laptop':
        return Icons.laptop_mac;
      case 'microphone':
      case 'audio':
        return Icons.mic;
      case 'camera':
      case 'video':
        return Icons.videocam;
      case 'projector':
        return Icons.cast;
      default:
        return Icons.inventory_2;
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalBorrowed = historyItems.length;
    final returned = historyItems
        .where((i) => i['status'] == 'Returned')
        .length;
    final active = historyItems.where((i) => i['status'] == 'Borrowed').length;

    return Theme(
      data: CyberpunkTheme.darkTheme,
      child: Scaffold(
        backgroundColor: CyberpunkTheme.background,
        appBar: AppBar(
          backgroundColor: CyberpunkTheme.surfaceDark,
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back,
              color: CyberpunkTheme.primaryPink,
            ),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            'Borrowing History',
            style: GoogleFonts.orbitron(
              color: CyberpunkTheme.primaryPink,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(
                Icons.refresh,
                color: CyberpunkTheme.primaryPink,
              ),
              onPressed: loadHistory,
            ),
          ],
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  _buildStat(
                    'Total',
                    totalBorrowed,
                    CyberpunkTheme.primaryPink,
                  ),
                  const SizedBox(width: 10),
                  _buildStat('Active', active, CyberpunkTheme.primaryBlue),
                  const SizedBox(width: 10),
                  _buildStat('Returned', returned, CyberpunkTheme.accentGreen),
                ],
              ),
            ),
            Expanded(
              child: isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: CyberpunkTheme.primaryPink,
                      ),
                    )
                  : historyItems.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.history,
                            size: 50,
                            color: CyberpunkTheme.textMuted.withOpacity(0.5),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'No history yet',
                            style: GoogleFonts.rajdhani(
                              color: CyberpunkTheme.textMuted,
                            ),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: loadHistory,
                      color: CyberpunkTheme.primaryPink,
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: historyItems.length,
                        itemBuilder: (_, i) =>
                            _buildHistoryCard(historyItems[i]),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStat(String label, int count, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: CyberpunkTheme.surfaceDark,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(
              count.toString(),
              style: GoogleFonts.orbitron(
                color: color,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
              style: GoogleFonts.rajdhani(
                color: CyberpunkTheme.textMuted,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryCard(Map<String, dynamic> item) {
    final status = item['status'] ?? 'Unknown';
    final isReturned = status == 'Returned';
    final color = isReturned
        ? CyberpunkTheme.accentGreen
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
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  _getCategoryIcon(item['category']),
                  color: color,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item['assetName'] ?? 'Unknown',
                      style: GoogleFonts.rajdhani(
                        color: CyberpunkTheme.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      item['category'] ?? '',
                      style: GoogleFonts.rajdhani(
                        color: CyberpunkTheme.textMuted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isReturned ? Icons.check_circle : Icons.schedule,
                      size: 12,
                      color: color,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      status.toUpperCase(),
                      style: GoogleFonts.rajdhani(
                        color: color,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
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
                if (isReturned) ...[
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
                          'Returned',
                          style: GoogleFonts.rajdhani(
                            color: CyberpunkTheme.accentGreen,
                            fontSize: 10,
                          ),
                        ),
                        Text(
                          formatDate(item['actualReturnDate']),
                          style: GoogleFonts.rajdhani(
                            color: CyberpunkTheme.accentGreen,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
