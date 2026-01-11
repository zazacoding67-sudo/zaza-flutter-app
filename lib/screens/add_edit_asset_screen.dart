import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';

class AddEditAssetScreen extends StatefulWidget {
  final Map<String, dynamic>? assetToEdit;

  const AddEditAssetScreen({super.key, this.assetToEdit});

  @override
  State<AddEditAssetScreen> createState() => _AddEditAssetScreenState();
}

class _AddEditAssetScreenState extends State<AddEditAssetScreen> {
  final _formKey = GlobalKey<FormState>();
  final _assetNameController = TextEditingController();
  final _brandController = TextEditingController();
  final _modelController = TextEditingController();
  final _serialNumberController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _purchasePriceController = TextEditingController();

  String _selectedCategory = 'Computer';
  String _selectedStatus = 'Available';
  String _selectedCondition = 'Good';
  DateTime? _purchaseDate;

  final List<String> _categories = [
    'Computer',
    'Furniture',
    'Electronics',
    'Tools',
    'Vehicle',
    'Other',
  ];

  final List<String> _statuses = [
    'Available',
    'Borrowed',
    'Maintenance',
    'Retired',
  ];

  final List<String> _conditions = ['Excellent', 'Good', 'Fair', 'Poor'];

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.assetToEdit != null) {
      _populateFormWithAsset();
    }
  }

  void _populateFormWithAsset() {
    final asset = widget.assetToEdit!;
    _assetNameController.text = asset['asset_name'] ?? '';
    _brandController.text = asset['brand'] ?? '';
    _modelController.text = asset['model'] ?? '';
    _serialNumberController.text = asset['serial_number'] ?? '';
    _descriptionController.text = asset['description'] ?? '';
    _locationController.text = asset['location'] ?? '';
    _purchasePriceController.text = asset['purchase_price']?.toString() ?? '';
    _selectedCategory = asset['category'] ?? 'Computer';
    _selectedStatus = asset['status'] ?? 'Available';
    _selectedCondition = asset['condition_status'] ?? 'Good';

    // Handle purchase date if exists
    if (asset['purchase_date'] != null) {
      try {
        _purchaseDate = DateTime.parse(asset['purchase_date']);
      } catch (e) {
        _purchaseDate = null;
      }
    }
  }

  @override
  void dispose() {
    _assetNameController.dispose();
    _brandController.dispose();
    _modelController.dispose();
    _serialNumberController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _purchasePriceController.dispose();
    super.dispose();
  }

  Future<void> _selectPurchaseDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _purchaseDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _purchaseDate) {
      setState(() {
        _purchaseDate = picked;
      });
    }
  }

  Future<void> _saveAsset() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final assetData = {
        'asset_name': _assetNameController.text.trim(),
        'category': _selectedCategory,
        'brand': _brandController.text.trim(),
        'model': _modelController.text.trim(),
        'serial_number': _serialNumberController.text.trim(),
        'description': _descriptionController.text.trim(),
        'location': _locationController.text.trim(),
        'status': _selectedStatus,
        'condition_status': _selectedCondition,
        'purchase_date': _purchaseDate?.toIso8601String(),
        'purchase_price': double.tryParse(_purchasePriceController.text) ?? 0.0,
      };

      if (widget.assetToEdit != null) {
        // Update existing asset
        await ApiService.updateAsset(widget.assetToEdit!['id'], assetData);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Asset updated successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        // Create new asset
        await ApiService.createAsset(assetData);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Asset created successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }

      if (mounted) {
        Navigator.pop(context, true); // Return true to indicate success
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.assetToEdit != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isEditing ? 'Edit Asset' : 'Add New Asset',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        backgroundColor: const Color(0xFF00897B),
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Asset Name
            TextFormField(
              controller: _assetNameController,
              decoration: InputDecoration(
                labelText: 'Asset Name *',
                prefixIcon: const Icon(Icons.inventory_2),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter asset name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Category Dropdown
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              decoration: InputDecoration(
                labelText: 'Category *',
                prefixIcon: const Icon(Icons.category),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              items: _categories.map((category) {
                return DropdownMenuItem(value: category, child: Text(category));
              }).toList(),
              onChanged: (value) {
                setState(() => _selectedCategory = value!);
              },
            ),
            const SizedBox(height: 16),

            // Brand
            TextFormField(
              controller: _brandController,
              decoration: InputDecoration(
                labelText: 'Brand',
                prefixIcon: const Icon(Icons.branding_watermark),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Model
            TextFormField(
              controller: _modelController,
              decoration: InputDecoration(
                labelText: 'Model',
                prefixIcon: const Icon(Icons.model_training),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Serial Number
            TextFormField(
              controller: _serialNumberController,
              decoration: InputDecoration(
                labelText: 'Serial Number',
                prefixIcon: const Icon(Icons.confirmation_number),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Location
            TextFormField(
              controller: _locationController,
              decoration: InputDecoration(
                labelText: 'Location *',
                prefixIcon: const Icon(Icons.location_on),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter location';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Status Dropdown
            DropdownButtonFormField<String>(
              value: _selectedStatus,
              decoration: InputDecoration(
                labelText: 'Status *',
                prefixIcon: const Icon(Icons.info),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              items: _statuses.map((status) {
                return DropdownMenuItem(value: status, child: Text(status));
              }).toList(),
              onChanged: (value) {
                setState(() => _selectedStatus = value!);
              },
            ),
            const SizedBox(height: 16),

            // Condition Dropdown
            DropdownButtonFormField<String>(
              value: _selectedCondition,
              decoration: InputDecoration(
                labelText: 'Condition *',
                prefixIcon: const Icon(Icons.health_and_safety),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              items: _conditions.map((condition) {
                return DropdownMenuItem(
                  value: condition,
                  child: Text(condition),
                );
              }).toList(),
              onChanged: (value) {
                setState(() => _selectedCondition = value!);
              },
            ),
            const SizedBox(height: 16),

            // Purchase Date
            InkWell(
              onTap: _selectPurchaseDate,
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: 'Purchase Date',
                  prefixIcon: const Icon(Icons.calendar_today),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  _purchaseDate != null
                      ? '${_purchaseDate!.day}/${_purchaseDate!.month}/${_purchaseDate!.year}'
                      : 'Select Date',
                  style: TextStyle(
                    color: _purchaseDate != null ? Colors.black : Colors.grey,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Purchase Price
            TextFormField(
              controller: _purchasePriceController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Purchase Price',
                prefixIcon: const Icon(Icons.attach_money),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Description
            TextFormField(
              controller: _descriptionController,
              maxLines: 4,
              decoration: InputDecoration(
                labelText: 'Description',
                prefixIcon: const Icon(Icons.description),
                alignLabelWithHint: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Save Button
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveAsset,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00897B),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        isEditing ? 'Update Asset' : 'Create Asset',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
