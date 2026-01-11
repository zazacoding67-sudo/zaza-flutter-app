import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/cyberpunk_theme.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  List<Map<String, dynamic>> users = [];
  bool isLoading = true;
  String filterRole = 'All';

  @override
  void initState() {
    super.initState();
    loadUsers();
  }

  Future<void> loadUsers() async {
    setState(() => isLoading = true);
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .get();
      final loadedUsers = snapshot.docs
          .map((doc) => {'id': doc.id, ...doc.data()})
          .toList();
      loadedUsers.sort((a, b) => (a['name'] ?? '').compareTo(b['name'] ?? ''));
      if (mounted)
        setState(() {
          users = loadedUsers;
          isLoading = false;
        });
    } catch (e) {
      if (mounted) setState(() => isLoading = false);
    }
  }

  List<Map<String, dynamic>> get filteredUsers {
    if (filterRole == 'All') return users;
    return users.where((u) => u['role'] == filterRole.toLowerCase()).toList();
  }

  Future<void> updateUserRole(String userId, String newRole) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'role': newRole,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Role updated!', style: GoogleFonts.rajdhani()),
            backgroundColor: CyberpunkTheme.surfaceDark,
          ),
        );
        loadUsers();
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

  Color getRoleColor(String? role) {
    switch (role?.toLowerCase()) {
      case 'admin':
        return CyberpunkTheme.primaryPurple;
      case 'staff':
        return CyberpunkTheme.accentOrange;
      case 'student':
        return CyberpunkTheme.primaryBlue;
      default:
        return CyberpunkTheme.textMuted;
    }
  }

  @override
  Widget build(BuildContext context) {
    final adminCount = users.where((u) => u['role'] == 'admin').length;
    final staffCount = users.where((u) => u['role'] == 'staff').length;
    final studentCount = users.where((u) => u['role'] == 'student').length;

    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.people_rounded,
                      color: CyberpunkTheme.primaryBlue,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'User Management',
                      style: GoogleFonts.orbitron(
                        color: CyberpunkTheme.primaryBlue,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(
                        Icons.refresh,
                        color: CyberpunkTheme.primaryBlue,
                      ),
                      onPressed: loadUsers,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('All', users.length),
                      const SizedBox(width: 8),
                      _buildFilterChip('Admin', adminCount),
                      const SizedBox(width: 8),
                      _buildFilterChip('Staff', staffCount),
                      const SizedBox(width: 8),
                      _buildFilterChip('Student', studentCount),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: CyberpunkTheme.primaryBlue,
                    ),
                  )
                : filteredUsers.isEmpty
                ? Center(
                    child: Text(
                      'No users found',
                      style: GoogleFonts.rajdhani(
                        color: CyberpunkTheme.textMuted,
                      ),
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: loadUsers,
                    color: CyberpunkTheme.primaryBlue,
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: filteredUsers.length,
                      itemBuilder: (_, i) => _buildUserCard(filteredUsers[i]),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, int count) {
    final isSelected = filterRole == label;
    final color = getRoleColor(label == 'All' ? null : label);
    return GestureDetector(
      onTap: () => setState(() => filterRole = label),
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
        child: Text(
          '$label ($count)',
          style: GoogleFonts.rajdhani(
            color: isSelected ? color : CyberpunkTheme.textMuted,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildUserCard(Map<String, dynamic> user) {
    final role = user['role'] ?? 'student';
    final color = getRoleColor(role);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: CyberpunkTheme.surfaceDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                (user['name'] ?? 'U')[0].toUpperCase(),
                style: GoogleFonts.orbitron(
                  color: color,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user['name'] ?? 'Unknown',
                  style: GoogleFonts.rajdhani(
                    color: CyberpunkTheme.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  user['email'] ?? '',
                  style: GoogleFonts.rajdhani(
                    color: CyberpunkTheme.textMuted,
                    fontSize: 11,
                  ),
                ),
                Row(
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        role.toUpperCase(),
                        style: GoogleFonts.rajdhani(
                          color: color,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (user['staffId'] != null) ...[
                      const SizedBox(width: 8),
                      Text(
                        'ID: ${user['staffId']}',
                        style: GoogleFonts.rajdhani(
                          color: CyberpunkTheme.textMuted,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            icon: const Icon(
              Icons.more_vert,
              color: CyberpunkTheme.textMuted,
              size: 20,
            ),
            color: CyberpunkTheme.surfaceDark,
            onSelected: (newRole) => updateUserRole(user['id'], newRole),
            itemBuilder: (_) => [
              PopupMenuItem(
                value: 'admin',
                child: Text(
                  'Make Admin',
                  style: GoogleFonts.rajdhani(
                    color: CyberpunkTheme.primaryPurple,
                  ),
                ),
              ),
              PopupMenuItem(
                value: 'staff',
                child: Text(
                  'Make Staff',
                  style: GoogleFonts.rajdhani(
                    color: CyberpunkTheme.accentOrange,
                  ),
                ),
              ),
              PopupMenuItem(
                value: 'student',
                child: Text(
                  'Make Student',
                  style: GoogleFonts.rajdhani(
                    color: CyberpunkTheme.primaryBlue,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
