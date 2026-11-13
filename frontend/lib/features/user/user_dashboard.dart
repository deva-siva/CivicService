import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/complaint_provider.dart';
import '../../services/api_service.dart';
import '../../models/complaint_model.dart';
import 'complaint_detail_screen.dart';
import 'register_complaint_screen.dart';

class UserDashboard extends StatefulWidget {
  final VoidCallback? onViewAll;
  const UserDashboard({super.key, this.onViewAll});
  @override
  State<UserDashboard> createState() => _UserDashboardState();
}

class _UserDashboardState extends State<UserDashboard> with WidgetsBindingObserver {
  Timer? _pollTimer;
  bool _hasDoneFirstLoad = false;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _load(silent: true);
  }

  Future<void> _load({bool silent = false}) async {
    if (!silent && mounted) setState(() => _loading = true);
    final cp = context.read<ComplaintProvider>();
    try {
      await Future.wait([cp.loadDashboard(), cp.loadNotificationCount()]);
    } catch (_) {}
    if (!mounted) return;
    if (_loading && mounted) setState(() => _loading = false);
    if (!_hasDoneFirstLoad) setState(() => _hasDoneFirstLoad = true);
    _schedulePoll();
  }

  void _schedulePoll() {
    _pollTimer?.cancel();
    _pollTimer = Timer(const Duration(seconds: 30), () => _load(silent: true));
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final cp = context.watch<ComplaintProvider>();
    final user = auth.user;
    final dashboard = cp.dashboard;
    final recent = (dashboard['recent'] as List? ?? [])
        .map((e) => ComplaintModel.fromJson(e))
        .toList();
    final notifCount = cp.notificationCount;

    if (_loading && !_hasDoneFirstLoad) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Row(children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.primary.withOpacity(0.1),
            child: Text(
              user?.displayName.isNotEmpty == true
                  ? user!.displayName[0].toUpperCase()
                  : 'U',
              style: const TextStyle(
                  color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 15),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Hi, ${user?.displayName.split(' ').first ?? 'User'}',
              style: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ]),
        actions: [
          Stack(alignment: Alignment.topRight, children: [
            IconButton(
              icon: const Icon(Icons.notifications_outlined, color: AppColors.textPrimary),
              onPressed: () => _showNotificationsPanel(context),
            ),
            if (notifCount > 0)
              Positioned(
                top: 10, right: 10,
                child: Container(
                  width: 14, height: 14,
                  decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                  child: Center(
                    child: Text(
                      notifCount > 9 ? '9+' : '$notifCount',
                      style: const TextStyle(color: Colors.white, fontSize: 7, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
          ]),
          const SizedBox(width: 4),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: const Color(0xFFE8ECF0)),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () => _load(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Section: Stats
            const Text('Overview',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary, letterSpacing: 0.5)),
            const SizedBox(height: 10),
            _statsRow(dashboard),
            const SizedBox(height: 20),

            // Section: Map
            const Text('Complaint Map',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary, letterSpacing: 0.5)),
            const SizedBox(height: 10),
            _mapCard(context),
            const SizedBox(height: 20),

            // Section: Recent
            Row(children: [
              const Expanded(
                child: Text('Recent Complaints',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary, letterSpacing: 0.5)),
              ),
              TextButton(
                onPressed: widget.onViewAll,
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text('View All', style: TextStyle(fontSize: 12)),
              ),
            ]),
            const SizedBox(height: 8),

            if (cp.loading && recent.isEmpty)
              const Padding(padding: EdgeInsets.all(32), child: Center(child: CircularProgressIndicator()))
            else if (recent.isEmpty)
              _emptyState()
            else
              ...recent.take(5).map((c) => _complaintCard(c)),

            const SizedBox(height: 24),
          ]),
        ),
      ),
    );
  }

  // ── Stats ────────────────────────────────────────────────────────────────────

  Widget _statsRow(Map<String, dynamic> dashboard) => Row(children: [
    _statCard('Active', dashboard['open'] ?? 0, Icons.folder_open_rounded, AppColors.primary),
    const SizedBox(width: 10),
    _statCard('In Progress', dashboard['in_progress'] ?? 0, Icons.pending_rounded, AppColors.warning),
    const SizedBox(width: 10),
    _statCard('Resolved', dashboard['resolved'] ?? 0, Icons.check_circle_outline_rounded, AppColors.success),
  ]);

  Widget _statCard(String label, int value, IconData icon, Color color) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE8ECF0)),
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(height: 6),
        Text('$value',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
        const SizedBox(height: 2),
        Text(label,
          style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
          textAlign: TextAlign.center),
      ]),
    ),
  );

  // ── Map ──────────────────────────────────────────────────────────────────────

  Widget _mapCard(BuildContext context) {
    final cp = context.watch<ComplaintProvider>();
    final pinned = (cp.dashboard['recent'] as List? ?? [])
        .map((e) => ComplaintModel.fromJson(e))
        .where((c) => c.latitude != null && c.longitude != null)
        .toList();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE8ECF0)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
          child: Row(children: [
            Expanded(
              child: Text(
                pinned.isEmpty ? 'No issues mapped yet' : '${pinned.length} issue(s) on map',
                style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
            ),
            TextButton.icon(
              onPressed: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const RegisterComplaintScreen())),
              icon: const Icon(Icons.add, size: 14),
              label: const Text('Report', style: TextStyle(fontSize: 12)),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                padding: const EdgeInsets.symmetric(horizontal: 4),
              ),
            ),
          ]),
        ),
        ClipRRect(
          borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
          child: SizedBox(height: 200, child: _GoogleMapWidget(complaints: pinned)),
        ),
      ]),
    );
  }

  // ── Complaint card ───────────────────────────────────────────────────────────

  Widget _complaintCard(ComplaintModel c) {
    final statusColor = AppTheme.getStatusColor(c.status);
    final catIcon = AppTheme.getCategoryIcon(c.category);
    final catColor = AppTheme.getCategoryColor(c.category);
    final dateStr = DateFormat('MMM dd, yyyy').format(c.createdAt);
    final statusLabel = c.status.replaceAll('_', ' ').split(' ')
        .map((w) => w.isEmpty ? '' : '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE8ECF0)),
      ),
      child: InkWell(
        onTap: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => ComplaintDetailScreen(complaintId: c.id))),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: catColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(catIcon, color: catColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Text('#${c.id}',
                    style: const TextStyle(fontSize: 11, color: AppColors.textHint)),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(statusLabel,
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: statusColor)),
                  ),
                ]),
                const SizedBox(height: 4),
                Text(c.title.isNotEmpty ? c.title : c.description,
                  maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary)),
                const SizedBox(height: 4),
                Row(children: [
                  const Icon(Icons.location_on_outlined, size: 12, color: AppColors.textHint),
                  const SizedBox(width: 2),
                  Expanded(
                    child: Text(c.locationText.split(',').first,
                      style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                      overflow: TextOverflow.ellipsis),
                  ),
                  Text(dateStr,
                    style: const TextStyle(fontSize: 10, color: AppColors.textHint)),
                ]),
              ]),
            ),
          ]),
        ),
      ),
    );
  }

  // ── Empty state ──────────────────────────────────────────────────────────────

  Widget _emptyState() => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: const Color(0xFFE8ECF0)),
    ),
    child: Column(children: [
      Icon(Icons.inbox_outlined, size: 48, color: Colors.grey.shade300),
      const SizedBox(height: 12),
      const Text('No complaints yet',
        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
      const SizedBox(height: 4),
      const Text('Tap "Report" to submit a civic issue',
        style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
    ]),
  );

  // ── Notifications panel ──────────────────────────────────────────────────────

  void _showNotificationsPanel(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      isScrollControlled: true,
      builder: (_) => _NotificationsSheet(),
    );
  }
}

// ── Notifications sheet ─────────────────────────────────────────────────────────

class _NotificationsSheet extends StatefulWidget {
  @override
  State<_NotificationsSheet> createState() => _NotificationsSheetState();
}

class _NotificationsSheetState extends State<_NotificationsSheet> {
  List<dynamic> _notifications = [];
  bool _loading = true;
  final _api = ApiService();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await _api.getNotifications();
      if (mounted) setState(() { _notifications = data; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _markAllRead() async {
    try {
      await _api.markNotificationRead(null);
      await _load();
      if (mounted) context.read<ComplaintProvider>().loadNotificationCount();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      maxChildSize: 0.9,
      builder: (_, controller) => Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 8, 0),
          child: Row(children: [
            const Expanded(child: Text('Notifications',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold))),
            TextButton(onPressed: _markAllRead, child: const Text('Mark all read')),
          ]),
        ),
        const Divider(),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _notifications.isEmpty
                  ? const Center(child: Text('No notifications',
                      style: TextStyle(color: AppColors.textHint)))
                  : ListView.separated(
                      controller: controller,
                      itemCount: _notifications.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (_, i) {
                        final n = _notifications[i];
                        final isRead = n['is_read'] == true;
                        final complaintId = n['related_complaint'];
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: isRead
                                ? Colors.grey.shade100
                                : AppColors.primary.withOpacity(0.1),
                            child: Icon(Icons.notifications_rounded,
                              color: isRead ? AppColors.textHint : AppColors.primary, size: 18),
                          ),
                          title: Text(n['title'] ?? '',
                            style: TextStyle(fontSize: 13,
                              fontWeight: isRead ? FontWeight.normal : FontWeight.w600)),
                          subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(n['body'] ?? '', style: const TextStyle(fontSize: 12)),
                            Text(
                              n['created_at'] != null
                                  ? DateFormat('MMM dd, hh:mm a')
                                      .format(DateTime.parse(n['created_at']).toLocal())
                                  : '',
                              style: const TextStyle(fontSize: 10, color: AppColors.textHint),
                            ),
                          ]),
                          onTap: complaintId != null
                              ? () {
                                  Navigator.pop(context);
                                  Navigator.push(context, MaterialPageRoute(
                                    builder: (_) => ComplaintDetailScreen(complaintId: complaintId),
                                  ));
                                }
                              : null,
                          tileColor: isRead ? null : AppColors.primary.withOpacity(0.03),
                        );
                      },
                    ),
        ),
      ]),
    );
  }
}

// ── Google Map Widget ───────────────────────────────────────────────────────────

class _GoogleMapWidget extends StatefulWidget {
  final List<ComplaintModel> complaints;
  const _GoogleMapWidget({required this.complaints});

  @override
  State<_GoogleMapWidget> createState() => _GoogleMapWidgetState();
}

class _GoogleMapWidgetState extends State<_GoogleMapWidget> {
  static const _defaultCenter = LatLng(20.5937, 78.9629);

  LatLng get _initialCenter {
    for (final c in widget.complaints) {
      if (c.latitude != null && c.longitude != null) {
        return LatLng(c.latitude!, c.longitude!);
      }
    }
    return _defaultCenter;
  }

  Set<Marker> get _markers => widget.complaints
      .where((c) => c.latitude != null && c.longitude != null)
      .map((c) => Marker(
            markerId: MarkerId('complaint_${c.id}'),
            position: LatLng(c.latitude!, c.longitude!),
            infoWindow: InfoWindow(title: '#${c.id}', snippet: c.title),
          ))
      .toSet();

  @override
  Widget build(BuildContext context) {
    return GoogleMap(
      initialCameraPosition: CameraPosition(
        target: _initialCenter,
        zoom: widget.complaints.isEmpty ? 4.5 : 13.0,
      ),
      markers: _markers,
      myLocationButtonEnabled: false,
      zoomControlsEnabled: false,
      liteModeEnabled: false,
    );
  }
}
