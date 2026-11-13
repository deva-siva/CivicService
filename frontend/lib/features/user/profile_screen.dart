import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/theme/app_theme.dart';
import '../../utils/image_utils.dart';
import '../../core/constants/app_constants.dart';
import '../../providers/auth_provider.dart';
import '../../providers/locale_provider.dart';
import '../../services/api_service.dart';
import '../../widgets/common/custom_button.dart';
import '../auth/login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  bool _editing = false;
  bool _savingProfile = false;
  File? _pickedPhoto;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().user;
    _nameCtrl.text = user?.fullName ?? '';
    _phoneCtrl.text = user?.phone ?? '';
    _locationCtrl.text = user?.locationText ?? '';
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _locationCtrl.dispose();
    super.dispose();
  }

  // ─── Photo Upload ────────────────────────────────────────────────────────

  Future<void> _pickPhoto() async {
    final picker = ImagePicker();
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const SizedBox(height: 8),
          Container(
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          ListTile(
            leading: const Icon(Icons.camera_alt_outlined, color: AppColors.primary),
            title: const Text('Take Photo'),
            onTap: () async {
              Navigator.pop(context);
              final picked = await picker.pickImage(
                  source: ImageSource.camera, imageQuality: 90);
              if (picked != null) {
                final compressed = await ImageUtils.compressUnder1MB(File(picked.path));
                setState(() => _pickedPhoto = compressed);
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.photo_library_outlined, color: AppColors.primary),
            title: const Text('Choose from Gallery'),
            onTap: () async {
              Navigator.pop(context);
              final picked = await picker.pickImage(
                  source: ImageSource.gallery, imageQuality: 90);
              if (picked != null) {
                final compressed = await ImageUtils.compressUnder1MB(File(picked.path));
                setState(() => _pickedPhoto = compressed);
              }
            },
          ),
          const SizedBox(height: 8),
        ]),
      ),
    );
  }

  // ─── Save Profile ─────────────────────────────────────────────────────────

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _savingProfile = true);
    final success = await context.read<AuthProvider>().updateProfile(
      fullName: _nameCtrl.text.trim(),
      phone: _phoneCtrl.text.trim(),
      locationText: _locationCtrl.text.trim(),
      profileImage: _pickedPhoto,
    );
    setState(() {
      _savingProfile = false;
      _editing = false;
      if (success) _pickedPhoto = null;
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(success ? 'Profile updated successfully' : 'Update failed'),
        backgroundColor: success ? AppColors.success : AppColors.error,
      ));
    }
  }

  // ─── Logout ───────────────────────────────────────────────────────────────

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
    if (confirm == true && mounted) {
      await context.read<AuthProvider>().logout();
      if (mounted) _showLoggedOutDialog();
    }
  }

  void _showLoggedOutDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                  color: AppColors.success, shape: BoxShape.circle),
              child: const Icon(Icons.check_rounded, color: Colors.white, size: 40),
            ),
            const SizedBox(height: 24),
            const Text("You're logged out",
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary)),
            const SizedBox(height: 10),
            const Text(
              'Thank you for using the Smart Civic Grievance Portal.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.5),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (_) => false,
                ),
                child: const Text('OK'),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  // ─── Delete Account ───────────────────────────────────────────────────────

  Future<void> _deleteAccount() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Account',
            style: TextStyle(color: AppColors.error)),
        content: const Text(
            'This will permanently delete your account and all your complaints. This action cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Delete Forever'),
          ),
        ],
      ),
    );
    if (confirm == true && mounted) {
      try {
        await ApiService().deleteAccount();
        await context.read<AuthProvider>().logout();
        if (mounted) _showLoggedOutDialog();
      } catch (_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Failed to delete account. Try again.'),
            backgroundColor: AppColors.error,
          ));
        }
      }
    }
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final locale = context.watch<LocaleProvider>();
    final user = auth.user;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text('Profile & Settings',
            style: TextStyle(
                fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
        actions: [
          if (!_editing)
            TextButton.icon(
              onPressed: () => setState(() => _editing = true),
              icon: const Icon(Icons.edit_outlined, color: AppColors.primary, size: 16),
              label: const Text('Edit',
                  style: TextStyle(color: AppColors.primary, fontSize: 13)),
            ),
          const SizedBox(width: 4),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: const Color(0xFFE8ECF0)),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

            // ── Avatar + Name card ───────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE8ECF0)),
              ),
              child: Row(children: [
                Column(children: [
                  Stack(children: [
                    CircleAvatar(
                      radius: 38,
                      backgroundColor: AppColors.primary.withOpacity(0.12),
                      backgroundImage: _pickedPhoto != null
                          ? FileImage(_pickedPhoto!) as ImageProvider
                          : (user?.profilePic != null
                              ? NetworkImage(user!.profilePic!)
                              : null),
                      child: (_pickedPhoto == null && user?.profilePic == null)
                          ? Text(
                              user?.displayName.isNotEmpty == true
                                  ? user!.displayName[0].toUpperCase()
                                  : 'U',
                              style: const TextStyle(
                                  fontSize: 30,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary))
                          : null,
                    ),
                    Positioned(
                      bottom: 0, right: 0,
                      child: GestureDetector(
                        onTap: _pickPhoto,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                              color: AppColors.primary, shape: BoxShape.circle),
                          child: const Icon(Icons.camera_alt,
                              color: Colors.white, size: 14),
                        ),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 6),
                  TextButton.icon(
                    onPressed: _pickPhoto,
                    icon: const Icon(Icons.upload_rounded, size: 14,
                        color: AppColors.primary),
                    label: const Text('Upload New Photo',
                        style: TextStyle(
                            fontSize: 11, color: AppColors.primary)),
                    style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2)),
                  ),
                ]),
                const SizedBox(width: 16),
                Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(user?.displayName ?? '',
                      style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary)),
                  const SizedBox(height: 4),
                  Text(user?.email ?? '',
                      style: const TextStyle(
                          fontSize: 13, color: AppColors.textSecondary)),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(user?.role.toUpperCase() ?? '',
                        style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold)),
                  ),
                ])),
              ]),
            ),
            const SizedBox(height: 16),

            // ── Account Information ──────────────────────────────────────
            _sectionCard('Account Information', Icons.person_outline, [
              TextFormField(
                controller: _nameCtrl,
                readOnly: !_editing,
                decoration: const InputDecoration(
                    labelText: 'Full Name',
                    prefixIcon: Icon(Icons.person_outline)),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Name is required' : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _phoneCtrl,
                readOnly: !_editing,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                    labelText: 'Mobile Number',
                    prefixIcon: Icon(Icons.phone_outlined)),
              ),
              const SizedBox(height: 14),
              TextFormField(
                initialValue: user?.email ?? '',
                readOnly: true,
                decoration: const InputDecoration(
                    labelText: 'Email Address',
                    prefixIcon: Icon(Icons.email_outlined)),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _locationCtrl,
                readOnly: !_editing,
                decoration: const InputDecoration(
                    labelText: 'Location',
                    prefixIcon: Icon(Icons.location_on_outlined)),
              ),
              if (_editing) ...[
                const SizedBox(height: 18),
                Row(children: [
                  Expanded(child: OutlinedButton(
                    onPressed: () => setState(() {
                      _editing = false;
                      _pickedPhoto = null;
                      final u = context.read<AuthProvider>().user;
                      _nameCtrl.text = u?.fullName ?? '';
                      _phoneCtrl.text = u?.phone ?? '';
                      _locationCtrl.text = u?.locationText ?? '';
                    }),
                    child: const Text('Cancel'),
                  )),
                  const SizedBox(width: 12),
                  Expanded(child: CustomButton(
                    label: 'Save Changes',
                    isLoading: _savingProfile,
                    onPressed: _saveProfile,
                  )),
                ]),
              ],
            ]),
            const SizedBox(height: 16),

            // ── Language ─────────────────────────────────────────────────
            _sectionCard('Language', Icons.language_outlined, [
              DropdownButtonFormField<String>(
                value: locale.languageCode,
                decoration: const InputDecoration(labelText: 'Preferred Language'),
                items: AppConstants.indianLanguages.entries
                    .map((e) => DropdownMenuItem(
                        value: e.key, child: Text(e.value)))
                    .toList(),
                onChanged: (v) {
                  if (v != null) {
                    locale.setLocale(v);
                    context.read<AuthProvider>().updateProfile(preferredLanguage: v);
                    final langName = AppConstants.indianLanguages[v] ?? v;
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text('Language changed to $langName'),
                      duration: const Duration(seconds: 2),
                    ));
                  }
                },
              ),
            ]),
            const SizedBox(height: 16),

            // ── Settings toggles ─────────────────────────────────────────
            _sectionCard('Settings', Icons.settings_outlined, [
              _switchTile(
                icon: Icons.notifications_outlined,
                title: 'Receive Notifications',
                value: user?.receiveNotifications ?? true,
                onChanged: (v) => context
                    .read<AuthProvider>()
                    .updateProfile(receiveNotifications: v),
              ),
              const Divider(height: 1),
              _switchTile(
                icon: Icons.dark_mode_outlined,
                title: 'Enable Dark Mode',
                value: user?.darkMode ?? false,
                onChanged: (v) =>
                    context.read<AuthProvider>().updateProfile(darkMode: v),
              ),
              const Divider(height: 1),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.lock_outline, color: AppColors.primary),
                title: const Text('Change Password',
                    style: TextStyle(fontSize: 14)),
                trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                onTap: _showChangePasswordSheet,
              ),
            ]),
            const SizedBox(height: 16),

            // ── Account actions ──────────────────────────────────────────
            _sectionCard('Account', Icons.manage_accounts_outlined, [
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.logout_rounded, color: AppColors.error),
                title: const Text('Logout',
                    style: TextStyle(fontSize: 14, color: AppColors.error)),
                onTap: _logout,
              ),
              const Divider(height: 1),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.delete_forever_rounded,
                    color: AppColors.error),
                title: const Text('Delete Account',
                    style: TextStyle(fontSize: 14, color: AppColors.error)),
                subtitle: const Text('Permanently remove your account',
                    style: TextStyle(fontSize: 11, color: AppColors.textHint)),
                onTap: _deleteAccount,
              ),
            ]),
            const SizedBox(height: 32),
          ]),
        ),
      ),
    );
  }

  // ─── Helpers ─────────────────────────────────────────────────────────────

  Widget _sectionCard(
          String title, IconData icon, List<Widget> children) =>
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE8ECF0)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(icon, color: AppColors.primary, size: 20),
            const SizedBox(width: 8),
            Text(title,
                style: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w600)),
          ]),
          const SizedBox(height: 16),
          ...children,
        ]),
      );

  Widget _switchTile({
    required IconData icon,
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) =>
      SwitchListTile(
        contentPadding: EdgeInsets.zero,
        secondary: Icon(icon, color: AppColors.primary),
        title: Text(title, style: const TextStyle(fontSize: 14)),
        value: value,
        onChanged: onChanged,
        activeColor: AppColors.primary,
      );

  void _showChangePasswordSheet() {
    final oldCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final api = ApiService();
    bool loading = false;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setModal) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 24, right: 24, top: 24,
          ),
          child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Change Password',
                    style: TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                TextField(
                  controller: oldCtrl,
                  obscureText: true,
                  decoration: const InputDecoration(
                      labelText: 'Current Password',
                      prefixIcon: Icon(Icons.lock_outline)),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: newCtrl,
                  obscureText: true,
                  decoration: const InputDecoration(
                      labelText: 'New Password (min 6 chars)',
                      prefixIcon: Icon(Icons.lock_reset_outlined)),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: CustomButton(
                    label: 'Update Password',
                    isLoading: loading,
                    onPressed: () async {
                      if (oldCtrl.text.isEmpty || newCtrl.text.length < 6) {
                        return;
                      }
                      setModal(() => loading = true);
                      try {
                        await api.changePassword(oldCtrl.text, newCtrl.text);
                        if (context.mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Password changed successfully'),
                              backgroundColor: AppColors.success,
                            ),
                          );
                        }
                      } catch (_) {
                        setModal(() => loading = false);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Failed. Check your current password.'),
                              backgroundColor: AppColors.error,
                            ),
                          );
                        }
                      }
                    },
                  ),
                ),
                const SizedBox(height: 24),
              ]),
        ),
      ),
    );
  }
}
