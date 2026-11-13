import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../auth/login_screen.dart';
import 'admin_dashboard.dart';
import 'all_complaints_screen.dart';
import 'manage_departments_screen.dart';
import 'analytics_screen.dart';
import 'user_management_screen.dart';
import 'staff_roles_screen.dart';

class AdminMainScreen extends StatefulWidget {
  const AdminMainScreen({super.key});
  @override
  State<AdminMainScreen> createState() => _AdminMainScreenState();
}

class _AdminMainScreenState extends State<AdminMainScreen> {
  int _currentIndex = 0;

  // 5 tabs: Dashboard | Complaints | Analytics | Users (citizens) | Staff & Roles
  final _pages = const [
    AdminDashboard(),
    AllComplaintsScreen(),
    AnalyticsScreen(),
    UserManagementScreen(),   // citizens only
    StaffRolesScreen(),        // staff list + role creation + permissions
  ];

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: IndexedStack(index: _currentIndex, children: _pages),
      drawer: _AdminDrawer(
          user: user,
          currentIndex: _currentIndex,
          onNavigate: (i) {
            Navigator.pop(context);
            setState(() => _currentIndex = i);
          }),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Container(
              height: 74,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.black.withOpacity(0.05)),
              ),
              child: BottomNavigationBar(
                currentIndex: _currentIndex,
                onTap: (i) => setState(() => _currentIndex = i),
                elevation: 0,
                backgroundColor: Colors.transparent,
                selectedItemColor: AppColors.primary,
                unselectedItemColor: AppColors.textHint.withOpacity(0.5),
                type: BottomNavigationBarType.fixed,
                showSelectedLabels: true,
                showUnselectedLabels: false,
                selectedLabelStyle: GoogleFonts.outfit(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
                items: [
                  _navItem(Icons.dashboard_outlined, Icons.dashboard_rounded, 'Home'),
                  _navItem(Icons.list_alt_outlined, Icons.list_alt_rounded, 'Feed'),
                  _navItem(Icons.bar_chart_outlined, Icons.bar_chart_rounded, 'Data'),
                  _navItem(Icons.people_outline_rounded, Icons.people_rounded, 'Users'),
                  _navItem(Icons.admin_panel_settings_outlined, Icons.admin_panel_settings_rounded, 'Admin'),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  BottomNavigationBarItem _navItem(IconData icon, IconData activeIcon, String label) {
    return BottomNavigationBarItem(
      icon: Icon(icon, size: 24),
      activeIcon: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(activeIcon, size: 24, color: AppColors.primary),
      ),
      label: label,
    );
  }
}

// ─── Admin Drawer ─────────────────────────────────────────────────────────────

class _AdminDrawer extends StatelessWidget {
  final dynamic user;
  final int currentIndex;
  final ValueChanged<int> onNavigate;

  const _AdminDrawer(
      {this.user, required this.currentIndex, required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(right: Radius.circular(32)),
      ),
      child: Column(children: [
        // ── Header ──
        UserAccountsDrawerHeader(
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: const BorderRadius.only(topRight: Radius.circular(32)),
          ),
          accountName: Text(
            user?.displayName ?? 'Admin',
            style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          accountEmail: Text(
            user?.email ?? '',
            style: GoogleFonts.outfit(color: Colors.white.withOpacity(0.8), fontSize: 13),
          ),
          currentAccountPicture: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withOpacity(0.2), width: 3),
            ),
            child: CircleAvatar(
              backgroundColor: Colors.white,
              backgroundImage: (user?.profilePic?.isNotEmpty == true)
                  ? NetworkImage(user!.profilePic!) as ImageProvider
                  : null,
              child: (user?.profilePic?.isEmpty ?? true)
                  ? Text(
                      user?.displayName?.isNotEmpty == true
                          ? user!.displayName[0].toUpperCase()
                          : 'A',
                      style: GoogleFonts.outfit(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 24))
                  : null,
            ),
          ),
        ),

        // ── Navigation ──
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text('WORKFLOW',
                style: GoogleFonts.outfit(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textHint,
                    letterSpacing: 2.0)),
          ),
        ),
        _drawerItem(context, 0, Icons.dashboard_rounded, 'Dashboard'),
        _drawerItem(context, 1, Icons.list_alt_rounded, 'All Complaints'),
        _drawerItem(context, 2, Icons.bar_chart_rounded, 'Analytics'),
        _drawerItem(context, 3, Icons.people_rounded, 'User Management'),
        _drawerItem(context, 4, Icons.admin_panel_settings_rounded, 'Staff & Roles'),

        const Divider(indent: 24, endIndent: 24),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text('CONTROL PANEL',
                style: GoogleFonts.outfit(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textHint,
                    letterSpacing: 2.0)),
          ),
        ),
        ListTile(
          leading: const Icon(Icons.person_outline_rounded, color: AppColors.primary),
          title: const Text('My Profile', style: TextStyle(fontSize: 14)),
          onTap: () {
            Navigator.pop(context);
            _showProfileSheet(context);
          },
        ),
        ListTile(
          leading: const Icon(Icons.lock_outline_rounded, color: AppColors.primary),
          title: const Text('Change Password', style: TextStyle(fontSize: 14)),
          onTap: () {
            Navigator.pop(context);
            _showChangePasswordSheet(context);
          },
        ),
        ListTile(
          leading: const Icon(Icons.business_outlined, color: AppColors.primary),
          title: const Text('Manage Departments', style: TextStyle(fontSize: 14)),
          onTap: () {
            Navigator.pop(context);
            Navigator.push(context,
                MaterialPageRoute(builder: (_) => const ManageDepartmentsScreen()));
          },
        ),

        const Spacer(),
        const Divider(),

        // ── Logout ──
        ListTile(
          leading: const Icon(Icons.logout_rounded, color: AppColors.error),
          title: const Text('Logout', style: TextStyle(color: AppColors.error, fontSize: 14)),
          onTap: () => _confirmLogout(context),
        ),
        const SizedBox(height: 16),
      ]),
    );
  }

  // ── Profile Sheet ────────────────────────────────────────────────────────────

  void _showProfileSheet(BuildContext context) {
    final auth = context.read<AuthProvider>();
    final nameCtrl = TextEditingController(text: auth.user?.fullName ?? '');
    final phoneCtrl = TextEditingController(text: auth.user?.phone ?? '');
    bool saving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => Padding(
          padding: EdgeInsets.fromLTRB(
              24, 16, 24, MediaQuery.of(ctx).viewInsets.bottom + 32),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Center(child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                  color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
            )),
            const SizedBox(height: 20),

            // Avatar + name
            Center(child: Column(children: [
              CircleAvatar(
                radius: 36,
                backgroundColor: AppColors.primary.withOpacity(0.12),
                backgroundImage: (auth.user?.profilePic?.isNotEmpty == true)
                    ? NetworkImage(auth.user!.profilePic!) as ImageProvider
                    : null,
                child: (auth.user?.profilePic?.isEmpty ?? true)
                    ? Text(
                        auth.user?.displayName.isNotEmpty == true
                            ? auth.user!.displayName[0].toUpperCase()
                            : 'A',
                        style: const TextStyle(
                            fontSize: 28, fontWeight: FontWeight.bold,
                            color: AppColors.primary))
                    : null,
              ),
              const SizedBox(height: 8),
              Text(auth.user?.email ?? '',
                  style: GoogleFonts.poppins(
                      fontSize: 13, color: AppColors.textSecondary)),
              Container(
                margin: const EdgeInsets.only(top: 4),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(auth.user?.role.toUpperCase() ?? 'ADMIN',
                    style: GoogleFonts.poppins(
                        fontSize: 10, fontWeight: FontWeight.bold,
                        color: AppColors.primary)),
              ),
            ])),
            const SizedBox(height: 28),

            Text('EDIT PROFILE',
                style: GoogleFonts.poppins(
                    fontSize: 11, fontWeight: FontWeight.w700,
                    color: AppColors.primary, letterSpacing: 1.2)),
            const SizedBox(height: 14),

            TextField(
              controller: nameCtrl,
              style: GoogleFonts.poppins(),
              decoration: const InputDecoration(
                labelText: 'Full Name',
                prefixIcon: Icon(Icons.person_outline_rounded, size: 20),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: phoneCtrl,
              keyboardType: TextInputType.phone,
              style: GoogleFonts.poppins(),
              decoration: const InputDecoration(
                labelText: 'Phone Number',
                prefixIcon: Icon(Icons.phone_outlined, size: 20),
              ),
            ),
            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: saving
                    ? null
                    : () async {
                        setModal(() => saving = true);
                        final ok = await auth.updateProfile(
                          fullName: nameCtrl.text.trim(),
                          phone: phoneCtrl.text.trim(),
                        );
                        if (ctx.mounted) {
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text(ok ? 'Profile updated!' : 'Update failed'),
                            backgroundColor: ok ? AppColors.success : AppColors.error,
                          ));
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: saving
                    ? const SizedBox(width: 20, height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text('Save Changes', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  // ── Change Password Sheet ────────────────────────────────────────────────────

  void _showChangePasswordSheet(BuildContext context) {
    final oldCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();
    bool obscureOld = true, obscureNew = true, obscureConfirm = true;
    bool saving = false;
    String? error;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => Padding(
          padding: EdgeInsets.fromLTRB(
              24, 16, 24, MediaQuery.of(ctx).viewInsets.bottom + 32),
          child: Column(mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start, children: [
            Center(child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                  color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
            )),
            const SizedBox(height: 20),
            Text('Change Password',
                style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text('Enter your current password and choose a new one.',
                style: GoogleFonts.poppins(fontSize: 13, color: AppColors.textSecondary)),
            const SizedBox(height: 24),

            TextField(
              controller: oldCtrl,
              obscureText: obscureOld,
              style: GoogleFonts.poppins(),
              decoration: InputDecoration(
                labelText: 'Current Password',
                prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
                suffixIcon: IconButton(
                  icon: Icon(obscureOld ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 20),
                  onPressed: () => setModal(() => obscureOld = !obscureOld),
                ),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: newCtrl,
              obscureText: obscureNew,
              style: GoogleFonts.poppins(),
              decoration: InputDecoration(
                labelText: 'New Password',
                prefixIcon: const Icon(Icons.lock_person_rounded, size: 20),
                suffixIcon: IconButton(
                  icon: Icon(obscureNew ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 20),
                  onPressed: () => setModal(() => obscureNew = !obscureNew),
                ),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: confirmCtrl,
              obscureText: obscureConfirm,
              style: GoogleFonts.poppins(),
              decoration: InputDecoration(
                labelText: 'Confirm New Password',
                prefixIcon: const Icon(Icons.verified_user_rounded, size: 20),
                suffixIcon: IconButton(
                  icon: Icon(obscureConfirm ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 20),
                  onPressed: () => setModal(() => obscureConfirm = !obscureConfirm),
                ),
              ),
            ),

            if (error != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.error.withOpacity(0.2)),
                ),
                child: Row(children: [
                  const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 18),
                  const SizedBox(width: 8),
                  Expanded(child: Text(error!,
                      style: GoogleFonts.poppins(fontSize: 12, color: AppColors.error))),
                ]),
              ),
            ],

            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: saving
                    ? null
                    : () async {
                        final old = oldCtrl.text;
                        final newP = newCtrl.text;
                        final conf = confirmCtrl.text;
                        if (old.isEmpty || newP.isEmpty || conf.isEmpty) {
                          setModal(() => error = 'Please fill all fields');
                          return;
                        }
                        if (newP.length < 6) {
                          setModal(() => error = 'New password must be at least 6 characters');
                          return;
                        }
                        if (newP != conf) {
                          setModal(() => error = 'New passwords do not match');
                          return;
                        }
                        setModal(() { saving = true; error = null; });
                        try {
                          await ApiService().changePassword(old, newP);
                          if (ctx.mounted) {
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                              content: Text('Password changed successfully!'),
                              backgroundColor: AppColors.success,
                            ));
                          }
                        } catch (e) {
                          setModal(() {
                            saving = false;
                            error = e.toString().contains('400')
                                ? 'Current password is incorrect'
                                : 'Failed to change password';
                          });
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: saving
                    ? const SizedBox(width: 20, height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text('Change Password',
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  // ── Logout ───────────────────────────────────────────────────────────────────

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              Navigator.pop(ctx);  // close dialog
              Navigator.pop(context);  // close drawer
              await context.read<AuthProvider>().logout();
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (_) => false,
                );
              }
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  Widget _drawerItem(BuildContext ctx, int index, IconData icon, String label) {
    final selected = currentIndex == index;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      child: ListTile(
        selected: selected,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        selectedTileColor: AppColors.primary.withOpacity(0.08),
        leading: Icon(icon,
            color: selected ? AppColors.primary : AppColors.textSecondary, size: 22),
        title: Text(label,
            style: GoogleFonts.outfit(
                color: selected ? AppColors.primary : AppColors.textPrimary,
                fontWeight: selected ? FontWeight.bold : FontWeight.w500,
                fontSize: 15)),
        onTap: () => onNavigate(index),
      ),
    );
  }
}
