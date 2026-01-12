// lib/screens/student_notifications_screen.dart - NOTIFICATIONS & ALERTS
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme/cyberpunk_theme.dart';

class StudentNotificationsScreen extends StatefulWidget {
  const StudentNotificationsScreen({super.key});

  @override
  State<StudentNotificationsScreen> createState() =>
      _StudentNotificationsScreenState();
}

class _StudentNotificationsScreenState extends State<StudentNotificationsScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Center(child: Text('Please login'));
    }

    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                CyberpunkTheme.primaryPink.withOpacity(0.2),
                Colors.transparent,
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'NOTIFICATIONS',
                style: GoogleFonts.orbitron(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: CyberpunkTheme.primaryPink,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 16),
              TabBar(
                controller: _tabController,
                labelStyle: GoogleFonts.rajdhani(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
                unselectedLabelStyle: GoogleFonts.rajdhani(fontSize: 11),
                labelColor: CyberpunkTheme.primaryPink,
                unselectedLabelColor: CyberpunkTheme.textMuted,
                indicatorColor: CyberpunkTheme.primaryPink,
                indicatorWeight: 3,
                tabs: const [
                  Tab(text: 'ALL'),
                  Tab(text: 'REMINDERS'),
                  Tab(text: 'UPDATES'),
                ],
              ),
            ],
          ),
        ),

        // Tab Content
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildAllNotifications(user.uid),
              _buildReminders(user.uid),
              _buildUpdates(user.uid),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAllNotifications(String userId) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('borrowings')
          .where('userId', isEqualTo: userId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: CyberpunkTheme.primaryPink),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyState('No notifications');
        }

        final notifications = _processNotifications(snapshot.data!.docs);

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: notifications.length,
          itemBuilder: (context, index) {
            return _buildNotificationCard(notifications[index]);
          },
        );
      },
    );
  }

  Widget _buildReminders(String userId) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('borrowings')
          .where('userId', isEqualTo: userId)
          .where('status', isEqualTo: 'active')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: CyberpunkTheme.primaryPink),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyState('No active reminders');
        }

        final reminders = <Map<String, dynamic>>[];
        for (var doc in snapshot.data!.docs) {
          final data = doc.data() as Map<String, dynamic>;
          final expectedReturn = (data['expectedReturnDate'] as Timestamp?)
              ?.toDate();

          if (expectedReturn != null) {
            final daysUntilDue = expectedReturn
                .difference(DateTime.now())
                .inDays;
            reminders.add({
              'type': 'reminder',
              'title': 'Return Due Soon',
              'message': '${data['assetName']} due in $daysUntilDue days',
              'timestamp': expectedReturn,
              'color': daysUntilDue <= 2
                  ? CyberpunkTheme.primaryPink
                  : CyberpunkTheme.accentOrange,
              'icon': Icons.alarm,
            });
          }
        }

        if (reminders.isEmpty) {
          return _buildEmptyState('No active reminders');
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: reminders.length,
          itemBuilder: (context, index) {
            return _buildNotificationCard(reminders[index]);
          },
        );
      },
    );
  }

  Widget _buildUpdates(String userId) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('borrowings')
          .where('userId', isEqualTo: userId)
          .where(
            'status',
            whereIn: ['pending', 'active', 'returned', 'rejected'],
          )
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: CyberpunkTheme.primaryPink),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyState('No updates');
        }

        final updates = <Map<String, dynamic>>[];
        for (var doc in snapshot.data!.docs) {
          final data = doc.data() as Map<String, dynamic>;
          final status = data['status'] as String;

          if (status == 'pending') {
            updates.add({
              'type': 'update',
              'title': 'Request Pending',
              'message': '${data['assetName']} awaiting approval',
              'timestamp': (data['requestedDate'] as Timestamp).toDate(),
              'color': CyberpunkTheme.accentOrange,
              'icon': Icons.pending,
            });
          } else if (status == 'active') {
            updates.add({
              'type': 'update',
              'title': 'Request Approved',
              'message': '${data['assetName']} is now borrowed',
              'timestamp':
                  (data['approvedDate'] as Timestamp?)?.toDate() ??
                  DateTime.now(),
              'color': CyberpunkTheme.neonGreen,
              'icon': Icons.check_circle,
            });
          } else if (status == 'rejected') {
            updates.add({
              'type': 'update',
              'title': 'Request Rejected',
              'message': '${data['assetName']} request was rejected',
              'timestamp':
                  (data['rejectedDate'] as Timestamp?)?.toDate() ??
                  DateTime.now(),
              'color': CyberpunkTheme.primaryPink,
              'icon': Icons.cancel,
            });
          }
        }

        if (updates.isEmpty) {
          return _buildEmptyState('No updates');
        }

        // Sort by timestamp
        updates.sort(
          (a, b) => (b['timestamp'] as DateTime).compareTo(
            a['timestamp'] as DateTime,
          ),
        );

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: updates.length,
          itemBuilder: (context, index) {
            return _buildNotificationCard(updates[index]);
          },
        );
      },
    );
  }

  List<Map<String, dynamic>> _processNotifications(
    List<QueryDocumentSnapshot> docs,
  ) {
    final notifications = <Map<String, dynamic>>[];

    for (var doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      final status = data['status'] as String;

      if (status == 'pending') {
        notifications.add({
          'type': 'info',
          'title': 'Request Pending',
          'message': '${data['assetName']} awaiting approval',
          'timestamp': (data['requestedDate'] as Timestamp).toDate(),
          'color': CyberpunkTheme.accentOrange,
          'icon': Icons.pending,
        });
      } else if (status == 'active') {
        final expectedReturn = (data['expectedReturnDate'] as Timestamp?)
            ?.toDate();
        if (expectedReturn != null) {
          final daysUntilDue = expectedReturn.difference(DateTime.now()).inDays;
          if (daysUntilDue <= 3) {
            notifications.add({
              'type': 'reminder',
              'title': 'Return Reminder',
              'message': '${data['assetName']} due in $daysUntilDue days',
              'timestamp': expectedReturn,
              'color': daysUntilDue <= 1
                  ? CyberpunkTheme.primaryPink
                  : CyberpunkTheme.accentOrange,
              'icon': Icons.alarm,
            });
          }
        }
      }
    }

    // Sort by timestamp
    notifications.sort(
      (a, b) =>
          (b['timestamp'] as DateTime).compareTo(a['timestamp'] as DateTime),
    );

    return notifications;
  }

  Widget _buildNotificationCard(Map<String, dynamic> notification) {
    final color = notification['color'] as Color;
    final timestamp = notification['timestamp'] as DateTime;
    final timeAgo = _formatTimeAgo(timestamp);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: CyberpunkTheme.surfaceDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3), width: 2),
        boxShadow: [BoxShadow(color: color.withOpacity(0.1), blurRadius: 20)],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Icon
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(color: color.withOpacity(0.3), blurRadius: 10),
                ],
              ),
              child: Icon(
                notification['icon'] as IconData,
                color: color,
                size: 24,
              ),
            ),

            const SizedBox(width: 16),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notification['title'] as String,
                    style: GoogleFonts.rajdhani(
                      color: CyberpunkTheme.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notification['message'] as String,
                    style: GoogleFonts.rajdhani(
                      color: CyberpunkTheme.textMuted,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    timeAgo,
                    style: GoogleFonts.rajdhani(
                      color: color,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
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

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_off,
            size: 80,
            color: CyberpunkTheme.textMuted.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            message.toUpperCase(),
            style: GoogleFonts.orbitron(
              color: CyberpunkTheme.textMuted,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  String _formatTimeAgo(DateTime timestamp) {
    final difference = DateTime.now().difference(timestamp);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}
