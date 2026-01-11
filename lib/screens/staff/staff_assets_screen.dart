import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/cyberpunk_theme.dart';

class StaffAssetsScreen extends StatefulWidget {
  const StaffAssetsScreen({super.key});

  @override
  State<StaffAssetsScreen> createState() => _StaffAssetsScreenState();
}

class _StaffAssetsScreenState extends State<StaffAssetsScreen> {
  List<Map<String, dynamic>> assets = [];
  bool isLoading = true;
  String searchQuery = '';

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
    if (searchQuery.isEmpty) return assets;
    return assets
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

  Future<void> _showAddEditDialog([Map<String, dynamic>? asset]) async {
    final isEdit = asset != null;
    final nameController = TextEditingController(text: asset?['name'] ?? '');
    final categoryController = TextEditingController(
      text: asset?['category'] ?? '',
    );
    final descController = TextEditingController(
      text: asset?['description'] ?? '',
    );
    final serialController = TextEditingController(
      text: asset?['serialNumber'] ?? '',
    );
    final locationController = TextEditingController(
      text: asset?['location'] ?? '',
    );

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: CyberpunkTheme.surfaceDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: CyberpunkTheme.primaryPink.withOpacity(0.3)),
        ),
        title: Text(
          isEdit ? 'EDIT ASSET' : 'ADD ASSET',
          style: GoogleFonts.orbitron(
            color: CyberpunkTheme.primaryPink,
            fontSize: 16,
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildTextField(nameController, 'Asset Name', Icons.inventory_2),
              const SizedBox(height: 12),
              _buildTextField(categoryController, 'Category', Icons.category),
              const SizedBox(height: 12),
              _buildTextField(descController, 'Description', Icons.description),
              const SizedBox(height: 12),
              _buildTextField(serialController, 'Serial Number', Icons.qr_code),
              const SizedBox(height: 12),
              _buildTextField(
                locationController,
                'Location',
                Icons.location_on,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: GoogleFonts.rajdhani(color: CyberpunkTheme.textMuted),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: CyberpunkTheme.primaryPink,
            ),
            onPressed: () async {
              if (nameController.text.isEmpty) return;
              final data = {
                'name': nameController.text,
                'category': categoryController.text,
                'description': descController.text,
                'serialNumber': serialController.text,
                'location': locationController.text,
                'isAvailable': asset?['isAvailable'] ?? true,
                'updatedAt': Timestamp.now(),
              };
              if (!isEdit) data['createdAt'] = Timestamp.now();
              if (isEdit) {
                await FirebaseFirestore.instance
                    .collection('assets')
                    .doc(asset!['id'])
                    .update(data);
              } else {
                await FirebaseFirestore.instance.collection('assets').add(data);
              }
              if (mounted) {
                Navigator.pop(ctx);
                loadAssets();
              }
            },
            child: Text(
              isEdit ? 'Update' : 'Add',
              style: GoogleFonts.rajdhani(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String hint,
    IconData icon,
  ) {
    return TextField(
      controller: controller,
      style: GoogleFonts.rajdhani(color: CyberpunkTheme.textPrimary),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.rajdhani(color: CyberpunkTheme.textMuted),
        prefixIcon: Icon(icon, color: CyberpunkTheme.primaryPink, size: 20),
        filled: true,
        fillColor: CyberpunkTheme.surfaceLight,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),
    );
  }

  Future<void> _deleteAsset(String id, String name) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: CyberpunkTheme.surfaceDark,
        title: Text(
          'Delete Asset?',
          style: GoogleFonts.orbitron(
            color: CyberpunkTheme.statusMaintenance,
            fontSize: 16,
          ),
        ),
        content: Text(
          'Are you sure you want to delete "$name"?',
          style: GoogleFonts.rajdhani(color: CyberpunkTheme.textSecondary),
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
              backgroundColor: CyberpunkTheme.statusMaintenance,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'Delete',
              style: GoogleFonts.rajdhani(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await FirebaseFirestore.instance.collection('assets').doc(id).delete();
      loadAssets();
    }
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
                Expanded(
                  child: Container(
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
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: () => _showAddEditDialog(),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: CyberpunkTheme.primaryGradient,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.add, color: Colors.white, size: 22),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _buildMiniStat(
                  'Total',
                  assets.length,
                  CyberpunkTheme.primaryPink,
                ),
                const SizedBox(width: 8),
                _buildMiniStat(
                  'Available',
                  assets.where((a) => a['isAvailable'] == true).length,
                  CyberpunkTheme.accentGreen,
                ),
                const SizedBox(width: 8),
                _buildMiniStat(
                  'On Loan',
                  assets.where((a) => a['isAvailable'] == false).length,
                  CyberpunkTheme.primaryBlue,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: CyberpunkTheme.primaryPink,
                    ),
                  )
                : filteredAssets.isEmpty
                ? Center(
                    child: Text(
                      'No assets found',
                      style: GoogleFonts.rajdhani(
                        color: CyberpunkTheme.textMuted,
                      ),
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: loadAssets,
                    color: CyberpunkTheme.primaryPink,
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: filteredAssets.length,
                      itemBuilder: (_, i) => _buildAssetItem(filteredAssets[i]),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat(String label, int count, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: CyberpunkTheme.surfaceDark,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text(
              count.toString(),
              style: GoogleFonts.orbitron(
                color: color,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
              style: GoogleFonts.rajdhani(
                color: CyberpunkTheme.textMuted,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAssetItem(Map<String, dynamic> asset) {
    final isAvailable = asset['isAvailable'] == true;
    final color = isAvailable
        ? CyberpunkTheme.accentGreen
        : CyberpunkTheme.primaryBlue;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: CyberpunkTheme.surfaceDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              _getCategoryIcon(asset['category']),
              color: color,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
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
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    isAvailable ? 'Available' : 'On Loan',
                    style: GoogleFonts.rajdhani(
                      color: color,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(
              Icons.edit,
              color: CyberpunkTheme.primaryBlue,
              size: 20,
            ),
            onPressed: () => _showAddEditDialog(asset),
          ),
          IconButton(
            icon: const Icon(
              Icons.delete,
              color: CyberpunkTheme.statusMaintenance,
              size: 20,
            ),
            onPressed: () => _deleteAsset(asset['id'], asset['name']),
          ),
        ],
      ),
    );
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
}
