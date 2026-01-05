import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class BorrowingsScreen extends StatefulWidget {
  const BorrowingsScreen({super.key});

  @override
  State<BorrowingsScreen> createState() => _BorrowingsScreenState();
}

class _BorrowingsScreenState extends State<BorrowingsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
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
      final snapshot = await _firestore
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
      if (mounted) {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading records: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  List<QueryDocumentSnapshot> getFilteredBorrowings() {
    if (selectedFilter == 'All') return allBorrowings;

    if (selectedFilter == 'Overdue') {
      return allBorrowings.where((doc) {
        final data = doc.data() as Map<String, dynamic>;
        final isBorrowed = data['status'] == 'Borrowed';
        final expectedReturn = data['expectedReturnDate'] as Timestamp?;
        final isOverdue =
            isBorrowed &&
            expectedReturn != null &&
            expectedReturn.toDate().isBefore(DateTime.now());
        return isOverdue;
      }).toList();
    }

    return allBorrowings.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return data['status'] == selectedFilter;
    }).toList();
  }

  Color getStatusColor(String status) {
    switch (status) {
      case 'Borrowed':
        return Colors.blue;
      case 'Returned':
        return Colors.green;
      case 'Overdue':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Future<void> markAsReturned(String borrowId, String assetName) async {
    try {
      await _firestore.collection('borrow_records').doc(borrowId).update({
        'status': 'Returned',
        'actualReturnDate': FieldValue.serverTimestamp(),
        'conditionAfter': 'Good', // You can customize this
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ $assetName marked as returned'),
            backgroundColor: Colors.green,
          ),
        );
      }

      loadBorrowings(); // Refresh list
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> extendDueDate(String borrowId, String assetName) async {
    // Show date picker
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null) {
      try {
        await _firestore.collection('borrow_records').doc(borrowId).update({
          'expectedReturnDate': Timestamp.fromDate(picked),
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '✅ $assetName due date extended to ${DateFormat('dd MMM yyyy').format(picked)}',
              ),
              backgroundColor: Colors.green,
            ),
          );
        }

        loadBorrowings(); // Refresh list
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('❌ Error: $e'), backgroundColor: Colors.red),
          );
        }
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
    return allBorrowings.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final isBorrowed = data['status'] == 'Borrowed';
      final expectedReturn = data['expectedReturnDate'] as Timestamp?;
      return isBorrowed &&
          expectedReturn != null &&
          expectedReturn.toDate().isBefore(DateTime.now());
    }).length;
  }

  @override
  Widget build(BuildContext context) {
    final filteredBorrowings = getFilteredBorrowings();
    final overdueCount = getOverdueCount();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Borrowing Records',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        backgroundColor: const Color(0xFF00897B),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() => isLoading = true);
              loadBorrowings();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Stats Overview
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem('Total', allBorrowings.length, Icons.list),
                _buildStatItem(
                  'Active',
                  allBorrowings.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    return data['status'] == 'Borrowed';
                  }).length,
                  Icons.shopping_bag,
                  color: Colors.blue,
                ),
                _buildStatItem(
                  'Returned',
                  allBorrowings.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    return data['status'] == 'Returned';
                  }).length,
                  Icons.check_circle,
                  color: Colors.green,
                ),
                _buildStatItem(
                  'Overdue',
                  overdueCount,
                  Icons.warning,
                  color: overdueCount > 0 ? Colors.red : Colors.grey,
                ),
              ],
            ),
          ),

          // Filter Chips
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            color: Colors.white,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('All', Icons.all_inclusive),
                  const SizedBox(width: 8),
                  _buildFilterChip('Borrowed', Icons.shopping_bag),
                  const SizedBox(width: 8),
                  _buildFilterChip('Returned', Icons.check_circle),
                  const SizedBox(width: 8),
                  _buildFilterChip(
                    'Overdue',
                    Icons.warning,
                    badgeCount: overdueCount,
                  ),
                ],
              ),
            ),
          ),
          const Divider(height: 1),

          // Results Count
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${filteredBorrowings.length} ${filteredBorrowings.length == 1 ? 'Record' : 'Records'}',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[700],
                  ),
                ),
                if (selectedFilter == 'Overdue' && overdueCount > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.warning, size: 14, color: Colors.red),
                        const SizedBox(width: 4),
                        Text(
                          '$overdueCount overdue',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.red,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),

          // Borrowings List
          Expanded(
            child: isLoading
                ? _buildLoadingState()
                : filteredBorrowings.isEmpty
                ? _buildEmptyState()
                : RefreshIndicator(
                    onRefresh: loadBorrowings,
                    color: const Color(0xFF00897B),
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: filteredBorrowings.length,
                      itemBuilder: (context, index) {
                        final doc = filteredBorrowings[index];
                        final data = doc.data() as Map<String, dynamic>;
                        return _buildBorrowingCard(doc.id, data);
                      },
                    ),
                  ),
          ),
        ],
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

  Widget _buildFilterChip(String label, IconData icon, {int badgeCount = 0}) {
    final isSelected = selectedFilter == label;
    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: isSelected ? Colors.white : Colors.grey),
          const SizedBox(width: 6),
          Text(label),
          if (badgeCount > 0) ...[
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                badgeCount.toString(),
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
      selected: isSelected,
      onSelected: (selected) {
        setState(() => selectedFilter = label);
      },
      selectedColor: const Color(0xFF00897B),
      checkmarkColor: Colors.white,
      labelStyle: GoogleFonts.poppins(
        color: isSelected ? Colors.white : Colors.black87,
        fontWeight: FontWeight.w500,
        fontSize: 13,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: Colors.grey[100],
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
            'Loading Records...',
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
          Icon(Icons.assignment_outlined, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'No borrowing records',
            style: GoogleFonts.poppins(fontSize: 18, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            selectedFilter == 'All'
                ? 'Borrowing records will appear here'
                : 'No $selectedFilter records found',
            style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[500]),
          ),
          const SizedBox(height: 20),
          if (selectedFilter != 'All')
            ElevatedButton(
              onPressed: () => setState(() => selectedFilter = 'All'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00897B),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('View All Records'),
            ),
        ],
      ),
    );
  }

  Widget _buildBorrowingCard(String borrowId, Map<String, dynamic> data) {
    final borrowedDate = data['borrowedDate'] as Timestamp?;
    final expectedReturn = data['expectedReturnDate'] as Timestamp?;
    final actualReturn = data['actualReturnDate'] as Timestamp?;
    final isBorrowed = data['status'] == 'Borrowed';
    final isOverdue =
        isBorrowed &&
        expectedReturn != null &&
        expectedReturn.toDate().isBefore(DateTime.now());
    final status = data['status'] ?? 'Unknown';

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with Status
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
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: getStatusColor(status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: getStatusColor(status), width: 1),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isOverdue)
                        Icon(Icons.warning, size: 12, color: Colors.red),
                      if (isOverdue) const SizedBox(width: 4),
                      Text(
                        isOverdue ? 'OVERDUE' : status,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: getStatusColor(status),
                        ),
                      ),
                    ],
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

            // User Info
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.withOpacity(0.1)),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: Colors.blue.withOpacity(0.2),
                    child: Icon(Icons.person, size: 20, color: Colors.blue),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          data['userName'] ?? 'Unknown User',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          data['userEmail'] ?? '',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        if (data['userStaffId'] != null &&
                            data['userStaffId'].toString().isNotEmpty)
                          Text(
                            'Staff ID: ${data['userStaffId']}',
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: Colors.grey[500],
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Dates Section
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Borrowed',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Colors.grey[500],
                            ),
                          ),
                          Text(
                            formatDateTime(borrowedDate),
                            style: GoogleFonts.poppins(
                              fontSize: 13,
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
                            'Due Date',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: isOverdue ? Colors.red : Colors.grey[500],
                            ),
                          ),
                          Text(
                            formatDate(expectedReturn),
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: isOverdue ? Colors.red : Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  if (actualReturn != null)
                    Container(
                      margin: const EdgeInsets.only(top: 8),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.green.withOpacity(0.2),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.check_circle,
                            size: 14,
                            color: Colors.green,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Returned on ${formatDateTime(actualReturn)}',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: Colors.green,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (isOverdue)
                    Container(
                      margin: const EdgeInsets.only(top: 8),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.withOpacity(0.2)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.warning, size: 14, color: Colors.red),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'This item is overdue',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: Colors.red,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),

            // Admin Actions (only for active borrowings)
            if (isBorrowed)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => extendDueDate(
                          borrowId,
                          data['assetName'] ?? 'Item',
                        ),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Colors.grey[300]!),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        icon: const Icon(Icons.calendar_today, size: 18),
                        label: Text(
                          'Extend Due Date',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey[700],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => markAsReturned(
                          borrowId,
                          data['assetName'] ?? 'Item',
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00897B),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        icon: const Icon(Icons.check_circle, size: 18),
                        label: Text(
                          'Mark Returned',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
