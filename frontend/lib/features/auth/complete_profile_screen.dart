import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common/custom_button.dart';
import '../user/user_main_screen.dart';

/// Shown to new Google-sign-in users so they can complete their profile
/// (name, phone, language, city) before entering the app.
class CompleteProfileScreen extends StatefulWidget {
  const CompleteProfileScreen({super.key});

  @override
  State<CompleteProfileScreen> createState() => _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends State<CompleteProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  String _selectedLanguage = 'en';

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().user;
    if (user != null && user.fullName.isNotEmpty) {
      _nameCtrl.text = user.fullName;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _locationCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final ok = await auth.updateProfile(
      fullName: _nameCtrl.text.trim(),
      phone: _phoneCtrl.text.trim(),
      locationText: _locationCtrl.text.trim(),
      preferredLanguage: _selectedLanguage,
    );
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const UserMainScreen()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not save profile. Please try again.'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(children: [
        Container(
          height: 220,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.primary, AppColors.primaryDark],
            ),
          ),
        ),
        SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const SizedBox(height: 20),
              const Row(children: [
                Icon(Icons.account_circle_outlined, color: Colors.white, size: 32),
                SizedBox(width: 12),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Complete Your Profile',
                      style: TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                  Text('Just a few more details to get started',
                      style: TextStyle(fontSize: 12, color: Colors.white70)),
                ]),
              ]),
              const SizedBox(height: 40),
              Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.1),
                      blurRadius: 30,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Form(
                  key: _formKey,
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(children: [
                        Icon(Icons.info_outline, color: AppColors.primary, size: 18),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Welcome! You signed in with Google. Please complete your profile to use the Grievance Portal.',
                            style: TextStyle(
                                fontSize: 12, color: AppColors.textSecondary, height: 1.5),
                          ),
                        ),
                      ]),
                    ),
                    const SizedBox(height: 24),

                    TextFormField(
                      controller: _nameCtrl,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        labelText: 'Full Name *',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Full name is required' : null,
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _phoneCtrl,
                      keyboardType: TextInputType.phone,
                      maxLength: 10,
                      decoration: const InputDecoration(
                        labelText: 'Mobile Number *',
                        hintText: '10-digit mobile number',
                        prefixIcon: Icon(Icons.phone_outlined),
                        prefixText: '+91 ',
                        counterText: '',
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Mobile number is required';
                        final digits = v.trim().replaceAll(RegExp(r'\D'), '');
                        if (digits.length != 10) return 'Enter a valid 10-digit mobile number';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _locationCtrl,
                      decoration: const InputDecoration(
                        labelText: 'City / Area (optional)',
                        hintText: 'e.g. Chennai, Tamil Nadu',
                        prefixIcon: Icon(Icons.location_on_outlined),
                      ),
                    ),
                    const SizedBox(height: 16),

                    DropdownButtonFormField<String>(
                      value: _selectedLanguage,
                      decoration: const InputDecoration(
                        labelText: 'Preferred Language',
                        prefixIcon: Icon(Icons.language_outlined),
                      ),
                      items: AppConstants.indianLanguages.entries
                          .map((e) => DropdownMenuItem(
                                value: e.key,
                                child: Text(e.value),
                              ))
                          .toList(),
                      onChanged: (v) => setState(() => _selectedLanguage = v!),
                    ),
                    const SizedBox(height: 28),

                    CustomButton(
                      label: 'Save & Continue',
                      icon: Icons.arrow_forward_rounded,
                      isLoading: auth.loading,
                      onPressed: _save,
                    ),
                    const SizedBox(height: 12),

                    Center(
                      child: TextButton(
                        onPressed: () => Navigator.of(context).pushReplacement(
                          MaterialPageRoute(builder: (_) => const UserMainScreen()),
                        ),
                        child: const Text(
                          'Skip for now',
                          style: TextStyle(fontSize: 13, color: AppColors.textHint),
                        ),
                      ),
                    ),
                  ]),
                ),
              ),
              const SizedBox(height: 32),
            ]),
          ),
        ),
      ]),
    );
  }
}
