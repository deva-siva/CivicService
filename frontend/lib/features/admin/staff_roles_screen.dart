import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../../services/api_service.dart';
import '../../models/user_model.dart';
import '../../widgets/common/custom_button.dart';

// ─── LOCAL MODELS ─────────────────────────────────────────────────────────────

class RoleModel {
  final int id;
  final String name;
  final String description;
  final List<PermissionModel> permissions;
  final int staffCount;

  RoleModel({required this.id, required this.name, this.description = '',
      this.permissions = const [], this.staffCount = 0});

  factory RoleModel.fromJson(Map<String, dynamic> j) => RoleModel(
        id: j['id'] ?? 0,
        name: j['name'] ?? '',
        description: j['description'] ?? '',
        staffCount: j['staff_count'] ?? 0,
        permissions: ((j['permissions'] as List?) ?? [])
            .map((p) => PermissionModel.fromJson(p))
            .toList(),
      );
}

class PermissionModel {
  final int id;
  final String codename;
  final String name;

  const PermissionModel(
      {required this.id, required this.codename, required this.name});

  factory PermissionModel.fromJson(Map<String, dynamic> j) => PermissionModel(
        id: j['id'] ?? 0,
        codename: j['codename'] ?? '',
        name: j['name'] ?? '',
      );
}

class DeptModel {
  final int id;
  final String name;
  DeptModel({required this.id, required this.name});
  factory DeptModel.fromJson(Map<String, dynamic> j) =>
      DeptModel(id: j['id'] ?? 0, name: j['name'] ?? '');
}

// ─── PERMISSION GROUPS ────────────────────────────────────────────────────────

const _permGroups = {
  'Complaints': {
    'icon': Icons.report_problem_rounded,
    'codenames': ['view_complaints', 'manage_complaints', 'escalate_complaints'],
  },
  'People': {
    'icon': Icons.people_rounded,
    'codenames': ['manage_users', 'manage_staff'],
  },
  'Platform': {
    'icon': Icons.settings_rounded,
    'codenames': ['manage_departments', 'manage_roles'],
  },
  'Reports': {
    'icon': Icons.show_chart_rounded,
    'codenames': ['view_analytics', 'export_reports', 'send_notifications'],
  },
};

// ─── MAIN SCREEN ──────────────────────────────────────────────────────────────

class StaffRolesScreen extends StatefulWidget {
  const StaffRolesScreen({super.key});
  @override
  State<StaffRolesScreen> createState() => _StaffRolesScreenState();
}

class _StaffRolesScreenState extends State<StaffRolesScreen> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  final _api = ApiService();

  List<RoleModel> _roles = [];
  List<PermissionModel> _permissions = [];
  List<DeptModel> _departments = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final rolesData = await _api.getRoles();
      _roles = rolesData.map((r) => RoleModel.fromJson(r)).toList();
      
      final permsData = await _api.getPermissions();
      _permissions = permsData.map((p) => PermissionModel.fromJson(p)).toList();
      
      final deptsData = await _api.getDepartments();
      _departments = deptsData.map((d) => DeptModel.fromJson(d)).toList();
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        toolbarHeight: 120,
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
                            'Administrative',
                            style: GoogleFonts.outfit(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        onPressed: _load,
                        icon: const Icon(Icons.refresh_rounded, color: AppColors.textHint, size: 20),
                      ),
                    ],
                  ),
                  const Spacer(),
                  TabBar(
                    controller: _tabCtrl,
                    indicatorColor: AppColors.primary,
                    indicatorWeight: 3,
                    indicatorSize: TabBarIndicatorSize.label,
                    dividerColor: Colors.transparent,
                    labelColor: AppColors.primary,
                    unselectedLabelColor: AppColors.textHint,
                    labelStyle: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14),
                    unselectedLabelStyle: GoogleFonts.outfit(fontWeight: FontWeight.w500, fontSize: 14),
                    tabs: const [
                      Tab(text: 'Access Roles'),
                      Tab(text: 'Staff Members'),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      floatingActionButton: AnimatedBuilder(
        animation: _tabCtrl,
        builder: (_, __) => FloatingActionButton.extended(
          elevation: 2,
          backgroundColor: AppColors.primary,
          splashColor: Colors.white.withOpacity(0.1),
          icon: const Icon(Icons.add_rounded, color: Colors.white),
          label: Text(
            _tabCtrl.index == 0 ? 'Create Role' : 'Assign Staff',
            style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white),
          ),
          onPressed: () => _tabCtrl.index == 0 ? _showRoleSheet() : _showAddStaffSheet(),
        ),
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: AppColors.primary))
          : TabBarView(
              controller: _tabCtrl,
              children: [
                _RolesTab(roles: _roles, permissions: _permissions, onEdit: _showRoleSheet, onDelete: _deleteRole),
                _StaffTab(api: _api, roles: _roles, departments: _departments, onRefresh: _load),
              ],
            ),
    );
  }

  Future<void> _deleteRole(RoleModel role) async {
    if (role.staffCount > 0) {
      _snack('Cannot delete role: ${role.staffCount} staff members active.', error: true);
      return;
    }
    final ok = await _showConfirmDialog('Delete Role', 'Are you sure you want to delete "${role.name}"?');
    if (ok == true) {
      await _api.deleteRole(role.id);
      _load();
    }
  }

  Future<bool?> _showConfirmDialog(String title, String body) {
    return showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(title, style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        content: Text(body, style: GoogleFonts.outfit()),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text('Cancel', style: GoogleFonts.outfit(color: AppColors.textHint))),
          TextButton(onPressed: () => Navigator.pop(context, true), child: Text('Confirm', style: GoogleFonts.outfit(color: AppColors.error, fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }

  void _showRoleSheet({RoleModel? role}) {
    final nameCtrl = TextEditingController(text: role?.name ?? '');
    final descCtrl = TextEditingController(text: role?.description ?? '');
    final selected = <int>{...?role?.permissions.map((p) => p.id)};
    bool saving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => Container(
          decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom + 24, left: 24, right: 24, top: 24),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.85),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.black.withOpacity(0.1), borderRadius: BorderRadius.circular(2)))),
                  const SizedBox(height: 24),
                  Text(role == null ? 'Create New Role' : 'Modify Role', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 24),
                  _textField(nameCtrl, 'Role Title', Icons.badge_outlined),
                  const SizedBox(height: 16),
                  _textField(descCtrl, 'Internal Description', Icons.description_outlined, lines: 2),
                  const SizedBox(height: 24),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Text('Permissions', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold)),
                    if (_permissions.isNotEmpty) TextButton(onPressed: () => setModal(() => selected.length == _permissions.length ? selected.clear() : selected.addAll(_permissions.map((p) => p.id))), child: Text(selected.length == _permissions.length ? 'Clear' : 'Select All')),
                  ]),
                  const SizedBox(height: 8),
                  if (_permissions.isEmpty) _buildEmptyPermissions(setModal),
                  ..._permGroups.entries.map((group) {
                    final groupPerms = _permissions.where((p) => (group.value['codenames'] as List).contains(p.codename)).toList();
                    if (groupPerms.isEmpty) return const SizedBox.shrink();
                    final groupSelected = groupPerms.every((p) => selected.contains(p.id));
                    return _PermissionGroupNode(
                      icon: group.value['icon'] as IconData,
                      title: group.key,
                      perms: groupPerms,
                      selected: selected,
                      allSelected: groupSelected,
                      onToggleGroup: (v) => setModal(() => v ? selected.addAll(groupPerms.map((p) => p.id)) : selected.removeAll(groupPerms.map((p) => p.id))),
                      onToggleItem: (id, v) => setModal(() => v ? selected.add(id) : selected.remove(id)),
                    );
                  }),
                  const SizedBox(height: 32),
                  CustomButton(
                    label: role == null ? 'Create Role' : 'Confirm Updates',
                    isLoading: saving,
                    onPressed: () async {
                      if (nameCtrl.text.trim().isEmpty) return;
                      setModal(() => saving = true);
                      try {
                        final payload = {'name': nameCtrl.text.trim(), 'description': descCtrl.text.trim(), 'permission_ids': selected.toList()};
                        if (role == null) await _api.createRole(payload);
                        else await _api.updateRole(role.id, payload);
                        if (ctx.mounted) Navigator.pop(ctx);
                        _load();
                      } catch (_) { setModal(() => saving = false); }
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyPermissions(StateSetter setModal) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.orange.withOpacity(0.08), borderRadius: BorderRadius.circular(16)),
      child: Column(children: [
        Text('No system permissions found. Sync your database.', style: GoogleFonts.outfit(color: Colors.orange.shade800, fontSize: 12)),
        TextButton(onPressed: () => _load().then((_) => setModal(() {})), child: Text('Try Refreshing')),
      ]),
    );
  }

  void _showAddStaffSheet() {
    final nameCtrl = TextEditingController(), emailCtrl = TextEditingController(), phoneCtrl = TextEditingController(), passCtrl = TextEditingController();
    RoleModel? selRole; DeptModel? selDept;
    bool saving = false, obscure = true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => Container(
          decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom + 24, left: 24, right: 24, top: 24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.black.withOpacity(0.1), borderRadius: BorderRadius.circular(2)))),
                const SizedBox(height: 24),
                Text('Add Staff Member', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text('Invite a new administrator or field officer', style: GoogleFonts.outfit(fontSize: 13, color: AppColors.textHint)),
                const SizedBox(height: 24),
                _textField(nameCtrl, 'Full Name', Icons.person_outline_rounded),
                const SizedBox(height: 16),
                _textField(emailCtrl, 'Work Email', Icons.alternate_email_rounded, kbd: TextInputType.emailAddress),
                const SizedBox(height: 16),
                _textField(passCtrl, 'Initial Password', Icons.lock_outline_rounded, obscure: obscure, 
                  suffix: IconButton(icon: Icon(obscure ? Icons.visibility_off_rounded : Icons.visibility_rounded, size: 20), onPressed: () => setModal(() => obscure = !obscure))),
                const SizedBox(height: 24),
                Row(children: [
                  Expanded(child: _buildDropdown<DeptModel>('Department', selDept, _departments.map((d) => DropdownMenuItem(value: d, child: Text(d.name, style: GoogleFonts.outfit(fontSize: 14)))).toList(), (v) => setModal(() => selDept = v))),
                  const SizedBox(width: 12),
                  Expanded(child: _buildDropdown<RoleModel>('Access Role', selRole, _roles.map((r) => DropdownMenuItem(value: r, child: Text(r.name, style: GoogleFonts.outfit(fontSize: 14)))).toList(), (v) => setModal(() => selRole = v))),
                ]),
                const SizedBox(height: 32),
                CustomButton(
                  label: 'Complete Assignment',
                  isLoading: saving,
                  onPressed: () async {
                    if (nameCtrl.text.isEmpty || emailCtrl.text.isEmpty || passCtrl.text.isEmpty || selRole == null) return;
                    setModal(() => saving = true);
                    try {
                      await _api.createStaff({
                        'full_name': nameCtrl.text.trim(), 'email': emailCtrl.text.trim(), 'phone': phoneCtrl.text.trim(),
                        'password': passCtrl.text, 'role_id': selRole!.id, if (selDept != null) 'department_id': selDept!.id,
                      });
                      if (ctx.mounted) Navigator.pop(ctx);
                      _load();
                    } catch (_) { setModal(() => saving = false); }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDropdown<T>(String label, T? val, List<DropdownMenuItem<T>> items, ValueChanged<T?> onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.black.withOpacity(0.04))),
      child: DropdownButton<T>(
        value: val, isExpanded: true, underline: const SizedBox(), hint: Text(label, style: GoogleFonts.outfit(fontSize: 13, color: AppColors.textHint)),
        items: items, onChanged: onChanged,
      ),
    );
  }

  Widget _textField(TextEditingController ctrl, String label, IconData icon, {bool obscure = false, int lines = 1, TextInputType? kbd, String? prefix, Widget? suffix}) {
    return Container(
      decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.black.withOpacity(0.04))),
      child: TextField(
        controller: ctrl, obscureText: obscure, maxLines: lines, keyboardType: kbd, style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          labelText: label, labelStyle: GoogleFonts.outfit(color: AppColors.textHint, fontSize: 13),
          prefixIcon: Icon(icon, size: 20, color: AppColors.textHint), prefixText: prefix, suffixIcon: suffix,
          border: InputBorder.none, contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }

  void _snack(String msg, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: error ? AppColors.error : AppColors.success));
  }
}

// ─── ROLES TAB ────────────────────────────────────────────────────────────────

class _RolesTab extends StatelessWidget {
  final List<RoleModel> roles;
  final List<PermissionModel> permissions;
  final void Function({RoleModel? role}) onEdit;
  final Future<void> Function(RoleModel) onDelete;

  const _RolesTab({required this.roles, required this.permissions, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    if (roles.isEmpty) return _emptyState(Icons.admin_panel_settings_rounded, 'No Access Roles', 'Create roles to manage staff permissions.');
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: roles.length,
      itemBuilder: (_, i) => _RoleCard(role: roles[i], onEdit: () => onEdit(role: roles[i]), onDelete: () => onDelete(roles[i])),
    );
  }

  Widget _emptyState(IconData icon, String title, String sub) => Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
    Icon(icon, size: 64, color: AppColors.textHint.withOpacity(0.2)),
    const SizedBox(height: 16),
    Text(title, style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
    Text(sub, style: GoogleFonts.outfit(fontSize: 13, color: AppColors.textHint)),
  ]));
}

class _RoleCard extends StatelessWidget {
  final RoleModel role;
  final VoidCallback onEdit, onDelete;
  const _RoleCard({required this.role, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.black.withOpacity(0.04)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))]),
      child: InkWell(
        onTap: onEdit, borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.08), borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.security_rounded, color: AppColors.primary, size: 20)),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(role.name, style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                Text('${role.permissions.length} Global Permissions', style: GoogleFonts.outfit(fontSize: 12, color: AppColors.textHint)),
              ])),
              PopupMenuButton<String>(
                onSelected: (v) => v == 'e' ? onEdit() : onDelete(),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                itemBuilder: (_) => [
                  PopupMenuItem(value: 'e', child: Text('Edit Role', style: GoogleFonts.outfit(fontSize: 14))),
                  PopupMenuItem(value: 'd', child: Text('Delete', style: GoogleFonts.outfit(fontSize: 14, color: AppColors.error))),
                ],
              ),
            ]),
            const SizedBox(height: 20),
            Row(children: [
              _pill('${role.staffCount} Active Members', AppColors.primary),
              const Spacer(),
              Text('Detail Settings', style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary)),
              const SizedBox(width: 4),
              const Icon(Icons.arrow_forward_ios_rounded, size: 10, color: AppColors.primary),
            ]),
          ]),
        ),
      ),
    );
  }

  Widget _pill(String txt, Color c) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(color: c.withOpacity(0.08), borderRadius: BorderRadius.circular(8)),
    child: Text(txt, style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.bold, color: c)),
  );
}

// ─── STAFF TAB ────────────────────────────────────────────────────────────────

class _StaffTab extends StatefulWidget {
  final ApiService api;
  final List<RoleModel> roles;
  final List<DeptModel> departments;
  final VoidCallback onRefresh;
  const _StaffTab({required this.api, required this.roles, required this.departments, required this.onRefresh});

  @override
  State<_StaffTab> createState() => _StaffTabState();
}

class _StaffTabState extends State<_StaffTab> {
  List<UserModel> _staff = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await widget.api.getUsers(role: 'staff');
      final raw = data is Map ? (data['results'] ?? []) : data as List;
      _staff = raw.map<UserModel>((u) => UserModel.fromJson(u)).toList();
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return Center(child: CircularProgressIndicator(color: AppColors.primary));
    if (_staff.isEmpty) return _emptyState(Icons.badge_rounded, 'No Staff Members', 'Assign your first staff member to manage work.');
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: _staff.length,
        itemBuilder: (_, i) => _StaffCard(user: _staff[i], onToggle: () => _toggle(_staff[i])),
      ),
    );
  }

  Future<void> _toggle(UserModel u) async {
    await widget.api.updateUser(u.id, {'is_active': !u.isActive});
    _load();
  }

  Widget _emptyState(IconData icon, String title, String sub) => Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
    Icon(icon, size: 64, color: AppColors.textHint.withOpacity(0.2)),
    const SizedBox(height: 16),
    Text(title, style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
    Text(sub, style: GoogleFonts.outfit(fontSize: 13, color: AppColors.textHint)),
  ]));
}

class _StaffCard extends StatelessWidget {
  final UserModel user;
  final VoidCallback onToggle;
  const _StaffCard({required this.user, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.black.withOpacity(0.04))),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(children: [
          CircleAvatar(
            radius: 24, backgroundColor: user.isActive ? AppColors.primary.withOpacity(0.08) : Colors.grey.withOpacity(0.08),
            child: Text(user.displayName.isNotEmpty ? user.displayName[0] : 'S', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: user.isActive ? AppColors.primary : Colors.grey)),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(user.displayName, style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
            Text(user.email, style: GoogleFonts.outfit(fontSize: 12, color: AppColors.textHint)),
          ])),
          Switch.adaptive(value: user.isActive, activeColor: AppColors.success, onChanged: (_) => onToggle()),
        ]),
      ),
    );
  }
}

// ─── HELPERS ──────────────────────────────────────────────────────────────────

class _PermissionGroupNode extends StatelessWidget {
  final IconData icon; final String title; final List<PermissionModel> perms; final Set<int> selected; final bool allSelected;
  final ValueChanged<bool> onToggleGroup; final void Function(int, bool) onToggleItem;
  const _PermissionGroupNode({required this.icon, required this.title, required this.perms, required this.selected, required this.allSelected, required this.onToggleGroup, required this.onToggleItem});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(16)),
      child: ExpansionTile(
        leading: Icon(icon, color: AppColors.primary, size: 20),
        title: Text(title, style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.bold)),
        trailing: Checkbox(value: allSelected, onChanged: (v) => onToggleGroup(v ?? false), activeColor: AppColors.primary,),
        children: perms.map((p) => CheckboxListTile(
          value: selected.contains(p.id), onChanged: (v) => onToggleItem(p.id, v ?? false), activeColor: AppColors.success,
          title: Text(p.name, style: GoogleFonts.outfit(fontSize: 13)), dense: true,
        )).toList(),
      ),
    );
  }
}
