// lib/screens/staff/staff_profile_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/cyberpunk_theme.dart';
import '../../providers/auth_provider.dart';
import '../../services/staff_service.dart';

class StaffProfileScreen extends ConsumerStatefulWidget {
  const StaffProfileScreen({super.key});

  @override
  ConsumerState<StaffProfileScreen> createState() => _StaffProfileScreenState();
}

class _StaffProfileScreenState extends ConsumerState<StaffProfileScreen> {
  final StaffService _staffService = StaffService();
  List<Map<String, dynamic>> _recentActivity = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadActivity();
  }

  Future<void> _loadActivity() async {
    setState(() => _isLoading = true);
    try {
      final activity = await _staffService.getStaffActivityHistory(limit: 10);
      setState(() => _recentActivity = activity);
    } catch (e) {
      debugPrint('Error loading activity: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(appUserProvider);

    return Scaffold(
      backgroundColor: CyberpunkTheme.deepBlack,
      body: userAsync.when(
        data: (user) {
          if (user == null) {
            return const Center(child: Text('No user data'));
          }

          return CustomScrollView(
            slivers: [
              _buildAppBar(user.name),
              SliverToBoxAdapter(
                child: Column(
                  children: [
                    _buildProfileHeader(user.name, user.email, user.staffId),
                    const SizedBox(height: 20),
                    _buildInfoSection(user.email, user.staffId),
                    const SizedBox(height: 20),
                    _buildActivitySection(),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ],
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: CyberpunkTheme.primaryCyan),
        ),
        error: (error, stack) => Center(
          child: Text('Error: $error', style: CyberpunkTheme.bodyText),
        ),
      ),
    );
  }

  Widget _buildAppBar(String name) {
    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      backgroundColor: CyberpunkTheme.surfaceDark,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: CyberpunkTheme.purpleCyanGradient,
          ),
          child: SafeArea(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 60),
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 4),
                      boxShadow: CyberpunkTheme.neonGlow(
                        CyberpunkTheme.primaryCyan,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        name.isNotEmpty ? name[0].toUpperCase() : 'S',
                        style: GoogleFonts.orbitron(
                          fontSize: 40,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        title: Text(
          'STAFF PROFILE',
          style: GoogleFonts.rajdhani(
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
        centerTitle: true,
      ),
    );
  }

  Widget _buildProfileHeader(String name, String email, String staffId) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: CyberpunkTheme.surfaceDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: CyberpunkTheme.primaryPurple.withAlpha(77)),
      ),
      child: Column(
        children: [
          Text(
            name.toUpperCase(),
            style: GoogleFonts.orbitron(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: CyberpunkTheme.primaryCyan,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: CyberpunkTheme.primaryPurple.withAlpha(51),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'STAFF',
              style: GoogleFonts.rajdhani(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: CyberpunkTheme.primaryPurple,
                letterSpacing: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection(String email, String staffId) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ACCOUNT INFO',
            style: GoogleFonts.rajdhani(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: CyberpunkTheme.primaryCyan,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          _buildInfoCard(
            'Email Address',
            email,
            Icons.email,
            CyberpunkTheme.primaryCyan,
          ),
          const SizedBox(height: 12),
          _buildInfoCard(
            'Staff ID',
            staffId,
            Icons.badge,
            CyberpunkTheme.primaryPurple,
          ),
          const SizedBox(height: 12),
          _buildInfoCard(
            'Role',
            'Staff Member',
            Icons.work,
            CyberpunkTheme.neonGreen,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CyberpunkTheme.surfaceDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withAlpha(77)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withAlpha(51),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.rajdhani(
                    fontSize: 12,
                    color: CyberpunkTheme.textMuted,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: GoogleFonts.rajdhani(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: CyberpunkTheme.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivitySection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'RECENT ACTIVITY',
                style: GoogleFonts.rajdhani(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: CyberpunkTheme.primaryCyan,
                  letterSpacing: 1.5,
                ),
              ),
              if (_isLoading)
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: CyberpunkTheme.primaryCyan,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: CyberpunkTheme.surfaceDark,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: CyberpunkTheme.primaryPink.withAlpha(77),
              ),
            ),
            child: _recentActivity.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(40),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(
                            Icons.history,
                            size: 48,
                            color: CyberpunkTheme.textMuted,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'No recent activity',
                            style: GoogleFonts.rajdhani(
                              color: CyberpunkTheme.textMuted,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(12),
                    itemCount: _recentActivity.length,
                    separatorBuilder: (context, index) => Divider(
                      color: CyberpunkTheme.textMuted.withAlpha(51),
                      height: 1,
                    ),
                    itemBuilder: (context, index) {
                      final activity = _recentActivity[index];
                      return _buildActivityItem(activity);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityItem(Map<String, dynamic> activity) {
    final action = activity['action'] ?? 'Activity';
    final description = activity['description'] ?? '';

    IconData icon;
    Color color;

    if (action.contains('Approved')) {
      icon = Icons.check_circle;
      color = CyberpunkTheme.neonGreen;
    } else if (action.contains('Rejected')) {
      icon = Icons.cancel;
      color = CyberpunkTheme.primaryPink;
    } else if (action.contains('Return')) {
      icon = Icons.assignment_return;
      color = CyberpunkTheme.primaryCyan;
    } else if (action.contains('Condition')) {
      icon = Icons.build;
      color = CyberpunkTheme.warningYellow;
    } else {
      icon = Icons.circle;
      color = CyberpunkTheme.textSecondary;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withAlpha(51),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  action,
                  style: GoogleFonts.rajdhani(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: CyberpunkTheme.textPrimary,
                  ),
                ),
                if (description.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: GoogleFonts.rajdhani(
                      fontSize: 12,
                      color: CyberpunkTheme.textMuted,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
