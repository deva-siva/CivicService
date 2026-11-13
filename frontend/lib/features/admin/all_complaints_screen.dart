import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';
import '../../providers/complaint_provider.dart';
import 'complaint_detail_admin.dart';

class AllComplaintsScreen extends StatefulWidget {
  const AllComplaintsScreen({super.key});
  @override
  State<AllComplaintsScreen> createState() => _AllComplaintsScreenState();
}

class _AllComplaintsScreenState extends State<AllComplaintsScreen> {
  final _searchCtrl = TextEditingController();
  String? _filterStatus;
  String? _filterCategory;
  String? _filterPriority;
  bool _loading = false;

  static const _statusOptions = [
    'submitted', 'assigned', 'in_progress', 'resolved', 'closed', 'escalated'
  ];
  static const _priorityOptions = ['high', 'medium', 'low'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    await context.read<ComplaintProvider>().loadAdminComplaints(
      status: _filterStatus,
      category: _filterCategory,
      priority: _filterPriority,
      search: _searchCtrl.text.trim().isEmpty ? null : _searchCtrl.text.trim(),
    );
    if (mounted) setState(() => _loading = false);
  }

  List _filtered(List complaints) {
    if (_searchCtrl.text.isEmpty) return complaints;
    final q = _searchCtrl.text.toLowerCase();
    return complaints.where((c) =>
      (c.title ?? '').toLowerCase().contains(q) ||
      (c.description ?? '').toLowerCase().contains(q) ||
      (c.locationText ?? '').toLowerCase().contains(q) ||
      (c.submittedByName ?? '').toLowerCase().contains(q)
    ).toList();
  }

  @override
  Widget build(BuildContext context) {
    final cp = context.watch<ComplaintProvider>();
    final complaints = _filtered(cp.adminComplaints);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        toolbarHeight: 140,
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
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
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
                          Text(
                            'Complaint Feed',
                            style: GoogleFonts.outfit(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${complaints.length} Total',
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 48,
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.black.withOpacity(0.05)),
                          ),
                          child: TextField(
                            controller: _searchCtrl,
                            onChanged: (_) => setState(() {}),
                            onSubmitted: (_) => _load(),
                            style: GoogleFonts.outfit(fontSize: 14),
                            decoration: InputDecoration(
                              hintText: 'Search by ID, title or citizen...',
                              hintStyle: GoogleFonts.outfit(color: AppColors.textHint.withOpacity(0.5), fontSize: 13),
                              prefixIcon: Icon(Icons.search_rounded, color: AppColors.textHint.withOpacity(0.5), size: 20),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      GestureDetector(
                        onTap: _showFilterSheet,
                        child: Container(
                          height: 48,
                          width: 48,
                          decoration: BoxDecoration(
                            color: (_filterStatus != null || _filterCategory != null || _filterPriority != null)
                                ? AppColors.primary
                                : AppColors.background,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.black.withOpacity(0.05)),
                          ),
                          child: Icon(
                            Icons.tune_rounded,
                            color: (_filterStatus != null || _filterCategory != null || _filterPriority != null)
                                ? Colors.white
                                : AppColors.textPrimary,
                            size: 20,
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
      body: Column(
        children: [
          if (_filterStatus != null || _filterCategory != null || _filterPriority != null)
            Padding(
              padding: const EdgeInsets.only(top: 8.0, bottom: 4.0),
              child: SizedBox(
                height: 40,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  children: [
                    if (_filterStatus != null)
                      _activeChip(_filterStatus!.replaceAll('_', ' '),
                          () => setState(() { _filterStatus = null; _load(); })),
                    if (_filterCategory != null)
                      _activeChip(AppConstants.categoryLabels[_filterCategory] ?? _filterCategory!,
                          () => setState(() { _filterCategory = null; _load(); })),
                    if (_filterPriority != null)
                      _activeChip(_filterPriority!,
                          () => setState(() { _filterPriority = null; _load(); })),
                  ],
                ),
              ),
            ),
          Expanded(
            child: _loading
                ? Center(child: CircularProgressIndicator(color: AppColors.primary))
                : complaints.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.assignment_late_outlined, size: 60, color: AppColors.textHint.withOpacity(0.2)),
                            const SizedBox(height: 16),
                            Text(
                              'No complaints match your criteria',
                              style: GoogleFonts.outfit(color: AppColors.textHint, fontSize: 16),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        color: AppColors.primary,
                        onRefresh: _load,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(20),
                          itemCount: complaints.length,
                          itemBuilder: (_, i) => _complaintCard(complaints[i]),
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _complaintCard(dynamic c) {
    final catColor = AppTheme.getCategoryColor(c.category ?? '');
    final statusColor = AppTheme.getStatusColor(c.status ?? '');
    final priorityColor = AppTheme.getPriorityColor(c.priority ?? '');
    final dt = c.createdAt != null
        ? DateFormat('MMM dd, yyyy • hh:mm a').format(c.createdAt!)
        : '—';
    const catLabels = {
      'road_pothole': 'Road / Pothole',
      'water_leakage': 'Water Leakage',
      'drainage': 'Drainage',
      'street_light': 'Street Light',
      'garbage_sanitation': 'Garbage / Sani.',
      'others': 'Others',
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.black.withOpacity(0.04)),
      ),
      child: InkWell(
        onTap: () => Navigator.push(context, MaterialPageRoute(
            builder: (_) => ComplaintDetailAdmin(complaintId: c.id ?? 0))),
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '#${c.id ?? '?'}',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textHint,
                      ),
                    ),
                  ),
                  const Spacer(),
                  _badge((c.status ?? '').toString().replaceAll('_', ' '), statusColor),
                  const SizedBox(width: 8),
                  if (c.isEscalated == true) ...[
                    _badge('ESCALATED', AppColors.error),
                    const SizedBox(width: 8),
                  ],
                  _badge((c.priority ?? 'low').toString(), priorityColor, isPriority: true),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                c.title ?? 'No Title',
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.location_on_outlined, size: 14, color: AppColors.textHint.withOpacity(0.6)),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      (c.locationText ?? '').toString().split(',').first,
                      style: GoogleFonts.outfit(fontSize: 13, color: AppColors.textSecondary),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 12),
              Row(
                children: [
                  CircleAvatar(
                    radius: 12,
                    backgroundColor: catColor.withOpacity(0.1),
                    child: Icon(Icons.category_outlined, size: 14, color: catColor),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    catLabels[c.category] ?? c.category ?? '',
                    style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textSecondary),
                  ),
                  const Spacer(),
                  Text(
                    dt,
                    style: GoogleFonts.outfit(fontSize: 11, color: AppColors.textHint),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showFilterSheet() {
    String? tmpStatus = _filterStatus;
    String? tmpCat = _filterCategory;
    String? tmpPri = _filterPriority;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        padding: const EdgeInsets.all(24),
        child: StatefulBuilder(
          builder: (ctx, setModal) => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text('Filter Complaints',
                  style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              Text('Status', style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Wrap(spacing: 8, runSpacing: 8,
                children: _statusOptions.map((s) => FilterChip(
                  label: Text(s.replaceAll('_', ' '), style: GoogleFonts.outfit(fontSize: 13)),
                  selected: tmpStatus == s,
                  onSelected: (v) => setModal(() => tmpStatus = v ? s : null),
                  selectedColor: AppColors.primary.withOpacity(0.1),
                  checkmarkColor: AppColors.primary,
                  backgroundColor: AppColors.background,
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                )).toList(),
              ),
              const SizedBox(height: 20),
              Text('Category', style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Wrap(spacing: 8, runSpacing: 8,
                children: AppConstants.categoryLabels.entries.map((e) => FilterChip(
                  label: Text(e.value, style: GoogleFonts.outfit(fontSize: 13)),
                  selected: tmpCat == e.key,
                  onSelected: (v) => setModal(() => tmpCat = v ? e.key : null),
                  selectedColor: AppColors.primary.withOpacity(0.1),
                  checkmarkColor: AppColors.primary,
                  backgroundColor: AppColors.background,
                )).toList(),
              ),
              const SizedBox(height: 20),
              Text('Priority', style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Wrap(spacing: 8, runSpacing: 8,
                children: _priorityOptions.map((p) => FilterChip(
                  label: Text(p, style: GoogleFonts.outfit(fontSize: 13)),
                  selected: tmpPri == p,
                  onSelected: (v) => setModal(() => tmpPri = v ? p : null),
                  selectedColor: AppTheme.getPriorityColor(p).withOpacity(0.1),
                  checkmarkColor: AppTheme.getPriorityColor(p),
                  backgroundColor: AppColors.background,
                )).toList(),
              ),
              const SizedBox(height: 32),
              Row(children: [
                Expanded(child: OutlinedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    setState(() {
                      _filterStatus = null;
                      _filterCategory = null;
                      _filterPriority = null;
                    });
                    _load();
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: Text('Clear All', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                )),
                const SizedBox(width: 12),
                Expanded(child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    setState(() {
                      _filterStatus = tmpStatus;
                      _filterCategory = tmpCat;
                      _filterPriority = tmpPri;
                    });
                    _load();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: Text('Apply Filters', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                )),
              ]),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _badge(String label, Color color, {bool isPriority = false}) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2))),
    child: Text(label.toUpperCase(),
        style: GoogleFonts.outfit(fontSize: 9, color: color, fontWeight: FontWeight.w800, letterSpacing: 0.5),
        overflow: TextOverflow.ellipsis),
  );

  Widget _activeChip(String label, VoidCallback onRemove) => Container(
    margin: const EdgeInsets.only(right: 8),
    padding: const EdgeInsets.fromLTRB(10, 4, 6, 4),
    decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(10)),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Text(label,
          style: GoogleFonts.outfit(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w500)),
      const SizedBox(width: 4),
      GestureDetector(onTap: onRemove,
          child: const Icon(Icons.close_rounded, size: 14, color: Colors.white70)),
    ]),
  );
}
