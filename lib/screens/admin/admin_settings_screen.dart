// lib/screens/admin/admin_settings_screen.dart - Admin Settings
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../theme/cyberpunk_theme.dart';
import '../../widgets/cyber_widgets.dart';

class AdminSettingsScreen extends StatefulWidget {
  const AdminSettingsScreen({super.key});

  @override
  State<AdminSettingsScreen> createState() => _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends State<AdminSettingsScreen> {
  bool _emailNotifications = true;
  bool _pushNotifications = true;
  bool _autoApproval = false;
  bool _allowStudentQR = true;
  int _defaultBorrowDays = 7;
  int _maxBorrowDays = 30;
  int _maxItemsPerStudent = 5;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final doc = await FirebaseFirestore.instance
            .collection('settings')
            .doc('app_settings')
            .get();

        if (doc.exists) {
          final data = doc.data()!;
          setState(() {
            _emailNotifications = data['emailNotifications'] ?? true;
            _pushNotifications = data['pushNotifications'] ?? true;
            _autoApproval = data['autoApproval'] ?? false;
            _allowStudentQR = data['allowStudentQR'] ?? true;
            _defaultBorrowDays = data['defaultBorrowDays'] ?? 7;
            _maxBorrowDays = data['maxBorrowDays'] ?? 30;
            _maxItemsPerStudent = data['maxItemsPerStudent'] ?? 5;
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading settings: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveSettings() async {
    setState(() => _isLoading = true);
    try {
      await FirebaseFirestore.instance
          .collection('settings')
          .doc('app_settings')
          .set({
            'emailNotifications': _emailNotifications,
            'pushNotifications': _pushNotifications,
            'autoApproval': _autoApproval,
            'allowStudentQR': _allowStudentQR,
            'defaultBorrowDays': _defaultBorrowDays,
            'maxBorrowDays': _maxBorrowDays,
            'maxItemsPerStudent': _maxItemsPerStudent,
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));

      _showSuccess('Settings saved successfully!');
    } catch (e) {
      _showError('Failed to save settings: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 12),
            Text(
              message,
              style: GoogleFonts.rajdhani(fontWeight: FontWeight.bold),
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
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                CyberpunkTheme.primaryPink,
                CyberpunkTheme.primaryPink.withOpacity(0.7),
              ],
            ),
          ),
        ),
        title: Text(
          'SETTINGS',
          style: GoogleFonts.orbitron(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(Icons.save, color: Colors.white),
            onPressed: _isLoading ? null : _saveSettings,
            tooltip: 'Save Settings',
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: CyberpunkTheme.primaryPink,
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // Notifications Section
                _buildSectionHeader(
                  'NOTIFICATIONS',
                  Icons.notifications_active,
                  CyberpunkTheme.primaryCyan,
                ),
                const SizedBox(height: 12),

                _buildSettingCard(
                  title: 'Email Notifications',
                  subtitle: 'Receive emails for new requests and updates',
                  value: _emailNotifications,
                  icon: Icons.email,
                  color: CyberpunkTheme.primaryCyan,
                  onChanged: (val) => setState(() => _emailNotifications = val),
                ),

                _buildSettingCard(
                  title: 'Push Notifications',
                  subtitle: 'Get instant notifications on your device',
                  value: _pushNotifications,
                  icon: Icons.notifications,
                  color: CyberpunkTheme.primaryCyan,
                  onChanged: (val) => setState(() => _pushNotifications = val),
                ),

                const SizedBox(height: 24),

                // Borrowing System Section
                _buildSectionHeader(
                  'BORROWING SYSTEM',
                  Icons.settings,
                  CyberpunkTheme.neonGreen,
                ),
                const SizedBox(height: 12),

                _buildSettingCard(
                  title: 'Auto-Approval Mode',
                  subtitle: 'Automatically approve requests from trusted users',
                  value: _autoApproval,
                  icon: Icons.speed,
                  color: CyberpunkTheme.accentOrange,
                  onChanged: (val) => setState(() => _autoApproval = val),
                ),

                _buildSettingCard(
                  title: 'Allow Student QR Scanning',
                  subtitle: 'Let students scan QR codes for quick borrowing',
                  value: _allowStudentQR,
                  icon: Icons.qr_code_scanner,
                  color: CyberpunkTheme.neonGreen,
                  onChanged: (val) => setState(() => _allowStudentQR = val),
                ),

                const SizedBox(height: 16),

                _buildSliderCard(
                  title: 'Default Borrow Duration',
                  subtitle: 'Standard number of days for borrowing',
                  value: _defaultBorrowDays.toDouble(),
                  min: 1,
                  max: 60,
                  divisions: 59,
                  displayValue: '$_defaultBorrowDays days',
                  icon: Icons.calendar_today,
                  color: CyberpunkTheme.primaryPink,
                  onChanged: (val) =>
                      setState(() => _defaultBorrowDays = val.toInt()),
                ),

                _buildSliderCard(
                  title: 'Maximum Borrow Duration',
                  subtitle: 'Longest time a student can borrow an item',
                  value: _maxBorrowDays.toDouble(),
                  min: 7,
                  max: 90,
                  divisions: 83,
                  displayValue: '$_maxBorrowDays days',
                  icon: Icons.event,
                  color: CyberpunkTheme.primaryPink,
                  onChanged: (val) =>
                      setState(() => _maxBorrowDays = val.toInt()),
                ),

                _buildSliderCard(
                  title: 'Max Items Per Student',
                  subtitle: 'Maximum items one student can borrow',
                  value: _maxItemsPerStudent.toDouble(),
                  min: 1,
                  max: 20,
                  divisions: 19,
                  displayValue: '$_maxItemsPerStudent items',
                  icon: Icons.inventory,
                  color: CyberpunkTheme.primaryPink,
                  onChanged: (val) =>
                      setState(() => _maxItemsPerStudent = val.toInt()),
                ),

                const SizedBox(height: 24),

                // App Information Section
                _buildSectionHeader(
                  'APP INFORMATION',
                  Icons.info,
                  CyberpunkTheme.primaryCyan,
                ),
                const SizedBox(height: 12),

                _buildInfoCard('App Name', 'Zaza Asset Management'),
                _buildInfoCard('Version', '1.0.0'),
                _buildInfoCard('Build', '2025.01.12'),
                _buildInfoCard('Theme', 'Cyberpunk Pink/Black'),
                _buildInfoCard('Database', 'Cloud Firestore'),

                const SizedBox(height: 24),

                // Account Section
                _buildSectionHeader(
                  'ACCOUNT',
                  Icons.person,
                  CyberpunkTheme.accentOrange,
                ),
                const SizedBox(height: 12),

                _buildActionButton(
                  'Change Password',
                  Icons.lock_reset,
                  CyberpunkTheme.primaryCyan,
                  () {
                    // TODO: Implement password change
                    _showError('Coming soon!');
                  },
                ),

                const SizedBox(height: 24),

                // Danger Zone
                _buildSectionHeader(
                  'DANGER ZONE',
                  Icons.warning,
                  CyberpunkTheme.primaryPink,
                ),
                const SizedBox(height: 12),

                _buildDangerButton(
                  'Clear All Cache',
                  Icons.delete_sweep,
                  () async {
                    final confirm = await _showConfirmDialog(
                      'Clear Cache?',
                      'This will clear all cached data.',
                    );
                    if (confirm == true) {
                      _showSuccess('Cache cleared!');
                    }
                  },
                ),

                const SizedBox(height: 8),

                _buildDangerButton('Reset Settings', Icons.restore, () async {
                  final confirm = await _showConfirmDialog(
                    'Reset Settings?',
                    'This will restore all settings to default values.',
                  );
                  if (confirm == true) {
                    setState(() {
                      _emailNotifications = true;
                      _pushNotifications = true;
                      _autoApproval = false;
                      _allowStudentQR = true;
                      _defaultBorrowDays = 7;
                      _maxBorrowDays = 30;
                      _maxItemsPerStudent = 5;
                    });
                    _saveSettings();
                  }
                }),

                const SizedBox(height: 100),
              ],
            ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: GoogleFonts.orbitron(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
            letterSpacing: 2,
          ),
        ),
      ],
    );
  }

  Widget _buildSettingCard({
    required String title,
    required String subtitle,
    required bool value,
    required IconData icon,
    required Color color,
    required Function(bool) onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: CyberpunkTheme.surfaceDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: SwitchListTile(
        value: value,
        onChanged: onChanged,
        secondary: Icon(icon, color: color),
        title: Text(
          title,
          style: GoogleFonts.rajdhani(
            color: CyberpunkTheme.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: GoogleFonts.rajdhani(
            color: CyberpunkTheme.textMuted,
            fontSize: 12,
          ),
        ),
        activeColor: color,
        activeTrackColor: color.withOpacity(0.3),
      ),
    );
  }

  Widget _buildSliderCard({
    required String title,
    required String subtitle,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required String displayValue,
    required IconData icon,
    required Color color,
    required Function(double) onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CyberpunkTheme.surfaceDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.rajdhani(
                        color: CyberpunkTheme.textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
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
              Text(
                displayValue,
                style: GoogleFonts.orbitron(
                  color: color,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: color,
              inactiveTrackColor: color.withOpacity(0.2),
              thumbColor: color,
              overlayColor: color.withOpacity(0.2),
            ),
            child: Slider(
              value: value,
              min: min,
              max: max,
              divisions: divisions,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(String title, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CyberpunkTheme.surfaceDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: CyberpunkTheme.primaryCyan.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: GoogleFonts.rajdhani(
              color: CyberpunkTheme.textMuted,
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.rajdhani(
              color: CyberpunkTheme.primaryCyan,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: CyberpunkTheme.surfaceDark,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 12),
            Text(
              title,
              style: GoogleFonts.rajdhani(
                color: CyberpunkTheme.textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            const Spacer(),
            Icon(Icons.arrow_forward_ios, color: color, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildDangerButton(String title, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: CyberpunkTheme.surfaceDark,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: CyberpunkTheme.primaryPink.withOpacity(0.5),
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: CyberpunkTheme.primaryPink),
            const SizedBox(width: 12),
            Text(
              title,
              style: GoogleFonts.rajdhani(
                color: CyberpunkTheme.primaryPink,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            const Spacer(),
            Icon(
              Icons.arrow_forward_ios,
              color: CyberpunkTheme.primaryPink,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Future<bool?> _showConfirmDialog(String title, String message) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: CyberpunkTheme.surfaceDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: CyberpunkTheme.primaryPink.withOpacity(0.5)),
        ),
        title: Text(
          title,
          style: GoogleFonts.orbitron(
            color: CyberpunkTheme.primaryPink,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          message,
          style: GoogleFonts.rajdhani(color: CyberpunkTheme.textPrimary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'CANCEL',
              style: GoogleFonts.rajdhani(
                color: CyberpunkTheme.textMuted,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: CyberpunkTheme.primaryPink,
            ),
            child: Text(
              'CONFIRM',
              style: GoogleFonts.rajdhani(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
