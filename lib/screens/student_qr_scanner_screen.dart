// lib/screens/student_qr_scanner_screen.dart - QR SCANNER FOR QUICK BORROWING
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme/cyberpunk_theme.dart';

class StudentQRScannerScreen extends StatefulWidget {
  const StudentQRScannerScreen({super.key});

  @override
  State<StudentQRScannerScreen> createState() => _StudentQRScannerScreenState();
}

class _StudentQRScannerScreenState extends State<StudentQRScannerScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _scanAnimation;
  bool isScanning = false;
  final _assetCodeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _scanAnimation = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _scanAnimation.dispose();
    _assetCodeController.dispose();
    super.dispose();
  }

  Future<void> _quickBorrow(String assetCode) async {
    setState(() => isScanning = true);

    try {
      // Find asset by code
      final assetQuery = await FirebaseFirestore.instance
          .collection('assets')
          .where('assetCode', isEqualTo: assetCode)
          .limit(1)
          .get();

      if (assetQuery.docs.isEmpty) {
        _showError('Asset not found');
        return;
      }

      final assetDoc = assetQuery.docs.first;
      final assetData = assetDoc.data();

      // Check if available
      if (assetData['status'] != 'Available') {
        _showError('Asset is not available');
        return;
      }

      // Get user data
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _showError('Please login');
        return;
      }

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (!userDoc.exists) {
        _showError('User data not found');
        return;
      }

      final userData = userDoc.data()!;
      final now = DateTime.now();
      final returnDate = now.add(const Duration(days: 7));

      // Create borrow request
      await FirebaseFirestore.instance.collection('borrowings').add({
        'assetId': assetDoc.id,
        'assetName': assetData['name'],
        'assetCode': assetCode,
        'category': assetData['category'],
        'serialNumber': assetData['serialNumber'],
        'userId': user.uid,
        'userName': userData['name'] ?? user.email,
        'userEmail': user.email,
        'userStaffId': userData['staffId'] ?? '',
        'userRole': userData['role'] ?? 'student',
        'requestedDate': Timestamp.fromDate(now),
        'requestedReturnDate': Timestamp.fromDate(returnDate),
        'status': 'pending',
        'expectedReturnDate': null,
        'approvedDate': null,
        'borrowedDate': null,
        'actualReturnDate': null,
        'rejectionReason': null,
        'purpose': 'Quick borrow via QR',
        'notes': '',
        'createdAt': Timestamp.fromDate(now),
        'updatedAt': Timestamp.fromDate(now),
      });

      _showSuccess('Borrow request submitted!');
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) Navigator.pop(context);
    } catch (e) {
      _showError('Error: $e');
    } finally {
      setState(() => isScanning = false);
    }
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.rajdhani(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        backgroundColor: CyberpunkTheme.neonGreen,
        behavior: SnackBarBehavior.floating,
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
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.rajdhani(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        backgroundColor: CyberpunkTheme.primaryPink,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CyberpunkTheme.deepBlack,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'QR SCANNER',
          style: GoogleFonts.orbitron(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: CyberpunkTheme.primaryPink,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          const SizedBox(height: 40),

          // Animated Scanner Frame
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(color: CyberpunkTheme.primaryPink, width: 3),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: CyberpunkTheme.primaryPink.withOpacity(0.3),
                    blurRadius: 30,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // Corner indicators
                  Positioned(
                    top: 0,
                    left: 0,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        border: Border(
                          top: BorderSide(
                            color: CyberpunkTheme.primaryPink,
                            width: 5,
                          ),
                          left: BorderSide(
                            color: CyberpunkTheme.primaryPink,
                            width: 5,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        border: Border(
                          top: BorderSide(
                            color: CyberpunkTheme.primaryPink,
                            width: 5,
                          ),
                          right: BorderSide(
                            color: CyberpunkTheme.primaryPink,
                            width: 5,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    left: 0,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: CyberpunkTheme.primaryPink,
                            width: 5,
                          ),
                          left: BorderSide(
                            color: CyberpunkTheme.primaryPink,
                            width: 5,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: CyberpunkTheme.primaryPink,
                            width: 5,
                          ),
                          right: BorderSide(
                            color: CyberpunkTheme.primaryPink,
                            width: 5,
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Scanning line animation
                  AnimatedBuilder(
                    animation: _scanAnimation,
                    builder: (context, child) {
                      return Positioned(
                        top: _scanAnimation.value * 210,
                        left: 0,
                        right: 0,
                        child: Container(
                          height: 3,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.transparent,
                                CyberpunkTheme.primaryPink,
                                Colors.transparent,
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: CyberpunkTheme.primaryPink,
                                blurRadius: 10,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),

                  // QR Icon
                  Center(
                    child: Icon(
                      Icons.qr_code_scanner,
                      size: 80,
                      color: CyberpunkTheme.primaryPink.withOpacity(0.3),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 40),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'Scan QR code on asset label',
              style: GoogleFonts.rajdhani(
                color: CyberpunkTheme.textPrimary,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
          ),

          const SizedBox(height: 40),

          // Manual Entry
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              children: [
                Text(
                  'OR ENTER ASSET CODE',
                  style: GoogleFonts.rajdhani(
                    color: CyberpunkTheme.textMuted,
                    fontSize: 12,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _assetCodeController,
                  style: GoogleFonts.rajdhani(
                    color: CyberpunkTheme.textPrimary,
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                  decoration: InputDecoration(
                    hintText: 'Enter asset code',
                    hintStyle: GoogleFonts.rajdhani(
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
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isScanning
                        ? null
                        : () {
                            if (_assetCodeController.text.isEmpty) {
                              _showError('Please enter asset code');
                              return;
                            }
                            _quickBorrow(_assetCodeController.text);
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: CyberpunkTheme.primaryPink,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: isScanning
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            'QUICK BORROW',
                            style: GoogleFonts.rajdhani(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.white,
                              letterSpacing: 1,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
