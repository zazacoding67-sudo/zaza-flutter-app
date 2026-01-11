import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../models/user.dart' as app_user;
import '../../providers/admin_providers.dart';
import '../../providers/auth_provider.dart';

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
      body: Column(
        children: [
          // Search and Filter Bar
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Column(
              children: [
                // Search Bar
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Search users...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.grey[100],
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
                          color: Colors.grey[300],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No users found',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            color: Colors.grey[600],
                          ),
                        ),
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
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) =>
                  Center(child: Text('Error loading users: $error')),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () =>
            _showAddUserDialog(context, currentUserAsync.value?.id ?? ''),
        icon: const Icon(Icons.person_add),
        label: const Text('Add User'),
        backgroundColor: const Color(0xFF00897B),
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
        backgroundColor: Colors.grey[200],
        selectedColor: const Color(0xFF00897B).withOpacity(0.2),
        checkmarkColor: const Color(0xFF00897B),
        labelStyle: GoogleFonts.poppins(
          color: isSelected ? const Color(0xFF00897B) : Colors.grey[700],
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
    );
  }

  Widget _buildUserCard(app_user.User user, String currentUserId) {
    Color getRoleColor(String role) {
      switch (role.toLowerCase()) {
        case 'admin':
          return Colors.amber;
        case 'staff':
          return Colors.green;
        case 'student':
          return Colors.blue;
        default:
          return Colors.grey;
      }
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          radius: 28,
          backgroundColor: getRoleColor(user.role).withOpacity(0.2),
          child: Text(
            user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
            style: TextStyle(
              color: getRoleColor(user.role),
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                user.name,
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: getRoleColor(user.role).withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                user.role.toUpperCase(),
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: getRoleColor(user.role),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              user.isActive ? Icons.check_circle : Icons.cancel,
              color: user.isActive ? Colors.green : Colors.red,
              size: 20,
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(user.email, style: const TextStyle(fontSize: 13)),
            Text(
              'ID: ${user.staffId} • ${user.department}',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            if (user.createdAt != null)
              Text(
                'Joined: ${DateFormat('MMM dd, yyyy').format(user.createdAt!)}',
                style: TextStyle(fontSize: 11, color: Colors.grey[500]),
              ),
          ],
        ),
        trailing: PopupMenuButton(
          icon: const Icon(Icons.more_vert),
          itemBuilder: (context) => [
            PopupMenuItem(
              child: Row(
                children: [
                  const Icon(Icons.edit, size: 18),
                  const SizedBox(width: 8),
                  Text('Edit', style: GoogleFonts.poppins()),
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
                    ),
                    const SizedBox(width: 8),
                    Text(
                      user.isActive ? 'Deactivate' : 'Activate',
                      style: GoogleFonts.poppins(),
                    ),
                  ],
                ),
                onTap: () => _toggleUserStatus(context, user, currentUserId),
              ),
            if (user.id != currentUserId)
              PopupMenuItem(
                child: Row(
                  children: [
                    const Icon(Icons.delete, size: 18, color: Colors.red),
                    const SizedBox(width: 8),
                    Text(
                      'Delete',
                      style: GoogleFonts.poppins(color: Colors.red),
                    ),
                  ],
                ),
                onTap: () => _deleteUser(context, user, currentUserId),
              ),
          ],
        ),
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
        title: Text('Add New User', style: GoogleFonts.poppins()),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Full Name'),
              ),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
              ),
              TextField(
                controller: staffIdController,
                decoration: const InputDecoration(
                  labelText: 'Staff/Student ID',
                ),
              ),
              TextField(
                controller: departmentController,
                decoration: const InputDecoration(labelText: 'Department'),
              ),
              TextField(
                controller: passwordController,
                decoration: const InputDecoration(labelText: 'Password'),
                obscureText: true,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedRole,
                decoration: const InputDecoration(labelText: 'Role'),
                items: ['admin', 'staff', 'student']
                    .map(
                      (role) => DropdownMenuItem(
                        value: role,
                        child: Text(role.toUpperCase()),
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
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isEmpty ||
                  emailController.text.isEmpty ||
                  passwordController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please fill all required fields'),
                  ),
                );
                return;
              }

              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) =>
                    const Center(child: CircularProgressIndicator()),
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
                  const SnackBar(content: Text('User created successfully')),
                );
              } catch (e) {
                Navigator.pop(context);
                if (context.mounted) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('Error: $e')));
                }
              }
            },
            child: const Text('Create'),
          ),
        ],
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
        title: Text('Edit User', style: GoogleFonts.poppins()),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Full Name'),
              ),
              TextField(
                controller: staffIdController,
                decoration: const InputDecoration(
                  labelText: 'Staff/Student ID',
                ),
              ),
              TextField(
                controller: departmentController,
                decoration: const InputDecoration(labelText: 'Department'),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedRole,
                decoration: const InputDecoration(labelText: 'Role'),
                items: ['admin', 'staff', 'student']
                    .map(
                      (role) => DropdownMenuItem(
                        value: role,
                        child: Text(role.toUpperCase()),
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
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) =>
                    const Center(child: CircularProgressIndicator()),
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
                  const SnackBar(content: Text('User updated successfully')),
                );
              } catch (e) {
                Navigator.pop(context);
                if (context.mounted) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('Error: $e')));
                }
              }
            },
            child: const Text('Save'),
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
      builder: (context) => const Center(child: CircularProgressIndicator()),
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
          ),
        );
      }
    } catch (e) {
      Navigator.pop(context);
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
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
        title: const Text('Delete User'),
        content: Text('Are you sure you want to delete ${user.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      try {
        final adminService = ref.read(adminServiceProvider);
        await adminService.deleteUser(user.id, deletedBy);

        Navigator.pop(context);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('User deleted successfully')),
          );
        }
      } catch (e) {
        Navigator.pop(context);
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      }
    }
  }
}
