import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/cyberpunk_theme.dart';

class AssetsScreen extends StatefulWidget {
  const AssetsScreen({super.key});

  @override
  State<AssetsScreen> createState() => _AssetsScreenState();
}

class _AssetsScreenState extends State<AssetsScreen> {
  List<Map<String, dynamic>> assets = [];
  bool isLoading = true;
  String searchQuery = '';
  String filterStatus = 'All';

  @override
  void initState() {
    super.initState();
    loadAssets();
  }

  Future<void> loadAssets() async {
    setState(() => isLoading = true);
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('assets')
          .get();
      final loadedAssets = snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'name': data['name'] ?? 'Unnamed',
          'category': data['category'] ?? 'Unknown',
          'description': data['description'] ?? '',
          'serialNumber': data['serialNumber'] ?? '',
          'isAvailable': data['isAvailable'] ?? true,
          'location': data['location'] ?? '',
        };
      }).toList();
      if (mounted)
        setState(() {
          assets = loadedAssets;
          isLoading = false;
        });
    } catch (e) {
      if (mounted) setState(() => isLoading = false);
    }
  }

  List<Map<String, dynamic>> get filteredAssets {
    var result = assets;
    if (filterStatus == 'Available')
      result = result.where((a) => a['isAvailable'] == true).toList();
    else if (filterStatus == 'Borrowed')
      result = result.where((a) => a['isAvailable'] == false).toList();
    if (searchQuery.isNotEmpty) {
      result = result
          .where(
            (a) =>
                (a['name'] ?? '').toLowerCase().contains(
                  searchQuery.toLowerCase(),
                ) ||
                (a['category'] ?? '').toLowerCase().contains(
                  searchQuery.toLowerCase(),
                ),
          )
          .toList();
    }
    return result;
  }

  Future<void> borrowAsset(Map<String, dynamic> asset) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      final userData = userDoc.data();
      final now = DateTime.now();
      final expectedReturn = now.add(const Duration(days: 7));

      await FirebaseFirestore.instance.collection('borrow_records').add({
        'assetId': asset['id'],
        'assetName': asset['name'],
        'category': asset['category'],
        'serialNumber': asset['serialNumber'],
        'userId': user.uid,
        'userName': userData?['name'] ?? user.email,
        'userEmail': user.email,
        'userStaffId': userData?['staffId'] ?? '',
        'borrowedDate': Timestamp.fromDate(now),
        'expectedReturnDate': Timestamp.fromDate(expectedReturn),
        'actualReturnDate': null,
        'status': 'Borrowed',
        'createdAt': Timestamp.fromDate(now),
      });

      await FirebaseFirestore.instance
          .collection('assets')
          .doc(asset['id'])
          .update({'isAvailable': false});

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '✅ Successfully borrowed ${asset['name']}!',
              style: GoogleFonts.rajdhani(fontWeight: FontWeight.w600),
            ),
            backgroundColor: CyberpunkTheme.surfaceDark,
          ),
        );
        loadAssets();
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error: $e'),
            backgroundColor: CyberpunkTheme.surfaceDark,
          ),
        );
    }
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
    final availableCount = assets.where((a) => a['isAvailable'] == true).length;
    final borrowedCount = assets.where((a) => a['isAvailable'] == false).length;

    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
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
                    onChanged: (v) => setState(() => searchQuery = v),
                  ),
                ),
                const SizedBox(height: 12),
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
                          ),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: loadAssets,
                    color: CyberpunkTheme.primaryPink,
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: filteredAssets.length,
                      itemBuilder: (_, i) => _buildAssetCard(filteredAssets[i]),
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

  Widget _buildAssetCard(Map<String, dynamic> asset) {
    final isAvailable = asset['isAvailable'] == true;
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
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              _getCategoryIcon(asset['category']),
              color: color,
              size: 26,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  asset['name'],
                  style: GoogleFonts.rajdhani(
                    color: CyberpunkTheme.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${asset['category']} • ${asset['serialNumber']}',
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
                    isAvailable ? 'AVAILABLE' : 'ON LOAN',
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
              onPressed: () => borrowAsset(asset),
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
