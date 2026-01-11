import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/asset.dart';
import '../theme/cyberpunk_theme.dart';

class AssetsScreen extends StatefulWidget {
  const AssetsScreen({super.key});

  @override
  State<AssetsScreen> createState() => _AssetsScreenState();
}

class _AssetsScreenState extends State<AssetsScreen> {
  List<Asset> assets = [];
  bool isLoading = true;
  String searchQuery = '';
  String filterStatus = 'All';

  @override
  void initState() {
    super.initState();
    _loadAssets();
  }

  Future<void> _loadAssets() async {
    setState(() => isLoading = true);
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('assets')
          .orderBy('createdAt', descending: true)
          .get();

      final loadedAssets = snapshot.docs.map((doc) {
        return Asset.fromFirestore(doc.data(), documentId: doc.id);
      }).toList();

      if (mounted) {
        setState(() {
          assets = loadedAssets;
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => isLoading = false);
      }
      debugPrint('Error loading assets: $e');
    }
  }

  List<Asset> get filteredAssets {
    var result = assets;

    // Apply status filter
    if (filterStatus == 'Available') {
      result = result.where((asset) => asset.isAvailable).toList();
    } else if (filterStatus == 'Borrowed') {
      result = result.where((asset) => !asset.isAvailable).toList();
    }

    // Apply search filter
    if (searchQuery.isNotEmpty) {
      final lowerQuery = searchQuery.toLowerCase();
      result = result.where((asset) {
        return asset.name.toLowerCase().contains(lowerQuery) ||
            asset.category.toLowerCase().contains(lowerQuery) ||
            asset.serialNumber.toLowerCase().contains(lowerQuery) ||
            (asset.assetCode ?? '').toLowerCase().contains(lowerQuery);
      }).toList();
    }

    return result;
  }

  Future<void> _borrowAsset(Asset asset) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (!userDoc.exists) {
        _showError('User data not found');
        return;
      }

      final userData = userDoc.data()!;
      final now = DateTime.now();

      // FIXED: Include ALL required fields
      await FirebaseFirestore.instance.collection('borrowings').add({
        'assetId': asset.id,
        'assetName': asset.name,
        'assetCode': asset.assetCode ?? asset.serialNumber,
        'category': asset.category,
        'serialNumber': asset.serialNumber,
        'userId': user.uid,
        'userName': userData['name'] ?? user.email,
        'userEmail': user.email,
        'userStaffId': userData['staffId'] ?? '',
        'userRole': userData['role'] ?? 'student',
        'requestedDate': Timestamp.fromDate(now),
        'status': 'pending',
        'expectedReturnDate': null,
        'approvedDate': null,
        'borrowedDate': null,
        'actualReturnDate': null,
        'rejectionReason': null,
        'purpose': 'General use',
        'notes': '',
        'createdAt': Timestamp.fromDate(now),
        'updatedAt': Timestamp.fromDate(now), // Initialize updatedAt
      });

      _showSuccess('Borrowing request submitted! Waiting for admin approval.');
      _loadAssets();
    } catch (e) {
      _showError('Error: $e');
      debugPrint('Error creating borrow request: $e');
    }
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '✅ $message',
          style: GoogleFonts.rajdhani(fontWeight: FontWeight.w600),
        ),
        backgroundColor: CyberpunkTheme.accentGreen.withOpacity(0.8),
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '❌ $message',
          style: GoogleFonts.rajdhani(fontWeight: FontWeight.w600),
        ),
        backgroundColor: CyberpunkTheme.primaryPink.withOpacity(0.8),
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
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
    final availableCount = assets.where((a) => a.isAvailable).length;
    final borrowedCount = assets.where((a) => !a.isAvailable).length;

    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Search Bar
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: CyberpunkTheme.surfaceDark,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: TextField(
                    style: GoogleFonts.rajdhani(
                      color: CyberpunkTheme.textPrimary,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Search assets...',
                      hintStyle: GoogleFonts.rajdhani(
                        color: CyberpunkTheme.textMuted,
                      ),
                      prefixIcon: const Icon(
                        Icons.search,
                        color: CyberpunkTheme.primaryPink,
                        size: 20,
                      ),
                      border: InputBorder.none,
                    ),
                    onChanged: (value) => setState(() => searchQuery = value),
                  ),
                ),
                const SizedBox(height: 12),

                // Filter Chips
                Row(
                  children: [
                    _buildFilterChip(
                      'All',
                      assets.length,
                      CyberpunkTheme.primaryPink,
                    ),
                    const SizedBox(width: 8),
                    _buildFilterChip(
                      'Available',
                      availableCount,
                      CyberpunkTheme.accentGreen,
                    ),
                    const SizedBox(width: 8),
                    _buildFilterChip(
                      'Borrowed',
                      borrowedCount,
                      CyberpunkTheme.primaryBlue,
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Asset List
          Expanded(
            child: isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: CyberpunkTheme.primaryPink,
                    ),
                  )
                : filteredAssets.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.inventory_2_outlined,
                          size: 50,
                          color: CyberpunkTheme.textMuted.withOpacity(0.5),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No assets found',
                          style: GoogleFonts.rajdhani(
                            color: CyberpunkTheme.textMuted,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _loadAssets,
                    color: CyberpunkTheme.primaryPink,
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: filteredAssets.length,
                      itemBuilder: (context, index) =>
                          _buildAssetCard(filteredAssets[index]),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, int count, Color color) {
    final isSelected = filterStatus == label;
    return GestureDetector(
      onTap: () => setState(() => filterStatus = label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withOpacity(0.2)
              : CyberpunkTheme.surfaceDark,
          borderRadius: BorderRadius.circular(16),
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
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: color.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                count.toString(),
                style: GoogleFonts.rajdhani(
                  color: color,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAssetCard(Asset asset) {
    final isAvailable = asset.isAvailable;
    final color = isAvailable
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
      child: Row(
        children: [
          // Icon
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              _getCategoryIcon(asset.category),
              color: color,
              size: 26,
            ),
          ),

          const SizedBox(width: 14),

          // Asset Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  asset.name,
                  style: GoogleFonts.rajdhani(
                    color: CyberpunkTheme.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${asset.category} • ${asset.assetCode ?? asset.serialNumber}',
                  style: GoogleFonts.rajdhani(
                    color: CyberpunkTheme.textMuted,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    asset.status.toUpperCase(),
                    style: GoogleFonts.rajdhani(
                      color: color,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Borrow Button (only if available)
          if (isAvailable)
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: CyberpunkTheme.primaryPink,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () => _borrowAsset(asset),
              child: Text(
                'Borrow',
                style: GoogleFonts.rajdhani(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: Colors.white,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
