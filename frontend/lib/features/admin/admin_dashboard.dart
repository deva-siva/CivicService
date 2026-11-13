import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/theme/app_theme.dart';
import '../../models/complaint_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/complaint_provider.dart';
import 'complaint_detail_admin.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});
  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final cp = context.read<ComplaintProvider>();
    await Future.wait([cp.loadAdminComplaints(), cp.loadAnalytics()]);
    if (mounted) setState(() => _loading = false);
  }

  BoxDecoration _glassDecoration({required Color accentColor, double borderRadius = 28}) {
    return BoxDecoration(
      color: Colors.white.withOpacity(0.9),
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(
        color: Colors.white.withOpacity(0.5),
        width: 1.5,
      ),
      boxShadow: [
        BoxShadow(
          color: accentColor.withOpacity(0.05),
          blurRadius: 30,
          offset: const Offset(0, 10),
        ),
        BoxShadow(
          color: Colors.black.withOpacity(0.02),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final cp = context.watch<ComplaintProvider>();

    if (_loading) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    return Builder(
      builder: (context) => RefreshIndicator(
        onRefresh: _load,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // ─── Compact Skeuomorphic AppBar ───────────────────────────
            SliverAppBar(
              expandedHeight: 120,
              floating: true,
              pinned: true,
              automaticallyImplyLeading: false,
              backgroundColor: Colors.white.withOpacity(0.9),
              surfaceTintColor: Colors.transparent,
              flexibleSpace: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.7),
                  border: Border(
                    bottom: BorderSide(
                      color: Colors.black.withOpacity(0.05),
                      width: 1,
                    ),
                  ),
                ),
                child: Stack(
                  children: [
                    // Abstract Background Deco
                    Positioned(
                      top: -30,
                      left: -20,
                      child: CircleAvatar(
                        radius: 80,
                        backgroundColor: AppColors.primary.withOpacity(0.03),
                      ),
                    ),
                    SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Profile Section - Clickable to open drawer/profile
                            InkWell(
                              onTap: () => Scaffold.of(context).openDrawer(),
                              borderRadius: BorderRadius.circular(30),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(2),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: LinearGradient(
                                        colors: [Colors.white, Colors.white.withOpacity(0.1)],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                    ),
                                    child: CircleAvatar(
                                      radius: 24,
                                      backgroundColor: AppColors.primary.withOpacity(0.1),
                                      child: Text(
                                        user?.displayName.isNotEmpty == true ? user!.displayName[0].toUpperCase() : 'A',
                                        style: TextStyle(
                                          color: AppColors.primary,
                                          fontWeight: FontWeight.w900,
                                          fontSize: 20,
                                          fontFamily: GoogleFonts.outfit().fontFamily,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 15),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        '${_greeting()},',
                                        style: GoogleFonts.outfit(
                                          color: AppColors.textSecondary.withOpacity(0.6),
                                          fontSize: 11,
                                          fontWeight: FontWeight.w500,
                                          height: 1.1,
                                        ),
                                      ),
                                      Text(
                                        user?.displayName.split(' ').first ?? 'Admin',
                                        style: GoogleFonts.outfit(
                                          color: AppColors.textPrimary,
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: -0.5,
                                          height: 1.2,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const Spacer(),
                            // Action Buttons
                            Container(
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: IconButton(
                                icon: const Icon(Icons.notifications_none_rounded, color: AppColors.primary, size: 24),
                                onPressed: () {},
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

            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // ─── Stats row ─────────────────────────────────────
                  _statsRow(cp),
                  const SizedBox(height: 16),

                  // ─── Escalation banner ──────────────────────────────
                  if ((cp.analytics['escalated'] ?? 0) > 0) ...[
                    _escalationBanner(cp.analytics['escalated']),
                    const SizedBox(height: 16),
                  ],

                  // ─── Heatmap (real complaint coords) ───────────────
                  _heatmapCard(cp),
                  const SizedBox(height: 16),

                  // ─── Category overview ──────────────────────────────
                  _overviewCard(cp),
                  const SizedBox(height: 16),

                  // ─── Weekly trend ───────────────────────────────────
                  _weeklyTrendCard(cp),
                  const SizedBox(height: 16),

                  // ─── Recent complaints ──────────────────────────────
                  _recentComplaintsCard(cp),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Morning';
    if (h < 17) return 'Afternoon';
    return 'Evening';
  }

  // ─── Stats Row ─────────────────────────────────────────────────────────────

  Widget _statsRow(ComplaintProvider cp) {
    final a = cp.analytics;
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Row(
        children: [
          _statCard('Total', a['total'] ?? 0, Icons.assignment_rounded, const Color(0xFF1565C0)),
          _statCard('Open', a['submitted'] ?? 0, Icons.folder_open_rounded, const Color(0xFF7C4DFF)),
          _statCard('In Progress', a['in_progress'] ?? 0, Icons.hourglass_top_rounded, const Color(0xFFE65100)),
          _statCard('High Priority', a['high_priority'] ?? 0, Icons.priority_high_rounded, const Color(0xFFC62828)),
          _statCard('Resolved', a['resolved'] ?? 0, Icons.check_circle_rounded, const Color(0xFF2E7D32)),
          _statCard('Escalated', a['escalated'] ?? 0, Icons.warning_rounded, const Color(0xFFE53935)),
        ],
      ),
    );
  }

  Widget _statCard(String label, int value, IconData icon, Color color) {
    return Container(
      width: 140,
      margin: const EdgeInsets.only(right: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.08),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
        border: Border.all(color: color.withOpacity(0.05), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.08),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 20),
          Text(
            '$value',
            style: GoogleFonts.outfit(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
              letterSpacing: -1,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Escalation Banner ─────────────────────────────────────────────────────

  Widget _escalationBanner(int count) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.error.withOpacity(0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.error.withOpacity(0.22)),
        ),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.12),
                shape: BoxShape.circle),
            child:
                const Icon(Icons.warning_rounded, color: AppColors.error, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(
                  '$count Escalated Complaint${count > 1 ? 's' : ''}',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.error,
                      fontSize: 13)),
              const Text('Require immediate attention',
                  style: TextStyle(fontSize: 11, color: AppColors.error)),
            ]),
          ),
          const Icon(Icons.arrow_forward_ios,
              size: 13, color: AppColors.error),
        ]),
      );

  // ─── Heatmap — real complaint coordinates via Google Static Maps ────────────

  Widget _heatmapCard(ComplaintProvider cp) {
    // Filter complaints that have real GPS coordinates
    final geoComplaints = cp.adminComplaints
        .where((c) => c.latitude != null && c.longitude != null)
        .toList();

    return Container(
      decoration: _glassDecoration(accentColor: AppColors.primary, borderRadius: 24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
          child: Row(children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.map_rounded,
                  color: AppColors.primary, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Complaint Heatmap',
                        style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.bold)),
                    Text(
                      geoComplaints.isEmpty
                          ? 'No location data yet'
                          : '${geoComplaints.length} complaint${geoComplaints.length == 1 ? '' : 's'} with GPS',
                      style: const TextStyle(
                          fontSize: 10, color: AppColors.textHint),
                    ),
                  ]),
            ),
                    // Legend
                    Row(children: [
                      _legendDot(AppColors.error, 'High'),
                      const SizedBox(width: 8),
                      _legendDot(AppColors.warning, 'Med'),
                      const SizedBox(width: 8),
                      _legendDot(AppColors.success, 'Low'),
                    ]),
                  ]),
                ),

                // Map - Proper alignment and margins
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.primary.withOpacity(0.05)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          )
                        ],
                      ),
                      child: geoComplaints.isEmpty ? _noLocationPlaceholder() : _mapplsMapView(geoComplaints),
                    ),
                  ),
                ),
              ]),
            );
  }

  Widget _mapplsMapView(List<ComplaintModel> complaints) {
    // Compute center from complaint coords
    final lats = complaints.map((c) => c.latitude!).toList();
    final lngs = complaints.map((c) => c.longitude!).toList();
    final centerLat = lats.reduce((a, b) => a + b) / lats.length;
    final centerLng = lngs.reduce((a, b) => a + b) / lngs.length;

    // Build markers string — max 20 to keep URL short
    final limited = complaints.take(20).toList();
    final markerStr = limited
        .map((c) => 'color:red|${c.latitude},${c.longitude}')
        .join('&markers=');

    const apiKey = 'AIzaSyC5_umn1UwO4eyITUiltvqjBqS21Cp9MxM';
    final mapUrl =
        'https://maps.googleapis.com/maps/api/staticmap'
        '?center=${centerLat.toStringAsFixed(6)},${centerLng.toStringAsFixed(6)}'
        '&zoom=12&size=600x220&markers=$markerStr&key=$apiKey';

    return Stack(children: [
      Image.network(
        mapUrl,
        height: 210,
        width: double.infinity,
        fit: BoxFit.cover,
        loadingBuilder: (_, child, progress) {
          if (progress == null) return child;
          return _mapLoadingView();
        },
        errorBuilder: (_, __, ___) => _fallbackMapView(complaints),
      ),
      // Priority pins overlay on top of map image
      Positioned.fill(
        child: LayoutBuilder(
          builder: (_, constraints) =>
              _PinOverlay(complaints: complaints, size: constraints.biggest),
        ),
      ),
      // Powered-by tag
      Positioned(
        bottom: 6,
        right: 8,
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.88),
            borderRadius: BorderRadius.circular(4),
          ),
          child: const Text('Powered by Google Maps',
              style: TextStyle(
                  fontSize: 8, color: AppColors.textSecondary)),
        ),
      ),
    ]);
  }

  Widget _mapLoadingView() => Container(
        height: 210,
        color: const Color(0xFFD4E6F1),
        child: const Center(
            child: CircularProgressIndicator(strokeWidth: 2)),
      );

  /// Fallback custom-painted map when Mappls image fails to load
  Widget _fallbackMapView(List<ComplaintModel> complaints) {
    return SizedBox(
      height: 210,
      child: Stack(children: [
        Container(
          color: const Color(0xFFCFE2F3),
          child: CustomPaint(
              size: const Size(double.infinity, 210),
              painter: _GridPainter()),
        ),
        CustomPaint(
            size: const Size(double.infinity, 210),
            painter: _RoadPainter()),
        // Plot real pins proportionally (normalise to viewport)
        ...complaints.take(15).map((c) {
          final color = c.priority == 'high'
              ? AppColors.error
              : c.priority == 'medium'
                  ? AppColors.warning
                  : AppColors.success;
          // Simple normalised position — spread evenly if no coord diff
          return LayoutBuilder(
            builder: (ctx, box) {
              final lats =
                  complaints.map((x) => x.latitude!).toList();
              final lngs =
                  complaints.map((x) => x.longitude!).toList();
              final minLat = lats.reduce((a, b) => a < b ? a : b);
              final maxLat = lats.reduce((a, b) => a > b ? a : b);
              final minLng = lngs.reduce((a, b) => a < b ? a : b);
              final maxLng = lngs.reduce((a, b) => a > b ? a : b);
              final latRange = (maxLat - minLat).abs();
              final lngRange = (maxLng - minLng).abs();
              final fx = latRange > 0
                  ? (c.longitude! - minLng) / lngRange
                  : 0.5;
              final fy = latRange > 0
                  ? 1 - ((c.latitude! - minLat) / latRange)
                  : 0.5;
              final w =
                  box.maxWidth.isFinite ? box.maxWidth : 300.0;
              return Positioned(
                left: (fx * w - 10).clamp(0.0, w - 20),
                top: (fy * 210 - 10).clamp(0.0, 190.0),
                child: _mapPin(color),
              );
            },
          );
        }),
        Positioned(
          bottom: 6,
          right: 8,
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.85),
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Text('Map data — real complaints',
                style: TextStyle(
                    fontSize: 8, color: AppColors.textSecondary)),
          ),
        ),
      ]),
    );
  }

  Widget _noLocationPlaceholder() => Container(
        height: 200,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: [
              const Color(0xFFE0EAFC).withOpacity(0.5),
              const Color(0xFFCFDEF3).withOpacity(0.5),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          children: [
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.2),
                          blurRadius: 30,
                          spreadRadius: 10,
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.map_rounded,
                      size: 40,
                      color: AppColors.primary.withOpacity(0.8),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Spatial Intelligence',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Text(
                      'Aggregating real-time GPS coordinates to generate city-wide density metrics.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary.withOpacity(0.7),
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _legendDot(Color color, String label) =>
      Row(mainAxisSize: MainAxisSize.min, children: [
        Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 3),
        Text(label,
            style: const TextStyle(
                fontSize: 9, color: AppColors.textSecondary)),
      ]);

  Widget _mapPin(Color color) => Container(
        width: 20,
        height: 20,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
                color: color.withOpacity(0.45), blurRadius: 6)
          ],
          border:
              Border.all(color: Colors.white, width: 1.5),
        ),
      );

  // ─── Category Overview ─────────────────────────────────────────────────────

  Widget _overviewCard(ComplaintProvider cp) {
    final a = cp.analytics;
    final total = (a['total'] as int?) ?? 1;
    final byCategory = (a['by_category'] as Map?) ?? {};

    const catColors = {
      'road_pothole': Color(0xFF795548),
      'water_leakage': Color(0xFF0288D1),
      'drainage': Color(0xFF00695C),
      'street_light': Color(0xFFF57F17),
      'garbage_sanitation': Color(0xFF558B2F),
      'others': Color(0xFF546E7A),
    };
    const catLabels = {
      'road_pothole': 'Road / Pothole',
      'water_leakage': 'Water Leakage',
      'drainage': 'Drainage',
      'street_light': 'Street Light',
      'garbage_sanitation': 'Garbage',
      'others': 'Others',
    };

    final sections = <PieChartSectionData>[];
    byCategory.forEach((k, v) {
      final count = (v as int?) ?? 0;
      if (count == 0) return;
      sections.add(PieChartSectionData(
          value: count.toDouble(),
          color: (catColors[k] ?? Colors.grey).withOpacity(0.9),
          title: '',
          radius: 22));
    });
    if (sections.isEmpty) {
      sections.add(PieChartSectionData(
          value: 1,
          color: AppColors.accent.withOpacity(0.1),
          title: '',
          radius: 16));
      sections.add(PieChartSectionData(
          value: 0.1,
          color: Colors.white,
          title: '',
          radius: 18));
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _glassDecoration(accentColor: AppColors.accent, borderRadius: 24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
                color: AppColors.accent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.donut_large_rounded,
                color: AppColors.accent, size: 18),
          ),
          const SizedBox(width: 10),
          const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('By Category',
                style:
                    TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            Text('Distribution overview',
                style:
                    TextStyle(fontSize: 10, color: AppColors.textHint)),
          ]),
        ]),
        const SizedBox(height: 16),
        Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
          SizedBox(
            width: 100,
            height: 100,
            child: PieChart(PieChartData(
                sections: sections,
                sectionsSpace: 4,
                centerSpaceRadius: 32,
                centerSpaceColor: Colors.transparent)),
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: catColors.entries.map((e) {
                final count = (byCategory[e.key] as int?) ?? 0;
                if (count == 0) return const SizedBox.shrink();
                final pct =
                    total > 0 ? (count / total * 100).round() : 0;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3.5),
                  child: Row(children: [
                    Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                            color: e.value,
                            borderRadius: BorderRadius.circular(3))),
                    const SizedBox(width: 7),
                    Expanded(
                      child: Text(catLabels[e.key] ?? e.key,
                          style: GoogleFonts.outfit(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textSecondary),
                          overflow: TextOverflow.ellipsis),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                          color: e.value.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: e.value.withOpacity(0.1))),
                      child: Text('$pct%',
                          style: GoogleFonts.outfit(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: e.value)),
                    ),
                  ]),
                );
              }).toList(),
            ),
          ),
        ]),
      ]),
    );
  }

  // ─── Weekly Trend ──────────────────────────────────────────────────────────

  Widget _weeklyTrendCard(ComplaintProvider cp) {
    // Build per-day counts from real complaints (last 7 days)
    final now = DateTime.now();
    final counts = List.filled(7, 0.0);
    for (final c in cp.adminComplaints) {
      final diff = now.difference(c.createdAt).inDays;
      if (diff >= 0 && diff < 7) counts[6 - diff]++;
    }
    final days = ['D-6', 'D-5', 'D-4', 'D-3', 'D-2', 'D-1', 'Today'];
    final maxY = (counts.reduce((a, b) => a > b ? a : b) + 2)
        .clamp(5.0, double.infinity);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _glassDecoration(accentColor: AppColors.success, borderRadius: 24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.trending_up_rounded,
                color: AppColors.success, size: 18),
          ),
          const SizedBox(width: 10),
          const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Weekly Trend',
                style:
                    TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            Text('Complaints submitted — last 7 days',
                style:
                    TextStyle(fontSize: 10, color: AppColors.textHint)),
          ]),
        ]),
        const SizedBox(height: 16),
        SizedBox(
          height: 120,
          child: BarChart(BarChartData(
            alignment: BarChartAlignment.spaceAround,
            maxY: maxY,
            barTouchData: BarTouchData(
              enabled: true,
              touchTooltipData: BarTouchTooltipData(
                tooltipBgColor: AppColors.primaryDark,
                tooltipRoundedRadius: 8,
                getTooltipItem: (group, _, rod, __) => BarTooltipItem(
                  '${rod.toY.toInt()}',
                  const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ),
            titlesData: FlTitlesData(
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, _) {
                    final i = value.toInt();
                    if (i < 0 || i >= 7) return const SizedBox.shrink();
                    return Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(days[i],
                          style: const TextStyle(
                              fontSize: 8,
                              color: AppColors.textHint)),
                    );
                  },
                ),
              ),
              leftTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false)),
              topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false)),
            ),
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              horizontalInterval: (maxY / 3).ceilToDouble(),
              getDrawingHorizontalLine: (_) =>
                  FlLine(color: Colors.grey.shade100, strokeWidth: 1),
            ),
            borderData: FlBorderData(show: false),
            barGroups: List.generate(
                7,
                (i) => BarChartGroupData(x: i, barRods: [
                      BarChartRodData(
                        toY: counts[i],
                        gradient: LinearGradient(
                          colors: [
                            AppColors.primary.withOpacity(0.4),
                            AppColors.primary,
                          ],
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                        ),
                        width: 14,
                        borderRadius: BorderRadius.circular(4),
                      )
                    ])),
          )),
        ),
      ]),
    );
  }

  // ─── Recent Complaints ─────────────────────────────────────────────────────

  Widget _recentComplaintsCard(ComplaintProvider cp) {
    final recent = cp.adminComplaints.take(5).toList();
    return Container(
      decoration: _glassDecoration(accentColor: AppColors.warning, borderRadius: 24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 12),
          child: Row(children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color: AppColors.warning.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.list_alt_rounded,
                  color: AppColors.warning, size: 18),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Recent Complaints',
                        style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.bold)),
                    Text('Latest submitted issues',
                        style: TextStyle(
                            fontSize: 10, color: AppColors.textHint)),
                  ]),
            ),
          ]),
        ),
        if (recent.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 40),
            child: Center(
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withOpacity(0.05),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.auto_awesome_rounded, color: AppColors.warning.withOpacity(0.4), size: 32),
                  ),
                  const SizedBox(height: 12),
                  const Text('System All Clear',
                      style: TextStyle(
                          color: AppColors.warning, fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 4),
                  Text('New submissions will appear here',
                      style: TextStyle(
                          color: AppColors.textHint.withOpacity(0.7), fontSize: 11)),
                ],
              ),
            ),
          )
        else
          ...recent.map((c) => _complaintTile(c)),
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 4, 18, 14),
          child: SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {},
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: BorderSide(
                    color: AppColors.primary.withOpacity(0.4)),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(vertical: 10),
              ),
              child: const Text('View All Complaints',
                  style: TextStyle(fontSize: 13)),
            ),
          ),
        ),
      ]),
    );
  }

  Widget _complaintTile(ComplaintModel c) {
    final catColor = AppTheme.getCategoryColor(c.category);
    final statusColor = AppTheme.getStatusColor(c.status);
    const catMap = {
      'road_pothole': 'Road / Pothole',
      'water_leakage': 'Water Leakage',
      'drainage': 'Drainage',
      'street_light': 'Street Light',
      'garbage_sanitation': 'Garbage',
      'others': 'Others',
    };

    return InkWell(
      onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) =>
                  ComplaintDetailAdmin(complaintId: c.id))),
      child: Container(
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
          border: Border.all(
              color: catColor.withOpacity(0.12)),
        ),
        child: Row(children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
                color: catColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10)),
            child: Center(
                child: Icon(
                    AppTheme.getCategoryIcon(c.category),
                    color: catColor,
                    size: 18)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Expanded(
                      child: Text(
                        catMap[c.category] ?? c.category,
                        style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    _statusBadge(
                        c.status.replaceAll('_', ' '),
                        statusColor),
                  ]),
                  const SizedBox(height: 2),
                  Text(c.description,
                      style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Row(children: [
                    const Icon(Icons.location_on_outlined,
                        size: 11, color: AppColors.textHint),
                    const SizedBox(width: 3),
                    Expanded(
                      child: Text(
                          c.locationText.split(',').first,
                          style: const TextStyle(
                              fontSize: 10,
                              color: AppColors.textHint),
                          overflow: TextOverflow.ellipsis),
                    ),
                    Text('#${c.id}',
                        style: const TextStyle(
                            fontSize: 10,
                            color: AppColors.textHint)),
                  ]),
                ]),
          ),
        ]),
      ),
    );
  }

  Widget _statusBadge(String label, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20)),
        child: Text(label,
            style: TextStyle(
                fontSize: 9,
                color: color,
                fontWeight: FontWeight.bold)),
      );
}

// ─── Pin Overlay (drawn on top of Mappls map image) ───────────────────────────

class _PinOverlay extends StatelessWidget {
  final List<ComplaintModel> complaints;
  final Size size;

  const _PinOverlay({required this.complaints, required this.size});

  @override
  Widget build(BuildContext context) {
    if (complaints.isEmpty) return const SizedBox.shrink();

    final lats = complaints.map((c) => c.latitude!).toList();
    final lngs = complaints.map((c) => c.longitude!).toList();
    final minLat = lats.reduce((a, b) => a < b ? a : b);
    final maxLat = lats.reduce((a, b) => a > b ? a : b);
    final minLng = lngs.reduce((a, b) => a < b ? a : b);
    final maxLng = lngs.reduce((a, b) => a > b ? a : b);
    final latRange = (maxLat - minLat).abs().clamp(0.001, 180.0);
    final lngRange = (maxLng - minLng).abs().clamp(0.001, 360.0);

    return Stack(
      children: complaints.take(20).map((c) {
        final fx = (c.longitude! - minLng) / lngRange;
        final fy = 1.0 - ((c.latitude! - minLat) / latRange);
        final color = c.priority == 'high'
            ? AppColors.error
            : c.priority == 'medium'
                ? AppColors.warning
                : AppColors.success;

        return Positioned(
          left: (fx * size.width - 10).clamp(2.0, size.width - 22),
          top: (fy * size.height - 10).clamp(2.0, size.height - 22),
          child: Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 1.5),
              boxShadow: [
                BoxShadow(
                    color: color.withOpacity(0.5), blurRadius: 6)
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ─── Painters ─────────────────────────────────────────────────────────────────

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = Colors.blueGrey.withOpacity(0.08)
      ..strokeWidth = 0.5;
    for (double x = 0; x < size.width; x += 24) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), p);
    }
    for (double y = 0; y < size.height; y += 24) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), p);
    }
  }

  @override
  bool shouldRepaint(_) => false;
}

class _RoadPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = Colors.white.withOpacity(0.50)
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(0, size.height * 0.48),
        Offset(size.width, size.height * 0.42), p);
    canvas.drawLine(Offset(size.width * 0.42, 0),
        Offset(size.width * 0.48, size.height), p);
    final p2 = Paint()
      ..color = Colors.white.withOpacity(0.30)
      ..strokeWidth = 2.5;
    canvas.drawLine(Offset(0, size.height * 0.24),
        Offset(size.width * 0.65, size.height * 0.28), p2);
    canvas.drawLine(Offset(size.width * 0.65, size.height * 0.28),
        Offset(size.width, size.height * 0.60), p2);
  }

  @override
  bool shouldRepaint(_) => false;
}
