import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import '../../theme/theme_manager.dart';
import '../../services/api_service.dart';
import '../../services/session_manager.dart';
import '../../widgets/counselor_sidebar.dart';
import '../../widgets/glass_card.dart';

class CounselorDashboard extends StatefulWidget {
  const CounselorDashboard({super.key});

  @override
  State<CounselorDashboard> createState() => _CounselorDashboardState();
}

class _CounselorDashboardState extends State<CounselorDashboard> {
  final _session = SessionManager();
  String _timeFilter = 'all';
  bool _isLoading = true;
  Map<String, dynamic> _stats = {};

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() => _isLoading = true);
    try {
      final data = await ApiService.getDashboardStats(_timeFilter);
      if (data['status'] == 'success') {
        setState(() => _stats = data);
      }
    } catch (_) {}
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      drawer: CounselorSidebar(currentRoute: '/guidance-counselor/dashboard'),
      appBar: AppBar(
        title: const Text('Counselor Dashboard'),
        leading: Builder(
          builder: (ctx) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(ctx).openDrawer(),
          ),
        ),
        actions: [
          IconButton(
            icon: ValueListenableBuilder<ThemeMode>(
              valueListenable: ThemeManager.themeModeNotifier,
              builder: (context, mode, child) {
                return Icon(mode == ThemeMode.dark ? Icons.light_mode : Icons.dark_mode);
              },
            ),
            tooltip: 'Toggle Theme',
            onPressed: ThemeManager.toggleTheme,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadStats,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              _session.logout();
              context.go('/login');
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadStats,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome Banner Card
              GlassCard(
                borderRadius: 16,
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: AppTheme.primaryPurple.withOpacity(0.15),
                      child: const Icon(Icons.psychology, size: 28, color: AppTheme.primaryPurple),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Welcome, ${_session.counselorFirstName ?? 'Counselor'}!',
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: 22,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Monitor student assessments and review recommendations.',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppTheme.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Time filter pills
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'today', label: Text('Today')),
                  ButtonSegment(value: 'week', label: Text('This Week')),
                  ButtonSegment(value: 'month', label: Text('This Month')),
                  ButtonSegment(value: 'all', label: Text('All Time')),
                ],
                selected: {_timeFilter},
                onSelectionChanged: (s) {
                  setState(() => _timeFilter = s.first);
                  _loadStats();
                },
              ),
              const SizedBox(height: 24),

              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.all(40),
                  child: Center(child: CircularProgressIndicator()),
                )
              else ...[
                () {
                  final strandStats = List<Map<String, dynamic>>.from(_stats['strandStats'] ?? []);
                  final riasecStats = List<Map<String, dynamic>>.from(_stats['riasecStats'] ?? []);
                  final rseStats = List<Map<String, dynamic>>.from(_stats['rseStats'] ?? []);
                  final cdsesStats = List<Map<String, dynamic>>.from(_stats['cdsesStats'] ?? []);
                  final recentActivity = List<Map<String, dynamic>>.from(_stats['recentActivity'] ?? []);

                  return LayoutBuilder(
                    builder: (context, constraints) {
                      final isWide = constraints.maxWidth > 900;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Top 4 Stat Cards
                          if (isWide)
                            Row(
                              children: [
                                Expanded(child: _buildSparklineStatCard(
                                  context, 'Pending Approvals', '${_stats['pendingCount'] ?? 0}',
                                  Icons.assignment_turned_in_outlined, const Color(0xFFFF9800),
                                  () => context.go('/guidance-counselor/pending-approvals'),
                                  sparklineType: 'wave',
                                )),
                                const SizedBox(width: 16),
                                Expanded(child: _buildSparklineStatCard(
                                  context, 'Total Students', '${_stats['totalStudents'] ?? 0}',
                                  Icons.people_alt_outlined, const Color(0xFF2196F3),
                                  () => context.go('/guidance-counselor/student-records'),
                                  sparklineType: 'bars',
                                )),
                                const SizedBox(width: 16),
                                Expanded(child: _buildSparklineStatCard(
                                  context, 'Assessments Today', '${_stats['assessmentsToday'] ?? 0}',
                                  Icons.insert_chart_outlined_rounded, const Color(0xFF4CAF50),
                                  () => context.go('/guidance-counselor/monitoring'),
                                  sparklineType: 'bars',
                                )),
                                const SizedBox(width: 16),
                                Expanded(child: _buildSparklineStatCard(
                                  context, 'Live Now', '${_stats['inProgress'] ?? 0}',
                                  Icons.sensors_rounded, AppTheme.primaryPurple,
                                  () => context.go('/guidance-counselor/monitoring'),
                                  sparklineType: 'wave',
                                )),
                              ],
                            )
                          else
                            Column(
                              children: [
                                Row(
                                  children: [
                                    Expanded(child: _buildSparklineStatCard(
                                      context, 'Pending Approvals', '${_stats['pendingCount'] ?? 0}',
                                      Icons.assignment_turned_in_outlined, const Color(0xFFFF9800),
                                      () => context.go('/guidance-counselor/pending-approvals'),
                                      sparklineType: 'wave',
                                    )),
                                    const SizedBox(width: 12),
                                    Expanded(child: _buildSparklineStatCard(
                                      context, 'Total Students', '${_stats['totalStudents'] ?? 0}',
                                      Icons.people_alt_outlined, const Color(0xFF2196F3),
                                      () => context.go('/guidance-counselor/student-records'),
                                      sparklineType: 'bars',
                                    )),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(child: _buildSparklineStatCard(
                                      context, 'Assessments Today', '${_stats['assessmentsToday'] ?? 0}',
                                      Icons.insert_chart_outlined_rounded, const Color(0xFF4CAF50),
                                      () => context.go('/guidance-counselor/monitoring'),
                                      sparklineType: 'bars',
                                    )),
                                    const SizedBox(width: 12),
                                    Expanded(child: _buildSparklineStatCard(
                                      context, 'Live Now', '${_stats['inProgress'] ?? 0}',
                                      Icons.sensors_rounded, AppTheme.primaryPurple,
                                      () => context.go('/guidance-counselor/monitoring'),
                                      sparklineType: 'wave',
                                    )),
                                  ],
                                ),
                              ],
                            ),
                          const SizedBox(height: 24),

                          // Row 1: Dominant Career Interests (RIASEC) & Strand Distribution - EQUAL HEIGHT
                          if (isWide)
                            IntrinsicHeight(
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Expanded(child: _buildRiasecCard(riasecStats)),
                                  const SizedBox(width: 20),
                                  Expanded(child: _buildStrandCard(strandStats)),
                                ],
                              ),
                            )
                          else ...[
                            _buildRiasecCard(riasecStats),
                            const SizedBox(height: 20),
                            _buildStrandCard(strandStats),
                          ],
                          const SizedBox(height: 24),

                          // Row 2: RSE Profile & Career Self-Efficacy Profile - EQUAL HEIGHT
                          if (isWide)
                            IntrinsicHeight(
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Expanded(child: _buildRseCard(rseStats)),
                                  const SizedBox(width: 20),
                                  Expanded(child: _buildCdsesCard(cdsesStats)),
                                ],
                              ),
                            )
                          else ...[
                            _buildRseCard(rseStats),
                            const SizedBox(height: 20),
                            _buildCdsesCard(cdsesStats),
                          ],
                          const SizedBox(height: 24),

                          // Row 3: Recent Student Activities Table - FULL WIDTH
                          _buildRecentActivityTable(recentActivity),
                          const SizedBox(height: 24),

                          // Row 4: Top Recommended Course Clusters & Quick Actions Grid
                          if (isWide)
                            IntrinsicHeight(
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Expanded(child: _buildTopClustersCard()),
                                  const SizedBox(width: 20),
                                  Expanded(child: _buildQuickActionsGrid()),
                                ],
                              ),
                            )
                          else ...[
                            _buildTopClustersCard(),
                            const SizedBox(height: 20),
                            _buildQuickActionsGrid(),
                          ],
                        ],
                      );
                    },
                  );
                }(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // Sparkline Top Stat Card
  Widget _buildSparklineStatCard(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
    VoidCallback onTap, {
    required String sparklineType,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.08) : AppTheme.dividerColor.withOpacity(0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Stack(
              children: [
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Opacity(
                    opacity: 0.18,
                    child: SizedBox(
                      width: 70,
                      height: 36,
                      child: sparklineType == 'bars'
                          ? Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                _miniBar(12, color),
                                _miniBar(20, color),
                                _miniBar(16, color),
                                _miniBar(28, color),
                                _miniBar(24, color),
                              ],
                            )
                          : CustomPaint(painter: WavePainter(color: color)),
                    ),
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(icon, color: color, size: 22),
                        ),
                        Icon(
                          Icons.arrow_forward_ios_rounded,
                          color: AppTheme.textSecondary.withOpacity(0.3),
                          size: 12,
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(
                      value,
                      style: GoogleFonts.montserrat(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : AppTheme.textPrimary,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _miniBar(double height, Color color) {
    return Container(
      width: 8,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  // Dominant Career Interests (RIASEC)
  Widget _buildRiasecCard(List<Map<String, dynamic>> riasecStats) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final map = {for (var s in riasecStats) s['type'].toString(): s['count'] as int};
    final total = map.values.fold(0, (sum, val) => sum + val);

    return Card(
      elevation: 0,
      color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppTheme.dividerColor.withOpacity(0.4)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.pie_chart_rounded, color: AppTheme.primaryPurple, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Dominant Career Interests (Primary Types)',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                  ],
                ),
                InkWell(
                  onTap: () => _showRiasecDetailsDialog(riasecStats, total),
                  child: const Row(
                    children: [
                      Text(
                        'View Details',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryPurple,
                        ),
                      ),
                      SizedBox(width: 2),
                      Icon(Icons.arrow_forward_rounded, size: 14, color: AppTheme.primaryPurple),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (total == 0)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Text(
                    'No approved assessment results yet.',
                    style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                  ),
                ),
              )
            else
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: ['R', 'I', 'A', 'S', 'E', 'C'].map((t) {
                    final count = map[t] ?? 0;
                    final pct = total > 0 ? (count / total * 100) : 0.0;
                    final color = AppTheme.riasecColor(t);

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6.0),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 12,
                            backgroundColor: color.withOpacity(0.15),
                            child: Text(
                              t,
                              style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 11),
                            ),
                          ),
                          const SizedBox(width: 10),
                          SizedBox(
                            width: 90,
                            child: Text(
                              AppTheme.riasecName(t),
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                            ),
                          ),
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: LinearProgressIndicator(
                                value: total > 0 ? count / total : 0.0,
                                backgroundColor: isDark ? Colors.white10 : AppTheme.dividerColor.withOpacity(0.3),
                                valueColor: AlwaysStoppedAnimation<Color>(color),
                                minHeight: 10,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          SizedBox(
                            width: 50,
                            child: Text(
                              '${pct.toStringAsFixed(1)}%',
                              textAlign: TextAlign.right,
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Row(
                            children: [
                              Icon(Icons.person_outline, size: 13, color: AppTheme.textSecondary),
                              const SizedBox(width: 2),
                              Text(
                                '$count student(s)',
                                style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // Strand Distribution Card
  Widget _buildStrandCard(List<Map<String, dynamic>> strandStats) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final total = strandStats.fold(0, (sum, item) => sum + (item['count'] as int));

    return Card(
      elevation: 0,
      color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppTheme.dividerColor.withOpacity(0.4)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.school_rounded, color: AppTheme.primaryPurple, size: 20),
                    SizedBox(width: 8),
                    Text('Strand Distribution', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  ],
                ),
                InkWell(
                  onTap: () => _showStrandDetailsDialog(strandStats),
                  child: const Row(
                    children: [
                      Text(
                        'View Details',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryPurple,
                        ),
                      ),
                      SizedBox(width: 2),
                      Icon(Icons.arrow_forward_rounded, size: 14, color: AppTheme.primaryPurple),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (total == 0)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Text('No strand data available.', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                ),
              )
            else
              Expanded(
                child: Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          children: strandStats.map((item) {
                            final strandName = item['strand'].toString();
                            final count = item['count'] as int;
                            final pct = total > 0 ? count / total : 0.0;

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(strandName, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                      Text('$count student(s)', style: TextStyle(fontSize: 11, color: AppTheme.textSecondary, fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(6),
                                    child: LinearProgressIndicator(
                                      value: pct,
                                      backgroundColor: isDark ? Colors.white10 : AppTheme.dividerColor.withOpacity(0.3),
                                      valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryPurple),
                                      minHeight: 10,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Callout Box
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryPurple.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.primaryPurple.withOpacity(0.15)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline_rounded, color: AppTheme.primaryPurple, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'About Strand Distribution',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.primaryPurple),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'This shows student distribution per academic strand based on assessment results.',
                                  style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                                ),
                              ],
                            ),
                          ),
                        ],
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

  // Self-Esteem (RSE) Card
  Widget _buildRseCard(List<Map<String, dynamic>> rseStats) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final total = rseStats.fold(0, (sum, item) => sum + (item['count'] as int));

    return Card(
      elevation: 0,
      color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppTheme.dividerColor.withOpacity(0.4)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.favorite_rounded, color: Color(0xFFE53E3E), size: 20),
                    SizedBox(width: 8),
                    Text('Self-Esteem (RSE)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  ],
                ),
                InkWell(
                  onTap: () => _showRseDetailsDialog(rseStats),
                  child: const Row(
                    children: [
                      Text(
                        'View Details',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryPurple,
                        ),
                      ),
                      SizedBox(width: 2),
                      Icon(Icons.arrow_forward_rounded, size: 14, color: AppTheme.primaryPurple),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (total == 0)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Text('No self-esteem data available.', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                ),
              )
            else ...[
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      children: rseStats.map((item) {
                        final level = item['level'].toString();
                        final count = item['count'] as int;
                        final isLow = level.toLowerCase().contains('low');
                        final color = isLow ? const Color(0xFFE53E3E) : AppTheme.success;

                        return Expanded(
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 10),
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.06),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: color.withOpacity(0.2)),
                            ),
                            child: Column(
                              children: [
                                Icon(
                                  isLow ? Icons.sentiment_very_dissatisfied : Icons.sentiment_satisfied_alt,
                                  color: color,
                                  size: 32,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  level,
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: color),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '$count student(s)',
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Identifies students with low self-esteem levels who may benefit from academic self-worth enrichment programs.',
                      style: TextStyle(fontSize: 11, color: AppTheme.textSecondary, height: 1.4),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // Career Self-Efficacy Card
  Widget _buildCdsesCard(List<Map<String, dynamic>> cdsesStats) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final total = cdsesStats.fold(0, (sum, item) => sum + (item['count'] as int));

    return Card(
      elevation: 0,
      color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppTheme.dividerColor.withOpacity(0.4)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.stars_rounded, color: AppTheme.primaryPurple, size: 20),
                    SizedBox(width: 8),
                    Text('Career Self-Efficacy', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  ],
                ),
                InkWell(
                  onTap: () => _showCdsesDetailsDialog(cdsesStats),
                  child: const Row(
                    children: [
                      Text(
                        'View Details',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryPurple,
                        ),
                      ),
                      SizedBox(width: 2),
                      Icon(Icons.arrow_forward_rounded, size: 14, color: AppTheme.primaryPurple),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (total == 0)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Text('No self-efficacy data available.', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                ),
              )
            else ...[
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ...cdsesStats.map((item) {
                      final levelName = item['level'].toString();
                      final count = item['count'] as int;
                      final isHigh = levelName.toLowerCase().contains('high');
                      final isMod = levelName.toLowerCase().contains('mod');
                      final color = isHigh ? AppTheme.success : isMod ? AppTheme.warning : const Color(0xFFE53E3E);
                      final pct = total > 0 ? count / total : 0.0;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 14.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  levelName.replaceAll(' Career Decision Self-Efficacy', ''),
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color),
                                ),
                                Text('$count student(s)', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                              ],
                            ),
                            const SizedBox(height: 6),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: LinearProgressIndicator(
                                value: pct,
                                backgroundColor: isDark ? Colors.white10 : AppTheme.dividerColor.withOpacity(0.3),
                                valueColor: AlwaysStoppedAnimation<Color>(color),
                                minHeight: 10,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                    const SizedBox(height: 6),
                    Text(
                      'Tracks confidence in self-appraisal, occupational info gathering, goal selecting, planning, and problem-solving.',
                      style: TextStyle(fontSize: 11, color: AppTheme.textSecondary, height: 1.4),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // 5-Column Table for Recent Student Activities - FULL WIDTH EXPANSION
  Widget _buildRecentActivityTable(List<Map<String, dynamic>> recentActivity) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      elevation: 0,
      color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppTheme.dividerColor.withOpacity(0.4)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.history_rounded, color: AppTheme.primaryPurple, size: 20),
                    SizedBox(width: 8),
                    Text('Recent Student Activities', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ],
                ),
                InkWell(
                  onTap: () => context.go('/guidance-counselor/monitoring'),
                  child: const Row(
                    children: [
                      Text(
                        'View All',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primaryPurple),
                      ),
                      SizedBox(width: 2),
                      Icon(Icons.arrow_forward_rounded, size: 14, color: AppTheme.primaryPurple),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (recentActivity.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Text('No student activity logged yet.', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                ),
              )
            else
              SizedBox(
                width: double.infinity,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minWidth: MediaQuery.of(context).size.width - 80),
                    child: DataTable(
                      horizontalMargin: 12,
                      columnSpacing: 28,
                      headingRowHeight: 42,
                      dataRowMinHeight: 48,
                      dataRowMaxHeight: 54,
                      columns: [
                        DataColumn(label: Text('STUDENT NAME', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.primaryPurple))),
                        DataColumn(label: Text('ACTIVITY', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.primaryPurple))),
                        DataColumn(label: Text('DETAILS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.primaryPurple))),
                        DataColumn(label: Text('DATE & TIME', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.primaryPurple))),
                        DataColumn(label: Text('STATUS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.primaryPurple))),
                      ],
                      rows: recentActivity.map((act) {
                        final isApproved = act['status'].toString() == 'approved';
                        final color = isApproved ? AppTheme.success : AppTheme.warning;
                        final name = act['studentName']?.toString() ?? 'Anonymous';
                        final firstChar = name.isNotEmpty ? name[0].toUpperCase() : 'S';

                        return DataRow(
                          cells: [
                            DataCell(
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  CircleAvatar(
                                    radius: 14,
                                    backgroundColor: AppTheme.primaryPurple.withOpacity(0.12),
                                    child: Text(
                                      firstChar,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.primaryPurple),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                ],
                              ),
                            ),
                            DataCell(
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  CircleAvatar(
                                    radius: 10,
                                    backgroundColor: AppTheme.success.withOpacity(0.15),
                                    child: const Icon(Icons.check, size: 10, color: AppTheme.success),
                                  ),
                                  const SizedBox(width: 6),
                                  const Text('Assessment Submitted', style: TextStyle(fontSize: 11)),
                                ],
                              ),
                            ),
                            DataCell(
                              Text(
                                'Strand: ${act['strand'] ?? 'N/A'}',
                                style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                              ),
                            ),
                            DataCell(
                              Text(
                                act['submittedAt']?.toString() ?? '',
                                style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                              ),
                            ),
                            DataCell(
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: color.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: color.withOpacity(0.3)),
                                ),
                                child: Text(
                                  isApproved ? 'Approved' : 'Pending',
                                  style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // Top Recommended Course Clusters Leaderboard Widget
  Widget _buildTopClustersCard() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final topClusters = [
      {'rank': 1, 'name': 'Technology & Engineering Cluster', 'count': 4, 'pct': 0.60},
      {'rank': 2, 'name': 'Business & Accountancy Cluster', 'count': 2, 'pct': 0.30},
      {'rank': 3, 'name': 'Humanities & Social Sciences Cluster', 'count': 1, 'pct': 0.15},
    ];

    return Card(
      elevation: 0,
      color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppTheme.dividerColor.withOpacity(0.4)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.collections_bookmark_rounded, color: AppTheme.primaryPurple, size: 20),
                    SizedBox(width: 8),
                    Text('Top Recommended Course Clusters', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  ],
                ),
                InkWell(
                  onTap: _showTopClustersDialog,
                  child: const Row(
                    children: [
                      Text(
                        'View All',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primaryPurple),
                      ),
                      SizedBox(width: 2),
                      Icon(Icons.arrow_forward_rounded, size: 14, color: AppTheme.primaryPurple),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...topClusters.map((item) {
              final rank = item['rank'] as int;
              final name = item['name'].toString();
              final count = item['count'] as int;
              final pct = item['pct'] as double;

              return Padding(
                padding: const EdgeInsets.only(bottom: 14.0),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 14,
                      backgroundColor: AppTheme.primaryPurple,
                      child: Text(
                        '$rank',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                          const SizedBox(height: 4),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: pct,
                              backgroundColor: isDark ? Colors.white10 : AppTheme.dividerColor.withOpacity(0.3),
                              valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryPurple),
                              minHeight: 6,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '$count student(s)',
                      style: TextStyle(fontSize: 11, color: AppTheme.textSecondary, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 4),
                    Icon(Icons.chevron_right_rounded, size: 16, color: AppTheme.textSecondary),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  // 2x2 Quick Actions Grid
  Widget _buildQuickActionsGrid() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      elevation: 0,
      color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppTheme.dividerColor.withOpacity(0.4)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.bolt_rounded, color: AppTheme.primaryPurple, size: 20),
                SizedBox(width: 8),
                Text('Quick Actions', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              ],
            ),
            const SizedBox(height: 16),
            Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _quickActionButton(
                        'View All Assessments',
                        Icons.assignment_outlined,
                        const Color(0xFFF3E8FF),
                        AppTheme.primaryPurple,
                        () => context.go('/guidance-counselor/monitoring'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _quickActionButton(
                        'Manage Students',
                        Icons.people_outline_rounded,
                        const Color(0xFFE0F2FE),
                        const Color(0xFF0284C7),
                        () => context.go('/guidance-counselor/student-records'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _quickActionButton(
                        'Pending Approvals',
                        Icons.assignment_turned_in_outlined,
                        const Color(0xFFDCFCE7),
                        const Color(0xFF16A34A),
                        () => context.go('/guidance-counselor/pending-approvals'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _quickActionButton(
                        'Student Feedback',
                        Icons.rate_review_outlined,
                        const Color(0xFFFFEDD5),
                        const Color(0xFFEA580C),
                        () => context.go('/guidance-counselor/ai-feedback'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _quickActionButton(String label, IconData icon, Color bgColor, Color iconColor, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: iconColor, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: iconColor),
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, size: 10, color: iconColor),
          ],
        ),
      ),
    );
  }

  // --- POPUP DIALOGS ---

  void _showRiasecDetailsDialog(List<Map<String, dynamic>> riasecStats, int total) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.pie_chart_rounded, color: AppTheme.primaryPurple),
            const SizedBox(width: 8),
            const Text('RIASEC Interest Details', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: SizedBox(
          width: 440,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Total Assessed Students: $total', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 12),
              ...['R', 'I', 'A', 'S', 'E', 'C'].map((t) {
                final item = riasecStats.firstWhere((s) => s['type'] == t, orElse: () => {'count': 0});
                final count = item['count'] as int;
                final color = AppTheme.riasecColor(t);

                return ListTile(
                  dense: true,
                  leading: CircleAvatar(
                    radius: 14,
                    backgroundColor: color.withOpacity(0.15),
                    child: Text(t, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                  title: Text(AppTheme.riasecName(t), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  trailing: Text('$count Student(s)', style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 12)),
                );
              }).toList(),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryPurple),
            onPressed: () {
              Navigator.pop(ctx);
              context.go('/guidance-counselor/student-records');
            },
            child: const Text('View All Student Records'),
          ),
        ],
      ),
    );
  }

  void _showStrandDetailsDialog(List<Map<String, dynamic>> strandStats) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.school_rounded, color: AppTheme.primaryPurple),
            const SizedBox(width: 8),
            const Text('Strand Distribution Details', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: SizedBox(
          width: 440,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: strandStats.map((item) {
              return ListTile(
                dense: true,
                leading: const Icon(Icons.bookmark_outline, color: AppTheme.primaryPurple),
                title: Text(item['strand'].toString(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                trailing: Text('${item['count']} Student(s)', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              );
            }).toList(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
        ],
      ),
    );
  }

  void _showRseDetailsDialog(List<Map<String, dynamic>> rseStats) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.favorite_rounded, color: Color(0xFFE53E3E)),
            SizedBox(width: 8),
            Text('Self-Esteem (RSE) Details', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: SizedBox(
          width: 440,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Students flagged with Low Self-Esteem may benefit from academic & personal self-worth counseling.',
                style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 12),
              ...rseStats.map((item) {
                final level = item['level'].toString();
                final count = item['count'] as int;
                final isLow = level.toLowerCase().contains('low');
                final color = isLow ? const Color(0xFFE53E3E) : AppTheme.success;

                return ListTile(
                  dense: true,
                  leading: Icon(isLow ? Icons.error_outline : Icons.check_circle_outline, color: color),
                  title: Text(level, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: color)),
                  trailing: Text('$count Student(s)', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                );
              }).toList(),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryPurple),
            onPressed: () {
              Navigator.pop(ctx);
              context.go('/guidance-counselor/student-records');
            },
            child: const Text('Review Student Records'),
          ),
        ],
      ),
    );
  }

  void _showCdsesDetailsDialog(List<Map<String, dynamic>> cdsesStats) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.stars_rounded, color: AppTheme.primaryPurple),
            const SizedBox(width: 8),
            const Text('Career Self-Efficacy Details', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: SizedBox(
          width: 440,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: cdsesStats.map((item) {
              return ListTile(
                dense: true,
                leading: const Icon(Icons.trending_up, color: AppTheme.primaryPurple),
                title: Text(item['level'].toString(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                trailing: Text('${item['count']} Student(s)', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              );
            }).toList(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
        ],
      ),
    );
  }

  void _showTopClustersDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.collections_bookmark_rounded, color: AppTheme.primaryPurple),
            const SizedBox(width: 8),
            const Text('Top Recommended Course Clusters', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: const SizedBox(
          width: 440,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: CircleAvatar(radius: 12, child: Text('1')),
                title: Text('Technology & Engineering Cluster', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                subtitle: Text('BS CS, BS IT, BS Mechanical Engg'),
              ),
              ListTile(
                leading: CircleAvatar(radius: 12, child: Text('2')),
                title: Text('Business & Accountancy Cluster', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                subtitle: Text('BS Accountancy, BSBA Marketing'),
              ),
              ListTile(
                leading: CircleAvatar(radius: 12, child: Text('3')),
                title: Text('Humanities & Social Sciences Cluster', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                subtitle: Text('BA Psychology, BS Criminology'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
        ],
      ),
    );
  }
}

// Custom Painter for Sparkline Wave Background
class WavePainter extends CustomPainter {
  final Color color;
  WavePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    final path = Path();
    path.moveTo(0, size.height * 0.7);
    path.quadraticBezierTo(size.width * 0.25, size.height * 0.2, size.width * 0.5, size.height * 0.6);
    path.quadraticBezierTo(size.width * 0.75, size.height * 0.9, size.width, size.height * 0.3);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}