// lib/screens/staff/process_returns_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../theme/cyberpunk_theme.dart';
import '../../services/staff_service.dart';
import '../../models/borrowing.dart';

class ProcessReturnsScreen extends StatefulWidget {
  const ProcessReturnsScreen({super.key});

  @override
  State<ProcessReturnsScreen> createState() => _ProcessReturnsScreenState();
}

class _ProcessReturnsScreenState extends State<ProcessReturnsScreen> {
  final StaffService _staffService = StaffService();
  List<Borrowing> _activeBorrowings = [];
  List<Borrowing> _overdueBorrowings = [];
  bool _isLoading = true;
  bool _showOverdueOnly = false;

  @override
  void initState() {
    super.initState();
    _loadBorrowings();
  }

  Future<void> _loadBorrowings() async {
    setState(() => _isLoading = true);
    try {
      final active = await _staffService.getActiveBorrowings();
      final overdue = await _staffService.getOverdueBorrowings();

      setState(() {
        _activeBorrowings = active;
        _overdueBorrowings = overdue;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading borrowings: $e'),
            backgroundColor: CyberpunkTheme.warningYellow,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showReturnDialog(Borrowing borrowing) {
    String selectedCondition = 'Good';
    bool requiresMaintenance = false;
    final damageNotesController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: CyberpunkTheme.surfaceDark,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'Process Return',
            style: GoogleFonts.rajdhani(
              color: CyberpunkTheme.primaryCyan,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Asset info
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: CyberpunkTheme.cardDark,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        borrowing.assetName,
                        style: GoogleFonts.rajdhani(
                          color: CyberpunkTheme.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Borrowed by: ${borrowing.userName}',
                        style: GoogleFonts.rajdhani(
                          color: CyberpunkTheme.textMuted,
                          fontSize: 12,
                        ),
                      ),
                      if (borrowing.isOverdue)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            'OVERDUE by ${borrowing.daysOverdue} days',
                            style: GoogleFonts.rajdhani(
                              color: CyberpunkTheme.warningYellow,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Condition inspection
                Text(
                  'Condition Inspection',
                  style: GoogleFonts.rajdhani(
                    color: CyberpunkTheme.textMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: selectedCondition,
                  dropdownColor: CyberpunkTheme.cardDark,
                  style: GoogleFonts.rajdhani(
                    color: CyberpunkTheme.textPrimary,
                  ),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: CyberpunkTheme.cardDark,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: CyberpunkTheme.primaryCyan.withAlpha(77),
                      ),
                    ),
                    prefixIcon: Icon(
                      Icons.verified,
                      color: CyberpunkTheme.primaryCyan,
                    ),
                  ),
                  items: ['Excellent', 'Good', 'Fair', 'Poor', 'Damaged'].map((
                    condition,
                  ) {
                    Color conditionColor;
                    switch (condition) {
                      case 'Excellent':
                      case 'Good':
                        conditionColor = CyberpunkTheme.neonGreen;
                        break;
                      case 'Fair':
                        conditionColor = CyberpunkTheme.primaryCyan;
                        break;
                      case 'Poor':
                        conditionColor = CyberpunkTheme.warningYellow;
                        break;
                      case 'Damaged':
                        conditionColor = CyberpunkTheme.primaryPink;
                        break;
                      default:
                        conditionColor = CyberpunkTheme.textMuted;
                    }

                    return DropdownMenuItem(
                      value: condition,
                      child: Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: conditionColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(condition),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setDialogState(() {
                      selectedCondition = value!;
                      // Auto-check maintenance if poor or damaged
                      if (value == 'Poor' || value == 'Damaged') {
                        requiresMaintenance = true;
                      }
                    });
                  },
                ),
                const SizedBox(height: 16),

                // Maintenance checkbox
                CheckboxListTile(
                  title: Text(
                    'Requires Maintenance',
                    style: GoogleFonts.rajdhani(
                      color: CyberpunkTheme.textPrimary,
                      fontSize: 14,
                    ),
                  ),
                  subtitle: Text(
                    'Asset needs repair or servicing',
                    style: GoogleFonts.rajdhani(
                      color: CyberpunkTheme.textMuted,
                      fontSize: 12,
                    ),
                  ),
                  value: requiresMaintenance,
                  activeColor: CyberpunkTheme.primaryPink,
                  checkColor: CyberpunkTheme.deepBlack,
                  contentPadding: EdgeInsets.zero,
                  onChanged: (value) {
                    setDialogState(() => requiresMaintenance = value ?? false);
                  },
                ),
                const SizedBox(height: 16),

                // Damage notes
                TextField(
                  controller: damageNotesController,
                  maxLines: 3,
                  style: GoogleFonts.rajdhani(
                    color: CyberpunkTheme.textPrimary,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Notes (damage, issues, observations)...',
                    hintStyle: GoogleFonts.rajdhani(
                      color: CyberpunkTheme.textMuted,
                    ),
                    filled: true,
                    fillColor: CyberpunkTheme.cardDark,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: CyberpunkTheme.primaryCyan.withAlpha(77),
                      ),
                    ),
                    prefixIcon: Icon(
                      Icons.note_alt,
                      color: CyberpunkTheme.primaryCyan,
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: GoogleFonts.rajdhani(color: CyberpunkTheme.textMuted),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  await _staffService.processReturn(
                    borrowing.id,
                    borrowing.assetId,
                    condition: selectedCondition,
                    damageNotes: damageNotesController.text.isEmpty
                        ? null
                        : damageNotesController.text,
                    requiresMaintenance: requiresMaintenance,
                  );

                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Return processed successfully'),
                        backgroundColor: CyberpunkTheme.neonGreen,
                      ),
                    );
                    _loadBorrowings();
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error: $e'),
                        backgroundColor: CyberpunkTheme.warningYellow,
                      ),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: CyberpunkTheme.neonGreen,
              ),
              child: Text(
                'Process Return',
                style: GoogleFonts.rajdhani(
                  color: CyberpunkTheme.deepBlack,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _sendReminder(Borrowing borrowing) async {
    try {
      await _staffService.sendReturnReminder(borrowing.id, borrowing.userId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Reminder sent to ${borrowing.userName}'),
            backgroundColor: CyberpunkTheme.neonGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sending reminder: $e'),
            backgroundColor: CyberpunkTheme.warningYellow,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final displayList = _showOverdueOnly
        ? _overdueBorrowings
        : _activeBorrowings;

    return Scaffold(
      backgroundColor: CyberpunkTheme.deepBlack,
      appBar: AppBar(
        backgroundColor: CyberpunkTheme.surfaceDark,
        title: Text(
          'PROCESS RETURNS',
          style: GoogleFonts.rajdhani(
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadBorrowings,
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter toggle
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: CyberpunkTheme.surfaceDark,
              border: Border(
                bottom: BorderSide(
                  color: CyberpunkTheme.primaryCyan.withAlpha(77),
                ),
              ),
            ),
            child: Row(
              children: [
                Text(
                  'Filter:',
                  style: GoogleFonts.rajdhani(
                    color: CyberpunkTheme.textMuted,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(width: 12),
                ChoiceChip(
                  label: Text('All Active (${_activeBorrowings.length})'),
                  selected: !_showOverdueOnly,
                  onSelected: (selected) {
                    setState(() => _showOverdueOnly = false);
                  },
                  labelStyle: GoogleFonts.rajdhani(
                    color: !_showOverdueOnly
                        ? CyberpunkTheme.deepBlack
                        : CyberpunkTheme.textMuted,
                    fontWeight: !_showOverdueOnly
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                  backgroundColor: CyberpunkTheme.cardDark,
                  selectedColor: CyberpunkTheme.primaryCyan,
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: Text('Overdue Only (${_overdueBorrowings.length})'),
                  selected: _showOverdueOnly,
                  onSelected: (selected) {
                    setState(() => _showOverdueOnly = true);
                  },
                  labelStyle: GoogleFonts.rajdhani(
                    color: _showOverdueOnly
                        ? CyberpunkTheme.deepBlack
                        : CyberpunkTheme.textMuted,
                    fontWeight: _showOverdueOnly
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                  backgroundColor: CyberpunkTheme.cardDark,
                  selectedColor: CyberpunkTheme.warningYellow,
                ),
              ],
            ),
          ),

          // Borrowings list
          Expanded(
            child: _isLoading
                ? Center(
                    child: CircularProgressIndicator(
                      color: CyberpunkTheme.primaryCyan,
                    ),
                  )
                : displayList.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.check_circle_outline,
                          size: 64,
                          color: CyberpunkTheme.textMuted,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _showOverdueOnly
                              ? 'No overdue items'
                              : 'No active borrowings',
                          style: GoogleFonts.rajdhani(
                            color: CyberpunkTheme.textMuted,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: displayList.length,
                    itemBuilder: (context, index) {
                      final borrowing = displayList[index];
                      return _buildBorrowingCard(borrowing);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildBorrowingCard(Borrowing borrowing) {
    final isOverdue = borrowing.isOverdue;
    final daysInfo = isOverdue
        ? 'Overdue ${borrowing.daysOverdue}d'
        : 'Due in ${borrowing.daysUntilDue}d';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: CyberpunkTheme.surfaceDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isOverdue
              ? CyberpunkTheme.warningYellow
              : CyberpunkTheme.primaryCyan.withAlpha(77),
          width: isOverdue ? 2 : 1,
        ),
        boxShadow: isOverdue
            ? [
                BoxShadow(
                  color: CyberpunkTheme.warningYellow.withAlpha(51),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isOverdue
                        ? CyberpunkTheme.warningYellow.withAlpha(51)
                        : CyberpunkTheme.primaryCyan.withAlpha(51),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    isOverdue ? Icons.warning : Icons.schedule,
                    color: isOverdue
                        ? CyberpunkTheme.warningYellow
                        : CyberpunkTheme.primaryCyan,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        borrowing.assetName,
                        style: GoogleFonts.rajdhani(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: CyberpunkTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.person,
                            size: 12,
                            color: CyberpunkTheme.textMuted,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            borrowing.userName,
                            style: GoogleFonts.rajdhani(
                              fontSize: 12,
                              color: CyberpunkTheme.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: isOverdue
                        ? CyberpunkTheme.warningYellow.withAlpha(51)
                        : CyberpunkTheme.primaryCyan.withAlpha(51),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    daysInfo,
                    style: GoogleFonts.rajdhani(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isOverdue
                          ? CyberpunkTheme.warningYellow
                          : CyberpunkTheme.primaryCyan,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Divider(color: CyberpunkTheme.textMuted.withAlpha(51)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Expected Return',
                        style: GoogleFonts.rajdhani(
                          fontSize: 10,
                          color: CyberpunkTheme.textMuted,
                        ),
                      ),
                      Text(
                        DateFormat(
                          'MMM dd, yyyy',
                        ).format(borrowing.expectedReturnDate),
                        style: GoogleFonts.rajdhani(
                          fontSize: 12,
                          color: CyberpunkTheme.textPrimary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isOverdue)
                  OutlinedButton.icon(
                    onPressed: () => _sendReminder(borrowing),
                    icon: const Icon(Icons.notifications, size: 16),
                    label: Text(
                      'Send Reminder',
                      style: GoogleFonts.rajdhani(fontSize: 12),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: CyberpunkTheme.warningYellow,
                      side: BorderSide(color: CyberpunkTheme.warningYellow),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                  ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () => _showReturnDialog(borrowing),
                  icon: const Icon(Icons.check, size: 16),
                  label: Text(
                    'Process',
                    style: GoogleFonts.rajdhani(fontSize: 12),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: CyberpunkTheme.neonGreen,
                    foregroundColor: CyberpunkTheme.deepBlack,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
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
