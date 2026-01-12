// lib/screens/assets_screen.dart - REDESIGNED WITH PINK THEME & CUSTOM RETURN DATE
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

class _AssetsScreenState extends State<AssetsScreen>
    with SingleTickerProviderStateMixin {
  List<Asset> assets = [];
  bool isLoading = true;
  String searchQuery = '';
  String filterStatus = 'All';
  String filterCategory = 'All';
  late AnimationController _animController;

  final List<String> categories = [
    'All',
    'Computer',
    'Laptop',
    'Microphone',
    'Camera',
    'Projector',
    'Audio',
    'Video',
  ];

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _loadAssets();
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
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

    // Status filter
    if (filterStatus == 'Available') {
      result = result.where((asset) => asset.isAvailable).toList();
    } else if (filterStatus == 'Borrowed') {
      result = result.where((asset) => !asset.isAvailable).toList();
    }

    // Category filter
    if (filterCategory != 'All') {
      result = result
          .where(
            (asset) =>
                asset.category.toLowerCase() == filterCategory.toLowerCase(),
          )
          .toList();
    }

    // Search filter
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
    // Show borrow dialog with custom return date
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => _BorrowRequestDialog(asset: asset),
    );

    if (result != null) {
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
        final returnDate = result['returnDate'] as DateTime;
        final purpose = result['purpose'] as String;
        final notes = result['notes'] as String;

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
          'requestedReturnDate': Timestamp.fromDate(returnDate),
          'status': 'pending',
          'expectedReturnDate': null,
          'approvedDate': null,
          'borrowedDate': null,
          'actualReturnDate': null,
          'rejectionReason': null,
          'purpose': purpose,
          'notes': notes,
          'createdAt': Timestamp.fromDate(now),
          'updatedAt': Timestamp.fromDate(now),
        });

        _showSuccess('Request submitted! Admin will review within 24 hours.');
        _loadAssets();
      } catch (e) {
        _showError('Error: $e');
        debugPrint('Error creating borrow request: $e');
      }
    }
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.rajdhani(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: CyberpunkTheme.neonGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.rajdhani(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: CyberpunkTheme.primaryPink,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
          // Header - NO GRADIENT to avoid stacking
          Container(
            color: CyberpunkTheme.deepBlack,
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'EXPLORE ASSETS',
                  style: GoogleFonts.orbitron(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFFFF10F0), // Updated pink
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 16),

                // Search Bar - Fixed stacking issue
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A0004), // Updated black
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(
                        0xFFFF10F0,
                      ).withOpacity(0.5), // Updated pink
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFF10F0).withOpacity(0.2),
                        blurRadius: 15,
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.search,
                        color: Color(0xFFFF10F0),
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          style: GoogleFonts.rajdhani(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Search by name, category, serial...',
                            hintStyle: GoogleFonts.rajdhani(
                              color: Colors.white54,
                            ),
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                          onChanged: (value) =>
                              setState(() => searchQuery = value),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Category Filter Chips
                SizedBox(
                  height: 40,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: categories.length,
                    itemBuilder: (context, index) {
                      final category = categories[index];
                      final isSelected = filterCategory == category;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(category),
                          labelStyle: GoogleFonts.rajdhani(
                            color: isSelected
                                ? Colors.white
                                : CyberpunkTheme.textMuted,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() => filterCategory = category);
                          },
                          backgroundColor: CyberpunkTheme.surfaceDark,
                          selectedColor: CyberpunkTheme.primaryPink,
                          checkmarkColor: Colors.white,
                          side: BorderSide(
                            color: isSelected
                                ? CyberpunkTheme.primaryPink
                                : CyberpunkTheme.textMuted.withOpacity(0.3),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 12),

                // Status Filter Chips
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
                      CyberpunkTheme.neonGreen,
                    ),
                    const SizedBox(width: 8),
                    _buildFilterChip(
                      'Borrowed',
                      borrowedCount,
                      CyberpunkTheme.primaryCyan,
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Asset List
          Expanded(
            child: isLoading
                ? Center(
                    child: CircularProgressIndicator(
                      color: CyberpunkTheme.primaryPink,
                    ),
                  )
                : filteredAssets.isEmpty
                ? _buildEmptyState()
                : RefreshIndicator(
                    onRefresh: _loadAssets,
                    color: CyberpunkTheme.primaryPink,
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: filteredAssets.length,
                      itemBuilder: (context, index) {
                        return _buildAssetCard(filteredAssets[index], index);
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, int count, Color color) {
    final isSelected = filterStatus == label;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => filterStatus = label),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? color.withOpacity(0.2)
                : CyberpunkTheme.surfaceDark,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? color : color.withOpacity(0.3),
              width: 2,
            ),
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
                label.toUpperCase(),
                style: GoogleFonts.rajdhani(
                  color: isSelected ? color : CyberpunkTheme.textMuted,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 80,
            color: CyberpunkTheme.textMuted.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'NO ASSETS FOUND',
            style: GoogleFonts.orbitron(
              color: CyberpunkTheme.textMuted,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your filters',
            style: GoogleFonts.rajdhani(
              color: CyberpunkTheme.textMuted,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAssetCard(Asset asset, int index) {
    final isAvailable = asset.isAvailable;
    final color = isAvailable
        ? CyberpunkTheme.neonGreen
        : CyberpunkTheme.primaryCyan;

    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 300 + (index * 50)),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(opacity: value, child: child),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: CyberpunkTheme.surfaceDark,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3), width: 2),
          boxShadow: [BoxShadow(color: color.withOpacity(0.1), blurRadius: 20)],
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Icon with glow
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: color.withOpacity(0.3),
                          blurRadius: 15,
                        ),
                      ],
                    ),
                    child: Icon(
                      _getCategoryIcon(asset.category),
                      color: color,
                      size: 32,
                    ),
                  ),

                  const SizedBox(width: 16),

                  // Asset Details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          asset.name,
                          style: GoogleFonts.rajdhani(
                            color: CyberpunkTheme.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          asset.category,
                          style: GoogleFonts.rajdhani(
                            color: CyberpunkTheme.textMuted,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            asset.status.toUpperCase(),
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
                ],
              ),
            ),

            // Borrow Button (only if available)
            if (isAvailable)
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      CyberpunkTheme.primaryPink,
                      CyberpunkTheme.primaryPink.withOpacity(0.8),
                    ],
                  ),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(14),
                    bottomRight: Radius.circular(14),
                  ),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => _borrowAsset(asset),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(14),
                      bottomRight: Radius.circular(14),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.add_shopping_cart,
                            color: Colors.white,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'BORROW THIS ITEM',
                            style: GoogleFonts.rajdhani(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: Colors.white,
                              letterSpacing: 1,
                            ),
                          ),
                        ],
                      ),
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

// ==================== BORROW REQUEST DIALOG ====================
class _BorrowRequestDialog extends StatefulWidget {
  final Asset asset;

  const _BorrowRequestDialog({required this.asset});

  @override
  State<_BorrowRequestDialog> createState() => _BorrowRequestDialogState();
}

class _BorrowRequestDialogState extends State<_BorrowRequestDialog> {
  DateTime selectedDate = DateTime.now().add(const Duration(days: 7));
  final purposeController = TextEditingController();
  final notesController = TextEditingController();

  @override
  void dispose() {
    purposeController.dispose();
    notesController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime.now().add(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 60)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: CyberpunkTheme.primaryPink,
              onPrimary: Colors.white,
              surface: CyberpunkTheme.surfaceDark,
              onSurface: CyberpunkTheme.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() => selectedDate = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: CyberpunkTheme.deepBlack,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: CyberpunkTheme.primaryPink.withOpacity(0.5),
          width: 2,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'BORROW REQUEST',
              style: GoogleFonts.orbitron(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: CyberpunkTheme.primaryPink,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.asset.name,
              style: GoogleFonts.rajdhani(
                fontSize: 16,
                color: CyberpunkTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 20),

            // Return Date Selector
            InkWell(
              onTap: _selectDate,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: CyberpunkTheme.surfaceDark,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: CyberpunkTheme.primaryPink.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      color: CyberpunkTheme.primaryPink,
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'RETURN DATE',
                          style: GoogleFonts.rajdhani(
                            fontSize: 10,
                            color: CyberpunkTheme.textMuted,
                            letterSpacing: 1,
                          ),
                        ),
                        Text(
                          '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                          style: GoogleFonts.orbitron(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: CyberpunkTheme.primaryPink,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Purpose Field
            TextField(
              controller: purposeController,
              style: GoogleFonts.rajdhani(color: CyberpunkTheme.textPrimary),
              decoration: InputDecoration(
                labelText: 'Purpose',
                labelStyle: GoogleFonts.rajdhani(
                  color: CyberpunkTheme.textMuted,
                ),
                filled: true,
                fillColor: CyberpunkTheme.surfaceDark,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: CyberpunkTheme.primaryPink.withOpacity(0.3),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Notes Field
            TextField(
              controller: notesController,
              style: GoogleFonts.rajdhani(color: CyberpunkTheme.textPrimary),
              maxLines: 2,
              decoration: InputDecoration(
                labelText: 'Additional Notes (Optional)',
                labelStyle: GoogleFonts.rajdhani(
                  color: CyberpunkTheme.textMuted,
                ),
                filled: true,
                fillColor: CyberpunkTheme.surfaceDark,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: CyberpunkTheme.primaryPink.withOpacity(0.3),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: CyberpunkTheme.textMuted),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'CANCEL',
                      style: GoogleFonts.rajdhani(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      if (purposeController.text.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Please enter purpose')),
                        );
                        return;
                      }

                      Navigator.pop(context, {
                        'returnDate': selectedDate,
                        'purpose': purposeController.text,
                        'notes': notesController.text,
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: CyberpunkTheme.primaryPink,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'SUBMIT',
                      style: GoogleFonts.rajdhani(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
