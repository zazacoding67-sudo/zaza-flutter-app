import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SystemSettingsScreen extends StatelessWidget {
  const SystemSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'System Settings',
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Configure system preferences and rules',
            style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[600]),
          ),
          const SizedBox(height: 30),

          // Borrowing Rules
          _buildSettingsSection('Borrowing Rules', Icons.rule, Colors.blue, [
            _buildSettingItem('Maximum borrow days', '7 days', () {}),
            _buildSettingItem('Max items per user', '3 items', () {}),
            _buildSettingItem('Require admin approval', 'Enabled', () {}),
            _buildSettingItem('Late fee per day', 'RM 5.00', () {}),
          ]),

          const SizedBox(height: 20),

          // Categories Management
          _buildSettingsSection(
            'Asset Categories',
            Icons.category,
            Colors.green,
            [
              _buildSettingItem(
                'Manage categories',
                'Edit, add, or remove',
                () {},
              ),
              _buildSettingItem('Default categories', '5 active', () {}),
            ],
          ),

          const SizedBox(height: 20),

          // Notifications
          _buildSettingsSection(
            'Notifications',
            Icons.notifications,
            Colors.orange,
            [
              _buildSettingItem('Email reminders', 'Enabled', () {}),
              _buildSettingItem('Overdue alerts', 'Daily', () {}),
              _buildSettingItem('Return confirmations', 'Enabled', () {}),
            ],
          ),

          const SizedBox(height: 20),

          // System Maintenance
          _buildSettingsSection(
            'System Maintenance',
            Icons.settings,
            Colors.purple,
            [
              _buildSettingItem('Backup database', 'Last: Never', () {}),
              _buildSettingItem('View audit logs', 'System activity', () {}),
              _buildSettingItem('Clear cache', 'Free up space', () {}),
            ],
          ),

          const SizedBox(height: 30),

          Card(
            color: Colors.amber[50],
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Icon(Icons.construction, size: 60, color: Colors.amber[700]),
                  const SizedBox(height: 16),
                  Text(
                    'Settings Configuration Coming Soon',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Full configuration options will be available here',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.grey[700],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsSection(
    String title,
    IconData icon,
    Color color,
    List<Widget> children,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildSettingItem(String title, String value, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: GoogleFonts.poppins(fontSize: 14)),
            Row(
              children: [
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(Icons.chevron_right, size: 20, color: Colors.grey[400]),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
