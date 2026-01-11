import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

class SystemSettingsScreen extends ConsumerWidget {
  const SystemSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'System Settings',
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          _buildSettingsSection('General Settings', [
            _buildSettingsTile(
              'App Name',
              'Zaza Asset Management',
              Icons.label,
            ),
            _buildSettingsTile('Version', '1.0.0', Icons.info),
          ]),
          const SizedBox(height: 20),
          _buildSettingsSection('Borrowing Rules', [
            _buildSettingsTile(
              'Max Borrowing Days',
              '14 days',
              Icons.calendar_today,
            ),
            _buildSettingsTile(
              'Max Items Per User',
              '5 items',
              Icons.inventory,
            ),
          ]),
          const SizedBox(height: 20),
          _buildSettingsSection('Notifications', [
            _buildSwitchTile('Email Notifications', true, (value) {}),
            _buildSwitchTile('SMS Notifications', false, (value) {}),
          ]),
        ],
      ),
    );
  }

  Widget _buildSettingsSection(String title, List<Widget> children) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const Divider(height: 1),
          ...children,
        ],
      ),
    );
  }

  Widget _buildSettingsTile(String title, String value, IconData icon) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF00897B)),
      title: Text(title, style: GoogleFonts.poppins()),
      trailing: Text(
        value,
        style: GoogleFonts.poppins(color: Colors.grey[600]),
      ),
    );
  }

  Widget _buildSwitchTile(
    String title,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return SwitchListTile(
      title: Text(title, style: GoogleFonts.poppins()),
      value: value,
      onChanged: onChanged,
      activeColor: const Color(0xFF00897B),
    );
  }
}
