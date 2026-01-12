// Replace your lib/screens/admin/add_asset_screen.dart with this:
import 'package:zaza_app/widgets/cyber_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/cyberpunk_theme.dart';
import '../../providers/admin_providers.dart';

class AddAssetScreen extends ConsumerStatefulWidget {
  const AddAssetScreen({super.key});

  @override
  ConsumerState<AddAssetScreen> createState() => _AddAssetScreenState();
}

class _AddAssetScreenState extends ConsumerState<AddAssetScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _serialNumberController = TextEditingController();
  final _purchaseDateController = TextEditingController();
  final _purchasePriceController = TextEditingController();
  final _locationController = TextEditingController();

  String _selectedCategory = 'Computer';
  String _selectedStatus = 'Available';
  bool _isLoading = false;

  final List<String> _categories = [
    'Computer',
    'Laptop',
    'Projector',
    'Printer',
    'Camera',
    'Audio Equipment',
    'Network Equipment',
    'Furniture',
    'Other',
  ];

  final List<String> _statuses = [
    'Available',
    'In Use',
    'Maintenance',
    'Retired',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _serialNumberController.dispose();
    _purchaseDateController.dispose();
    _purchasePriceController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: CyberpunkTheme.primaryPink,
              onPrimary: Colors.white,
              surface: CyberpunkTheme.cardDark,
              onSurface: Colors.white,
            ),
            dialogBackgroundColor: CyberpunkTheme.cardDark,
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _purchaseDateController.text =
            "${picked.day}/${picked.month}/${picked.year}";
      });
    }
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final adminService = ref.read(adminServiceProvider);

        // Prepare asset data
        final assetData = {
          'name': _nameController.text.trim(),
          'category': _selectedCategory,
          'description': _descriptionController.text.trim(),
          'serialNumber': _serialNumberController.text.trim(),
          'purchaseDate': _purchaseDateController.text.trim(),
          'purchasePrice': double.parse(_purchasePriceController.text.trim()),
          'location': _locationController.text.trim(),
          'status': _selectedStatus,
          'borrowedBy': null,
          'borrowedAt': null,
          'expectedReturnDate': null,
        };

        // Add asset to Firebase
        await adminService.addAsset(assetData);

        if (mounted) {
          setState(() {
            _isLoading = false;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Asset "${_nameController.text}" added successfully!',
                      style: CyberpunkTheme.bodyText,
                    ),
                  ),
                ],
              ),
              backgroundColor: CyberpunkTheme.neonGreen,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              duration: const Duration(seconds: 3),
            ),
          );

          Navigator.pop(context, true); // Return true to indicate success
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Failed to add asset: ${e.toString()}',
                      style: CyberpunkTheme.bodyText,
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CyberpunkTheme.deepBlack,
      appBar: AppBar(
        title: Text(
          'ADD NEW ASSET',
          style: CyberpunkTheme.heading3.copyWith(
            fontSize: 18,
            letterSpacing: 2,
          ),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: CyberpunkTheme.pinkCyanGradient,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              CyberpunkTheme.cardDark.withOpacity(0.3),
              CyberpunkTheme.deepBlack,
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: CyberpunkTheme.glassCard(),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            gradient: CyberpunkTheme.pinkPurpleGradient,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: CyberpunkTheme.neonGlow(
                              CyberpunkTheme.primaryPink,
                            ),
                          ),
                          child: const Icon(
                            Icons.add_circle_outline,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'New Asset',
                                style: CyberpunkTheme.heading2.copyWith(
                                  fontSize: 20,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Fill in the details below',
                                style: CyberpunkTheme.bodyText.copyWith(
                                  color: CyberpunkTheme.textSecondary,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Asset Name
                  _buildTextField(
                    controller: _nameController,
                    label: 'Asset Name',
                    hint: 'e.g., Dell Laptop XPS 15',
                    icon: Icons.devices,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter asset name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Category Dropdown
                  _buildDropdown(
                    value: _selectedCategory,
                    label: 'Category',
                    icon: Icons.category,
                    items: _categories,
                    onChanged: (value) {
                      setState(() {
                        _selectedCategory = value!;
                      });
                    },
                  ),
                  const SizedBox(height: 16),

                  // Description
                  _buildTextField(
                    controller: _descriptionController,
                    label: 'Description',
                    hint: 'Enter asset description',
                    icon: Icons.description,
                    maxLines: 3,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter description';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Serial Number
                  _buildTextField(
                    controller: _serialNumberController,
                    label: 'Serial Number',
                    hint: 'e.g., SN12345678',
                    icon: Icons.tag,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter serial number';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Purchase Date
                  _buildTextField(
                    controller: _purchaseDateController,
                    label: 'Purchase Date',
                    hint: 'Select date',
                    icon: Icons.calendar_today,
                    readOnly: true,
                    onTap: () => _selectDate(context),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please select purchase date';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Purchase Price
                  _buildTextField(
                    controller: _purchasePriceController,
                    label: 'Purchase Price (RM)',
                    hint: 'e.g., 5000',
                    icon: Icons.attach_money,
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter purchase price';
                      }
                      if (double.tryParse(value) == null) {
                        return 'Please enter a valid number';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Location
                  _buildTextField(
                    controller: _locationController,
                    label: 'Location',
                    hint: 'e.g., Room 301, Building A',
                    icon: Icons.location_on,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter location';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Status Dropdown
                  _buildDropdown(
                    value: _selectedStatus,
                    label: 'Status',
                    icon: Icons.info_outline,
                    items: _statuses,
                    onChanged: (value) {
                      setState(() {
                        _selectedStatus = value!;
                      });
                    },
                  ),
                  const SizedBox(height: 32),

                  // Submit Button
                  SizedBox(
                    width: double.infinity,
                    child: _isLoading
                        ? Center(
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: CyberpunkTheme.cardDark,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: CyberpunkTheme.primaryCyan,
                                  width: 2,
                                ),
                              ),
                              child: const CircularProgressIndicator(
                                color: CyberpunkTheme.primaryCyan,
                              ),
                            ),
                          )
                        : CyberButton(
                            text: 'ADD ASSET',
                            icon: Icons.add,
                            onPressed: _submitForm,
                            gradient: CyberpunkTheme.pinkPurpleGradient,
                            glowColor: CyberpunkTheme.primaryPink,
                          ),
                  ),
                  const SizedBox(height: 16),

                  // Cancel Button
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: _isLoading
                          ? null
                          : () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: const BorderSide(
                          color: CyberpunkTheme.textMuted,
                          width: 2,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'CANCEL',
                        style: CyberpunkTheme.buttonText.copyWith(
                          color: CyberpunkTheme.textMuted,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    String? Function(String?)? validator,
    int maxLines = 1,
    bool readOnly = false,
    VoidCallback? onTap,
    TextInputType? keyboardType,
  }) {
    return Container(
      decoration: CyberpunkTheme.glassCard(),
      child: TextFormField(
        controller: controller,
        validator: validator,
        maxLines: maxLines,
        readOnly: readOnly,
        onTap: onTap,
        keyboardType: keyboardType,
        style: GoogleFonts.rajdhani(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Icon(icon, color: CyberpunkTheme.primaryCyan),
          labelStyle: GoogleFonts.rajdhani(
            color: CyberpunkTheme.primaryCyan,
            fontSize: 14,
          ),
          hintStyle: GoogleFonts.rajdhani(
            color: CyberpunkTheme.textMuted,
            fontSize: 14,
          ),
          filled: true,
          fillColor: CyberpunkTheme.cardDark.withOpacity(0.5),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: CyberpunkTheme.primaryCyan.withOpacity(0.3),
              width: 1,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(
              color: CyberpunkTheme.primaryPink,
              width: 2,
            ),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.redAccent, width: 2),
          ),
          errorStyle: GoogleFonts.rajdhani(
            color: Colors.redAccent,
            fontSize: 12,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String value,
    required String label,
    required IconData icon,
    required List<String> items,
    required void Function(String?) onChanged,
  }) {
    return Container(
      decoration: CyberpunkTheme.glassCard(),
      child: DropdownButtonFormField<String>(
        value: value,
        onChanged: onChanged,
        style: GoogleFonts.rajdhani(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
        dropdownColor: CyberpunkTheme.cardDark,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: CyberpunkTheme.primaryCyan),
          labelStyle: GoogleFonts.rajdhani(
            color: CyberpunkTheme.primaryCyan,
            fontSize: 14,
          ),
          filled: true,
          fillColor: CyberpunkTheme.cardDark.withOpacity(0.5),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: CyberpunkTheme.primaryCyan.withOpacity(0.3),
              width: 1,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(
              color: CyberpunkTheme.primaryPink,
              width: 2,
            ),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
        icon: const Icon(
          Icons.arrow_drop_down,
          color: CyberpunkTheme.primaryCyan,
        ),
        items: items.map((String item) {
          return DropdownMenuItem<String>(
            value: item,
            child: Text(
              item,
              style: GoogleFonts.rajdhani(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
