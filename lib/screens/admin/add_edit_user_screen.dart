// lib/screens/admin/add_edit_user_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/user.dart';
import '../../services/user_service.dart';
import '../../providers/auth_provider.dart';

class AddEditUserScreen extends ConsumerStatefulWidget {
  final User? userToEdit;

  const AddEditUserScreen({super.key, this.userToEdit});

  @override
  ConsumerState<AddEditUserScreen> createState() => _AddEditUserScreenState();
}

class _AddEditUserScreenState extends ConsumerState<AddEditUserScreen> {
  final _formKey = GlobalKey<FormState>();
  final _userService = UserService();

  // Controllers
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _passwordController;
  late TextEditingController _staffIdController;
  late TextEditingController _departmentController;
  late TextEditingController _phoneController;

  String _selectedRole = 'student';
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _isEditMode = false;

  final List<String> _roles = ['admin', 'staff', 'student'];
  final List<String> _departments = [
    'Information Technology',
    'Computer Science',
    'Engineering',
    'Business',
    'Science',
    'Arts',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _isEditMode = widget.userToEdit != null;

    _nameController = TextEditingController(
      text: widget.userToEdit?.name ?? '',
    );
    _emailController = TextEditingController(
      text: widget.userToEdit?.email ?? '',
    );
    _passwordController = TextEditingController();
    _staffIdController = TextEditingController(
      text: widget.userToEdit?.staffId ?? '',
    );
    _departmentController = TextEditingController(
      text: widget.userToEdit?.department ?? '',
    );
    _phoneController = TextEditingController(
      text: widget.userToEdit?.phone ?? '',
    );

    if (widget.userToEdit != null) {
      _selectedRole = widget.userToEdit!.role;
    }

    // Auto-generate staff ID for new users
    if (!_isEditMode) {
      _generateStaffId();
    }
  }

  Future<void> _generateStaffId() async {
    final staffId = await _userService.generateStaffId(_selectedRole);
    setState(() {
      _staffIdController.text = staffId;
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _staffIdController.dispose();
    _departmentController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          _isEditMode ? 'Edit User' : 'Add New User',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        backgroundColor: const Color(0xFF00897B),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [const Color(0xFF00897B), const Color(0xFF004D40)],
                ),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _isEditMode ? Icons.edit : Icons.person_add,
                      size: 40,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _isEditMode
                        ? 'Update User Information'
                        : 'Create New User Account',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _isEditMode
                        ? 'Modify user details and permissions'
                        : 'Fill in the details to create a new user',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            // Form Card
            Padding(
              padding: const EdgeInsets.all(20),
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Section: Basic Information
                        _buildSectionHeader('Basic Information', Icons.person),
                        const SizedBox(height: 16),

                        _buildTextField(
                          controller: _nameController,
                          label: 'Full Name',
                          icon: Icons.person_outline,
                          hint: 'John Doe',
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Name is required';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        _buildTextField(
                          controller: _emailController,
                          label: 'Email Address',
                          icon: Icons.email_outlined,
                          hint: 'john.doe@example.com',
                          enabled: !_isEditMode,
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Email is required';
                            }
                            if (!RegExp(
                              r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                            ).hasMatch(value)) {
                              return 'Enter a valid email';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        if (!_isEditMode) ...[
                          _buildTextField(
                            controller: _passwordController,
                            label: 'Password',
                            icon: Icons.lock_outline,
                            hint: 'Minimum 6 characters',
                            obscureText: _obscurePassword,
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                                color: Colors.grey,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Password is required';
                              }
                              if (value.length < 6) {
                                return 'Password must be at least 6 characters';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                        ],

                        const SizedBox(height: 24),

                        // Section: Organization Details
                        _buildSectionHeader(
                          'Organization Details',
                          Icons.business,
                        ),
                        const SizedBox(height: 16),

                        _buildTextField(
                          controller: _staffIdController,
                          label: 'Staff/Student ID',
                          icon: Icons.badge_outlined,
                          hint: 'Auto-generated',
                          enabled: false,
                        ),
                        const SizedBox(height: 16),

                        _buildDropdownField(
                          label: 'Role',
                          icon: Icons.admin_panel_settings_outlined,
                          value: _selectedRole,
                          items: _roles,
                          onChanged: (value) {
                            setState(() {
                              _selectedRole = value!;
                              if (!_isEditMode) {
                                _generateStaffId();
                              }
                            });
                          },
                        ),
                        const SizedBox(height: 16),

                        _buildDropdownField(
                          label: 'Department',
                          icon: Icons.account_tree_outlined,
                          value:
                              _departments.contains(_departmentController.text)
                              ? _departmentController.text
                              : _departments.first,
                          items: _departments,
                          onChanged: (value) {
                            _departmentController.text = value!;
                          },
                        ),
                        const SizedBox(height: 16),

                        _buildTextField(
                          controller: _phoneController,
                          label: 'Phone Number (Optional)',
                          icon: Icons.phone_outlined,
                          hint: '+60123456789',
                          keyboardType: TextInputType.phone,
                        ),

                        const SizedBox(height: 32),

                        // Action Buttons
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: _isLoading
                                    ? null
                                    : () => Navigator.pop(context),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  side: BorderSide(color: Colors.grey[300]!),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: Text(
                                  'Cancel',
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey[700],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              flex: 2,
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _handleSubmit,
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  backgroundColor: const Color(0xFF00897B),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 2,
                                ),
                                child: _isLoading
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                Colors.white,
                                              ),
                                        ),
                                      )
                                    : Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            _isEditMode
                                                ? Icons.save
                                                : Icons.add,
                                            size: 20,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            _isEditMode
                                                ? 'Save Changes'
                                                : 'Create User',
                                            style: GoogleFonts.poppins(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF00897B).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: const Color(0xFF00897B), size: 20),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
    bool obscureText = false,
    bool enabled = true,
    TextInputType? keyboardType,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      enabled: enabled,
      keyboardType: keyboardType,
      validator: validator,
      style: GoogleFonts.poppins(),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: const Color(0xFF00897B)),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: enabled ? Colors.white : Colors.grey[100],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF00897B), width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red),
        ),
        labelStyle: GoogleFonts.poppins(color: Colors.grey[700]),
        hintStyle: GoogleFonts.poppins(color: Colors.grey[400]),
      ),
    );
  }

  Widget _buildDropdownField({
    required String label,
    required IconData icon,
    required String value,
    required List<String> items,
    required void Function(String?) onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFF00897B)),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF00897B), width: 2),
        ),
        labelStyle: GoogleFonts.poppins(color: Colors.grey[700]),
      ),
      items: items.map((item) {
        return DropdownMenuItem(
          value: item,
          child: Text(item.toUpperCase(), style: GoogleFonts.poppins()),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final currentUserAsync = ref.read(appUserProvider);
      final currentUser = currentUserAsync.value;

      if (currentUser == null) {
        throw Exception('No authenticated user found');
      }

      Map<String, dynamic> result;

      if (_isEditMode) {
        // Update existing user
        result = await _userService.updateUser(
          userId: widget.userToEdit!.id,
          name: _nameController.text.trim(),
          department: _departmentController.text,
          role: _selectedRole,
          phone: _phoneController.text.trim().isEmpty
              ? null
              : _phoneController.text.trim(),
          updatedBy: currentUser.id,
        );
      } else {
        // Create new user
        result = await _userService.createUser(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          name: _nameController.text.trim(),
          staffId: _staffIdController.text,
          department: _departmentController.text,
          role: _selectedRole,
          phone: _phoneController.text.trim().isEmpty
              ? null
              : _phoneController.text.trim(),
          createdBy: currentUser.id,
        );
      }

      if (mounted) {
        if (result['success']) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message']),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true); // Return true to indicate success
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message']),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
