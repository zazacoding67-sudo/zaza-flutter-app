// lib/screens/admin/reports/widgets/filter_dialog.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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

  final List<String> _categories = [
    'Laptop',
    'Microphone',
    'Camera',
    'Projector',
    'Monitor',
    'Tablet',
    'Printer',
    'Other',
  ];

  final List<String> _statuses = [
    'Available',
    'In Use',
    'Maintenance',
    'Retired',
  ];

  final List<String> _roles = ['Admin', 'Staff', 'Student'];

  @override
  void initState() {
    super.initState();
    // Initialize with current filters
    _startDate = widget.currentFilters['startDate'];
    _endDate = widget.currentFilters['endDate'];
    _selectedCategory = widget.currentFilters['category'];
    _selectedStatus = widget.currentFilters['status'];
    _selectedRole = widget.currentFilters['role'];
  }

  Map<String, dynamic> _getFilters() {
    final filters = <String, dynamic>{};

    if (_startDate != null) filters['startDate'] = _startDate;
    if (_endDate != null) filters['endDate'] = _endDate;
    if (_selectedCategory != null) filters['category'] = _selectedCategory;
    if (_selectedStatus != null) filters['status'] = _selectedStatus;
    if (_selectedRole != null) filters['role'] = _selectedRole;

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
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Filter Reports',
              style: GoogleFonts.rajdhani(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: CyberpunkTheme.textPrimary,
              ),
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
                initialSelectedRange: _startDate != null && _endDate != null
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
                monthViewSettings: const DateRangePickerMonthViewSettings(
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
                hintText: 'Select category',
                hintStyle: GoogleFonts.rajdhani(
                  color: CyberpunkTheme.textMuted,
                ),
              ),
              dropdownColor: CyberpunkTheme.surfaceDark,
              style: GoogleFonts.rajdhani(color: CyberpunkTheme.textPrimary),
              items: _categories.map((category) {
                return DropdownMenuItem(value: category, child: Text(category));
              }).toList(),
              onChanged: (value) => setState(() => _selectedCategory = value),
            ),
            const SizedBox(height: 15),

            // Status Filter
            Text(
              'Status',
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
                hintText: 'Select status',
                hintStyle: GoogleFonts.rajdhani(
                  color: CyberpunkTheme.textMuted,
                ),
              ),
              dropdownColor: CyberpunkTheme.surfaceDark,
              style: GoogleFonts.rajdhani(color: CyberpunkTheme.textPrimary),
              items: _statuses.map((status) {
                return DropdownMenuItem(value: status, child: Text(status));
              }).toList(),
              onChanged: (value) => setState(() => _selectedStatus = value),
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
                hintText: 'Select role',
                hintStyle: GoogleFonts.rajdhani(
                  color: CyberpunkTheme.textMuted,
                ),
              ),
              dropdownColor: CyberpunkTheme.surfaceDark,
              style: GoogleFonts.rajdhani(color: CyberpunkTheme.textPrimary),
              items: _roles.map((role) {
                return DropdownMenuItem(value: role, child: Text(role));
              }).toList(),
              onChanged: (value) => setState(() => _selectedRole = value),
            ),
            const SizedBox(height: 25),

            // Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () {
                    _clearFilters();
                    Navigator.pop(context, <String, dynamic>{});
                  },
                  child: Text(
                    'Clear All',
                    style: GoogleFonts.rajdhani(
                      color: CyberpunkTheme.textMuted,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context, _getFilters());
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: CyberpunkTheme.primaryCyan,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'Apply Filters',
                    style: GoogleFonts.rajdhani(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
