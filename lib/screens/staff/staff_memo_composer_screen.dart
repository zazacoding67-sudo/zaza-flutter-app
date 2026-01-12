// lib/screens/staff/staff_memo_composer_screen.dart - NEW FILE
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../theme/cyberpunk_theme.dart';
import '../../models/memo.dart';
import '../../services/memo_service.dart';

class StaffMemoComposerScreen extends StatefulWidget {
  const StaffMemoComposerScreen({super.key});

  @override
  State<StaffMemoComposerScreen> createState() =>
      _StaffMemoComposerScreenState();
}

class _StaffMemoComposerScreenState extends State<StaffMemoComposerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _messageController = TextEditingController();
  final _memoService = MemoService();

  bool _isLoading = false;
  bool _isBroadcast = true;
  String? _selectedStudentId;
  String? _selectedStudentName;
  MemoType _selectedType = MemoType.info;
  MemoPriority _selectedPriority = MemoPriority.normal;
  DateTime? _expiresAt;

  List<Map<String, dynamic>> _students = [];

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
          .where('isActive', isEqualTo: true)
          .get();

      setState(() {
        _students = snapshot.docs.map((doc) {
          final data = doc.data();
          return {
            'id': doc.id,
            'name': data['name'] ?? 'Unknown',
            'staffId': data['staffId'] ?? '',
            'email': data['email'] ?? '',
          };
        }).toList();
      });
    } catch (e) {
      debugPrint('Error loading students: $e');
    }
  }

  Future<void> _sendMemo() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_isBroadcast && _selectedStudentId == null) {
      _showError('Please select a student');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _showError('User not logged in');
        return;
      }

      // Get sender details
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (!userDoc.exists) {
        _showError('User profile not found');
        return;
      }

      final userData = userDoc.data()!;

      await _memoService.sendMemo(
        title: _titleController.text.trim(),
        message: _messageController.text.trim(),
        sentBy: user.uid,
        sentByName: userData['name'] ?? user.email ?? 'Staff',
        sentByRole: userData['role'] ?? 'staff',
        recipientId: _isBroadcast ? null : _selectedStudentId,
        recipientName: _isBroadcast ? null : _selectedStudentName,
        type: _selectedType,
        priority: _selectedPriority,
        expiresAt: _expiresAt,
      );

      _showSuccess('Memo sent successfully!');
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      _showError('Failed to send memo: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _selectExpiryDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: CyberpunkTheme.primaryPink,
              onPrimary: Colors.white,
              surface: CyberpunkTheme.surfaceDark,
              onSurface: CyberpunkTheme.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() => _expiresAt = picked);
    }
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: CyberpunkTheme.neonGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: CyberpunkTheme.primaryPink,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CyberpunkTheme.deepBlack,
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: CyberpunkTheme.pinkCyanGradient,
          ),
        ),
        title: Text(
          'COMPOSE MEMO',
          style: GoogleFonts.orbitron(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
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
                style: GoogleFonts.orbitron(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: CyberpunkTheme.primaryPink,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 12),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: CyberpunkTheme.surfaceDark,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: CyberpunkTheme.primaryPink.withOpacity(0.3),
                  ),
                ),
                child: Column(
                  children: [
                    SwitchListTile(
                      title: Text(
                        'Broadcast to All Students',
                        style: GoogleFonts.rajdhani(
                          color: CyberpunkTheme.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      value: _isBroadcast,
                      onChanged: (value) =>
                          setState(() => _isBroadcast = value),
                      activeColor: CyberpunkTheme.primaryPink,
                    ),
                    if (!_isBroadcast) ...[
                      const Divider(color: Colors.white12),
                      DropdownButtonFormField<String>(
                        value: _selectedStudentId,
                        decoration: InputDecoration(
                          labelText: 'Select Student',
                          labelStyle: GoogleFonts.rajdhani(
                            color: CyberpunkTheme.textMuted,
                          ),
                          filled: true,
                          fillColor: CyberpunkTheme.deepBlack,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        items: _students.map((student) {
                          return DropdownMenuItem<String>(
                            value: student['id'],
                            child: Text(
                              '${student['name']} (${student['staffId']})',
                              style: GoogleFonts.rajdhani(),
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedStudentId = value;
                            _selectedStudentName = _students.firstWhere(
                              (s) => s['id'] == value,
                            )['name'];
                          });
                        },
                        dropdownColor: CyberpunkTheme.surfaceDark,
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Title
              TextFormField(
                controller: _titleController,
                style: GoogleFonts.rajdhani(
                  color: CyberpunkTheme.textPrimary,
                  fontSize: 16,
                ),
                decoration: InputDecoration(
                  labelText: 'Title *',
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
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Title is required';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Message
              TextFormField(
                controller: _messageController,
                style: GoogleFonts.rajdhani(
                  color: CyberpunkTheme.textPrimary,
                  fontSize: 16,
                ),
                maxLines: 6,
                decoration: InputDecoration(
                  labelText: 'Message *',
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
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Message is required';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 24),

              // Type & Priority
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'TYPE',
                          style: GoogleFonts.orbitron(
                            fontSize: 12,
                            color: CyberpunkTheme.textMuted,
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<MemoType>(
                          value: _selectedType,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: CyberpunkTheme.surfaceDark,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          items: MemoType.values.map((type) {
                            return DropdownMenuItem(
                              value: type,
                              child: Text(
                                type.value.toUpperCase(),
                                style: GoogleFonts.rajdhani(),
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() => _selectedType = value);
                            }
                          },
                          dropdownColor: CyberpunkTheme.surfaceDark,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'PRIORITY',
                          style: GoogleFonts.orbitron(
                            fontSize: 12,
                            color: CyberpunkTheme.textMuted,
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<MemoPriority>(
                          value: _selectedPriority,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: CyberpunkTheme.surfaceDark,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          items: MemoPriority.values.map((priority) {
                            return DropdownMenuItem(
                              value: priority,
                              child: Text(
                                priority.value.toUpperCase(),
                                style: GoogleFonts.rajdhani(),
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() => _selectedPriority = value);
                            }
                          },
                          dropdownColor: CyberpunkTheme.surfaceDark,
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Expiry Date
              InkWell(
                onTap: _selectExpiryDate,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: CyberpunkTheme.surfaceDark,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: CyberpunkTheme.primaryCyan.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        color: CyberpunkTheme.primaryCyan,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'EXPIRES ON (Optional)',
                              style: GoogleFonts.rajdhani(
                                fontSize: 10,
                                color: CyberpunkTheme.textMuted,
                                letterSpacing: 1,
                              ),
                            ),
                            Text(
                              _expiresAt != null
                                  ? '${_expiresAt!.day}/${_expiresAt!.month}/${_expiresAt!.year}'
                                  : 'No expiration',
                              style: GoogleFonts.orbitron(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: CyberpunkTheme.primaryCyan,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (_expiresAt != null)
                        IconButton(
                          icon: const Icon(Icons.clear, size: 20),
                          color: CyberpunkTheme.textMuted,
                          onPressed: () => setState(() => _expiresAt = null),
                        ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Send Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _sendMemo,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: CyberpunkTheme.primaryPink,
                    disabledBackgroundColor: CyberpunkTheme.textMuted,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 3,
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.send, size: 20),
                            const SizedBox(width: 12),
                            Text(
                              'SEND MEMO',
                              style: GoogleFonts.rajdhani(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                letterSpacing: 2,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
