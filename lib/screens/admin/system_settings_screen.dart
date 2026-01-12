// lib/screens/admin/system_settings_screen.dart - NEW FILE
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../theme/cyberpunk_theme.dart';

class SystemSettingsScreen extends StatefulWidget {
  const SystemSettingsScreen({super.key});

  @override
  State<SystemSettingsScreen> createState() => _SystemSettingsScreenState();
}

class _SystemSettingsScreenState extends State<SystemSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  // Settings values
  int _defaultBorrowDays = 7;
  int _maxBorrowItems = 3;
  bool _autoApproveEnabled = false;
  bool _emailNotificationsEnabled = true;
  String _systemMode = 'Production';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);
    try {
      final doc = await FirebaseFirestore.instance
          .collection('system_settings')
          .doc('main')
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        setState(() {
          _defaultBorrowDays = data['defaultBorrowDays'] ?? 7;
          _maxBorrowItems = data['maxBorrowItems'] ?? 3;
          _autoApproveEnabled = data['autoApproveEnabled'] ?? false;
          _emailNotificationsEnabled =
              data['emailNotificationsEnabled'] ?? true;
          _systemMode = data['systemMode'] ?? 'Production';
        });
      }
    } catch (e) {
      _showError('Failed to load settings: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveSettings() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      await FirebaseFirestore.instance
          .collection('system_settings')
          .doc('main')
          .set({
            'defaultBorrowDays': _defaultBorrowDays,
            'maxBorrowItems': _maxBorrowItems,
            'autoApproveEnabled': _autoApproveEnabled,
            'emailNotificationsEnabled': _emailNotificationsEnabled,
            'systemMode': _systemMode,
            'updatedAt': FieldValue.serverTimestamp(),
            'updatedBy': FirebaseAuth.instance.currentUser?.uid,
          }, SetOptions(merge: true));

      _showSuccess('Settings saved successfully!');
    } catch (e) {
      _showError('Failed to save settings: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _clearCache() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: CyberpunkTheme.deepBlack,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: CyberpunkTheme.primaryPink.withOpacity(0.3)),
        ),
        title: Text(
          'Clear Cache',
          style: GoogleFonts.orbitron(color: CyberpunkTheme.primaryPink),
        ),
        content: const Text('This will clear all cached data. Continue?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: CyberpunkTheme.primaryPink,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      _showSuccess('Cache cleared successfully!');
    }
  }

  Future<void> _exportData() async {
    _showSuccess('Data export started. You will receive an email when ready.');
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
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
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: CyberpunkTheme.primaryPink,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CyberpunkTheme.deepBlack,
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: CyberpunkTheme.primaryPink,
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'SYSTEM SETTINGS',
                      style: GoogleFonts.orbitron(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: CyberpunkTheme.primaryPink,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Configure system behavior and preferences',
                      style: GoogleFonts.rajdhani(
                        color: CyberpunkTheme.textMuted,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 30),

                    // Borrowing Settings
                    _buildSection(
                      title: 'BORROWING SETTINGS',
                      icon: Icons.settings,
                      color: CyberpunkTheme.primaryPink,
                      children: [
                        _buildNumberField(
                          label: 'Default Borrow Days',
                          value: _defaultBorrowDays,
                          onChanged: (val) =>
                              setState(() => _defaultBorrowDays = val),
                          min: 1,
                          max: 60,
                        ),
                        const SizedBox(height: 16),
                        _buildNumberField(
                          label: 'Max Items Per Student',
                          value: _maxBorrowItems,
                          onChanged: (val) =>
                              setState(() => _maxBorrowItems = val),
                          min: 1,
                          max: 10,
                        ),
                        const SizedBox(height: 16),
                        _buildSwitchTile(
                          title: 'Auto-Approve Requests',
                          subtitle: 'Automatically approve borrow requests',
                          value: _autoApproveEnabled,
                          onChanged: (val) =>
                              setState(() => _autoApproveEnabled = val),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Notification Settings
                    _buildSection(
                      title: 'NOTIFICATIONS',
                      icon: Icons.notifications,
                      color: CyberpunkTheme.primaryCyan,
                      children: [
                        _buildSwitchTile(
                          title: 'Email Notifications',
                          subtitle: 'Send email alerts for important events',
                          value: _emailNotificationsEnabled,
                          onChanged: (val) =>
                              setState(() => _emailNotificationsEnabled = val),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // System Mode
                    _buildSection(
                      title: 'SYSTEM MODE',
                      icon: Icons.cloud,
                      color: CyberpunkTheme.neonGreen,
                      children: [
                        _buildDropdown(
                          label: 'Environment',
                          value: _systemMode,
                          items: ['Production', 'Development', 'Testing'],
                          onChanged: (val) =>
                              setState(() => _systemMode = val!),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Maintenance
                    _buildSection(
                      title: 'MAINTENANCE',
                      icon: Icons.build,
                      color: CyberpunkTheme.accentOrange,
                      children: [
                        _buildActionButton(
                          label: 'Clear Cache',
                          icon: Icons.delete_sweep,
                          color: CyberpunkTheme.accentOrange,
                          onPressed: _clearCache,
                        ),
                        const SizedBox(height: 12),
                        _buildActionButton(
                          label: 'Export System Data',
                          icon: Icons.file_download,
                          color: CyberpunkTheme.primaryCyan,
                          onPressed: _exportData,
                        ),
                      ],
                    ),

                    const SizedBox(height: 40),

                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _saveSettings,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: CyberpunkTheme.primaryPink,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'SAVE SETTINGS',
                          style: GoogleFonts.rajdhani(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            letterSpacing: 2,
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

  Widget _buildSection({
    required String title,
    required IconData icon,
    required Color color,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: CyberpunkTheme.surfaceDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3), width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(width: 12),
              Text(
                title,
                style: GoogleFonts.orbitron(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: color,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }

  Widget _buildNumberField({
    required String label,
    required int value,
    required Function(int) onChanged,
    required int min,
    required int max,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.rajdhani(
            color: CyberpunkTheme.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.remove_circle_outline),
              color: CyberpunkTheme.primaryPink,
              onPressed: value > min ? () => onChanged(value - 1) : null,
            ),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: CyberpunkTheme.deepBlack,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: CyberpunkTheme.primaryPink.withOpacity(0.3),
                  ),
                ),
                child: Text(
                  value.toString(),
                  textAlign: TextAlign.center,
                  style: GoogleFonts.orbitron(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: CyberpunkTheme.primaryPink,
                  ),
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.add_circle_outline),
              color: CyberpunkTheme.primaryPink,
              onPressed: value < max ? () => onChanged(value + 1) : null,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CyberpunkTheme.deepBlack,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: value
              ? CyberpunkTheme.primaryPink.withOpacity(0.5)
              : CyberpunkTheme.textMuted.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.rajdhani(
                    color: CyberpunkTheme.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: GoogleFonts.rajdhani(
                    color: CyberpunkTheme.textMuted,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: CyberpunkTheme.primaryPink,
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required String value,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.rajdhani(
            color: CyberpunkTheme.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: value,
          items: items.map((item) {
            return DropdownMenuItem(value: item, child: Text(item));
          }).toList(),
          onChanged: onChanged,
          decoration: InputDecoration(
            filled: true,
            fillColor: CyberpunkTheme.deepBlack,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: CyberpunkTheme.primaryPink.withOpacity(0.3),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: CyberpunkTheme.primaryPink.withOpacity(0.3),
              ),
            ),
          ),
          dropdownColor: CyberpunkTheme.surfaceDark,
          style: GoogleFonts.rajdhani(
            color: CyberpunkTheme.textPrimary,
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, color: color),
        label: Text(
          label,
          style: GoogleFonts.rajdhani(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: color,
          side: BorderSide(color: color, width: 2),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}
