import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';
import '../../providers/complaint_provider.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});
  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  int _selectedDays = 30;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  void _load() => context.read<ComplaintProvider>().loadAnalytics(days: _selectedDays);

  @override
  Widget build(BuildContext context) {
    final cp = context.watch<ComplaintProvider>();
    final data = cp.analytics;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        toolbarHeight: 100,
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        automaticallyImplyLeading: false,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(bottom: BorderSide(color: Colors.black.withOpacity(0.05))),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Builder(builder: (ctx) {
                        return GestureDetector(
                          onTap: () => Scaffold.of(ctx).openDrawer(),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.menu_rounded, color: AppColors.primary, size: 20),
                          ),
                        );
                      }),
                      const SizedBox(width: 12),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Analytics',
                            style: GoogleFonts.outfit(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                              letterSpacing: -0.5,
                            ),
                          ),
                          Text(
                            'Performance insights',
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              color: AppColors.textHint,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  _buildPeriodSelector(),
                ],
              ),
            ),
          ),
        ),
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async => _load(),
        child: cp.loading && data.isEmpty
          ? Center(child: CircularProgressIndicator(color: AppColors.primary))
          : SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(20),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _summaryRow(data),
                const SizedBox(height: 24),
                _sectionHeader('Complaint Status Overview', 'Real-time pipeline distribution'),
                const SizedBox(height: 16),
                _glassCard(child: _buildStatusBars(data)),
                const SizedBox(height: 24),
                _sectionHeader('Category Insights', 'Common civic issue themes'),
                const SizedBox(height: 16),
                _glassCard(
                  child: Column(
                    children: [
                      SizedBox(height: 220, child: _buildPieChart(data)),
                      const SizedBox(height: 20),
                      _buildCategoryLegend(data),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                _sectionHeader('Departmental Load', 'Top performing departments'),
                const SizedBox(height: 16),
                _glassCard(child: _buildDeptTable(data)),
                const SizedBox(height: 24),
                _sectionHeader('Performance Metrics', 'System efficiency markers'),
                const SizedBox(height: 16),
                _glassCard(
                  child: Column(children: [
                    _metricRow(Icons.timer_rounded, 'Avg Resolution',
                      '${data['avg_resolution_days'] ?? 0} Days', AppColors.primary),
                    const Divider(height: 24, thickness: 0.5),
                    _metricRow(Icons.check_circle_rounded, 'Total Resolved', '${data['resolved'] ?? 0}', AppColors.success),
                    const Divider(height: 24, thickness: 0.5),
                    _metricRow(Icons.report_problem_rounded, 'Escalation Rate', 
                      '${((data['escalated'] ?? 0) / (data['total'] ?? 1) * 100).toStringAsFixed(1)}%', AppColors.error),
                  ]),
                ),
                const SizedBox(height: 32),
              ]),
            ),
      ),
    );
  }

  Widget _buildPeriodSelector() {
    return PopupMenuButton<int>(
      initialValue: _selectedDays,
      onSelected: (v) { setState(() => _selectedDays = v); _load(); },
      offset: const Offset(0, 50),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      itemBuilder: (_) => [
        _popupItem(7, 'Last 7 Days'),
        _popupItem(30, 'Last 30 Days'),
        _popupItem(90, 'Last 90 Days'),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(children: [
          Text(
            '$_selectedDays D',
            style: GoogleFonts.outfit(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 4),
          const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.primary, size: 18),
        ]),
      ),
    );
  }

  PopupMenuItem<int> _popupItem(int val, String label) => PopupMenuItem(
    value: val,
    child: Text(label, style: GoogleFonts.outfit(fontSize: 14)),
  );

  Widget _sectionHeader(String title, String sub) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(title, style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
      Text(sub, style: GoogleFonts.outfit(fontSize: 12, color: AppColors.textHint)),
    ],
  );

  Widget _glassCard({required Widget child, EdgeInsets? padding}) => Container(
    width: double.infinity,
    padding: padding ?? const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: Colors.black.withOpacity(0.04)),
      boxShadow: [
        BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
      ],
    ),
    child: child,
  );

  Widget _summaryRow(Map data) => Row(children: [
    Expanded(child: _miniCard('Tickets', '${data['total'] ?? 0}', AppColors.primary, Icons.assignment_rounded)),
    const SizedBox(width: 12),
    Expanded(child: _miniCard('Active', '${data['submitted'] ?? 0}', AppColors.statusSubmitted, Icons.pending_actions_rounded)),
    const SizedBox(width: 12),
    Expanded(child: _miniCard('Solved', '${data['resolved'] ?? 0}', AppColors.success, Icons.task_alt_rounded)),
  ]);

  Widget _miniCard(String label, String value, Color color, IconData icon) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: color.withOpacity(0.1)),
      boxShadow: [
        BoxShadow(color: color.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 5)),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: color.withOpacity(0.6)),
        const SizedBox(height: 12),
        Text(value, style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
        Text(label, style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.textHint)),
      ],
    ),
  );

  Widget _buildStatusBars(Map data) {
    final statuses = {
      'submitted': AppColors.statusSubmitted,
      'in_progress': AppColors.statusInProgress,
      'resolved': AppColors.success,
      'escalated': AppColors.error,
    };
    final total = (data['total'] ?? 1) as int;
    return Column(children: statuses.entries.map((e) {
      final count = (data[e.key] ?? 0) as int;
      final pct = total > 0 ? count / total : 0.0;
      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: Text(AppConstants.statusLabels[e.key] ?? e.key,
              style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary))),
            Text('$count', style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.bold, color: e.value)),
            const SizedBox(width: 8),
            Text('${(pct * 100).toStringAsFixed(0)}%',
              style: GoogleFonts.outfit(fontSize: 11, color: AppColors.textHint)),
          ]),
          const SizedBox(height: 8),
          ClipRRect(borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: pct.toDouble(), minHeight: 10,
              backgroundColor: e.value.withOpacity(0.08),
              valueColor: AlwaysStoppedAnimation<Color>(e.value),
            )),
        ]),
      );
    }).toList());
  }

  Widget _buildPieChart(Map data) {
    final byCategory = data['by_category'] as Map? ?? {};
    if (byCategory.isEmpty) return Center(child: Text('Insufficient data for charts', style: GoogleFonts.outfit(color: AppColors.textHint)));
    final colors = [AppColors.primary, AppColors.secondary, AppColors.accent,
      AppColors.success, AppColors.warning, AppColors.error];
    final entries = byCategory.entries.toList();
    final total = entries.fold(0, (sum, e) => sum + (e.value as int));

    return PieChart(PieChartData(
      sections: entries.asMap().entries.map<PieChartSectionData>((e) {
        final pct = total > 0 ? e.value.value / total * 100 : 0.0;
        return PieChartSectionData(
          value: e.value.value.toDouble(),
          title: '${pct.toStringAsFixed(0)}%',
          radius: 80,
          titleStyle: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
          color: colors[e.key % colors.length],
        );
      }).toList(),
      borderData: FlBorderData(show: false),
      sectionsSpace: 4,
      centerSpaceRadius: 40,
    ));
  }

  Widget _buildCategoryLegend(Map data) {
    final byCategory = data['by_category'] as Map? ?? {};
    final colors = [AppColors.primary, AppColors.secondary, AppColors.accent,
      AppColors.success, AppColors.warning, AppColors.error];
    return Wrap(spacing: 12, runSpacing: 10,
      children: byCategory.entries.toList().asMap().entries.map((e) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min, children: [
            Container(width: 8, height: 8, decoration: BoxDecoration(
              color: colors[e.key % colors.length], shape: BoxShape.circle)),
            const SizedBox(width: 8),
            Text(AppConstants.categoryLabels[e.value.key] ?? e.value.key,
              style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.textSecondary)),
            const SizedBox(width: 6),
            Text('${e.value.value}',
              style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
          ],
        ),
      )).toList());
  }

  Widget _buildDeptTable(Map data) {
    final byDept = data['by_department'] as List? ?? [];
    if (byDept.isEmpty) return Text('No departmental activity recorded', style: GoogleFonts.outfit(color: AppColors.textHint, fontSize: 13));
    return Column(children: byDept.take(5).map((d) {
      final isLast = byDept.indexOf(d) == (byDept.length < 5 ? byDept.length - 1 : 4);
      return Container(
        margin: EdgeInsets.only(bottom: isLast ? 0 : 16),
        child: Row(children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.primary.withOpacity(0.08),
            child: const Icon(Icons.business_rounded, size: 16, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(d['assigned_department__name'] ?? 'General',
            style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary))),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.08), borderRadius: BorderRadius.circular(12)),
            child: Text('${d['count']}', style: GoogleFonts.outfit(fontSize: 12,
              color: AppColors.primary, fontWeight: FontWeight.bold))),
        ]),
      );
    }).toList());
  }

  Widget _metricRow(IconData icon, String label, String value, Color color) => Row(children: [
    Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
      child: Icon(icon, size: 18, color: color),
    ),
    const SizedBox(width: 12),
    Expanded(child: Text(label, style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textPrimary))),
    Text(value, style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold, color: color)),
  ]);
}
