import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/cyberpunk_theme.dart';

class AssetDetailScreen extends StatelessWidget {
  final Map<String, dynamic> asset;

  const AssetDetailScreen({super.key, required this.asset});

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
        return CyberpunkTheme.statusBorrowed;
      case 'Maintenance':
        return CyberpunkTheme.statusMaintenance;
      default:
        return CyberpunkTheme.textMuted;
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = asset['status'] ?? 'Unknown';
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
        body: SingleChildScrollView(
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
                          icon: getCategoryIcon(asset['category'] ?? ''),
                          color: CyberpunkTheme.primaryBlue,
                          size: 64,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                asset['asset_name'] ?? 'Unknown Asset',
                                style: GoogleFonts.rajdhani(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: CyberpunkTheme.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${asset['brand'] ?? ''} ${asset['model'] ?? ''}'
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
                    _buildDetailRow('Category', asset['category'] ?? 'N/A'),
                    _buildDetailRow(
                      'Serial Number',
                      asset['serial_number'] ?? 'N/A',
                    ),
                    _buildDetailRow('Location', asset['location'] ?? 'N/A'),
                    _buildDetailRow(
                      'Condition',
                      asset['condition_status'] ?? 'N/A',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Action Button
              if (status == 'Available')
                SizedBox(
                  width: double.infinity,
                  child: CyberButton(
                    text: 'BORROW THIS ASSET',
                    icon: Icons.shopping_bag,
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Use the Browse screen to borrow',
                            style: GoogleFonts.rajdhani(),
                          ),
                          backgroundColor: CyberpunkTheme.surfaceLight,
                        ),
                      );
                      Navigator.pop(context);
                    },
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
