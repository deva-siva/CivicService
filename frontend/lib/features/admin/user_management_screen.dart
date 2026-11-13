import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../../models/user_model.dart';
import '../../services/api_service.dart';
import '../../widgets/common/custom_button.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});
  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  final _api = ApiService();
  List<UserModel> _citizens = [];
  bool _loading = true;
  final _searchCtrl = TextEditingController();
  String? _filterStatus; // 'active' | 'inactive' | null

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
    try {
      final data = await _api.getUsers(role: 'citizen');
      final raw = data is Map ? (data['results'] ?? []) : data as List;
      _citizens = raw.map<UserModel>((u) => UserModel.fromJson(u)).toList();
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  List<UserModel> get _filtered {
    var list = _citizens;
    if (_filterStatus == 'active') {
      list = list.where((u) => u.isActive).toList();
    } else if (_filterStatus == 'inactive') {
      list = list.where((u) => !u.isActive).toList();
    }
    final q = _searchCtrl.text.trim().toLowerCase();
    if (q.isNotEmpty) {
      list = list.where((u) =>
          u.displayName.toLowerCase().contains(q) ||
          u.email.toLowerCase().contains(q) ||
          u.phone.contains(q)).toList();
    }
    return list;
  }

  Future<void> _toggleUser(UserModel user) async {
    await _api.updateUser(user.id, {'is_active': !user.isActive});
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    final activeCount = _citizens.where((u) => u.isActive).length;
    final inactiveCount = _citizens.length - activeCount;

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
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Column(
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
                            'Citizens',
                            style: GoogleFonts.outfit(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ],
                      ),
                      GestureDetector(
                        onTap: () => _showAddCitizenSheet(context),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 3)),
                            ],
                          ),
                          child: const Icon(Icons.person_add_rounded, color: Colors.white, size: 20),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.black.withOpacity(0.05)),
                    ),
                    child: TextField(
                      controller: _searchCtrl,
                      onChanged: (_) => setState(() {}),
                      style: GoogleFonts.outfit(fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'Search by name, email or phone...',
                        hintStyle: GoogleFonts.outfit(color: AppColors.textHint.withOpacity(0.5), fontSize: 13),
                        prefixIcon: Icon(Icons.search_rounded, color: AppColors.textHint.withOpacity(0.5), size: 20),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 12),
                        suffixIcon: _searchCtrl.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear_rounded, size: 18),
                                onPressed: () { _searchCtrl.clear(); setState(() {}); })
                            : null,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: AppColors.primary))
          : Column(
              children: [
                _buildSummaryRow(activeCount, inactiveCount),
                Expanded(
                  child: filtered.isEmpty
                      ? _buildEmptyState()
                      : RefreshIndicator(
                          color: AppColors.primary,
                          onRefresh: _load,
                          child: ListView.builder(
                            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                            itemCount: filtered.length,
                            itemBuilder: (_, i) => _CitizenCard(
                              user: filtered[i],
                              onToggle: () => _toggleUser(filtered[i]),
                              onView: () => _showUserDetail(context, filtered[i]),
                            ),
                          ),
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildSummaryRow(int active, int inactive) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          _filterPill('All Citizens', _citizens.length, null, AppColors.primary),
          const SizedBox(width: 8),
          _filterPill('Active', active, 'active', AppColors.success),
          const SizedBox(width: 8),
          _filterPill('Inactive', inactive, 'inactive', AppColors.error),
        ],
      ),
    );
  }

  Widget _filterPill(String label, int count, String? val, Color color) {
    final active = _filterStatus == val;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _filterStatus = val),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: active ? color : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: active ? color : Colors.black.withOpacity(0.05)),
            boxShadow: active ? [
              BoxShadow(color: color.withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 4)),
            ] : null,
          ),
          child: Column(
            children: [
              Text(
                '$count',
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: active ? Colors.white : AppColors.textPrimary,
                ),
              ),
              Text(
                label,
                style: GoogleFonts.outfit(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: active ? Colors.white.withOpacity(0.8) : AppColors.textHint,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline_rounded, size: 64, color: AppColors.textHint.withOpacity(0.2)),
          const SizedBox(height: 16),
          Text(
            _searchCtrl.text.isNotEmpty ? 'No matches found' : 'No citizens registered',
            style: GoogleFonts.outfit(color: AppColors.textHint, fontSize: 16),
          ),
        ],
      ),
    );
  }

  void _showUserDetail(BuildContext context, UserModel user) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.black.withOpacity(0.1), borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 32),
            CircleAvatar(
              radius: 40,
              backgroundColor: user.isActive ? AppColors.success.withOpacity(0.1) : AppColors.error.withOpacity(0.1),
              child: Text(
                user.displayName.isNotEmpty ? user.displayName[0].toUpperCase() : 'U',
                style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.bold, color: user.isActive ? AppColors.success : AppColors.error),
              ),
            ),
            const SizedBox(height: 16),
            Text(user.displayName, style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
            Text(user.email, style: GoogleFonts.outfit(fontSize: 14, color: AppColors.textSecondary)),
            if (user.phone.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(user.phone, style: GoogleFonts.outfit(fontSize: 13, color: AppColors.textHint, fontWeight: FontWeight.w500)),
            ],
            const SizedBox(height: 32),
            _detailRow(Icons.cake_rounded, 'Member Since', 'Oct 2023'), // Placeholder for joins date
            _detailRow(Icons.verified_user_rounded, 'Account Status', user.isActive ? 'Active' : 'Restricted'),
            const SizedBox(height: 32),
            Row(children: [
              Expanded(child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: Text('Close', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
              )),
              const SizedBox(width: 12),
              Expanded(child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _toggleUser(user);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: user.isActive ? AppColors.error : AppColors.success,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: Text(user.isActive ? 'Deactivate' : 'Activate', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
              )),
            ]),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String val) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(children: [
        Icon(icon, size: 18, color: AppColors.textHint),
        const SizedBox(width: 12),
        Text(label, style: GoogleFonts.outfit(fontSize: 14, color: AppColors.textSecondary)),
        const Spacer(),
        Text(val, style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
      ]),
    );
  }

  void _showAddCitizenSheet(BuildContext context) {
    final emailCtrl = TextEditingController();
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final passCtrl = TextEditingController();
    bool saving = false;
    bool obscure = true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
          ),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
            left: 24, right: 24, top: 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.black.withOpacity(0.1), borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 24),
              Text('Register Citizen', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('Create a new account for grievance submission', style: GoogleFonts.outfit(fontSize: 13, color: AppColors.textHint)),
              const SizedBox(height: 24),
              _textField(nameCtrl, 'Full Name', Icons.person_outline_rounded),
              const SizedBox(height: 16),
              _textField(emailCtrl, 'Email Address', Icons.alternate_email_rounded, kbd: TextInputType.emailAddress),
              const SizedBox(height: 16),
              _textField(phoneCtrl, 'Mobile Number', Icons.phone_android_rounded, kbd: TextInputType.phone, prefix: '+91 '),
              const SizedBox(height: 16),
              _textField(passCtrl, 'Password', Icons.lock_outline_rounded, obscure: obscure, 
                suffix: IconButton(icon: Icon(obscure ? Icons.visibility_off_rounded : Icons.visibility_rounded, size: 20), onPressed: () => setModal(() => obscure = !obscure))),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: CustomButton(
                  label: 'Complete Registration',
                  isLoading: saving,
                  onPressed: () async {
                    if (nameCtrl.text.isEmpty || emailCtrl.text.isEmpty || passCtrl.text.isEmpty) return;
                    setModal(() => saving = true);
                    try {
                      await _api.createStaff({
                        'full_name': nameCtrl.text.trim(),
                        'email': emailCtrl.text.trim(),
                        'phone': phoneCtrl.text.trim(),
                        'password': passCtrl.text,
                        'role': 'citizen',
                      });
                      if (ctx.mounted) Navigator.pop(ctx);
                      _load();
                    } catch (_) { setModal(() => saving = false); }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _textField(TextEditingController ctrl, String label, IconData icon, {bool obscure = false, TextInputType? kbd, String? prefix, Widget? suffix}) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withOpacity(0.04)),
      ),
      child: TextField(
        controller: ctrl,
        obscureText: obscure,
        keyboardType: kbd,
        style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.outfit(color: AppColors.textHint, fontSize: 13),
          prefixIcon: Icon(icon, size: 20, color: AppColors.textHint),
          prefixText: prefix,
          suffixIcon: suffix,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }
}

class _CitizenCard extends StatelessWidget {
  final UserModel user;
  final VoidCallback onToggle;
  final VoidCallback onView;

  const _CitizenCard({required this.user, required this.onToggle, required this.onView});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black.withOpacity(0.04)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: InkWell(
        onTap: onView,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: user.isActive ? AppColors.primary.withOpacity(0.08) : Colors.grey.withOpacity(0.08),
                child: Text(
                  user.displayName.isNotEmpty ? user.displayName[0].toUpperCase() : 'U',
                  style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: user.isActive ? AppColors.primary : Colors.grey),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(user.displayName, style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary), overflow: TextOverflow.ellipsis),
                        ),
                        _statusBadge(user.isActive),
                      ],
                    ),
                    Text(user.email, style: GoogleFonts.outfit(fontSize: 12, color: AppColors.textSecondary), overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: onToggle,
                icon: Icon(user.isActive ? Icons.block_rounded : Icons.check_circle_rounded, size: 20, color: user.isActive ? AppColors.error.withOpacity(0.7) : AppColors.success),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statusBadge(bool active) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: active ? AppColors.success.withOpacity(0.08) : AppColors.error.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        active ? 'Active' : 'Inactive',
        style: GoogleFonts.outfit(fontSize: 9, fontWeight: FontWeight.bold, color: active ? AppColors.success : AppColors.error),
      ),
    );
  }
}
