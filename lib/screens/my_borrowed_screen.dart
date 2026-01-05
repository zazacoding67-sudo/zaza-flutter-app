import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class MyBorrowedScreen extends StatefulWidget {
  const MyBorrowedScreen({super.key});

  @override
  State<MyBorrowedScreen> createState() => _MyBorrowedScreenState();
}

class _MyBorrowedScreenState extends State<MyBorrowedScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool isLoading = true;
  List<QueryDocumentSnapshot> borrowedItems = [];

  @override
  void initState() {
    super.initState();
    loadBorrowedItems();
  }

  Future<void> loadBorrowedItems() async {
    try {
      final userId = _auth.currentUser!.uid;
      final snapshot = await _firestore
          .collection('borrow_records')
          .where('userId', isEqualTo: userId)
          .where('status', isEqualTo: 'Borrowed')
          .orderBy('borrowedDate', descending: true)
          .get();

      if (mounted) {
        setState(() {
          borrowedItems = snapshot.docs;
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading items: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> returnItem(String borrowId, String assetName) async {
    try {
      await _firestore.collection('borrow_records').doc(borrowId).update({
        'status': 'Returned',
        'actualReturnDate': FieldValue.serverTimestamp(),
        'conditionAfter': 'Good',
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ $assetName returned successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }

      loadBorrowedItems(); // Refresh list
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Return failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String formatDate(Timestamp? timestamp) {
    if (timestamp == null) return 'N/A';
    return DateFormat('dd MMM yyyy').format(timestamp.toDate());
  }

  String formatDateTime(Timestamp? timestamp) {
    if (timestamp == null) return 'N/A';
    return DateFormat('dd MMM yyyy, hh:mm a').format(timestamp.toDate());
  }

  int getOverdueCount() {
    return borrowedItems.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final expectedReturn = data['expectedReturnDate'] as Timestamp?;
      return expectedReturn != null &&
          expectedReturn.toDate().isBefore(DateTime.now());
    }).length;
  }

  @override
  Widget build(BuildContext context) {
    final overdueCount = getOverdueCount();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'My Borrowed Items',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        backgroundColor: const Color(0xFF00897B),
        foregroundColor: Colors.white,
        actions: [
          if (overdueCount > 0)
            Badge(
              label: Text(overdueCount.toString()),
              backgroundColor: Colors.red,
              child: IconButton(
                icon: const Icon(Icons.warning),
                onPressed: () {},
                tooltip: '$overdueCount overdue items',
              ),
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() => isLoading = true);
              loadBorrowedItems();
            },
          ),
        ],
      ),
      body: isLoading
          ? _buildLoadingState()
          : borrowedItems.isEmpty
          ? _buildEmptyState()
          : RefreshIndicator(
              onRefresh: loadBorrowedItems,
              color: const Color(0xFF00897B),
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Stats Card
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildStatItem(
                            'Total',
                            borrowedItems.length,
                            Icons.shopping_bag,
                            color: Colors.blue,
                          ),
                          _buildStatItem(
                            'Overdue',
                            overdueCount,
                            Icons.warning,
                            color: overdueCount > 0 ? Colors.red : Colors.grey,
                          ),
                          _buildStatItem(
                            'Due Soon',
                            borrowedItems.where((doc) {
                              final data = doc.data() as Map<String, dynamic>;
                              final expectedReturn =
                                  data['expectedReturnDate'] as Timestamp?;
                              if (expectedReturn == null) return false;
                              final daysUntilDue = expectedReturn
                                  .toDate()
                                  .difference(DateTime.now())
                                  .inDays;
                              return daysUntilDue <= 3 && daysUntilDue > 0;
                            }).length,
                            Icons.access_time,
                            color: Colors.orange,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Items List
                  ...borrowedItems.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    return _buildItemCard(doc.id, data);
                  }).toList(),
                ],
              ),
            ),
    );
  }

  Widget _buildStatItem(
    String label,
    int count,
    IconData icon, {
    Color color = Colors.blue,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(height: 4),
        Text(
          count.toString(),
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(const Color(0xFF00897B)),
            strokeWidth: 2,
          ),
          const SizedBox(height: 16),
          Text(
            'Loading your items...',
            style: GoogleFonts.poppins(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_bag_outlined, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'No borrowed items',
            style: GoogleFonts.poppins(fontSize: 18, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'Borrow assets from the inventory',
            style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[500]),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00897B),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Browse Assets'),
          ),
        ],
      ),
    );
  }

  Widget _buildItemCard(String borrowId, Map<String, dynamic> data) {
    final borrowedDate = data['borrowedDate'] as Timestamp?;
    final expectedReturn = data['expectedReturnDate'] as Timestamp?;
    final isOverdue =
        expectedReturn != null &&
        expectedReturn.toDate().isBefore(DateTime.now());
    final daysUntilDue = expectedReturn != null
        ? expectedReturn.toDate().difference(DateTime.now()).inDays
        : 0;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    data['assetName'] ?? 'Unknown Asset',
                    style: GoogleFonts.poppins(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (isOverdue)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'OVERDUE',
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 8),

            // Asset Details
            Text(
              '${data['category'] ?? ''} • ${data['brand'] ?? ''} ${data['model'] ?? ''}'
                  .trim(),
              style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[600]),
            ),

            if (data['serialNumber'] != null &&
                data['serialNumber'].toString().isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'S/N: ${data['serialNumber']}',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey[500],
                  ),
                ),
              ),

            const SizedBox(height: 12),

            // Due Date Status
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isOverdue
                    ? Colors.red.withOpacity(0.05)
                    : daysUntilDue <= 3
                    ? Colors.orange.withOpacity(0.05)
                    : Colors.green.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isOverdue
                      ? Colors.red.withOpacity(0.2)
                      : daysUntilDue <= 3
                      ? Colors.orange.withOpacity(0.2)
                      : Colors.green.withOpacity(0.2),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Borrowed Date',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.grey[500],
                        ),
                      ),
                      Text(
                        formatDate(borrowedDate),
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        isOverdue ? 'Overdue' : 'Due Date',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: isOverdue
                              ? Colors.red
                              : daysUntilDue <= 3
                              ? Colors.orange
                              : Colors.green,
                        ),
                      ),
                      Text(
                        formatDate(expectedReturn),
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: isOverdue
                              ? Colors.red
                              : daysUntilDue <= 3
                              ? Colors.orange
                              : Colors.green,
                        ),
                      ),
                      if (!isOverdue && daysUntilDue <= 3)
                        Text(
                          '$daysUntilDue ${daysUntilDue == 1 ? 'day' : 'days'} left',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: Colors.orange,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Return Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () =>
                    returnItem(borrowId, data['assetName'] ?? 'Item'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00897B),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                icon: const Icon(Icons.check_circle, size: 20),
                label: Text(
                  'Return Item',
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
