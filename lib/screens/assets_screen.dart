import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
import 'asset_detail_screen.dart';
import 'my_borrowed_screen.dart';

class AssetsScreen extends StatefulWidget {
  const AssetsScreen({super.key});

  @override
  State<AssetsScreen> createState() => _AssetsScreenState();
}

class _AssetsScreenState extends State<AssetsScreen> {
  List<dynamic> assets = [];
  List<dynamic> filteredAssets = [];
  bool isLoading = true;
  String selectedFilter = 'All';
  String searchQuery = '';
  bool showSearchBar = false;
  bool isAdmin = false;

  @override
  void initState() {
    super.initState();
    loadAssets();
    checkUserRole();
  }

  Future<void> checkUserRole() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (mounted) {
        setState(() {
          isAdmin = userDoc.data()?['role'] == 'admin';
        });
      }
    }
  }

  Future<void> loadAssets() async {
    try {
      final data = await ApiService.getAssets();
      if (mounted) {
        setState(() {
          assets = data;
          filteredAssets = data;
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading assets: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void filterAssets(String filter) {
    setState(() {
      selectedFilter = filter;
      applyFilters();
    });
  }

  void applyFilters() {
    List<dynamic> tempAssets = assets;

    // Apply status filter
    if (selectedFilter != 'All') {
      tempAssets = tempAssets
          .where((asset) => asset['status'] == selectedFilter)
          .toList();
    }

    // Apply search filter
    if (searchQuery.isNotEmpty) {
      tempAssets = tempAssets
          .where(
            (asset) =>
                (asset['asset_name'] ?? '').toLowerCase().contains(
                  searchQuery.toLowerCase(),
                ) ||
                (asset['brand'] ?? '').toLowerCase().contains(
                  searchQuery.toLowerCase(),
                ) ||
                (asset['model'] ?? '').toLowerCase().contains(
                  searchQuery.toLowerCase(),
                ) ||
                (asset['serial_number'] ?? '').toLowerCase().contains(
                  searchQuery.toLowerCase(),
                ),
          )
          .toList();
    }

    setState(() {
      filteredAssets = tempAssets;
    });
  }

  Future<void> borrowAsset(Map<String, dynamic> asset) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please login first'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      // Get user data from Firestore
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      final userData = userDoc.data();

      // Create borrow record
      await FirebaseFirestore.instance.collection('borrow_records').add({
        'assetId': asset['id'],
        'assetName': asset['asset_name'],
        'category': asset['category'],
        'brand': asset['brand'],
        'model': asset['model'],
        'serialNumber': asset['serial_number'],
        'userId': user.uid,
        'userName': userData?['name'] ?? 'Unknown User',
        'userEmail': user.email,
        'userStaffId': userData?['staffId'] ?? '',
        'borrowedDate': FieldValue.serverTimestamp(),
        'expectedReturnDate': DateTime.now().add(const Duration(days: 7)),
        'actualReturnDate': null,
        'status': 'Borrowed',
        'conditionBefore': asset['condition_status'],
        'conditionAfter': null,
        'notes': '',
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Successfully borrowed ${asset['asset_name']}'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );

      // Refresh assets list
      loadAssets();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Borrow failed: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Color getStatusColor(String status) {
    switch (status) {
      case 'Available':
        return Colors.green;
      case 'Borrowed':
        return Colors.orange;
      case 'Maintenance':
        return Colors.red;
      case 'Retired':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  IconData getCategoryIcon(String category) {
    switch (category) {
      case 'Computer':
        return Icons.laptop_mac;
      case 'Furniture':
        return Icons.chair;
      case 'Electronics':
        return Icons.devices;
      case 'Tools':
        return Icons.build_circle;
      case 'Vehicle':
        return Icons.directions_car;
      default:
        return Icons.category;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: showSearchBar
            ? TextField(
                autofocus: true,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Search assets...',
                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
                  border: InputBorder.none,
                  icon: const Icon(Icons.search, color: Colors.white),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () {
                      setState(() {
                        showSearchBar = false;
                        searchQuery = '';
                        applyFilters();
                      });
                    },
                  ),
                ),
                onChanged: (value) {
                  setState(() {
                    searchQuery = value;
                    applyFilters();
                  });
                },
              )
            : Text(
                'Asset Inventory',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  fontSize: 20,
                ),
              ),
        backgroundColor: const Color(0xFF00897B),
        foregroundColor: Colors.white,
        elevation: 2,
        actions: [
          if (!showSearchBar)
            IconButton(
              icon: const Icon(Icons.search, size: 24),
              onPressed: () {
                setState(() {
                  showSearchBar = true;
                });
              },
            ),
          IconButton(
            icon: const Icon(Icons.refresh, size: 24),
            onPressed: () {
              setState(() {
                isLoading = true;
              });
              loadAssets();
            },
          ),
          if (!isAdmin)
            IconButton(
              icon: Badge(
                backgroundColor: Colors.orange,
                child: const Icon(Icons.shopping_bag, size: 24),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const MyBorrowedScreen(),
                  ),
                );
              },
              tooltip: 'My Borrowed Items',
            ),
          const SizedBox(width: 8),
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
                _buildStatItem('Total', assets.length, Icons.inventory),
                _buildStatItem(
                  'Available',
                  assets.where((a) => a['status'] == 'Available').length,
                  Icons.check_circle,
                  color: Colors.green,
                ),
                _buildStatItem(
                  'Borrowed',
                  assets.where((a) => a['status'] == 'Borrowed').length,
                  Icons.assignment,
                  color: Colors.orange,
                ),
                _buildStatItem(
                  'Maintenance',
                  assets.where((a) => a['status'] == 'Maintenance').length,
                  Icons.build,
                  color: Colors.red,
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
                  _buildFilterChip('Available', Icons.check_circle),
                  const SizedBox(width: 8),
                  _buildFilterChip('Borrowed', Icons.assignment_turned_in),
                  const SizedBox(width: 8),
                  _buildFilterChip('Maintenance', Icons.build_circle),
                ],
              ),
            ),
          ),
          const Divider(height: 1, thickness: 1),

          // Results Count
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${filteredAssets.length} ${filteredAssets.length == 1 ? 'Asset' : 'Assets'} Found',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[700],
                  ),
                ),
                if (searchQuery.isNotEmpty)
                  Chip(
                    label: Text('Search: "$searchQuery"'),
                    onDeleted: () {
                      setState(() {
                        searchQuery = '';
                        applyFilters();
                      });
                    },
                  ),
              ],
            ),
          ),

          // Assets Grid/List
          Expanded(
            child: isLoading
                ? _buildLoadingState()
                : filteredAssets.isEmpty
                ? _buildEmptyState()
                : RefreshIndicator(
                    onRefresh: loadAssets,
                    color: const Color(0xFF00897B),
                    child: GridView.builder(
                      padding: const EdgeInsets.all(12),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 0.75,
                          ),
                      itemCount: filteredAssets.length,
                      itemBuilder: (context, index) {
                        final asset = filteredAssets[index];
                        return _buildAssetCard(asset);
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

  Widget _buildFilterChip(String label, IconData icon) {
    final isSelected = selectedFilter == label;
    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: isSelected ? Colors.white : Colors.grey),
          const SizedBox(width: 6),
          Text(label),
        ],
      ),
      selected: isSelected,
      onSelected: (selected) => filterAssets(label),
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
            'Loading Assets...',
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
          Icon(Icons.inventory_2_outlined, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            searchQuery.isEmpty
                ? 'No assets found'
                : 'No assets matching "$searchQuery"',
            style: GoogleFonts.poppins(fontSize: 18, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'Try changing filters or search term',
            style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildAssetCard(Map<String, dynamic> asset) {
    final isAvailable = asset['status'] == 'Available';

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AssetDetailScreen(asset: asset),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon and Status
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00897B).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      getCategoryIcon(asset['category'] ?? ''),
                      color: const Color(0xFF00897B),
                      size: 28,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: getStatusColor(
                        asset['status'] ?? '',
                      ).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      asset['status'] ?? 'Unknown',
                      style: GoogleFonts.poppins(
                        color: getStatusColor(asset['status'] ?? ''),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Asset Name
              Text(
                asset['asset_name'] ?? 'Unnamed Asset',
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),

              const SizedBox(height: 4),

              // Brand & Model
              Text(
                '${asset['brand'] ?? ''} ${asset['model'] ?? ''}'.trim(),
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: Colors.grey[600],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),

              const SizedBox(height: 8),

              // Details Row
              Row(
                children: [
                  Icon(Icons.location_on, size: 14, color: Colors.grey[500]),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      asset['location'] ?? 'Unknown',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 4),

              Row(
                children: [
                  Icon(
                    Icons.confirmation_number,
                    size: 14,
                    color: Colors.grey[500],
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      asset['serial_number'] ?? 'No S/N',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),

              const Spacer(),

              // Borrow Button
              if (isAvailable && !isAdmin)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => borrowAsset(asset),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00897B),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.shopping_bag, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          'Borrow',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // View Details Button (for admin or unavailable items)
              if (!isAvailable || isAdmin)
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AssetDetailScreen(asset: asset),
                        ),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.grey[300]!),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    child: Text(
                      'View Details',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[700],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
