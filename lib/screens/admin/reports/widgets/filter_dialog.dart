// lib/screens/admin/reports/widgets/filter_dialog.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:syncfusion_flutter_datepicker/datepicker.dart';
import '../../../../theme/cyberpunk_theme.dart';

class FilterDialog extends StatefulWidget {
  final Map<String, dynamic> currentFilters;

  const FilterDialog({super.key, required this.currentFilters});

  @override
  State<FilterDialog> createState() => _FilterDialogState();
}

class _FilterDialogState extends State<FilterDialog> {
  DateTime? _startDate;
  DateTime? _endDate;
  String? _selectedCategory;
  String? _selectedStatus;
  String? _selectedRole;

  List<String> _categories = [];
  List<String> _statuses = [];
  List<String> _roles = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // Initialize with current filters
    _startDate = widget.currentFilters['startDate'];
    _endDate = widget.currentFilters['endDate'];
    _selectedCategory = widget.currentFilters['assetCategory'];
    _selectedStatus = widget.currentFilters['assetStatus'];
    _selectedRole = widget.currentFilters['userRole'];

    _loadFiltersFromFirestore();
  }

  // Load real categories, statuses, and roles from Firestore
  Future<void> _loadFiltersFromFirestore() async {
    try {
      final firestore = FirebaseFirestore.instance;

      // Get unique categories from assets
      final assetsSnapshot = await firestore.collection('assets').get();
      final categoriesSet = <String>{};
      final statusesSet = <String>{};

      for (var doc in assetsSnapshot.docs) {
        final data = doc.data();
        if (data['category'] != null) {
          categoriesSet.add(data['category'].toString());
        }
        if (data['status'] != null) {
          statusesSet.add(data['status'].toString());
        }
      }

      // Get unique roles from users
      final usersSnapshot = await firestore.collection('users').get();
      final rolesSet = <String>{};

      for (var doc in usersSnapshot.docs) {
        final data = doc.data();
        if (data['role'] != null) {
          rolesSet.add(data['role'].toString());
        }
      }

      setState(() {
        _categories = categoriesSet.toList()..sort();
        _statuses = statusesSet.toList()..sort();
        _roles = rolesSet.toList()..sort();
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading filters: $e');
      // Fallback to default values
      setState(() {
        _categories = [
          'Laptop',
          'Microphone',
          'Camera',
          'Projector',
          'Monitor',
          'Tablet',
          'Printer',
          'Other',
        ];
        _statuses = ['Available', 'In Use', 'Maintenance', 'Retired'];
        _roles = ['admin', 'staff', 'student'];
        _isLoading = false;
      });
    }
  }

  Map<String, dynamic> _getFilters() {
    final filters = <String, dynamic>{};

    if (_startDate != null) filters['startDate'] = _startDate;
    if (_endDate != null) filters['endDate'] = _endDate;
    if (_selectedCategory != null) filters['assetCategory'] = _selectedCategory;
    if (_selectedStatus != null) filters['assetStatus'] = _selectedStatus;
    if (_selectedRole != null) filters['userRole'] = _selectedRole;

    return filters;
  }

  void _clearFilters() {
    setState(() {
      _startDate = null;
      _endDate = null;
      _selectedCategory = null;
      _selectedStatus = null;
      _selectedRole = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: CyberpunkTheme.surfaceDark,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: CyberpunkTheme.primaryCyan.withAlpha(77)),
      ),
      child: Container(
        width: 500,
        constraints: const BoxConstraints(maxHeight: 700),
        padding: const EdgeInsets.all(20),
        child: _isLoading
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(
                      color: CyberpunkTheme.primaryCyan,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Loading filter options...',
                      style: GoogleFonts.rajdhani(
                        color: CyberpunkTheme.textMuted,
                      ),
                    ),
                  ],
                ),
              )
            : SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.filter_alt,
                          color: CyberpunkTheme.primaryCyan,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Filter Reports',
                          style: GoogleFonts.rajdhani(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: CyberpunkTheme.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Date Range
                    Text(
                      'Date Range',
                      style: GoogleFonts.rajdhani(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: CyberpunkTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 200,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: CyberpunkTheme.primaryPurple.withAlpha(77),
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: SfDateRangePicker(
                        selectionMode: DateRangePickerSelectionMode.range,
                        initialSelectedRange:
                            _startDate != null && _endDate != null
                            ? PickerDateRange(_startDate, _endDate)
                            : null,
                        onSelectionChanged: (args) {
                          if (args.value is PickerDateRange) {
                            final range = args.value as PickerDateRange;
                            setState(() {
                              _startDate = range.startDate;
                              _endDate = range.endDate;
                            });
                          }
                        },
                        monthViewSettings:
                            const DateRangePickerMonthViewSettings(
                              firstDayOfWeek: 1,
                            ),
                        headerStyle: DateRangePickerHeaderStyle(
                          textStyle: GoogleFonts.rajdhani(
                            color: CyberpunkTheme.textPrimary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Category Filter
                    Text(
                      'Asset Category',
                      style: GoogleFonts.rajdhani(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: CyberpunkTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _selectedCategory,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: CyberpunkTheme.deepBlack,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: CyberpunkTheme.primaryCyan.withAlpha(77),
                          ),
                        ),
                        hintText: _categories.isEmpty
                            ? 'No categories available'
                            : 'Select category',
                        hintStyle: GoogleFonts.rajdhani(
                          color: CyberpunkTheme.textMuted,
                        ),
                        prefixIcon: Icon(
                          Icons.category,
                          color: CyberpunkTheme.primaryCyan,
                        ),
                      ),
                      dropdownColor: CyberpunkTheme.surfaceDark,
                      style: GoogleFonts.rajdhani(
                        color: CyberpunkTheme.textPrimary,
                      ),
                      items: _categories.map((category) {
                        return DropdownMenuItem(
                          value: category,
                          child: Text(category),
                        );
                      }).toList(),
                      onChanged: (value) =>
                          setState(() => _selectedCategory = value),
                    ),
                    const SizedBox(height: 15),

                    // Status Filter
                    Text(
                      'Asset Status',
                      style: GoogleFonts.rajdhani(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: CyberpunkTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _selectedStatus,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: CyberpunkTheme.deepBlack,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: CyberpunkTheme.primaryCyan.withAlpha(77),
                          ),
                        ),
                        hintText: _statuses.isEmpty
                            ? 'No statuses available'
                            : 'Select status',
                        hintStyle: GoogleFonts.rajdhani(
                          color: CyberpunkTheme.textMuted,
                        ),
                        prefixIcon: Icon(
                          Icons.info,
                          color: CyberpunkTheme.neonGreen,
                        ),
                      ),
                      dropdownColor: CyberpunkTheme.surfaceDark,
                      style: GoogleFonts.rajdhani(
                        color: CyberpunkTheme.textPrimary,
                      ),
                      items: _statuses.map((status) {
                        return DropdownMenuItem(
                          value: status,
                          child: Text(status),
                        );
                      }).toList(),
                      onChanged: (value) =>
                          setState(() => _selectedStatus = value),
                    ),
                    const SizedBox(height: 15),

                    // Role Filter
                    Text(
                      'User Role',
                      style: GoogleFonts.rajdhani(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: CyberpunkTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _selectedRole,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: CyberpunkTheme.deepBlack,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: CyberpunkTheme.primaryCyan.withAlpha(77),
                          ),
                        ),
                        hintText: _roles.isEmpty
                            ? 'No roles available'
                            : 'Select role',
                        hintStyle: GoogleFonts.rajdhani(
                          color: CyberpunkTheme.textMuted,
                        ),
                        prefixIcon: Icon(
                          Icons.people,
                          color: CyberpunkTheme.primaryPink,
                        ),
                      ),
                      dropdownColor: CyberpunkTheme.surfaceDark,
                      style: GoogleFonts.rajdhani(
                        color: CyberpunkTheme.textPrimary,
                      ),
                      items: _roles.map((role) {
                        return DropdownMenuItem(
                          value: role,
                          child: Text(
                            role[0].toUpperCase() + role.substring(1),
                          ),
                        );
                      }).toList(),
                      onChanged: (value) =>
                          setState(() => _selectedRole = value),
                    ),
                    const SizedBox(height: 25),

                    // Active Filters Summary
                    if (_getFilters().isNotEmpty)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: CyberpunkTheme.primaryCyan.withAlpha(25),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: CyberpunkTheme.primaryCyan.withAlpha(77),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Active Filters: ${_getFilters().length}',
                              style: GoogleFonts.rajdhani(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: CyberpunkTheme.primaryCyan,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: _getFilters().entries.map((entry) {
                                String displayValue = '';
                                if (entry.value is DateTime) {
                                  displayValue =
                                      '${entry.value.day}/${entry.value.month}/${entry.value.year}';
                                } else {
                                  displayValue = entry.value.toString();
                                }
                                return Chip(
                                  label: Text(
                                    displayValue,
                                    style: GoogleFonts.rajdhani(fontSize: 10),
                                  ),
                                  backgroundColor: CyberpunkTheme.deepBlack,
                                  side: BorderSide(
                                    color: CyberpunkTheme.primaryCyan,
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 15),

                    // Buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () {
                            _clearFilters();
                            Navigator.pop(context, <String, dynamic>{});
                          },
                          style: TextButton.styleFrom(
                            foregroundColor: CyberpunkTheme.textMuted,
                          ),
                          child: Text(
                            'Clear All',
                            style: GoogleFonts.rajdhani(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(context, _getFilters());
                          },
                          icon: const Icon(Icons.check, size: 18),
                          label: Text(
                            'Apply Filters',
                            style: GoogleFonts.rajdhani(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: CyberpunkTheme.primaryCyan,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
