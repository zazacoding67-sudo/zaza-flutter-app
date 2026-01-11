import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../models/user.dart' as app_user;
import '../../providers/admin_providers.dart';
import '../../providers/auth_provider.dart';
import '../../theme/cyberpunk_theme.dart';

class UserManagementScreen extends ConsumerStatefulWidget {
  const UserManagementScreen({super.key});

  @override
  ConsumerState<UserManagementScreen> createState() =>
      _UserManagementScreenState();
}

class _UserManagementScreenState extends ConsumerState<UserManagementScreen> {
  String _searchQuery = '';
  String _filterRole = 'all';

  @override
  Widget build(BuildContext context) {
    final usersAsync = ref.watch(allUsersProvider);
    final currentUserAsync = ref.watch(appUserProvider);

    return Scaffold(
      backgroundColor: CyberpunkTheme.deepBlack,
      body: Column(
        children: [
          // Search and Filter Bar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: CyberpunkTheme.surfaceDark,
              border: Border(
                bottom: BorderSide(
                  color: CyberpunkTheme.primaryPink.withOpacity(0.2),
                  width: 1,
                ),
              ),
            ),
            child: Column(
              children: [
                // Search Bar
                TextField(
                  style: CyberpunkTheme.bodyText,
                  decoration: InputDecoration(
                    hintText: 'Search users...',
                    hintStyle: CyberpunkTheme.bodyText.copyWith(
                      color: CyberpunkTheme.textMuted,
                    ),
                    prefixIcon: Icon(
                      Icons.search,
                      color: CyberpunkTheme.primaryCyan,
                    ),
                    filled: true,
                    fillColor: CyberpunkTheme.deepBlack,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: CyberpunkTheme.primaryCyan.withOpacity(0.3),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: CyberpunkTheme.primaryCyan.withOpacity(0.3),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: CyberpunkTheme.primaryPink,
                        width: 2,
                      ),
                    ),
                  ),
                  onChanged: (value) {
                    setState(() => _searchQuery = value);
                  },
                ),
                const SizedBox(height: 12),
                // Filter Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('All', 'all'),
                      _buildFilterChip('Admin', 'admin'),
                      _buildFilterChip('Staff', 'staff'),
                      _buildFilterChip('Student', 'student'),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Users List
          Expanded(
            child: usersAsync.when(
              data: (users) {
                // Filter users
                var filteredUsers = users.where((user) {
                  final matchesSearch =
                      user.name.toLowerCase().contains(
                        _searchQuery.toLowerCase(),
                      ) ||
                      user.email.toLowerCase().contains(
                        _searchQuery.toLowerCase(),
                      ) ||
                      user.staffId.toLowerCase().contains(
                        _searchQuery.toLowerCase(),
                      );

                  final matchesRole =
                      _filterRole == 'all' ||
                      user.role.toLowerCase() == _filterRole;

                  return matchesSearch && matchesRole;
                }).toList();

                if (filteredUsers.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.people_outline,
                          size: 64,
                          color: CyberpunkTheme.textMuted,
                        ),
                        const SizedBox(height: 16),
                        Text('No users found', style: CyberpunkTheme.heading3),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredUsers.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final user = filteredUsers[index];
                    return _buildUserCard(
                      user,
                      currentUserAsync.value?.id ?? '',
                    );
                  },
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(
                  color: CyberpunkTheme.primaryPink,
                ),
              ),
              error: (error, stack) => Center(
                child: Text(
                  'Error loading users: $error',
                  style: CyberpunkTheme.bodyText.copyWith(
                    color: CyberpunkTheme.primaryPink,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () =>
            _showAddUserDialog(context, currentUserAsync.value?.id ?? ''),
        icon: const Icon(Icons.person_add),
        label: Text(
          'Add User',
          style: CyberpunkTheme.buttonText.copyWith(fontSize: 12),
        ),
        backgroundColor: CyberpunkTheme.primaryCyan,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _filterRole == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          setState(() => _filterRole = value);
        },
        backgroundColor: CyberpunkTheme.surfaceLight,
        selectedColor: CyberpunkTheme.primaryPink.withOpacity(0.2),
        checkmarkColor: CyberpunkTheme.primaryPink,
        side: BorderSide(
          color: isSelected
              ? CyberpunkTheme.primaryPink
              : CyberpunkTheme.textMuted.withOpacity(0.3),
          width: isSelected ? 2 : 1,
        ),
        labelStyle: CyberpunkTheme.bodyText.copyWith(
          color: isSelected
              ? CyberpunkTheme.primaryPink
              : CyberpunkTheme.textSecondary,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildUserCard(app_user.User user, String currentUserId) {
    Color getRoleColor(String role) {
      switch (role.toLowerCase()) {
        case 'admin':
          return CyberpunkTheme.accentOrange;
        case 'staff':
          return CyberpunkTheme.neonGreen;
        case 'student':
          return CyberpunkTheme.primaryCyan;
        default:
          return CyberpunkTheme.textMuted;
      }
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CyberpunkTheme.surfaceDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: getRoleColor(user.role).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Avatar
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: getRoleColor(user.role), width: 2),
                  color: getRoleColor(user.role).withOpacity(0.1),
                ),
                child: Center(
                  child: Text(
                    user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                    style: CyberpunkTheme.heading2.copyWith(
                      color: getRoleColor(user.role),
                      fontSize: 24,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // User Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            user.name,
                            style: CyberpunkTheme.heading3.copyWith(
                              fontSize: 16,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: getRoleColor(user.role).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: getRoleColor(user.role),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            user.role.toUpperCase(),
                            style: CyberpunkTheme.buttonText.copyWith(
                              fontSize: 9,
                              color: getRoleColor(user.role),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          user.isActive ? Icons.check_circle : Icons.cancel,
                          color: user.isActive
                              ? CyberpunkTheme.neonGreen
                              : CyberpunkTheme.primaryPink,
                          size: 20,
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      user.email,
                      style: CyberpunkTheme.bodyText.copyWith(
                        fontSize: 13,
                        color: CyberpunkTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'ID: ${user.staffId} • ${user.department}',
                      style: CyberpunkTheme.bodyText.copyWith(
                        fontSize: 11,
                        color: CyberpunkTheme.textMuted,
                      ),
                    ),
                    if (user.createdAt != null)
                      Text(
                        'Joined: ${DateFormat('MMM dd, yyyy').format(user.createdAt!)}',
                        style: CyberpunkTheme.bodyText.copyWith(
                          fontSize: 10,
                          color: CyberpunkTheme.textMuted,
                        ),
                      ),
                  ],
                ),
              ),
              // Menu
              PopupMenuButton(
                icon: Icon(
                  Icons.more_vert,
                  color: CyberpunkTheme.textSecondary,
                ),
                color: CyberpunkTheme.surfaceDark,
                itemBuilder: (context) => [
                  PopupMenuItem(
                    child: Row(
                      children: [
                        Icon(
                          Icons.edit,
                          size: 18,
                          color: CyberpunkTheme.primaryCyan,
                        ),
                        const SizedBox(width: 8),
                        Text('Edit', style: CyberpunkTheme.bodyText),
                      ],
                    ),
                    onTap: () {
                      Future.delayed(
                        Duration.zero,
                        () => _showEditUserDialog(context, user, currentUserId),
                      );
                    },
                  ),
                  if (user.id != currentUserId)
                    PopupMenuItem(
                      child: Row(
                        children: [
                          Icon(
                            user.isActive ? Icons.block : Icons.check_circle,
                            size: 18,
                            color: user.isActive
                                ? CyberpunkTheme.primaryPink
                                : CyberpunkTheme.neonGreen,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            user.isActive ? 'Deactivate' : 'Activate',
                            style: CyberpunkTheme.bodyText,
                          ),
                        ],
                      ),
                      onTap: () =>
                          _toggleUserStatus(context, user, currentUserId),
                    ),
                  if (user.id != currentUserId)
                    PopupMenuItem(
                      child: Row(
                        children: [
                          Icon(
                            Icons.delete,
                            size: 18,
                            color: CyberpunkTheme.primaryPink,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Delete',
                            style: CyberpunkTheme.bodyText.copyWith(
                              color: CyberpunkTheme.primaryPink,
                            ),
                          ),
                        ],
                      ),
                      onTap: () => _deleteUser(context, user, currentUserId),
                    ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showAddUserDialog(BuildContext context, String createdBy) {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final staffIdController = TextEditingController();
    final departmentController = TextEditingController();
    final passwordController = TextEditingController();
    String selectedRole = 'student';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: CyberpunkTheme.surfaceDark,
        title: Text(
          'Add New User',
          style: CyberpunkTheme.heading2.copyWith(fontSize: 20),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDialogTextField(nameController, 'Full Name', Icons.person),
              const SizedBox(height: 12),
              _buildDialogTextField(
                emailController,
                'Email',
                Icons.email,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 12),
              _buildDialogTextField(
                staffIdController,
                'Staff/Student ID',
                Icons.badge,
              ),
              const SizedBox(height: 12),
              _buildDialogTextField(
                departmentController,
                'Department',
                Icons.business,
              ),
              const SizedBox(height: 12),
              _buildDialogTextField(
                passwordController,
                'Password',
                Icons.lock,
                obscureText: true,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedRole,
                dropdownColor: CyberpunkTheme.surfaceDark,
                style: CyberpunkTheme.bodyText,
                decoration: InputDecoration(
                  labelText: 'Role',
                  labelStyle: CyberpunkTheme.bodyText.copyWith(
                    color: CyberpunkTheme.textSecondary,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: CyberpunkTheme.primaryCyan.withOpacity(0.3),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: CyberpunkTheme.primaryCyan.withOpacity(0.3),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: CyberpunkTheme.primaryPink,
                      width: 2,
                    ),
                  ),
                ),
                items: ['admin', 'staff', 'student']
                    .map(
                      (role) => DropdownMenuItem(
                        value: role,
                        child: Text(
                          role.toUpperCase(),
                          style: CyberpunkTheme.bodyText,
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) selectedRole = value;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: CyberpunkTheme.bodyText.copyWith(
                color: CyberpunkTheme.textMuted,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isEmpty ||
                  emailController.text.isEmpty ||
                  passwordController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Please fill all required fields'),
                    backgroundColor: CyberpunkTheme.primaryPink,
                  ),
                );
                return;
              }

              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => const Center(
                  child: CircularProgressIndicator(
                    color: CyberpunkTheme.primaryPink,
                  ),
                ),
              );

              try {
                final adminService = ref.read(adminServiceProvider);
                final newUser = app_user.User(
                  id: '',
                  staffId: staffIdController.text,
                  name: nameController.text,
                  email: emailController.text,
                  department: departmentController.text,
                  role: selectedRole,
                  isActive: true,
                  createdAt: DateTime.now(),
                  createdBy: createdBy,
                );

                await adminService.createUser(
                  newUser,
                  passwordController.text,
                  createdBy,
                );

                Navigator.pop(context);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('User created successfully'),
                    backgroundColor: CyberpunkTheme.neonGreen,
                  ),
                );
              } catch (e) {
                Navigator.pop(context);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: $e'),
                      backgroundColor: CyberpunkTheme.primaryPink,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: CyberpunkTheme.primaryCyan,
            ),
            child: Text(
              'Create',
              style: CyberpunkTheme.buttonText.copyWith(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDialogTextField(
    TextEditingController controller,
    String label,
    IconData icon, {
    bool obscureText = false,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      style: CyberpunkTheme.bodyText,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: CyberpunkTheme.bodyText.copyWith(
          color: CyberpunkTheme.textSecondary,
        ),
        prefixIcon: Icon(icon, color: CyberpunkTheme.primaryCyan),
        filled: true,
        fillColor: CyberpunkTheme.deepBlack,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: CyberpunkTheme.primaryCyan.withOpacity(0.3),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: CyberpunkTheme.primaryCyan.withOpacity(0.3),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: CyberpunkTheme.primaryPink, width: 2),
        ),
      ),
    );
  }

  void _showEditUserDialog(
    BuildContext context,
    app_user.User user,
    String updatedBy,
  ) {
    final nameController = TextEditingController(text: user.name);
    final staffIdController = TextEditingController(text: user.staffId);
    final departmentController = TextEditingController(text: user.department);
    String selectedRole = user.role;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: CyberpunkTheme.surfaceDark,
        title: Text(
          'Edit User',
          style: CyberpunkTheme.heading2.copyWith(fontSize: 20),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDialogTextField(nameController, 'Full Name', Icons.person),
              const SizedBox(height: 12),
              _buildDialogTextField(
                staffIdController,
                'Staff/Student ID',
                Icons.badge,
              ),
              const SizedBox(height: 12),
              _buildDialogTextField(
                departmentController,
                'Department',
                Icons.business,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedRole,
                dropdownColor: CyberpunkTheme.surfaceDark,
                style: CyberpunkTheme.bodyText,
                decoration: InputDecoration(
                  labelText: 'Role',
                  labelStyle: CyberpunkTheme.bodyText.copyWith(
                    color: CyberpunkTheme.textSecondary,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: CyberpunkTheme.primaryCyan.withOpacity(0.3),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: CyberpunkTheme.primaryCyan.withOpacity(0.3),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: CyberpunkTheme.primaryPink,
                      width: 2,
                    ),
                  ),
                ),
                items: ['admin', 'staff', 'student']
                    .map(
                      (role) => DropdownMenuItem(
                        value: role,
                        child: Text(
                          role.toUpperCase(),
                          style: CyberpunkTheme.bodyText,
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) selectedRole = value;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: CyberpunkTheme.bodyText.copyWith(
                color: CyberpunkTheme.textMuted,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => const Center(
                  child: CircularProgressIndicator(
                    color: CyberpunkTheme.primaryPink,
                  ),
                ),
              );

              try {
                final adminService = ref.read(adminServiceProvider);
                final updatedUser = user.copyWith(
                  name: nameController.text,
                  staffId: staffIdController.text,
                  department: departmentController.text,
                  role: selectedRole,
                );

                await adminService.updateUser(updatedUser, updatedBy);

                Navigator.pop(context);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('User updated successfully'),
                    backgroundColor: CyberpunkTheme.neonGreen,
                  ),
                );
              } catch (e) {
                Navigator.pop(context);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: $e'),
                      backgroundColor: CyberpunkTheme.primaryPink,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: CyberpunkTheme.primaryCyan,
            ),
            child: Text(
              'Save',
              style: CyberpunkTheme.buttonText.copyWith(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  void _toggleUserStatus(
    BuildContext context,
    app_user.User user,
    String updatedBy,
  ) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: CyberpunkTheme.primaryPink),
      ),
    );

    try {
      final adminService = ref.read(adminServiceProvider);
      await adminService.toggleUserStatus(user.id, !user.isActive, updatedBy);

      Navigator.pop(context);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'User ${!user.isActive ? 'activated' : 'deactivated'} successfully',
            ),
            backgroundColor: CyberpunkTheme.neonGreen,
          ),
        );
      }
    } catch (e) {
      Navigator.pop(context);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: CyberpunkTheme.primaryPink,
          ),
        );
      }
    }
  }

  void _deleteUser(
    BuildContext context,
    app_user.User user,
    String deletedBy,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: CyberpunkTheme.surfaceDark,
        title: Text(
          'Delete User',
          style: CyberpunkTheme.heading2.copyWith(fontSize: 20),
        ),
        content: Text(
          'Are you sure you want to delete ${user.name}?',
          style: CyberpunkTheme.bodyText,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: CyberpunkTheme.bodyText.copyWith(
                color: CyberpunkTheme.textMuted,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: CyberpunkTheme.primaryPink,
            ),
            child: Text(
              'Delete',
              style: CyberpunkTheme.buttonText.copyWith(fontSize: 12),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(color: CyberpunkTheme.primaryPink),
        ),
      );

      try {
        final adminService = ref.read(adminServiceProvider);
        await adminService.deleteUser(user.id, deletedBy);

        Navigator.pop(context);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('User deleted successfully'),
              backgroundColor: CyberpunkTheme.neonGreen,
            ),
          );
        }
      } catch (e) {
        Navigator.pop(context);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
              backgroundColor: CyberpunkTheme.primaryPink,
            ),
          );
        }
      }
    }
  }
}
