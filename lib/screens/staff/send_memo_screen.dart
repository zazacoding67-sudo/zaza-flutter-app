// lib/screens/staff/send_memo_screen.dart - Staff Send Memo to Students
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../theme/cyberpunk_theme.dart';
import '../../models/memo.dart';
import '../../services/memo_service.dart';
import '../../widgets/cyber_widgets.dart';

class SendMemoScreen extends ConsumerStatefulWidget {
  const SendMemoScreen({super.key});

  @override
  ConsumerState<SendMemoScreen> createState() => _SendMemoScreenState();
}

class _SendMemoScreenState extends ConsumerState<SendMemoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _messageController = TextEditingController();
  final _memoService = MemoService();

  MemoType _selectedType = MemoType.info;
  MemoPriority _selectedPriority = MemoPriority.normal;
  String? _selectedRecipient;
  DateTime? _expiresAt;
  bool _isSending = false;
  bool _isBroadcast = true;

  List<Map<String, dynamic>> _students = [];
  bool _loadingStudents = true;

  @override
  void initState() {
    super.initState();
    _loadStudents();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _loadStudents() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'student')
          .get();

      setState(() {
        _students = snapshot.docs
            .map(
              (doc) => {
                'id': doc.id,
                'name': doc.data()['name'] ?? 'Unknown',
                'email': doc.data()['email'] ?? '',
                'staffId': doc.data()['staffId'] ?? '',
              },
            )
            .toList();
        _loadingStudents = false;
      });
    } catch (e) {
      setState(() => _loadingStudents = false);
      debugPrint('Error loading students: $e');
    }
  }

  Future<void> _sendMemo() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSending = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Not authenticated');

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      final userData = userDoc.data()!;

      String? recipientName;
      if (!_isBroadcast && _selectedRecipient != null) {
        final student = _students.firstWhere(
          (s) => s['id'] == _selectedRecipient,
          orElse: () => {'name': 'Unknown'},
        );
        recipientName = student['name'];
      }

      await _memoService.sendMemo(
        title: _titleController.text.trim(),
        message: _messageController.text.trim(),
        sentBy: user.uid,
        sentByName: userData['name'] ?? user.email ?? 'Staff',
        sentByRole: userData['role'] ?? 'staff',
        recipientId: _isBroadcast ? null : _selectedRecipient,
        recipientName: recipientName,
        type: _selectedType,
        priority: _selectedPriority,
        expiresAt: _expiresAt,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Text(
                  _isBroadcast
                      ? 'Memo sent to all students!'
                      : 'Memo sent successfully!',
                  style: GoogleFonts.rajdhani(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            backgroundColor: CyberpunkTheme.neonGreen,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: CyberpunkTheme.primaryPink,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  Color _getTypeColor(MemoType type) {
    switch (type) {
      case MemoType.info:
        return CyberpunkTheme.primaryCyan;
      case MemoType.warning:
        return CyberpunkTheme.accentOrange;
      case MemoType.urgent:
        return CyberpunkTheme.primaryPink;
      case MemoType.announcement:
        return CyberpunkTheme.neonGreen;
    }
  }

  IconData _getTypeIcon(MemoType type) {
    switch (type) {
      case MemoType.info:
        return Icons.info;
      case MemoType.warning:
        return Icons.warning;
      case MemoType.urgent:
        return Icons.priority_high;
      case MemoType.announcement:
        return Icons.campaign;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CyberpunkTheme.deepBlack,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'SEND MEMO',
          style: GoogleFonts.orbitron(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: CyberpunkTheme.primaryPink,
            letterSpacing: 2,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Recipient Selection
              Text(
                'RECIPIENT',
                style: GoogleFonts.rajdhani(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: CyberpunkTheme.textMuted,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 12),

              // Broadcast Toggle
              SwitchListTile(
                value: _isBroadcast,
                onChanged: (value) => setState(() => _isBroadcast = value),
                title: Text(
                  'Broadcast to All Students',
                  style: GoogleFonts.rajdhani(
                    color: CyberpunkTheme.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Text(
                  _isBroadcast
                      ? 'All students will receive this memo'
                      : 'Select a specific student',
                  style: GoogleFonts.rajdhani(
                    color: CyberpunkTheme.textMuted,
                    fontSize: 12,
                  ),
                ),
                activeColor: CyberpunkTheme.primaryPink,
                tileColor: CyberpunkTheme.surfaceDark,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: CyberpunkTheme.primaryPink.withOpacity(0.3),
                  ),
                ),
              ),

              // Student Selector (if not broadcast)
              if (!_isBroadcast) ...[
                const SizedBox(height: 16),
                if (_loadingStudents)
                  Center(
                    child: CircularProgressIndicator(
                      color: CyberpunkTheme.primaryPink,
                    ),
                  )
                else
                  DropdownButtonFormField<String>(
                    value: _selectedRecipient,
                    decoration: InputDecoration(
                      labelText: 'Select Student',
                      labelStyle: GoogleFonts.rajdhani(
                        color: CyberpunkTheme.textMuted,
                      ),
                      filled: true,
                      fillColor: CyberpunkTheme.surfaceDark,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: CyberpunkTheme.primaryPink.withOpacity(0.3),
                        ),
                      ),
                    ),
                    dropdownColor: CyberpunkTheme.surfaceDark,
                    style: GoogleFonts.rajdhani(
                      color: CyberpunkTheme.textPrimary,
                    ),
                    items: _students.map((student) {
                      return DropdownMenuItem(
                        value: student['id'],
                        child: Text(
                          '${student['name']} (${student['staffId']})',
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() => _selectedRecipient = value);
                    },
                    validator: (value) {
                      if (!_isBroadcast && value == null) {
                        return 'Please select a student';
                      }
                      return null;
                    },
                  ),
              ],

              const SizedBox(height: 24),

              // Memo Type
              Text(
                'MEMO TYPE',
                style: GoogleFonts.rajdhani(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: CyberpunkTheme.textMuted,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: MemoType.values.map((type) {
                  final isSelected = _selectedType == type;
                  final color = _getTypeColor(type);
                  return FilterChip(
                    selected: isSelected,
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(_getTypeIcon(type), size: 16, color: color),
                        const SizedBox(width: 8),
                        Text(type.value.toUpperCase()),
                      ],
                    ),
                    onSelected: (selected) {
                      setState(() => _selectedType = type);
                    },
                    backgroundColor: CyberpunkTheme.surfaceDark,
                    selectedColor: color.withOpacity(0.2),
                    checkmarkColor: color,
                    labelStyle: GoogleFonts.rajdhani(
                      color: isSelected ? color : CyberpunkTheme.textMuted,
                      fontWeight: FontWeight.bold,
                    ),
                    side: BorderSide(color: color.withOpacity(0.3)),
                  );
                }).toList(),
              ),

              const SizedBox(height: 24),

              // Priority
              Text(
                'PRIORITY',
                style: GoogleFonts.rajdhani(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: CyberpunkTheme.textMuted,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: MemoPriority.values.map((priority) {
                  final isSelected = _selectedPriority == priority;
                  return ChoiceChip(
                    selected: isSelected,
                    label: Text(priority.value.toUpperCase()),
                    onSelected: (selected) {
                      setState(() => _selectedPriority = priority);
                    },
                    backgroundColor: CyberpunkTheme.surfaceDark,
                    selectedColor: CyberpunkTheme.primaryPink.withOpacity(0.2),
                    labelStyle: GoogleFonts.rajdhani(
                      color: isSelected
                          ? CyberpunkTheme.primaryPink
                          : CyberpunkTheme.textMuted,
                      fontWeight: FontWeight.bold,
                    ),
                    side: BorderSide(
                      color: CyberpunkTheme.primaryPink.withOpacity(0.3),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 24),

              // Title
              CyberTextField(
                controller: _titleController,
                label: 'Memo Title',
                hint: 'e.g., Lab Equipment Return Reminder',
                icon: Icons.title,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Message
              CyberTextField(
                controller: _messageController,
                label: 'Message',
                hint: 'Enter your message...',
                icon: Icons.message,
                maxLines: 5,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a message';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 24),

              // Expiry Date
              Text(
                'EXPIRY DATE (OPTIONAL)',
                style: GoogleFonts.rajdhani(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: CyberpunkTheme.textMuted,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 12),
              InkWell(
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now().add(const Duration(days: 7)),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                    builder: (context, child) {
                      return Theme(
                        data: Theme.of(context).copyWith(
                          colorScheme: ColorScheme.dark(
                            primary: CyberpunkTheme.primaryPink,
                            surface: CyberpunkTheme.surfaceDark,
                          ),
                        ),
                        child: child!,
                      );
                    },
                  );
                  if (date != null) {
                    setState(() => _expiresAt = date);
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: CyberpunkTheme.surfaceDark,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: CyberpunkTheme.primaryPink.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        color: CyberpunkTheme.primaryPink,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        _expiresAt != null
                            ? '${_expiresAt!.day}/${_expiresAt!.month}/${_expiresAt!.year}'
                            : 'No expiry',
                        style: GoogleFonts.rajdhani(
                          color: CyberpunkTheme.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      if (_expiresAt != null)
                        IconButton(
                          icon: Icon(
                            Icons.clear,
                            color: CyberpunkTheme.textMuted,
                          ),
                          onPressed: () => setState(() => _expiresAt = null),
                        ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Send Button
              CyberButton(
                text: 'SEND MEMO',
                icon: Icons.send,
                onPressed: _sendMemo,
                isLoading: _isSending,
                gradient: CyberpunkTheme.pinkPurpleGradient,
                glowColor: CyberpunkTheme.primaryPink,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
