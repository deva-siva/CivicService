import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';
import '../../providers/complaint_provider.dart';
import '../../models/complaint_model.dart';
import 'complaint_detail_screen.dart';

class MyComplaintsScreen extends StatefulWidget {
  const MyComplaintsScreen({super.key});
  @override
  State<MyComplaintsScreen> createState() => _MyComplaintsScreenState();
}

class _MyComplaintsScreenState extends State<MyComplaintsScreen>
    with WidgetsBindingObserver {
  String? _selectedCategory;
  String? _selectedStatus;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _load();
  }

  void _load() {
    context.read<ComplaintProvider>().loadMyComplaints(
        status: _selectedStatus, category: _selectedCategory);
    _pollTimer?.cancel();
    _pollTimer = Timer(const Duration(seconds: 30), _load);
  }

  @override
  Widget build(BuildContext context) {
    final cp = context.watch<ComplaintProvider>();
    final complaints = cp.myComplaints;
    final hasFilter = _selectedStatus != null || _selectedCategory != null;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Row(children: [
          const Text('My Issues',
              style: TextStyle(
                  fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
          if (complaints.isNotEmpty) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text('${complaints.length}',
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary)),
            ),
          ],
        ]),
        actions: [
          if (cp.loading)
            const Padding(
              padding: EdgeInsets.only(right: 16),
              child: Center(
                  child: SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2))),
            ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: const Color(0xFFE8ECF0)),
        ),
      ),
      body: Column(children: [
        // ── Filters ────────────────────────────────────────────────────────
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
          child: Row(children: [
            Expanded(
              child: _Dropdown(
                value: _selectedCategory,
                hint: 'All Categories',
                items: AppConstants.categoryLabels.entries
                    .map((e) =>
                        DropdownMenuItem(value: e.key, child: Text(e.value)))
                    .toList(),
                onChanged: (v) => setState(() {
                  _selectedCategory = v;
                  _load();
                }),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _Dropdown(
                value: _selectedStatus,
                hint: 'All Status',
                items: AppConstants.statusLabels.entries
                    .map((e) =>
                        DropdownMenuItem(value: e.key, child: Text(e.value)))
                    .toList(),
                onChanged: (v) => setState(() {
                  _selectedStatus = v;
                  _load();
                }),
              ),
            ),
            if (hasFilter) ...[
              const SizedBox(width: 6),
              GestureDetector(
                onTap: () => setState(() {
                  _selectedCategory = null;
                  _selectedStatus = null;
                  _load();
                }),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.close_rounded,
                      size: 16, color: AppColors.error),
                ),
              ),
            ],
          ]),
        ),
        const SizedBox(height: 1),

        // ── List ───────────────────────────────────────────────────────────
        Expanded(
          child: cp.loading && complaints.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : complaints.isEmpty
                  ? _EmptyState(hasFilter: hasFilter)
                  : RefreshIndicator(
                      onRefresh: () async => _load(),
                      child: ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: complaints.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (_, i) => _ComplaintCard(
                          complaint: complaints[i],
                          onTap: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ComplaintDetailScreen(
                                    complaintId: complaints[i].id),
                              ),
                            );
                            _load();
                          },
                        ),
                      ),
                    ),
        ),
      ]),
    );
  }
}

// ── Complaint card ──────────────────────────────────────────────────────────────

class _ComplaintCard extends StatelessWidget {
  final ComplaintModel complaint;
  final VoidCallback onTap;
  const _ComplaintCard({required this.complaint, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = complaint;
    final statusColor = AppTheme.getStatusColor(c.status);
    final catIcon = AppTheme.getCategoryIcon(c.category);
    final catColor = AppTheme.getCategoryColor(c.category);
    final statusLabel = AppConstants.statusLabels[c.status] ?? c.status;
    final dateStr = DateFormat('MMM dd, yyyy').format(c.createdAt);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE8ECF0)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Category icon
            Container(
              width: 42, height: 42,
              decoration: BoxDecoration(
                color: catColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(catIcon, color: catColor, size: 20),
            ),
            const SizedBox(width: 12),
            // Content
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Text('#${c.id}',
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.textHint)),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(statusLabel,
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: statusColor)),
                  ),
                ]),
                const SizedBox(height: 4),
                Text(c.title.isNotEmpty ? c.title : c.description,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary)),
                const SizedBox(height: 5),
                Row(children: [
                  const Icon(Icons.location_on_outlined,
                      size: 12, color: AppColors.textHint),
                  const SizedBox(width: 2),
                  Expanded(
                    child: Text(c.locationText.split(',').first,
                        style: const TextStyle(
                            fontSize: 11, color: AppColors.textSecondary),
                        overflow: TextOverflow.ellipsis),
                  ),
                  Text(dateStr,
                      style: const TextStyle(
                          fontSize: 10, color: AppColors.textHint)),
                ]),
              ]),
            ),
            const SizedBox(width: 6),
            const Icon(Icons.chevron_right_rounded,
                size: 18, color: AppColors.textHint),
          ]),
        ),
      ),
    );
  }
}

// ── Filter dropdown ─────────────────────────────────────────────────────────────

class _Dropdown extends StatelessWidget {
  final String? value;
  final String hint;
  final List<DropdownMenuItem<String>> items;
  final ValueChanged<String?> onChanged;

  const _Dropdown({
    required this.value,
    required this.hint,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F7FA),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE8ECF0)),
      ),
      child: DropdownButton<String>(
        value: value,
        hint: Text(hint,
            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
        isExpanded: true,
        underline: const SizedBox.shrink(),
        icon: const Icon(Icons.keyboard_arrow_down_rounded,
            size: 16, color: AppColors.textHint),
        style: const TextStyle(fontSize: 11, color: AppColors.textPrimary),
        items: [
          DropdownMenuItem<String>(
              value: null,
              child: Text(hint,
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.textSecondary))),
          ...items,
        ],
        onChanged: onChanged,
      ),
    );
  }
}

// ── Empty state ─────────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final bool hasFilter;
  const _EmptyState({required this.hasFilter});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.inbox_outlined, size: 60, color: Colors.grey.shade300),
        const SizedBox(height: 14),
        Text(
          hasFilter ? 'No complaints match filters' : 'No complaints yet',
          style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary),
        ),
        const SizedBox(height: 6),
        Text(
          hasFilter
              ? 'Try clearing the filters'
              : 'Tap Report to submit a civic issue',
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
      ]),
    );
  }
}
