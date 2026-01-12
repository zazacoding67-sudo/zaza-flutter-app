// lib/screens/student_qr_scanner_screen.dart - FIXED QR SCANNER
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

  Future<void> _quickBorrow(String searchCode) async {
    setState(() => isScanning = true);

    try {
      // FIXED: Search by BOTH assetCode AND serialNumber
      QuerySnapshot assetQuery;

      // First try assetCode
      assetQuery = await FirebaseFirestore.instance
          .collection('assets')
          .where('assetCode', isEqualTo: searchCode)
          .limit(1)
          .get();

      // If not found, try serialNumber
      if (assetQuery.docs.isEmpty) {
        assetQuery = await FirebaseFirestore.instance
            .collection('assets')
            .where('serialNumber', isEqualTo: searchCode)
            .limit(1)
            .get();
      }

      if (assetQuery.docs.isEmpty) {
        _showError('Asset not found with code: $searchCode');
        return;
      }

      final assetDoc = assetQuery.docs.first;
      final assetData = assetDoc.data() as Map<String, dynamic>;

      // Check if available
      final status = assetData['status']?.toString() ?? '';
      if (status.toLowerCase() != 'available') {
        _showError(
          'Asset is currently ${status.toUpperCase()}. Not available for borrowing.',
        );
        return;
      }

      // Get user data
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _showError('Please login first');
        return;
      }

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (!userDoc.exists) {
        _showError('User profile not found');
        return;
      }

      final userData = userDoc.data()!;
      final now = DateTime.now();
      final returnDate = now.add(const Duration(days: 7));

      // Create borrow request
      await FirebaseFirestore.instance.collection('borrowings').add({
        'assetId': assetDoc.id,
        'assetName': assetData['name'] ?? 'Unknown',
        'assetCode': assetData['assetCode'] ?? assetData['serialNumber'],
        'category': assetData['category'] ?? '',
        'serialNumber': assetData['serialNumber'] ?? '',
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
        'purpose': 'Quick borrow via QR/Code: ${assetData['name']}',
        'notes': 'Scanned asset code: $searchCode',
        'createdAt': Timestamp.fromDate(now),
        'updatedAt': Timestamp.fromDate(now),
      });

      _showSuccess('✓ Borrow request submitted for ${assetData['name']}!');
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) Navigator.pop(context, true); // Return true to refresh
    } catch (e) {
      _showError('Error: ${e.toString()}');
      debugPrint('Quick borrow error: $e');
    } finally {
      if (mounted) {
        setState(() => isScanning = false);
      }
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
                style: GoogleFonts.rajdhani(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
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
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.rajdhani(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
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
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'QR SCANNER',
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
        child: Column(
          children: [
            const SizedBox(height: 20),

            // Animated Scanner Frame
            Center(
              child: Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: CyberpunkTheme.primaryPink,
                    width: 3,
                  ),
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
                    ...List.generate(4, (index) {
                      final positions = [
                        {'top': 0.0, 'left': 0.0},
                        {'top': 0.0, 'right': 0.0},
                        {'bottom': 0.0, 'left': 0.0},
                        {'bottom': 0.0, 'right': 0.0},
                      ];
                      final borders = [
                        {'top': true, 'left': true},
                        {'top': true, 'right': true},
                        {'bottom': true, 'left': true},
                        {'bottom': true, 'right': true},
                      ];

                      return Positioned(
                        top: positions[index]['top'] as double?,
                        left: positions[index]['left'] as double?,
                        right: positions[index]['right'] as double?,
                        bottom: positions[index]['bottom'] as double?,
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            border: Border(
                              top: borders[index]['top'] == true
                                  ? BorderSide(
                                      color: CyberpunkTheme.primaryPink,
                                      width: 5,
                                    )
                                  : BorderSide.none,
                              left: borders[index]['left'] == true
                                  ? BorderSide(
                                      color: CyberpunkTheme.primaryPink,
                                      width: 5,
                                    )
                                  : BorderSide.none,
                              right: borders[index]['right'] == true
                                  ? BorderSide(
                                      color: CyberpunkTheme.primaryPink,
                                      width: 5,
                                    )
                                  : BorderSide.none,
                              bottom: borders[index]['bottom'] == true
                                  ? BorderSide(
                                      color: CyberpunkTheme.primaryPink,
                                      width: 5,
                                    )
                                  : BorderSide.none,
                            ),
                          ),
                        ),
                      );
                    }),

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

            const SizedBox(height: 30),

            // Instructions
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: CyberpunkTheme.surfaceDark,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: CyberpunkTheme.primaryCyan.withOpacity(0.3),
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: CyberpunkTheme.primaryCyan,
                    size: 24,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Scan QR code on asset label\nor enter code manually below',
                    style: GoogleFonts.rajdhani(
                      color: CyberpunkTheme.textPrimary,
                      fontSize: 14,
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // Manual Entry Section
            Text(
              'MANUAL ENTRY',
              style: GoogleFonts.rajdhani(
                color: CyberpunkTheme.textMuted,
                fontSize: 12,
                letterSpacing: 2,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // Asset Code Input
            TextField(
              controller: _assetCodeController,
              style: GoogleFonts.rajdhani(
                color: CyberpunkTheme.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
              textCapitalization: TextCapitalization.characters,
              decoration: InputDecoration(
                hintText: 'Enter SN001 or Asset Code',
                hintStyle: GoogleFonts.rajdhani(
                  color: CyberpunkTheme.textMuted,
                  fontSize: 14,
                ),
                filled: true,
                fillColor: CyberpunkTheme.surfaceDark,
                prefixIcon: Icon(Icons.edit, color: CyberpunkTheme.primaryPink),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: CyberpunkTheme.primaryPink.withOpacity(0.3),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: CyberpunkTheme.primaryPink.withOpacity(0.3),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: CyberpunkTheme.primaryPink,
                    width: 2,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Quick Borrow Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: isScanning
                    ? null
                    : () {
                        final code = _assetCodeController.text.trim();
                        if (code.isEmpty) {
                          _showError('Please enter asset code');
                          return;
                        }
                        _quickBorrow(code);
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: CyberpunkTheme.primaryPink,
                  disabledBackgroundColor: CyberpunkTheme.textMuted,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                  shadowColor: CyberpunkTheme.primaryPink.withOpacity(0.5),
                ),
                child: isScanning
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
                          const Icon(Icons.flash_on, size: 24),
                          const SizedBox(width: 12),
                          Text(
                            'QUICK BORROW',
                            style: GoogleFonts.rajdhani(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.white,
                              letterSpacing: 2,
                            ),
                          ),
                        ],
                      ),
              ),
            ),

            const SizedBox(height: 20),

            // Help Text
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: CyberpunkTheme.neonGreen.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: CyberpunkTheme.neonGreen.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.tips_and_updates,
                    color: CyberpunkTheme.neonGreen,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Accepts both Serial Number (SN001) and Asset Code',
                      style: GoogleFonts.rajdhani(
                        color: CyberpunkTheme.neonGreen,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
