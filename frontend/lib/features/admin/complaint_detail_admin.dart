import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';
import '../../models/complaint_model.dart';
import '../../providers/complaint_provider.dart';
import '../../services/api_service.dart';
import '../../widgets/common/custom_button.dart';

class ComplaintDetailAdmin extends StatefulWidget {
  final int complaintId;
  const ComplaintDetailAdmin({super.key, required this.complaintId});
  @override
  State<ComplaintDetailAdmin> createState() => _ComplaintDetailAdminState();
}

class _ComplaintDetailAdminState extends State<ComplaintDetailAdmin> {
  final _api = ApiService();
  ComplaintModel? _complaint;
  List<DepartmentModel> _departments = [];
  bool _loading = true;
  String? _selectedStatus;
  String? _selectedPriority;
  int? _selectedDeptId;
  final _notesCtrl = TextEditingController();
  final _resolutionCtrl = TextEditingController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _notesCtrl.dispose();
    _resolutionCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final results = await Future.wait([
        _api.getComplaintDetail(widget.complaintId),
        _api.getDepartments(),
      ]);
      final c = ComplaintModel.fromJson(results[0] as Map<String, dynamic>);
      _complaint = c;
      _departments = (results[1] as List).map((d) => DepartmentModel.fromJson(d)).toList();
      _selectedStatus = c.status;
      _selectedPriority = c.priority;
      _selectedDeptId = c.assignedDepartment;
      _notesCtrl.text = c.adminNotes;
      _resolutionCtrl.text = c.resolutionNotes;
    } catch (_) {}
    setState(() => _loading = false);
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final cp = context.read<ComplaintProvider>();
    final success = await cp.updateComplaint(widget.complaintId, {
      'status': _selectedStatus,
      'priority': _selectedPriority,
      'assigned_department': _selectedDeptId,
      'admin_notes': _notesCtrl.text,
      'resolution_notes': _resolutionCtrl.text,
    });
    if (success) await _load();
    setState(() => _saving = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(success ? 'Complaint updated successfully' : 'Update failed'),
        backgroundColor: success ? AppColors.success : AppColors.error,
      ));
    }
  }

  Future<void> _escalate() async {
    final reasonCtrl = TextEditingController();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Escalate Complaint'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('Provide reason for escalation:'),
          const SizedBox(height: 12),
          TextField(controller: reasonCtrl, maxLines: 3,
            decoration: const InputDecoration(hintText: 'Reason...')),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Escalate'),
          ),
        ],
      ),
    );
    if (confirm == true && mounted) {
      await context.read<ComplaintProvider>().escalateComplaint(
        widget.complaintId, reasonCtrl.text.isEmpty ? 'Manual escalation by admin' : reasonCtrl.text,
      );
      await _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: Text('Complaint #${widget.complaintId}'),
        actions: [
          if (_complaint != null && !_complaint!.isEscalated)
            TextButton.icon(
              onPressed: _escalate,
              icon: const Icon(Icons.warning_amber_rounded, color: Colors.orange),
              label: const Text('Escalate', style: TextStyle(color: Colors.orange)),
            ),
        ],
      ),
      body: _loading
        ? const Center(child: CircularProgressIndicator())
        : _complaint == null
          ? const Center(child: Text('Failed to load'))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _infoCard(),
                const SizedBox(height: 16),
                _manageCard(),
                const SizedBox(height: 16),
                _notesCard(),
                const SizedBox(height: 16),
                _aiCard(),
                const SizedBox(height: 16),
                _historyCard(),
                const SizedBox(height: 24),
                CustomButton(label: 'Save Changes', isLoading: _saving, onPressed: _save),
                const SizedBox(height: 32),
              ]),
            ),
    );
  }

  Widget _infoCard() {
    final c = _complaint!;
    final color = AppTheme.getCategoryColor(c.category);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(12)),
            child: Icon(AppTheme.getCategoryIcon(c.category), color: color, size: 22)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(AppConstants.categoryLabels[c.category] ?? c.category,
              style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
            Text(c.title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
          ])),
        ]),
        const Divider(height: 24),
        _row(Icons.person_outline, 'Citizen', c.submittedByName ?? '-'),
        _row(Icons.phone_outlined, 'Phone', c.submittedByPhone ?? '-'),
        _row(Icons.location_on_outlined, 'Location', c.locationText.isEmpty ? '-' : c.locationText),
        _row(Icons.access_time, 'Submitted', DateFormat('MMM dd, yyyy • hh:mm a').format(c.createdAt.toLocal())),
        if (c.slaDeadline != null)
          _row(Icons.schedule_outlined, 'SLA Deadline',
            DateFormat('MMM dd, yyyy').format(c.slaDeadline!.toLocal()),
            valueColor: c.isSlaBreached ? AppColors.error : null),
        const SizedBox(height: 8),
        Text(c.description, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.6)),
        if (c.imageUrl != null) ...[
          const SizedBox(height: 12),
          ClipRRect(borderRadius: BorderRadius.circular(10),
            child: Image.network(c.imageUrl!, height: 160, width: double.infinity, fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const SizedBox.shrink())),
        ],
      ]),
    );
  }

  Widget _manageCard() => Container(
    padding: const EdgeInsets.all(20),
    decoration: _cardDecoration(),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Row(children: [
        Icon(Icons.manage_accounts_outlined, color: AppColors.primary, size: 20),
        SizedBox(width: 8),
        Text('Manage Complaint', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
      ]),
      const SizedBox(height: 16),
      DropdownButtonFormField<String>(
        value: _selectedStatus,
        decoration: const InputDecoration(labelText: 'Update Status'),
        items: AppConstants.statusLabels.entries.map((e) =>
          DropdownMenuItem(value: e.key, child: Row(children: [
            Container(width: 8, height: 8, decoration: BoxDecoration(
              color: AppTheme.getStatusColor(e.key), shape: BoxShape.circle)),
            const SizedBox(width: 8),
            Text(e.value),
          ]))).toList(),
        onChanged: (v) => setState(() => _selectedStatus = v),
      ),
      const SizedBox(height: 12),
      DropdownButtonFormField<String>(
        value: _selectedPriority,
        decoration: const InputDecoration(labelText: 'Set Priority'),
        items: AppConstants.priorityLabels.entries.map((e) =>
          DropdownMenuItem(value: e.key, child: Text(e.value))).toList(),
        onChanged: (v) => setState(() => _selectedPriority = v),
      ),
      const SizedBox(height: 12),
      DropdownButtonFormField<int>(
        value: _selectedDeptId,
        decoration: const InputDecoration(labelText: 'Assign Department'),
        items: [
          const DropdownMenuItem(value: null, child: Text('Unassigned')),
          ..._departments.map((d) => DropdownMenuItem(value: d.id, child: Text(d.name))),
        ],
        onChanged: (v) => setState(() => _selectedDeptId = v),
      ),
    ]),
  );

  Widget _notesCard() => Container(
    padding: const EdgeInsets.all(20),
    decoration: _cardDecoration(),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Row(children: [
        Icon(Icons.note_outlined, color: AppColors.primary, size: 20),
        SizedBox(width: 8),
        Text('Notes', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
      ]),
      const SizedBox(height: 16),
      TextField(controller: _notesCtrl, maxLines: 3,
        decoration: const InputDecoration(labelText: 'Admin Notes', hintText: 'Internal notes...')),
      const SizedBox(height: 12),
      TextField(controller: _resolutionCtrl, maxLines: 3,
        decoration: const InputDecoration(labelText: 'Resolution Notes',
          hintText: 'Visible to citizen upon resolution...')),
    ]),
  );

  Widget _aiCard() {
    final c = _complaint!;
    if (c.aiPredictedCategory.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.psychology_outlined, color: AppColors.accent, size: 20),
          const SizedBox(width: 8),
          const Text('AI Prediction', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
          const Spacer(),
          Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(color: AppColors.accent.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
            child: Text('${(c.aiConfidence * 100).toStringAsFixed(0)}% confident',
              style: const TextStyle(color: AppColors.accent, fontSize: 11, fontWeight: FontWeight.w600))),
        ]),
        const SizedBox(height: 10),
        _row(Icons.category_outlined, 'Category', AppConstants.categoryLabels[c.aiPredictedCategory] ?? c.aiPredictedCategory),
        if (c.aiPredictedDepartment.isNotEmpty)
          _row(Icons.business_outlined, 'Department', c.aiPredictedDepartment),
      ]),
    );
  }

  Widget _historyCard() {
    final history = _complaint!.statusHistory;
    if (history.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Row(children: [
          Icon(Icons.timeline, color: AppColors.primary, size: 20),
          SizedBox(width: 8),
          Text('Status History', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
        ]),
        const SizedBox(height: 12),
        ...history.map((h) {
          final color = AppTheme.getStatusColor(h.newStatus);
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(children: [
              Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(AppConstants.statusLabels[h.newStatus] ?? h.newStatus,
                  style: TextStyle(fontWeight: FontWeight.w600, color: color, fontSize: 13)),
                if (h.notes.isNotEmpty)
                  Text(h.notes, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                Text(DateFormat('MMM dd, hh:mm a').format(h.timestamp.toLocal()),
                  style: const TextStyle(fontSize: 11, color: AppColors.textHint)),
              ])),
            ]),
          );
        }),
      ]),
    );
  }

  Widget _row(IconData icon, String label, String value, {Color? valueColor}) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Row(children: [
      Icon(icon, size: 14, color: AppColors.textHint),
      const SizedBox(width: 6),
      Text('$label: ', style: const TextStyle(fontSize: 12, color: AppColors.textHint)),
      Expanded(child: Text(value, style: TextStyle(fontSize: 12,
        color: valueColor ?? AppColors.textPrimary, fontWeight: FontWeight.w500))),
    ]),
  );

  BoxDecoration _cardDecoration() => BoxDecoration(
    color: Colors.white, borderRadius: BorderRadius.circular(16),
    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
  );
}
