// lib/widgets/memo_notification_widget.dart - Popup Memo Notifications
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
  final _memoService = MemoService();
  List<Memo> _unreadMemos = [];
  int _currentMemoIndex = 0;
  bool _isVisible = false;

  @override
  void initState() {
    super.initState();
    _listenToMemos();
  }

  void _listenToMemos() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    _memoService.getUnreadMemosForUser(user.uid).listen((memos) {
      if (mounted) {
        setState(() {
          _unreadMemos = memos
              .where((m) => m.priority != MemoPriority.low)
              .toList();
          if (_unreadMemos.isNotEmpty) {
            _currentMemoIndex = 0;
            _isVisible = true;
          } else {
            _isVisible = false;
          }
        });
      }
    });
  }

  void _markAsReadAndNext() async {
    if (_unreadMemos.isEmpty) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await _memoService.markAsRead(
        _unreadMemos[_currentMemoIndex].id,
        user.uid,
      );
    }

    if (_currentMemoIndex < _unreadMemos.length - 1) {
      setState(() => _currentMemoIndex++);
    } else {
      setState(() => _isVisible = false);
    }
  }

  void _dismissAll() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      for (var memo in _unreadMemos) {
        await _memoService.markAsRead(memo.id, user.uid);
      }
    }
    setState(() => _isVisible = false);
  }

  Color _getMemoColor(Memo memo) {
    switch (memo.type) {
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

  IconData _getMemoIcon(Memo memo) {
    switch (memo.type) {
      case MemoType.info:
        return Icons.info_outline;
      case MemoType.warning:
        return Icons.warning_amber;
      case MemoType.urgent:
        return Icons.priority_high;
      case MemoType.announcement:
        return Icons.campaign;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isVisible || _unreadMemos.isEmpty) {
      return const SizedBox.shrink();
    }

    final memo = _unreadMemos[_currentMemoIndex];
    final color = _getMemoColor(memo);

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Material(
            color: Colors.transparent,
            child: TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 400),
              tween: Tween(begin: 0.0, end: 1.0),
              builder: (context, value, child) {
                return Transform.translate(
                  offset: Offset(0, -50 * (1 - value)),
                  child: Opacity(opacity: value, child: child),
                );
              },
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [color.withOpacity(0.9), color.withOpacity(0.7)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.3),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.5),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            _getMemoIcon(memo),
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                memo.type.value.toUpperCase(),
                                style: GoogleFonts.rajdhani(
                                  color: Colors.white70,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 2,
                                ),
                              ),
                              Text(
                                memo.title,
                                style: GoogleFonts.orbitron(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white),
                          onPressed: _dismissAll,
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Message
                    Text(
                      memo.message,
                      style: GoogleFonts.rajdhani(
                        color: Colors.white,
                        fontSize: 14,
                        height: 1.4,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: 12),

                    // Footer
                    Row(
                      children: [
                        Icon(
                          Icons.person_outline,
                          color: Colors.white70,
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'From: ${memo.sentByName}',
                          style: GoogleFonts.rajdhani(
                            color: Colors.white70,
                            fontSize: 11,
                          ),
                        ),
                        const Spacer(),
                        if (_unreadMemos.length > 1)
                          Text(
                            '${_currentMemoIndex + 1}/${_unreadMemos.length}',
                            style: GoogleFonts.rajdhani(
                              color: Colors.white70,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          onPressed: _markAsReadAndNext,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: color,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            _currentMemoIndex < _unreadMemos.length - 1
                                ? 'NEXT'
                                : 'GOT IT',
                            style: GoogleFonts.rajdhani(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Sidebar Memo Badge Widget
class MemoBadgeWidget extends StatelessWidget {
  final int unreadCount;

  const MemoBadgeWidget({super.key, required this.unreadCount});

  @override
  Widget build(BuildContext context) {
    if (unreadCount == 0) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: CyberpunkTheme.primaryPink,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: CyberpunkTheme.primaryPink.withOpacity(0.5),
            blurRadius: 8,
          ),
        ],
      ),
      child: Text(
        unreadCount > 99 ? '99+' : unreadCount.toString(),
        style: GoogleFonts.rajdhani(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

// Stream builder for unread count
class UnreadMemoCount extends StatelessWidget {
  final String userId;
  final Widget Function(BuildContext, int) builder;

  const UnreadMemoCount({
    super.key,
    required this.userId,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Memo>>(
      stream: MemoService().getUnreadMemosForUser(userId),
      builder: (context, snapshot) {
        final count = snapshot.data?.length ?? 0;
        return builder(context, count);
      },
    );
  }
}
