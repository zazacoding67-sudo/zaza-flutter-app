// lib/widgets/memo_notification_widget.dart - NEW FILE
// Add this widget to student_dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme/cyberpunk_theme.dart';
import '../models/memo.dart';
import '../services/memo_service.dart';

class MemoNotificationWidget extends StatefulWidget {
  const MemoNotificationWidget({super.key});

  @override
  State<MemoNotificationWidget> createState() => _MemoNotificationWidgetState();
}

class _MemoNotificationWidgetState extends State<MemoNotificationWidget> {
  final MemoService _memoService = MemoService();
  final user = FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    if (user == null) return const SizedBox.shrink();

    return StreamBuilder<List<Memo>>(
      stream: _memoService.getUnreadMemosForUser(user!.uid),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox.shrink();
        }

        final unreadMemos = snapshot.data!;
        final urgentMemos = unreadMemos
            .where(
              (m) =>
                  m.priority == MemoPriority.urgent ||
                  m.type == MemoType.urgent,
            )
            .toList();

        // Show urgent memos as popup
        if (urgentMemos.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _showUrgentMemoDialog(urgentMemos.first);
          });
        }

        return _buildNotificationBadge(unreadMemos.length);
      },
    );
  }

  Widget _buildNotificationBadge(int count) {
    return Stack(
      children: [
        IconButton(
          icon: Icon(
            Icons.notifications,
            color: CyberpunkTheme.primaryPink,
            size: 28,
          ),
          onPressed: () => _showAllMemos(),
        ),
        if (count > 0)
          Positioned(
            right: 8,
            top: 8,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: CyberpunkTheme.primaryPink,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: CyberpunkTheme.primaryPink,
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ],
              ),
              constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
              child: Text(
                count > 9 ? '9+' : count.toString(),
                style: GoogleFonts.rajdhani(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }

  void _showUrgentMemoDialog(Memo memo) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: CyberpunkTheme.deepBlack,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: CyberpunkTheme.primaryPink, width: 3),
        ),
        title: Column(
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: CyberpunkTheme.primaryPink,
              size: 48,
            ),
            const SizedBox(height: 12),
            Text(
              memo.title,
              style: GoogleFonts.orbitron(
                color: CyberpunkTheme.primaryPink,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: CyberpunkTheme.surfaceDark,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                memo.message,
                style: GoogleFonts.rajdhani(
                  color: CyberpunkTheme.textPrimary,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'From: ${memo.sentByName}',
              style: GoogleFonts.rajdhani(
                color: CyberpunkTheme.textMuted,
                fontSize: 12,
              ),
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                _memoService.markAsRead(memo.id, user!.uid);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: CyberpunkTheme.primaryPink,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'GOT IT',
                style: GoogleFonts.rajdhani(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  letterSpacing: 2,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAllMemos() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const StudentNotificationsListScreen(),
      ),
    );
  }
}

// Full notifications screen
class StudentNotificationsListScreen extends StatefulWidget {
  const StudentNotificationsListScreen({super.key});

  @override
  State<StudentNotificationsListScreen> createState() =>
      _StudentNotificationsListScreenState();
}

class _StudentNotificationsListScreenState
    extends State<StudentNotificationsListScreen> {
  final MemoService _memoService = MemoService();
  final user = FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    if (user == null) {
      return const Scaffold(body: Center(child: Text('Please login')));
    }

    return Scaffold(
      backgroundColor: CyberpunkTheme.deepBlack,
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: CyberpunkTheme.pinkCyanGradient,
          ),
        ),
        title: Text(
          'NOTIFICATIONS',
          style: GoogleFonts.orbitron(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all),
            tooltip: 'Mark all as read',
            onPressed: () async {
              await _memoService.markAllAsRead(user!.uid);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('All notifications marked as read'),
                    backgroundColor: CyberpunkTheme.neonGreen,
                  ),
                );
              }
            },
          ),
        ],
      ),
      body: StreamBuilder<List<Memo>>(
        stream: _memoService.getAllMemosForUser(user!.uid, limit: 50),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                color: CyberpunkTheme.primaryPink,
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
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
                    'NO NOTIFICATIONS',
                    style: GoogleFonts.orbitron(
                      fontSize: 16,
                      color: CyberpunkTheme.textMuted,
                    ),
                  ),
                ],
              ),
            );
          }

          final memos = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: memos.length,
            itemBuilder: (context, index) {
              return _buildMemoCard(memos[index]);
            },
          );
        },
      ),
    );
  }

  Widget _buildMemoCard(Memo memo) {
    final isUnread = !memo.isReadBy(user!.uid);
    final color = _getPriorityColor(memo.priority, memo.type);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: CyberpunkTheme.surfaceDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isUnread ? color : color.withOpacity(0.3),
          width: isUnread ? 2 : 1,
        ),
        boxShadow: isUnread
            ? [
                BoxShadow(
                  color: color.withOpacity(0.2),
                  blurRadius: 15,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            if (isUnread) {
              _memoService.markAsRead(memo.id, user!.uid);
            }
            _showMemoDetails(memo);
          },
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
                        color: color.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        _getTypeIcon(memo.type),
                        color: color,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            memo.title,
                            style: GoogleFonts.rajdhani(
                              color: CyberpunkTheme.textPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'From: ${memo.sentByName}',
                            style: GoogleFonts.rajdhani(
                              color: CyberpunkTheme.textMuted,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isUnread)
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: color,
                              blurRadius: 8,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  memo.message,
                  style: GoogleFonts.rajdhani(
                    color: CyberpunkTheme.textSecondary,
                    fontSize: 14,
                    height: 1.4,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Text(
                  _formatTime(memo.sentAt),
                  style: GoogleFonts.rajdhani(
                    color: CyberpunkTheme.textMuted,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showMemoDetails(Memo memo) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: CyberpunkTheme.deepBlack,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: _getPriorityColor(memo.priority, memo.type).withOpacity(0.5),
            width: 2,
          ),
        ),
        title: Text(
          memo.title,
          style: GoogleFonts.orbitron(
            color: _getPriorityColor(memo.priority, memo.type),
            fontWeight: FontWeight.bold,
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: CyberpunkTheme.surfaceDark,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  memo.message,
                  style: GoogleFonts.rajdhani(
                    color: CyberpunkTheme.textPrimary,
                    fontSize: 14,
                    height: 1.6,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'From: ${memo.sentByName} (${memo.sentByRole})',
                style: GoogleFonts.rajdhani(
                  color: CyberpunkTheme.textMuted,
                  fontSize: 12,
                ),
              ),
              Text(
                'Sent: ${_formatTime(memo.sentAt)}',
                style: GoogleFonts.rajdhani(
                  color: CyberpunkTheme.textMuted,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'CLOSE',
              style: GoogleFonts.rajdhani(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Color _getPriorityColor(MemoPriority priority, MemoType type) {
    if (type == MemoType.urgent) return Colors.red;
    switch (priority) {
      case MemoPriority.urgent:
        return Colors.red;
      case MemoPriority.high:
        return CyberpunkTheme.primaryPink;
      case MemoPriority.normal:
        return CyberpunkTheme.primaryCyan;
      case MemoPriority.low:
        return CyberpunkTheme.neonGreen;
    }
  }

  IconData _getTypeIcon(MemoType type) {
    switch (type) {
      case MemoType.urgent:
        return Icons.warning;
      case MemoType.warning:
        return Icons.error_outline;
      case MemoType.announcement:
        return Icons.campaign;
      case MemoType.info:
        return Icons.info_outline;
    }
  }

  String _formatTime(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}d ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
