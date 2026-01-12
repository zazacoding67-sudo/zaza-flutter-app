// lib/screens/staff/asset_inventory_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../theme/cyberpunk_theme.dart';
import '../../services/staff_service.dart';
import '../../models/asset.dart';

class AssetInventoryScreen extends StatefulWidget {
  const AssetInventoryScreen({super.key});

  @override
  State<AssetInventoryScreen> createState() => _AssetInventoryScreenState();
}

class _AssetInventoryScreenState extends State<AssetInventoryScreen> {
  final StaffService _staffService = StaffService();
  List<Asset> _assets = [];
  List<Asset> _filteredAssets = [];
  bool _isLoading = true;
  String _selectedFilter = 'All';
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadAssets();
  }

  Future<void> _loadAssets() async {
    setState(() => _isLoading = true);
    try {
      final assets = await _staffService.getAllAssetsForInventory();
      setState(() {
        _assets = assets;
        _applyFilters();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading assets: $e'),
            backgroundColor: CyberpunkTheme.warningYellow,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _applyFilters() {
    setState(() {
      _filteredAssets = _assets.where((asset) {
        // Status filter
        final statusMatch =
            _selectedFilter == 'All' || asset.status == _selectedFilter;

        // Search filter
        final searchMatch =
            _searchQuery.isEmpty ||
            asset.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            asset.category.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            asset.serialNumber.toLowerCase().contains(
              _searchQuery.toLowerCase(),
            ) ||
            asset.location.toLowerCase().contains(_searchQuery.toLowerCase());

        return statusMatch && searchMatch;
      }).toList();
    });
  }

  void _showAssetDetails(Asset asset) {
    showModalBottomSheet(
      context: context,
      backgroundColor: CyberpunkTheme.surfaceDark,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) =>
          _AssetDetailsSheet(asset: asset, onUpdated: _loadAssets),
    );
  }

  void _showReportIssueDialog(Asset asset) {
    final issueController = TextEditingController();
    String selectedIssueType = 'Damage';
    String selectedUrgency = 'medium';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: CyberpunkTheme.surfaceDark,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'Report Issue',
            style: GoogleFonts.rajdhani(
              color: CyberpunkTheme.primaryPink,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  asset.name,
                  style: GoogleFonts.rajdhani(
                    color: CyberpunkTheme.textPrimary,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Issue Type',
                  style: GoogleFonts.rajdhani(
                    color: CyberpunkTheme.textMuted,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: selectedIssueType,
                  dropdownColor: CyberpunkTheme.cardDark,
                  style: GoogleFonts.rajdhani(
                    color: CyberpunkTheme.textPrimary,
                  ),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: CyberpunkTheme.cardDark,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: CyberpunkTheme.primaryCyan.withAlpha(77),
                      ),
                    ),
                  ),
                  items:
                      [
                            'Damage',
                            'Malfunction',
                            'Missing Parts',
                            'Wear & Tear',
                            'Other',
                          ]
                          .map(
                            (type) => DropdownMenuItem(
                              value: type,
                              child: Text(type),
                            ),
                          )
                          .toList(),
                  onChanged: (value) {
                    setDialogState(() => selectedIssueType = value!);
                  },
                ),
                const SizedBox(height: 16),
                Text(
                  'Urgency',
                  style: GoogleFonts.rajdhani(
                    color: CyberpunkTheme.textMuted,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: selectedUrgency,
                  dropdownColor: CyberpunkTheme.cardDark,
                  style: GoogleFonts.rajdhani(
                    color: CyberpunkTheme.textPrimary,
                  ),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: CyberpunkTheme.cardDark,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: CyberpunkTheme.primaryCyan.withAlpha(77),
                      ),
                    ),
                  ),
                  items: [
                    DropdownMenuItem(value: 'low', child: Text('Low')),
                    DropdownMenuItem(value: 'medium', child: Text('Medium')),
                    DropdownMenuItem(value: 'high', child: Text('High')),
                    DropdownMenuItem(
                      value: 'critical',
                      child: Text('Critical'),
                    ),
                  ],
                  onChanged: (value) {
                    setDialogState(() => selectedUrgency = value!);
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: issueController,
                  maxLines: 4,
                  style: GoogleFonts.rajdhani(
                    color: CyberpunkTheme.textPrimary,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Describe the issue in detail...',
                    hintStyle: GoogleFonts.rajdhani(
                      color: CyberpunkTheme.textMuted,
                    ),
                    filled: true,
                    fillColor: CyberpunkTheme.cardDark,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: CyberpunkTheme.primaryCyan.withAlpha(77),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: GoogleFonts.rajdhani(color: CyberpunkTheme.textMuted),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                if (issueController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please describe the issue')),
                  );
                  return;
                }

                try {
                  await _staffService.reportAssetIssue(
                    asset.id,
                    asset.name,
                    issueType: selectedIssueType,
                    description: issueController.text,
                    urgency: selectedUrgency,
                  );

                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Issue reported successfully'),
                        backgroundColor: CyberpunkTheme.neonGreen,
                      ),
                    );
                    _loadAssets();
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error: $e'),
                        backgroundColor: CyberpunkTheme.warningYellow,
                      ),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: CyberpunkTheme.primaryPink,
              ),
              child: Text(
                'Report',
                style: GoogleFonts.rajdhani(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CyberpunkTheme.deepBlack,
      appBar: AppBar(
        backgroundColor: CyberpunkTheme.surfaceDark,
        title: Text(
          'ASSET INVENTORY',
          style: GoogleFonts.rajdhani(
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadAssets),
        ],
      ),
      body: Column(
        children: [
          // Search and filters
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: CyberpunkTheme.surfaceDark,
              border: Border(
                bottom: BorderSide(
                  color: CyberpunkTheme.primaryCyan.withAlpha(77),
                ),
              ),
            ),
            child: Column(
              children: [
                // Search bar
                TextField(
                  onChanged: (value) {
                    setState(() => _searchQuery = value);
                    _applyFilters();
                  },
                  style: GoogleFonts.rajdhani(
                    color: CyberpunkTheme.textPrimary,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Search by name, category, serial...',
                    hintStyle: GoogleFonts.rajdhani(
                      color: CyberpunkTheme.textMuted,
                    ),
                    prefixIcon: Icon(
                      Icons.search,
                      color: CyberpunkTheme.primaryCyan,
                    ),
                    filled: true,
                    fillColor: CyberpunkTheme.cardDark,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Status filters
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('All'),
                      _buildFilterChip('Available'),
                      _buildFilterChip('In Use'),
                      _buildFilterChip('Maintenance'),
                      _buildFilterChip('Retired'),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Assets list
          Expanded(
            child: _isLoading
                ? Center(
                    child: CircularProgressIndicator(
                      color: CyberpunkTheme.primaryCyan,
                    ),
                  )
                : _filteredAssets.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.inventory_2_outlined,
                          size: 64,
                          color: CyberpunkTheme.textMuted,
                        ),
                        const SizedBox(height: 16),
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
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _filteredAssets.length,
                    itemBuilder: (context, index) {
                      final asset = _filteredAssets[index];
                      return _buildAssetCard(asset);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    final isSelected = _selectedFilter == label;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            _selectedFilter = label;
            _applyFilters();
          });
        },
        labelStyle: GoogleFonts.rajdhani(
          color: isSelected
              ? CyberpunkTheme.deepBlack
              : CyberpunkTheme.textMuted,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
        backgroundColor: CyberpunkTheme.cardDark,
        selectedColor: CyberpunkTheme.primaryCyan,
        checkmarkColor: CyberpunkTheme.deepBlack,
      ),
    );
  }

  Widget _buildAssetCard(Asset asset) {
    Color statusColor;
    switch (asset.status) {
      case 'Available':
        statusColor = CyberpunkTheme.neonGreen;
        break;
      case 'In Use':
        statusColor = CyberpunkTheme.primaryCyan;
        break;
      case 'Maintenance':
        statusColor = CyberpunkTheme.warningYellow;
        break;
      default:
        statusColor = CyberpunkTheme.textMuted;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: CyberpunkTheme.surfaceDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withAlpha(77)),
      ),
      child: InkWell(
        onTap: () => _showAssetDetails(asset),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: statusColor.withAlpha(51),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.devices, color: statusColor, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          asset.name,
                          style: GoogleFonts.rajdhani(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: CyberpunkTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: statusColor.withAlpha(51),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                asset.status,
                                style: GoogleFonts.rajdhani(
                                  fontSize: 11,
                                  color: statusColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              asset.category,
                              style: GoogleFonts.rajdhani(
                                fontSize: 12,
                                color: CyberpunkTheme.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.report_problem,
                      color: CyberpunkTheme.primaryPink,
                    ),
                    onPressed: () => _showReportIssueDialog(asset),
                    tooltip: 'Report Issue',
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Divider(color: CyberpunkTheme.textMuted.withAlpha(51)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _buildInfoRow(
                      Icons.qr_code,
                      'Serial',
                      asset.serialNumber,
                    ),
                  ),
                  Expanded(
                    child: _buildInfoRow(
                      Icons.location_on,
                      'Location',
                      asset.location,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 14, color: CyberpunkTheme.textMuted),
        const SizedBox(width: 4),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.rajdhani(
                  fontSize: 10,
                  color: CyberpunkTheme.textMuted,
                ),
              ),
              Text(
                value,
                style: GoogleFonts.rajdhani(
                  fontSize: 12,
                  color: CyberpunkTheme.textPrimary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// Asset Details Sheet Widget
class _AssetDetailsSheet extends StatefulWidget {
  final Asset asset;
  final VoidCallback onUpdated;

  const _AssetDetailsSheet({required this.asset, required this.onUpdated});

  @override
  State<_AssetDetailsSheet> createState() => _AssetDetailsSheetState();
}

class _AssetDetailsSheetState extends State<_AssetDetailsSheet> {
  final StaffService _staffService = StaffService();
  String _selectedCondition = 'Good';

  Future<void> _updateCondition() async {
    try {
      await _staffService.updateAssetCondition(
        widget.asset.id,
        condition: _selectedCondition,
      );

      if (mounted) {
        Navigator.pop(context);
        widget.onUpdated();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Condition updated successfully'),
            backgroundColor: CyberpunkTheme.neonGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: CyberpunkTheme.warningYellow,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ASSET DETAILS',
            style: GoogleFonts.rajdhani(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: CyberpunkTheme.primaryCyan,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            widget.asset.name,
            style: GoogleFonts.rajdhani(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: CyberpunkTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          _buildDetailRow('Category', widget.asset.category),
          _buildDetailRow('Serial Number', widget.asset.serialNumber),
          _buildDetailRow('Location', widget.asset.location),
          _buildDetailRow('Purchase Date', widget.asset.purchaseDate),
          _buildDetailRow(
            'Purchase Price',
            'RM ${widget.asset.purchasePrice.toStringAsFixed(2)}',
          ),
          _buildDetailRow('Status', widget.asset.status),
          const SizedBox(height: 20),
          Text(
            'Update Condition',
            style: GoogleFonts.rajdhani(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: CyberpunkTheme.textMuted,
            ),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _selectedCondition,
            dropdownColor: CyberpunkTheme.cardDark,
            style: GoogleFonts.rajdhani(color: CyberpunkTheme.textPrimary),
            decoration: InputDecoration(
              filled: true,
              fillColor: CyberpunkTheme.cardDark,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            items: ['Excellent', 'Good', 'Fair', 'Poor', 'Damaged']
                .map(
                  (condition) => DropdownMenuItem(
                    value: condition,
                    child: Text(condition),
                  ),
                )
                .toList(),
            onChanged: (value) {
              setState(() => _selectedCondition = value!);
            },
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _updateCondition,
              style: ElevatedButton.styleFrom(
                backgroundColor: CyberpunkTheme.primaryCyan,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'UPDATE CONDITION',
                style: GoogleFonts.rajdhani(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: GoogleFonts.rajdhani(
                fontSize: 12,
                color: CyberpunkTheme.textMuted,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.rajdhani(
                fontSize: 14,
                color: CyberpunkTheme.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
