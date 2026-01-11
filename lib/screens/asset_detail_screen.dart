import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../theme/cyberpunk_theme.dart';
import '../services/borrowing_service.dart';

class AssetDetailScreen extends StatefulWidget {
  final Map<String, dynamic> asset;

  const AssetDetailScreen({super.key, required this.asset});

  @override
  State<AssetDetailScreen> createState() => _AssetDetailScreenState();
}

class _AssetDetailScreenState extends State<AssetDetailScreen> {
  final _borrowingService = BorrowingService();
  bool _isLoading = false;

  IconData getCategoryIcon(String c) {
    switch (c.toLowerCase()) {
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

  Color getStatusColor(String s) {
    switch (s) {
      case 'Available':
        return CyberpunkTheme.statusAvailable;
      case 'Borrowed':
      case 'In Use': // Updated to match service status
        return CyberpunkTheme.statusBorrowed;
      case 'Maintenance':
        return CyberpunkTheme.statusMaintenance;
      default:
        return CyberpunkTheme.textMuted;
    }
  }

  Future<void> _showBorrowDialog() async {
    final purposeController = TextEditingController();
    DateTime selectedDate = DateTime.now().add(const Duration(days: 7));

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: CyberpunkTheme.cardDark,
          title: Text(
            'REQUEST ASSET',
            style: CyberpunkTheme.heading3.copyWith(
              color: CyberpunkTheme.primaryCyan,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Return Date:',
                style: CyberpunkTheme.bodyText.copyWith(
                  color: CyberpunkTheme.textMuted,
                ),
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: selectedDate,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                    builder: (context, child) {
                      return Theme(
                        data: CyberpunkTheme.darkTheme,
                        child: child!,
                      );
                    },
                  );
                  if (picked != null) {
                    setDialogState(() => selectedDate = picked);
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: CyberpunkTheme.primaryPink),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        DateFormat('MMM dd, yyyy').format(selectedDate),
                        style: CyberpunkTheme.bodyText,
                      ),
                      const Icon(
                        Icons.calendar_today,
                        color: CyberpunkTheme.primaryPink,
                        size: 16,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: purposeController,
                style: CyberpunkTheme.bodyText,
                decoration: InputDecoration(
                  labelText: 'Purpose',
                  labelStyle: TextStyle(color: CyberpunkTheme.textMuted),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: CyberpunkTheme.textMuted),
                  ),
                  focusedBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: CyberpunkTheme.primaryCyan),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'CANCEL',
                style: TextStyle(color: CyberpunkTheme.textMuted),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: CyberpunkTheme.primaryCyan,
              ),
              onPressed: () {
                Navigator.pop(context);
                _submitBorrowRequest(selectedDate, purposeController.text);
              },
              child: const Text(
                'SUBMIT REQUEST',
                style: TextStyle(color: Colors.black),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitBorrowRequest(DateTime returnDate, String purpose) async {
    setState(() => _isLoading = true);
    try {
      await _borrowingService.createBorrowRequest(
        assetId: widget.asset['id'], // Ensure your asset map has 'id'
        assetName:
            widget.asset['name'] ?? widget.asset['asset_name'] ?? 'Unknown',
        expectedReturnDate: returnDate,
        purpose: purpose.isEmpty ? 'General Use' : purpose,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Request submitted successfully!'),
            backgroundColor: CyberpunkTheme.neonGreen,
          ),
        );
        Navigator.pop(context); // Go back to list
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Handle both 'name' (firebase) and 'asset_name' (legacy) keys
    final assetName =
        widget.asset['name'] ?? widget.asset['asset_name'] ?? 'Unknown Asset';
    final status = widget.asset['status'] ?? 'Unknown';
    final statusColor = getStatusColor(status);

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
            'ASSET DETAILS',
            style: GoogleFonts.orbitron(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: CyberpunkTheme.primaryPink,
              letterSpacing: 2,
            ),
          ),
        ),
        body: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  color: CyberpunkTheme.primaryCyan,
                ),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Card
                    CyberCard(
                      borderColor: statusColor,
                      child: Column(
                        children: [
                          Row(
                            children: [
                              NeonIconContainer(
                                icon: getCategoryIcon(
                                  widget.asset['category'] ?? '',
                                ),
                                color: CyberpunkTheme.primaryBlue,
                                size: 64,
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      assetName,
                                      style: GoogleFonts.rajdhani(
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                        color: CyberpunkTheme.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${widget.asset['brand'] ?? ''} ${widget.asset['model'] ?? ''}'
                                          .trim(),
                                      style: GoogleFonts.rajdhani(
                                        fontSize: 14,
                                        color: CyberpunkTheme.textMuted,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    StatusBadge(status: status),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Details Card
                    CyberCard(
                      borderColor: CyberpunkTheme.primaryPurple,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'DETAILS',
                            style: GoogleFonts.orbitron(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: CyberpunkTheme.textPrimary,
                              letterSpacing: 2,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildDetailRow(
                            'Category',
                            widget.asset['category'] ?? 'N/A',
                          ),
                          _buildDetailRow(
                            'Serial Number',
                            widget.asset['serialNumber'] ??
                                widget.asset['serial_number'] ??
                                'N/A',
                          ),
                          _buildDetailRow(
                            'Location',
                            widget.asset['location'] ?? 'N/A',
                          ),
                          _buildDetailRow(
                            'Condition',
                            widget.asset['condition'] ??
                                widget.asset['condition_status'] ??
                                'N/A',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Action Button - NOW FUNCTIONAL
                    if (status == 'Available')
                      SizedBox(
                        width: double.infinity,
                        child: CyberButton(
                          text: 'REQUEST TO BORROW',
                          icon: Icons.assignment_add,
                          onPressed: _showBorrowDialog,
                        ),
                      ),
                  ],
                ),
              ),
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
                fontSize: 13,
                color: CyberpunkTheme.textMuted,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.rajdhani(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: CyberpunkTheme.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
