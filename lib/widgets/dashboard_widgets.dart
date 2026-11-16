import 'dart:math' as math;
import 'dart:ui' show Tangent;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

/// Stat card with hover lift, "View all" hint and count-up number animation.
class HoverStatCard extends StatefulWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final Widget sparkline;

  const HoverStatCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.onTap,
    required this.sparkline,
  });

  @override
  State<HoverStatCard> createState() => _HoverStatCardState();
}

class _HoverStatCardState extends State<HoverStatCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = widget.color;
    final target = int.tryParse(widget.value);

    final textStyle = GoogleFonts.montserrat(
      fontSize: 26,
      fontWeight: FontWeight.w800,
      color: isDark ? Colors.white : AppTheme.textPrimary,
      letterSpacing: -0.5,
    );

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        transform: Matrix4.translationValues(0, _hovered ? -4 : 0, 0),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _hovered
                ? color.withOpacity(0.55)
                : (isDark ? Colors.white.withOpacity(0.08) : AppTheme.dividerColor.withOpacity(0.5)),
          ),
          boxShadow: [
            BoxShadow(
              color: _hovered ? color.withOpacity(0.22) : Colors.black.withOpacity(isDark ? 0.2 : 0.03),
              blurRadius: _hovered ? 18 : 10,
              offset: Offset(0, _hovered ? 8 : 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Stack(
                children: [
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Opacity(
                      opacity: _hovered ? 0.3 : 0.18,
                      child: SizedBox(width: 70, height: 36, child: widget.sparkline),
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
                            child: Icon(widget.icon, color: color, size: 22),
                          ),
                          AnimatedOpacity(
                            duration: const Duration(milliseconds: 180),
                            opacity: _hovered ? 1 : 0.35,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                AnimatedSize(
                                  duration: const Duration(milliseconds: 180),
                                  child: _hovered
                                      ? Padding(
                                          padding: const EdgeInsets.only(right: 4),
                                          child: Text(
                                            'View all',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w700,
                                              color: color,
                                            ),
                                          ),
                                        )
                                      : const SizedBox.shrink(),
                                ),
                                Icon(
                                  Icons.arrow_forward_rounded,
                                  color: _hovered ? color : AppTheme.textSecondary,
                                  size: 14,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      if (target != null)
                        TweenAnimationBuilder<double>(
                          key: ValueKey(widget.value),
                          tween: Tween(begin: 0, end: target.toDouble()),
                          duration: const Duration(milliseconds: 900),
                          curve: Curves.easeOutCubic,
                          builder: (_, v, __) => Text('${v.round()}', style: textStyle),
                        )
                      else
                        Text(widget.value, style: textStyle),
                      const SizedBox(height: 4),
                      Text(
                        widget.label,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
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
      ),
    );
  }
}

/// Animated shimmer skeleton block.
class ShimmerBox extends StatefulWidget {
  final double height;
  final double? width;
  final double radius;

  const ShimmerBox({super.key, required this.height, this.width, this.radius = 16});

  @override
  State<ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<ShimmerBox> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final base = isDark ? const Color(0xFF26263A) : const Color(0xFFEAE6F2);
    final hi = isDark ? const Color(0xFF34344D) : const Color(0xFFF7F4FC);
    return AnimatedBuilder(
      animation: _c,
      builder: (_, __) {
        final t = _c.value;
        return Container(
          height: widget.height,
          width: widget.width,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.radius),
            gradient: LinearGradient(
              begin: Alignment(-1.5 + 3 * t, 0),
              end: Alignment(-0.5 + 3 * t, 0),
              colors: [base, hi, base],
            ),
          ),
        );
      },
    );
  }
}

/// Skeleton shown while dashboard stats load.
class DashboardSkeleton extends StatelessWidget {
  const DashboardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final wide = constraints.maxWidth > 900;
      final cardsPerRow = wide ? 4 : 2;
      Widget row(List<Widget> kids) => Row(
            children: [
              for (int i = 0; i < kids.length; i++) ...[
                if (i > 0) const SizedBox(width: 16),
                Expanded(child: kids[i]),
              ],
            ],
          );
      Widget statRow() => row(List.generate(cardsPerRow, (_) => const ShimmerBox(height: 112)));
      return Column(
        children: [
          statRow(),
          if (!wide) ...[const SizedBox(height: 12), statRow()],
          const SizedBox(height: 24),
          wide
              ? row(const [ShimmerBox(height: 220), ShimmerBox(height: 220)])
              : const Column(children: [
                  ShimmerBox(height: 200),
                  SizedBox(height: 16),
                  ShimmerBox(height: 200),
                ]),
          const SizedBox(height: 24),
          const ShimmerBox(height: 110),
          const SizedBox(height: 24),
          const ShimmerBox(height: 220),
        ],
      );
    });
  }
}


// ─────────────────────────────────────────────────────────────────────────
// Phase 2: interactive donut, strand card, and combined demographics card
// ─────────────────────────────────────────────────────────────────────────

class DonutSegment {
  final String label;
  final int value;
  final Color color;
  const DonutSegment(this.label, this.value, this.color);
}

/// Animated donut with hover highlight and click callbacks.
class DonutChart extends StatelessWidget {
  final List<DonutSegment> segments;
  final double size;
  final double thickness;
  final int? highlight;
  final ValueChanged<int?> onHover;
  final ValueChanged<int>? onTapSegment;
  final String centerTitle;
  final String centerSubtitle;

  const DonutChart({
    super.key,
    required this.segments,
    required this.onHover,
    this.onTapSegment,
    this.highlight,
    this.size = 150,
    this.thickness = 22,
    this.centerTitle = '',
    this.centerSubtitle = '',
  });

  int get _total => segments.fold(0, (s, e) => s + e.value);

  int? _hit(Offset p) {
    final total = _total;
    if (total == 0) return null;
    final c = Offset(size / 2, size / 2);
    final d = p - c;
    final dist = d.distance;
    final outer = size / 2 + 4;
    final inner = size / 2 - thickness - 8;
    if (dist > outer || dist < inner) return null;
    var ang = math.atan2(d.dy, d.dx) + math.pi / 2;
    if (ang < 0) ang += 2 * math.pi;
    double acc = 0;
    for (int i = 0; i < segments.length; i++) {
      acc += segments[i].value / total * 2 * math.pi;
      if (ang <= acc) return i;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hi = highlight != null && highlight! < segments.length ? segments[highlight!] : null;
    final title = hi != null ? '${hi.value}' : centerTitle;
    final subtitle = hi != null ? hi.label : centerSubtitle;

    return MouseRegion(
      cursor: highlight != null && onTapSegment != null
          ? SystemMouseCursors.click
          : SystemMouseCursors.basic,
      onHover: (e) => onHover(_hit(e.localPosition)),
      onExit: (_) => onHover(null),
      child: GestureDetector(
        onTapUp: (d) {
          final i = _hit(d.localPosition);
          if (i != null) onTapSegment?.call(i);
        },
        child: SizedBox(
          width: size,
          height: size,
          child: TweenAnimationBuilder<double>(
            key: ValueKey(segments.map((s) => '${s.label}${s.value}').join('|')),
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeOutCubic,
            builder: (_, t, __) => CustomPaint(
              painter: _DonutPainter(
                segments: segments,
                progress: t,
                thickness: thickness,
                highlight: highlight,
                track: isDark ? Colors.white10 : const Color(0xFFEFEAF7),
              ),
              child: Center(
                child: Padding(
                  padding: EdgeInsets.all(thickness + 10),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.montserrat(
                          fontSize: size * 0.17,
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white : AppTheme.textPrimary,
                        ),
                      ),
                      if (subtitle.isNotEmpty)
                        Text(
                          subtitle,
                          maxLines: 2,
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 10, color: AppTheme.textSecondary),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  final List<DonutSegment> segments;
  final double progress;
  final double thickness;
  final int? highlight;
  final Color track;

  _DonutPainter({
    required this.segments,
    required this.progress,
    required this.thickness,
    required this.highlight,
    required this.track,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width / 2 - thickness / 2 - 4;
    final rect = Rect.fromCircle(center: center, radius: radius);
    final total = segments.fold(0, (s, e) => s + e.value);

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = thickness
        ..color = track,
    );
    if (total == 0) return;

    final gap = segments.length > 1 ? 0.05 : 0.0;
    double start = -math.pi / 2;
    for (int i = 0; i < segments.length; i++) {
      final full = segments[i].value / total * 2 * math.pi;
      final sweep = math.max(0.0, full * progress - gap);
      final isHi = highlight == i;
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.butt
        ..strokeWidth = isHi ? thickness + 8 : thickness
        ..color = highlight != null && !isHi
            ? segments[i].color.withOpacity(0.45)
            : segments[i].color;
      canvas.drawArc(rect, start + gap / 2, sweep, false, paint);
      start += full * progress;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter old) =>
      old.progress != progress || old.highlight != highlight || old.segments != segments;
}

/// Strand distribution card: bars/donut toggle, hover tooltips, click-to-filter.
class InteractiveStrandCard extends StatefulWidget {
  /// Each map has 'strand' (canonical name) and 'count' (int), sorted desc.
  final List<Map<String, dynamic>> stats;
  final ValueChanged<String> onStrandTap;
  final VoidCallback onViewAll;

  const InteractiveStrandCard({
    super.key,
    required this.stats,
    required this.onStrandTap,
    required this.onViewAll,
  });

  @override
  State<InteractiveStrandCard> createState() => _InteractiveStrandCardState();
}

class _InteractiveStrandCardState extends State<InteractiveStrandCard> {
  bool _donut = false;
  int? _hover;

  Widget _toggleBtn(IconData icon, String tip, bool active, VoidCallback onTap) {
    return Tooltip(
      message: tip,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: active ? AppTheme.primaryPurple : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: active ? Colors.white : AppTheme.textSecondary),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final stats = widget.stats;
    final total = stats.fold<int>(0, (s, e) => s + (e['count'] as int));

    String tip(String strand, int count, double pct) =>
        '$strand\n$count student(s) · ${(pct * 100).toStringAsFixed(1)}%\nClick to view these students';

    Widget barRows() => Column(
          children: [
            for (int i = 0; i < stats.length; i++)
              Builder(builder: (_) {
                final strand = stats[i]['strand'].toString();
                final count = stats[i]['count'] as int;
                final pct = total > 0 ? count / total : 0.0;
                final color = AppTheme.strandColor(strand);
                final hovered = _hover == i;
                return Tooltip(
                  message: tip(strand, count, pct),
                  waitDuration: const Duration(milliseconds: 250),
                  child: MouseRegion(
                    cursor: SystemMouseCursors.click,
                    onEnter: (_) => setState(() => _hover = i),
                    onExit: (_) => setState(() => _hover = null),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: () => widget.onStrandTap(strand),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        margin: const EdgeInsets.only(bottom: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                        decoration: BoxDecoration(
                          color: hovered ? color.withOpacity(isDark ? 0.14 : 0.08) : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: TweenAnimationBuilder<double>(
                          key: ValueKey('strand_${strand}_${count}_$total'),
                          tween: Tween(begin: 0.0, end: pct),
                          duration: Duration(milliseconds: 600 + (i * 80)),
                          curve: Curves.easeOutCubic,
                          builder: (_, v, __) {
                            final currentPct = total > 0 ? (v * 100) : 0.0;
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        strand,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      '$count student(s) (${currentPct.toStringAsFixed(1)}%)',
                                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(6),
                                  child: LinearProgressIndicator(
                                    value: v,
                                    backgroundColor: isDark ? Colors.white10 : color.withOpacity(0.12),
                                    valueColor: AlwaysStoppedAnimation<Color>(color),
                                    minHeight: hovered ? 11 : 8,
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                );
              }),
          ],
        );

    Widget donutView() {
      final segs = [
        for (final s in stats)
          DonutSegment(
            s['strand'].toString().split(' ').first,
            s['count'] as int,
            AppTheme.strandColor(s['strand'].toString()),
          ),
      ];
      return Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          DonutChart(
            segments: segs,
            size: 140,
            thickness: 18,
            highlight: _hover,
            onHover: (i) {
              if (i != _hover) setState(() => _hover = i);
            },
            onTapSegment: (i) => widget.onStrandTap(stats[i]['strand'].toString()),
            centerTitle: '$total',
            centerSubtitle: 'students',
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              children: [
                for (int i = 0; i < stats.length; i++)
                  MouseRegion(
                    cursor: SystemMouseCursors.click,
                    onEnter: (_) => setState(() => _hover = i),
                    onExit: (_) => setState(() => _hover = null),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () => widget.onStrandTap(stats[i]['strand'].toString()),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                        decoration: BoxDecoration(
                          color: _hover == i ? segs[i].color.withOpacity(0.12) : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(color: segs[i].color, shape: BoxShape.circle),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                segs[i].label,
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                              ),
                            ),
                            Text(
                              '${segs[i].value} · ${total > 0 ? (segs[i].value / total * 100).toStringAsFixed(1) : '0'}%',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: segs[i].color,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      );
    }

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
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.school_rounded, color: AppTheme.primaryPurple, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Senior High Academic Strands',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryPurple.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _toggleBtn(Icons.bar_chart_rounded, 'Bar view', !_donut, () => setState(() {
                                _donut = false;
                                _hover = null;
                              })),
                          _toggleBtn(Icons.donut_large_rounded, 'Donut view', _donut, () => setState(() {
                                _donut = true;
                                _hover = null;
                              })),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    InkWell(
                      onTap: widget.onViewAll,
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'View Directory',
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
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Hover for details, click a strand to see its students.',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
            ),
            const SizedBox(height: 14),
            if (stats.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Text('No student records found.',
                      style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                ),
              )
            else
              AnimatedCrossFade(
                firstChild: barRows(),
                secondChild: donutView(),
                crossFadeState: _donut ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                duration: const Duration(milliseconds: 250),
                sizeCurve: Curves.easeOutCubic,
              ),
          ],
        ),
      ),
    );
  }
}

/// Combined demographics card: gender donut + compact grade chips.
class InteractiveCohortCard extends StatefulWidget {
  final List<Map<String, dynamic>> gradeStats; // gradeLevel, count
  final List<Map<String, dynamic>> genderStats; // gender, count
  final VoidCallback onViewAll;

  const InteractiveCohortCard({
    super.key,
    required this.gradeStats,
    required this.genderStats,
    required this.onViewAll,
  });

  @override
  State<InteractiveCohortCard> createState() => _InteractiveCohortCardState();
}

class _InteractiveCohortCardState extends State<InteractiveCohortCard> {
  int? _hover;

  Color _genderColor(String g) {
    final l = g.toLowerCase();
    if (l == 'male') return const Color(0xFF0284C7);
    if (l == 'female') return const Color(0xFFE91E63);
    return const Color(0xFF8B5CF6);
  }

  IconData _genderIcon(String g) {
    final l = g.toLowerCase();
    if (l == 'male') return Icons.male_rounded;
    if (l == 'female') return Icons.female_rounded;
    return Icons.person_outline_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final genders = widget.genderStats;
    final grades = widget.gradeStats;
    final totalGender = genders.fold<int>(0, (s, e) => s + (e['count'] as int));
    final totalGrade = grades.fold<int>(0, (s, e) => s + (e['count'] as int));
    final segs = [
      for (final g in genders)
        DonutSegment(g['gender'].toString(), g['count'] as int, _genderColor(g['gender'].toString())),
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
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 6,
              children: [
                const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.groups_rounded, color: Color(0xFF2196F3), size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Student Demographics & Cohort Profile',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                  ],
                ),
                InkWell(
                  onTap: widget.onViewAll,
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Cumulative Records',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2196F3),
                        ),
                      ),
                      SizedBox(width: 2),
                      Icon(Icons.arrow_forward_rounded, size: 14, color: Color(0xFF2196F3)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Gender split and grade level across registered students.',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
            ),
            const SizedBox(height: 16),
            if (genders.isEmpty && grades.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Text('No demographic data yet.',
                      style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                ),
              )
            else ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  DonutChart(
                    segments: segs,
                    size: 130,
                    thickness: 18,
                    highlight: _hover,
                    onHover: (i) {
                      if (i != _hover) setState(() => _hover = i);
                    },
                    centerTitle: '$totalGender',
                    centerSubtitle: 'students',
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      children: [
                        for (int i = 0; i < segs.length; i++)
                          MouseRegion(
                            onEnter: (_) => setState(() => _hover = i),
                            onExit: (_) => setState(() => _hover = null),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              decoration: BoxDecoration(
                                color: segs[i].color.withOpacity(_hover == i ? 0.16 : 0.06),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: segs[i].color.withOpacity(_hover == i ? 0.55 : 0.2),
                                ),
                              ),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 13,
                                    backgroundColor: segs[i].color.withOpacity(0.15),
                                    child: Icon(_genderIcon(segs[i].label), color: segs[i].color, size: 15),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      segs[i].label,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                        color: segs[i].color,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    '${segs[i].value} (${totalGender > 0 ? (segs[i].value / totalGender * 100).toStringAsFixed(1) : '0'}%)',
                                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 11),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                'GRADE LEVEL',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8,
                  color: const Color(0xFF2196F3),
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final g in grades)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white.withOpacity(0.04) : const Color(0xFFF0F7FF),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFF2196F3).withOpacity(0.25)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(g['gradeLevel'].toString(),
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                          const SizedBox(width: 8),
                          Text(
                            '${g['count']} · ${totalGrade > 0 ? ((g['count'] as int) / totalGrade * 100).toStringAsFixed(0) : '0'}%',
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                              color: Color(0xFF2196F3),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}


// ─────────────────────────────────────────────────────────────────────────
// Phase 3: Assessment & counseling activity trend chart
// ─────────────────────────────────────────────────────────────────────────

class ActivityTrendCard extends StatefulWidget {
  /// Each map: label, rangeText, submitted (int), released (int).
  final List<Map<String, dynamic>> trend;
  final String mode; // 'daily' | 'weekly'
  final VoidCallback? onViewAll;

  const ActivityTrendCard({
    super.key,
    required this.trend,
    required this.mode,
    this.onViewAll,
  });

  @override
  State<ActivityTrendCard> createState() => _ActivityTrendCardState();
}

class _ActivityTrendCardState extends State<ActivityTrendCard> {
  int? _hover;

  static const _submittedColor = AppTheme.primaryPurple;
  static const _releasedColor = Color(0xFF3FA37A); // muted emerald

  int _val(Map<String, dynamic> m, String k) => (m[k] is num) ? (m[k] as num).toInt() : 0;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final trend = widget.trend;
    final totalSub = trend.fold<int>(0, (s, e) => s + _val(e, 'submitted'));
    final totalRel = trend.fold<int>(0, (s, e) => s + _val(e, 'released'));
    final periodText = widget.mode == 'weekly'
        ? 'Weekly totals · last 12 weeks'
        : 'Daily totals · last ${trend.length} days';

    Widget legend(Color c, String label, int total) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(3)),
            ),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
            const SizedBox(width: 6),
            Text('$total', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
          ],
        );

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
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              runSpacing: 8,
              spacing: 16,
              children: [
                const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.show_chart_rounded, color: AppTheme.primaryPurple, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Assessment & Counseling Activity',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    legend(_submittedColor, 'Submitted', totalSub),
                    const SizedBox(width: 16),
                    legend(_releasedColor, 'Released', totalRel),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              '$periodText. Hover the chart for exact numbers.',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 220,
              child: trend.isEmpty
                  ? Center(
                      child: Text('No activity data yet.',
                          style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                    )
                  : LayoutBuilder(builder: (context, c) {
                      final w = c.maxWidth;
                      const left = 30.0, right = 10.0;
                      int? indexFor(double dx) {
                        if (trend.length == 1) return 0;
                        final step = (w - left - right) / (trend.length - 1);
                        final i = ((dx - left) / step).round();
                        return i.clamp(0, trend.length - 1);
                      }

                      final hovered = _hover;
                      Widget? tooltip;
                      if (hovered != null) {
                        final step = trend.length == 1 ? 0.0 : (w - left - right) / (trend.length - 1);
                        final x = left + hovered * step;
                        final flip = x > w - 170;
                        final m = trend[hovered];
                        tooltip = Positioned(
                          left: flip ? null : x + 12,
                          right: flip ? (w - x) + 12 : null,
                          top: 4,
                          child: IgnorePointer(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF2A2A3E) : Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: AppTheme.dividerColor.withOpacity(0.6)),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.12),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(m['rangeText'].toString(),
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                  const SizedBox(height: 6),
                                  Row(mainAxisSize: MainAxisSize.min, children: [
                                    Container(
                                        width: 8,
                                        height: 8,
                                        decoration: const BoxDecoration(
                                            color: _submittedColor, shape: BoxShape.circle)),
                                    const SizedBox(width: 6),
                                    Text('${_val(m, 'submitted')} submitted',
                                        style: const TextStyle(fontSize: 12)),
                                  ]),
                                  const SizedBox(height: 3),
                                  Row(mainAxisSize: MainAxisSize.min, children: [
                                    Container(
                                        width: 8,
                                        height: 8,
                                        decoration: const BoxDecoration(
                                            color: _releasedColor, shape: BoxShape.circle)),
                                    const SizedBox(width: 6),
                                    Text('${_val(m, 'released')} released',
                                        style: const TextStyle(fontSize: 12)),
                                  ]),
                                ],
                              ),
                            ),
                          ),
                        );
                      }

                      return MouseRegion(
                        onHover: (e) {
                          final i = indexFor(e.localPosition.dx);
                          if (i != _hover) setState(() => _hover = i);
                        },
                        onExit: (_) => setState(() => _hover = null),
                        child: GestureDetector(
                          onTapDown: (d) => setState(() => _hover = indexFor(d.localPosition.dx)),
                          onHorizontalDragUpdate: (d) =>
                              setState(() => _hover = indexFor(d.localPosition.dx)),
                          child: Stack(
                            children: [
                              Positioned.fill(
                                child: TweenAnimationBuilder<double>(
                                  key: ValueKey('${widget.mode}_${trend.map((e) => '${e['label']}${e['submitted']}${e['released']}').join('|')}'),
                                  tween: Tween(begin: 0.0, end: 1.0),
                                  duration: const Duration(milliseconds: 900),
                                  curve: Curves.easeOutCubic,
                                  builder: (_, t, __) => CustomPaint(
                                    painter: _TrendPainter(
                                      submitted: [for (final e in trend) _val(e, 'submitted')],
                                      released: [for (final e in trend) _val(e, 'released')],
                                      labels: [for (final e in trend) e['label'].toString()],
                                      progress: t,
                                      hover: hovered,
                                      isDark: isDark,
                                      submittedColor: _submittedColor,
                                      releasedColor: _releasedColor,
                                      textColor: AppTheme.textSecondary,
                                    ),
                                  ),
                                ),
                              ),
                              if (tooltip != null) tooltip,
                            ],
                          ),
                        ),
                      );
                    }),
            ),
            if (totalSub == 0 && totalRel == 0 && trend.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'No assessments were submitted or released in this period.',
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _TrendPainter extends CustomPainter {
  final List<int> submitted;
  final List<int> released;
  final List<String> labels;
  final double progress;
  final int? hover;
  final bool isDark;
  final Color submittedColor;
  final Color releasedColor;
  final Color textColor;

  _TrendPainter({
    required this.submitted,
    required this.released,
    required this.labels,
    required this.progress,
    required this.hover,
    required this.isDark,
    required this.submittedColor,
    required this.releasedColor,
    required this.textColor,
  });

  static const double left = 30, right = 10, top = 10, bottom = 24;

  @override
  void paint(Canvas canvas, Size size) {
    final n = submitted.length;
    final plotW = size.width - left - right;
    final plotH = size.height - top - bottom;

    final maxData = [...submitted, ...released].fold<int>(0, math.max);
    final maxY = math.max(4, ((maxData + 3) ~/ 4) * 4);

    double xAt(int i) => n == 1 ? left + plotW / 2 : left + i * plotW / (n - 1);
    double yAt(num v) => top + plotH - (v / maxY) * plotH;

    // Grid + y labels
    final gridPaint = Paint()
      ..color = (isDark ? Colors.white : Colors.black).withOpacity(0.07)
      ..strokeWidth = 1;
    for (int g = 0; g <= 4; g++) {
      final y = top + plotH - g * plotH / 4;
      canvas.drawLine(Offset(left, y), Offset(size.width - right, y), gridPaint);
      _text(canvas, '${(maxY * g / 4).round()}', Offset(left - 6, y), align: _A.right, size: 10);
    }

    // X labels (thinned)
    final every = n <= 8 ? 1 : (n / 6).ceil();
    for (int i = 0; i < n; i += every) {
      _text(canvas, labels[i], Offset(xAt(i), size.height - 6), align: _A.center, size: 10, bottomAnchor: true);
    }

    // Hover guide
    if (hover != null) {
      final x = xAt(hover!);
      canvas.drawLine(
        Offset(x, top),
        Offset(x, top + plotH),
        Paint()
          ..color = textColor.withOpacity(0.35)
          ..strokeWidth = 1,
      );
    }

    void series(List<int> data, Color color, {bool fill = false}) {
      final pts = [for (int i = 0; i < n; i++) Offset(xAt(i), yAt(data[i]))];
      final path = Path()..moveTo(pts.first.dx, pts.first.dy);
      for (int i = 1; i < pts.length; i++) {
        final mx = (pts[i - 1].dx + pts[i].dx) / 2;
        path.cubicTo(mx, pts[i - 1].dy, mx, pts[i].dy, pts[i].dx, pts[i].dy);
      }
      // Reveal left-to-right
      final metrics = path.computeMetrics().toList();
      final drawn = Path();
      Tangent? lastTangent;
      for (final m in metrics) {
        final d = m.length * progress;
        drawn.addPath(m.extractPath(0, d), Offset.zero);
        if (d > 0) {
          lastTangent = m.getTangentForOffset(d);
        }
      }
      final tipX = lastTangent?.position.dx ?? (left + plotW * progress);

      if (fill && n > 1) {
        final area = Path.from(drawn);
        area.lineTo(tipX, top + plotH);
        area.lineTo(pts.first.dx, top + plotH);
        area.close();
        canvas.drawPath(
          area,
          Paint()
            ..shader = LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [color.withOpacity(0.18), color.withOpacity(0.0)],
            ).createShader(Rect.fromLTWH(left, top, plotW, plotH)),
        );
      }
      canvas.drawPath(
        drawn,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.4
          ..strokeCap = StrokeCap.round
          ..color = color,
      );

      // Glowing lead tracer cursor while animating
      if (progress > 0.02 && progress < 0.98 && lastTangent != null) {
        canvas.drawCircle(lastTangent.position, 6.5, Paint()..color = color.withOpacity(0.28));
        canvas.drawCircle(lastTangent.position, 3.8, Paint()..color = color);
        canvas.drawCircle(lastTangent.position, 1.8, Paint()..color = Colors.white);
      }

      if (n == 1 || n <= 14) {
        for (final p in pts) {
          if (p.dx <= tipX + 1.0) {
            canvas.drawCircle(p, 2.8, Paint()..color = color);
          }
        }
      }
      if (hover != null) {
        final p = pts[hover!];
        canvas.drawCircle(p, 6, Paint()..color = color.withOpacity(0.2));
        canvas.drawCircle(p, 4, Paint()..color = color);
        canvas.drawCircle(p, 4, Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.6
          ..color = isDark ? const Color(0xFF1E1E2E) : Colors.white);
      }
    }

    series(released, releasedColor);
    series(submitted, submittedColor, fill: true);
  }

  void _text(Canvas canvas, String s, Offset at,
      {_A align = _A.left, double size = 10, bool bottomAnchor = false}) {
    final tp = TextPainter(
      text: TextSpan(text: s, style: TextStyle(fontSize: size, color: textColor)),
      textDirection: TextDirection.ltr,
    )..layout();
    double dx = at.dx;
    if (align == _A.right) dx -= tp.width;
    if (align == _A.center) dx -= tp.width / 2;
    final dy = bottomAnchor ? at.dy - tp.height + 2 : at.dy - tp.height / 2;
    tp.paint(canvas, Offset(dx, dy));
  }

  @override
  bool shouldRepaint(covariant _TrendPainter old) =>
      old.progress != progress ||
      old.hover != hover ||
      old.isDark != isDark ||
      old.submitted != submitted ||
      old.released != released;
}

enum _A { left, center, right }


// ─────────────────────────────────────────────────────────────────────────
// Psychometrician: Interactive RIASEC Dominant Interest Card
// ─────────────────────────────────────────────────────────────────────────

class InteractiveRiasecCard extends StatefulWidget {
  final List<Map<String, dynamic>> riasecStats;
  final VoidCallback onViewDetails;
  final ValueChanged<String>? onTypeTap;

  const InteractiveRiasecCard({
    super.key,
    required this.riasecStats,
    required this.onViewDetails,
    this.onTypeTap,
  });

  @override
  State<InteractiveRiasecCard> createState() => _InteractiveRiasecCardState();
}

class _InteractiveRiasecCardState extends State<InteractiveRiasecCard> {
  bool _donut = false;
  int? _hover;

  static const _types = ['R', 'I', 'A', 'S', 'E', 'C'];

  Widget _toggleBtn(IconData icon, String tip, bool active, VoidCallback onTap) {
    return Tooltip(
      message: tip,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: active ? AppTheme.primaryPurple : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: active ? Colors.white : AppTheme.textSecondary),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final map = {for (var s in widget.riasecStats) s['type'].toString(): (s['count'] is num) ? (s['count'] as num).toInt() : 0};
    final total = map.values.fold<int>(0, (sum, val) => sum + val);

    Widget barRows() => Column(
          children: [
            for (int i = 0; i < _types.length; i++)
              Builder(builder: (_) {
                final t = _types[i];
                final count = map[t] ?? 0;
                final pct = total > 0 ? (count / total) : 0.0;
                final color = AppTheme.riasecColor(t);
                final hovered = _hover == i;

                return Tooltip(
                  message: '${AppTheme.riasecName(t)}: $count student(s) (${(pct * 100).toStringAsFixed(1)}%)\nClick to view records',
                  waitDuration: const Duration(milliseconds: 250),
                  child: MouseRegion(
                    cursor: SystemMouseCursors.click,
                    onEnter: (_) => setState(() => _hover = i),
                    onExit: (_) => setState(() => _hover = null),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: () => widget.onTypeTap?.call(t),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        margin: const EdgeInsets.only(bottom: 5),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                        decoration: BoxDecoration(
                          color: hovered ? color.withOpacity(isDark ? 0.14 : 0.08) : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 12,
                              backgroundColor: color.withOpacity(0.18),
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
                              child: TweenAnimationBuilder<double>(
                                key: ValueKey('riasec_${t}_${count}_$total'),
                                tween: Tween(begin: 0.0, end: pct),
                                duration: Duration(milliseconds: 600 + (i * 80)),
                                curve: Curves.easeOutCubic,
                                builder: (_, v, __) {
                                  final currentPct = total > 0 ? (v * 100) : 0.0;
                                  return Row(
                                    children: [
                                      Expanded(
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(6),
                                          child: LinearProgressIndicator(
                                            value: v,
                                            backgroundColor: isDark ? Colors.white10 : AppTheme.dividerColor.withOpacity(0.3),
                                            valueColor: AlwaysStoppedAnimation<Color>(color),
                                            minHeight: hovered ? 11 : 8,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      SizedBox(
                                        width: 50,
                                        child: Text(
                                          '${currentPct.toStringAsFixed(1)}%',
                                          textAlign: TextAlign.right,
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: color,
                                          ),
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            SizedBox(
                              width: 60,
                              child: Text(
                                '$count student(s)',
                                textAlign: TextAlign.right,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }),
          ],
        );

    Widget donutView() {
      final activeTypes = _types.where((t) => (map[t] ?? 0) > 0).toList();
      final segs = [
        for (final t in activeTypes)
          DonutSegment(
            AppTheme.riasecName(t),
            map[t] ?? 0,
            AppTheme.riasecColor(t),
          ),
      ];

      return Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          DonutChart(
            segments: segs,
            size: 140,
            thickness: 18,
            highlight: _hover,
            onHover: (i) {
              if (i != _hover) setState(() => _hover = i);
            },
            onTapSegment: (i) {
              if (i < activeTypes.length) widget.onTypeTap?.call(activeTypes[i]);
            },
            centerTitle: '$total',
            centerSubtitle: 'assessed',
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              children: [
                for (int i = 0; i < activeTypes.length; i++)
                  MouseRegion(
                    cursor: SystemMouseCursors.click,
                    onEnter: (_) => setState(() => _hover = i),
                    onExit: (_) => setState(() => _hover = null),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () => widget.onTypeTap?.call(activeTypes[i]),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                        decoration: BoxDecoration(
                          color: _hover == i ? segs[i].color.withOpacity(0.12) : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(color: segs[i].color, shape: BoxShape.circle),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                segs[i].label,
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                              ),
                            ),
                            Text(
                              '${segs[i].value} · ${total > 0 ? (segs[i].value / total * 100).toStringAsFixed(1) : '0'}%',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: segs[i].color,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      );
    }

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
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.pie_chart_rounded, color: AppTheme.primaryPurple, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Dominant Career Interests (Primary Types)',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryPurple.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _toggleBtn(Icons.bar_chart_rounded, 'Bar view', !_donut, () => setState(() {
                                _donut = false;
                                _hover = null;
                              })),
                          _toggleBtn(Icons.donut_large_rounded, 'Donut view', _donut, () => setState(() {
                                _donut = true;
                                _hover = null;
                              })),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    InkWell(
                      onTap: widget.onViewDetails,
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
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
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Holland code distribution based on verified student assessments.',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
            ),
            const SizedBox(height: 14),
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
              AnimatedCrossFade(
                firstChild: barRows(),
                secondChild: donutView(),
                crossFadeState: _donut ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                duration: const Duration(milliseconds: 250),
                sizeCurve: Curves.easeOutCubic,
              ),
          ],
        ),
      ),
    );
  }
}
