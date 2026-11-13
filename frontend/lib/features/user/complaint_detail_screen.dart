import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';
import '../../models/complaint_model.dart';
import '../../services/api_service.dart';
import '../../widgets/common/custom_button.dart';

class ComplaintDetailScreen extends StatefulWidget {
  final int complaintId;
  const ComplaintDetailScreen({super.key, required this.complaintId});
  @override
  State<ComplaintDetailScreen> createState() => _ComplaintDetailScreenState();
}

class _ComplaintDetailScreenState extends State<ComplaintDetailScreen> {
  final _api = ApiService();
  ComplaintModel? _complaint;
  bool _loading = true;
  DateTime? _lastRefreshed;
  Timer? _pollTimer;

  static const _finalStatuses = {'resolved', 'closed'};

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _load({bool silent = false}) async {
    if (!silent) setState(() => _loading = _complaint == null);
    try {
      final data = await _api.getComplaintDetail(widget.complaintId);
      if (!mounted) return;
      final updated = ComplaintModel.fromJson(data);
      setState(() {
        _complaint = updated;
        _loading = false;
        _lastRefreshed = DateTime.now();
      });
      _schedulePoll(updated.status);
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _schedulePoll(String status) {
    _pollTimer?.cancel();
    if (_finalStatuses.contains(status)) return; // Stop polling once done
    _pollTimer = Timer(const Duration(seconds: 30), () => _load(silent: true));
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    return '${diff.inHours}h ago';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: Text('Complaint #${widget.complaintId}'),
        actions: [
          if (_lastRefreshed != null)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Center(
                child: Text(
                  'Updated ${_timeAgo(_lastRefreshed!)}',
                  style: const TextStyle(fontSize: 11, color: Colors.white70),
                ),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => _load(),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _complaint == null
              ? _errorState()
              : RefreshIndicator(
                  onRefresh: () => _load(),
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      _headerCard(),
                      const SizedBox(height: 16),
                      _statusTracker(),
                      const SizedBox(height: 16),
                      _detailCard(),
                      const SizedBox(height: 16),
                      if (_complaint!.imageUrl != null) ...[
                        _imageCard(),
                        const SizedBox(height: 16),
                      ],
                      if (_complaint!.aiPredictedCategory.isNotEmpty) ...[
                        _aiCard(),
                        const SizedBox(height: 16),
                      ],
                      if (_complaint!.statusHistory.isNotEmpty) ...[
                        _statusTimelineCard(),
                        const SizedBox(height: 16),
                      ],
                      if (_complaint!.resolutionNotes.isNotEmpty) ...[
                        _resolutionCard(),
                        const SizedBox(height: 16),
                      ],
                      _followUpCard(),
                      const SizedBox(height: 32),
                    ]),
                  ),
                ),
    );
  }

  // ── Header ──────────────────────────────────────────────────────────────────

  Widget _headerCard() {
    final c = _complaint!;
    final color = AppTheme.getCategoryColor(c.category);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDecor(),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(12)),
            child: Icon(AppTheme.getCategoryIcon(c.category), color: color, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(AppConstants.categoryLabels[c.category] ?? c.category,
              style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w600)),
            Text(c.title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
          ])),
        ]),
        const SizedBox(height: 16),
        Wrap(spacing: 8, runSpacing: 6, children: [
          StatusBadge(status: c.status),
          PriorityBadge(priority: c.priority),
          if (c.isEscalated)
            _chip('ESCALATED', AppColors.error),
          if (c.isSlaBreached)
            _chip('SLA BREACHED', Colors.deepOrange),
        ]),
        const SizedBox(height: 12),
        _iconRow(Icons.access_time, DateFormat('MMM dd, yyyy • hh:mm a').format(c.createdAt.toLocal())),
        if (c.locationText.isNotEmpty) ...[
          const SizedBox(height: 4),
          _iconRow(Icons.location_on_outlined, c.locationText),
        ],
        if (c.slaDeadline != null) ...[
          const SizedBox(height: 4),
          _iconRow(
            Icons.timer_outlined,
            'SLA Deadline: ${DateFormat('MMM dd, yyyy').format(c.slaDeadline!.toLocal())}',
            color: c.isSlaBreached ? AppColors.error : AppColors.textSecondary,
          ),
        ],
        if (c.departmentName != null) ...[
          const SizedBox(height: 4),
          _iconRow(Icons.business_outlined, 'Assigned to: ${c.departmentName!}'),
        ],
      ]),
    );
  }

  // ── Visual Status Tracker ───────────────────────────────────────────────────

  Widget _statusTracker() {
    const steps = ['submitted', 'assigned', 'in_progress', 'resolved'];
    final current = _complaint!.status;
    final isEscalated = _complaint!.isEscalated;
    final isClosed = current == 'closed';

    int currentStep = steps.indexOf(current);
    if (currentStep == -1) currentStep = isClosed ? 3 : 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDecor(),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Row(children: [
          Icon(Icons.track_changes_rounded, color: AppColors.primary, size: 20),
          SizedBox(width: 8),
          Text('Progress', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
        ]),
        const SizedBox(height: 20),
        Row(children: steps.asMap().entries.map((entry) {
          final i = entry.key;
          final step = entry.value;
          final done = i <= currentStep;
          final active = i == currentStep;
          final color = isEscalated && active ? AppColors.error
              : done ? AppColors.success : Colors.grey.shade300;
          return Expanded(child: Row(children: [
            Column(mainAxisSize: MainAxisSize.min, children: [
              Container(
                width: 28, height: 28,
                decoration: BoxDecoration(
                  color: done ? color : Colors.transparent,
                  border: Border.all(color: color, width: 2),
                  shape: BoxShape.circle,
                ),
                child: done
                    ? const Icon(Icons.check, color: Colors.white, size: 14)
                    : null,
              ),
              const SizedBox(height: 4),
              Text(
                AppConstants.statusLabels[step] ?? step,
                style: TextStyle(fontSize: 8, color: done ? color : AppColors.textHint,
                  fontWeight: active ? FontWeight.bold : FontWeight.normal),
                textAlign: TextAlign.center,
              ),
            ]),
            if (i < steps.length - 1)
              Expanded(child: Container(height: 2, margin: const EdgeInsets.only(bottom: 18),
                color: i < currentStep ? AppColors.success : Colors.grey.shade200)),
          ]));
        }).toList()),
        if (isEscalated) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.error.withOpacity(0.08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.error.withOpacity(0.2)),
            ),
            child: Row(children: [
              const Icon(Icons.priority_high_rounded, color: AppColors.error, size: 16),
              const SizedBox(width: 8),
              Expanded(child: Text(
                _complaint!.escalationReason.isNotEmpty
                    ? 'Escalated: ${_complaint!.escalationReason}'
                    : 'This complaint has been escalated for priority resolution.',
                style: const TextStyle(color: AppColors.error, fontSize: 12),
              )),
            ]),
          ),
        ],
      ]),
    );
  }

  // ── Detail Card ─────────────────────────────────────────────────────────────

  Widget _detailCard() => _card('Description', Icons.description_outlined, [
    Text(_complaint!.description,
      style: const TextStyle(fontSize: 14, color: AppColors.textPrimary, height: 1.6)),
    const SizedBox(height: 12),
    const Divider(),
    const SizedBox(height: 8),
    _infoRow(Icons.tag_outlined, 'Complaint ID', '#${_complaint!.id}'),
    _infoRow(Icons.category_outlined, 'Category',
      AppConstants.categoryLabels[_complaint!.category] ?? _complaint!.category),
    if (_complaint!.daysOpen > 0)
      _infoRow(Icons.calendar_today_outlined, 'Open for', '${_complaint!.daysOpen} day(s)'),
  ]);

  // ── Image Card ──────────────────────────────────────────────────────────────

  Widget _imageCard() => _card('Photo Evidence', Icons.photo_outlined, [
    ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.network(
        _complaint!.imageUrl!,
        height: 200, width: double.infinity, fit: BoxFit.cover,
        loadingBuilder: (_, child, progress) => progress == null ? child
            : Container(height: 200, color: Colors.grey.shade100,
                child: const Center(child: CircularProgressIndicator())),
        errorBuilder: (_, __, ___) => Container(height: 100,
          color: Colors.grey.shade100, child: const Icon(Icons.broken_image)),
      ),
    ),
  ]);

  // ── AI Card ─────────────────────────────────────────────────────────────────

  Widget _aiCard() {
    final c = _complaint!;
    return _card('AI Analysis', Icons.psychology_outlined, [
      Row(children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(color: AppColors.accent.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20)),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.auto_awesome, size: 14, color: AppColors.accent),
            const SizedBox(width: 4),
            Text('${(c.aiConfidence * 100).toStringAsFixed(0)}% confidence',
              style: const TextStyle(color: AppColors.accent, fontSize: 12, fontWeight: FontWeight.w600)),
          ]),
        ),
        if (c.adminOverride) ...[
          const SizedBox(width: 8),
          const Chip(label: Text('Admin Override', style: TextStyle(fontSize: 11))),
        ],
      ]),
      const SizedBox(height: 10),
      _infoRow(Icons.category_outlined, 'Predicted Category',
        AppConstants.categoryLabels[c.aiPredictedCategory] ?? c.aiPredictedCategory),
      if (c.aiPredictedDepartment.isNotEmpty)
        _infoRow(Icons.business_outlined, 'Predicted Department', c.aiPredictedDepartment),
    ]);
  }

  // ── Status Timeline ──────────────────────────────────────────────────────────

  Widget _statusTimelineCard() {
    final history = _complaint!.statusHistory;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDecor(),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Row(children: [
          Icon(Icons.timeline, color: AppColors.primary, size: 20),
          SizedBox(width: 8),
          Text('Activity Timeline', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
        ]),
        const SizedBox(height: 16),
        ...history.asMap().entries.map((entry) {
          final h = entry.value;
          final isLast = entry.key == history.length - 1;
          final color = AppTheme.getStatusColor(h.newStatus);
          return IntrinsicHeight(
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Column(children: [
                Container(width: 12, height: 12,
                  decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                if (!isLast) Expanded(child: Container(width: 2, color: Colors.grey.shade200)),
              ]),
              const SizedBox(width: 12),
              Expanded(child: Padding(
                padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Text(AppConstants.statusLabels[h.newStatus] ?? h.newStatus,
                      style: TextStyle(fontWeight: FontWeight.w600, color: color, fontSize: 13)),
                    if (h.updatedByName != null) ...[
                      const SizedBox(width: 6),
                      Text('by ${h.updatedByName}',
                        style: const TextStyle(fontSize: 11, color: AppColors.textHint)),
                    ],
                  ]),
                  if (h.notes.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(h.notes, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  ],
                  const SizedBox(height: 2),
                  Text(DateFormat('MMM dd, yyyy • hh:mm a').format(h.timestamp.toLocal()),
                    style: const TextStyle(fontSize: 11, color: AppColors.textHint)),
                ]),
              )),
            ]),
          );
        }),
      ]),
    );
  }

  // ── Resolution Card ──────────────────────────────────────────────────────────

  Widget _resolutionCard() => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: AppColors.success.withOpacity(0.06),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppColors.success.withOpacity(0.2)),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Row(children: [
        Icon(Icons.check_circle_rounded, color: AppColors.success, size: 20),
        SizedBox(width: 8),
        Text('Resolution Notes', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600,
          color: AppColors.success)),
      ]),
      const SizedBox(height: 12),
      Text(_complaint!.resolutionNotes,
        style: const TextStyle(fontSize: 14, color: AppColors.textPrimary, height: 1.6)),
      if (_complaint!.resolvedAt != null) ...[
        const SizedBox(height: 8),
        Text('Resolved on ${DateFormat('MMM dd, yyyy').format(_complaint!.resolvedAt!.toLocal())}',
          style: const TextStyle(fontSize: 12, color: AppColors.success)),
      ],
    ]),
  );

  // ── Follow-up Card ───────────────────────────────────────────────────────────

  Widget _followUpCard() {
    final status = _complaint!.status;
    final isResolved = status == 'resolved' || status == 'closed';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDecor(),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Row(children: [
          Icon(Icons.support_agent_rounded, color: AppColors.primary, size: 20),
          SizedBox(width: 8),
          Text('Follow-up & Support', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
        ]),
        const SizedBox(height: 14),

        if (isResolved) ...[
          // Resolved: ask for satisfaction
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.06),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.success.withOpacity(0.15)),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Is your issue resolved?',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
              const SizedBox(height: 10),
              Row(children: [
                Expanded(child: OutlinedButton.icon(
                  onPressed: () => _showSnack('Thank you for your feedback!'),
                  icon: const Icon(Icons.thumb_up_outlined, size: 16),
                  label: const Text('Yes, resolved'),
                  style: OutlinedButton.styleFrom(foregroundColor: AppColors.success,
                    side: const BorderSide(color: AppColors.success)),
                )),
                const SizedBox(width: 10),
                Expanded(child: OutlinedButton.icon(
                  onPressed: () => _showReportNotResolvedDialog(),
                  icon: const Icon(Icons.thumb_down_outlined, size: 16),
                  label: const Text('Not resolved'),
                  style: OutlinedButton.styleFrom(foregroundColor: AppColors.error,
                    side: const BorderSide(color: AppColors.error)),
                )),
              ]),
            ]),
          ),
        ] else ...[
          // Active: show status info + next steps
          Text(
            _getNextStepMessage(status),
            style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.5),
          ),
          const SizedBox(height: 14),
          // Auto-refresh notice
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.06),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(children: [
              SizedBox(width: 14, height: 14,
                child: CircularProgressIndicator(strokeWidth: 2,
                  color: AppColors.primary.withOpacity(0.5))),
              const SizedBox(width: 10),
              const Text('Live tracking active — refreshes every 30 seconds',
                style: TextStyle(fontSize: 11, color: AppColors.primary)),
            ]),
          ),
        ],

        const SizedBox(height: 14),
        const Divider(),
        const SizedBox(height: 10),

        // Need help section
        const Text('Need help?',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(child: _supportButton(
            Icons.info_outline_rounded,
            'Complaint ID: #${_complaint!.id}',
            AppColors.primary.withOpacity(0.08),
            AppColors.primary,
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Complaint ID #${_complaint!.id} — share this with support'),
                  backgroundColor: AppColors.primary),
              );
            },
          )),
        ]),
      ]),
    );
  }

  String _getNextStepMessage(String status) {
    switch (status) {
      case 'submitted':
        return 'Your complaint has been received and is pending review. Our team will assign it to the appropriate department shortly.';
      case 'assigned':
        return 'Your complaint has been assigned to the ${_complaint!.departmentName ?? 'concerned'} department. Work will begin soon.';
      case 'in_progress':
        return 'The department is actively working on your complaint. You will be notified when it\'s resolved.';
      case 'escalated':
        return 'Your complaint has been escalated for priority resolution due to urgency or delay. Expect faster action.';
      default:
        return 'We are processing your complaint. Please check back for updates.';
    }
  }

  void _showReportNotResolvedDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Report as Not Resolved'),
        content: const Text(
          'Your feedback has been noted. An administrator will review your complaint and follow up shortly.\n\nQuote your Complaint ID when contacting support.',
          style: TextStyle(height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: AppColors.success),
    );
  }

  // ── Helpers ──────────────────────────────────────────────────────────────────

  Widget _errorState() => Center(
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(Icons.cloud_off_rounded, size: 64, color: Colors.grey.shade300),
      const SizedBox(height: 16),
      const Text('Could not load complaint', style: TextStyle(color: AppColors.textSecondary)),
      const SizedBox(height: 12),
      ElevatedButton.icon(
        onPressed: _load,
        icon: const Icon(Icons.refresh_rounded),
        label: const Text('Try Again'),
      ),
    ]),
  );

  Widget _card(String title, IconData icon, List<Widget> children) => Container(
    padding: const EdgeInsets.all(20),
    decoration: _cardDecor(),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Icon(icon, color: AppColors.primary, size: 20),
        const SizedBox(width: 8),
        Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
      ]),
      const SizedBox(height: 14),
      ...children,
    ]),
  );

  BoxDecoration _cardDecor() => BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(16),
    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
  );

  Widget _infoRow(IconData icon, String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(children: [
      Icon(icon, size: 14, color: AppColors.textHint),
      const SizedBox(width: 6),
      Text('$label: ', style: const TextStyle(fontSize: 12, color: AppColors.textHint)),
      Expanded(child: Text(value, style: const TextStyle(fontSize: 12, color: AppColors.textPrimary,
        fontWeight: FontWeight.w500))),
    ]),
  );

  Widget _iconRow(IconData icon, String text, {Color? color}) => Row(children: [
    Icon(icon, size: 14, color: color ?? AppColors.textHint),
    const SizedBox(width: 6),
    Expanded(child: Text(text,
      style: TextStyle(fontSize: 12, color: color ?? AppColors.textSecondary))),
  ]);

  Widget _chip(String label, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
    child: Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
  );

  Widget _supportButton(IconData icon, String label, Color bg, Color fg,
      {required VoidCallback onTap}) =>
      InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, size: 16, color: fg),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(fontSize: 12, color: fg, fontWeight: FontWeight.w500)),
          ]),
        ),
      );
}
