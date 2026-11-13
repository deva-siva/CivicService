import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';
import '../../providers/auth_provider.dart';
import '../../providers/locale_provider.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/language_selector.dart';
import '../../generated/app_localizations.dart';
import '../user/user_main_screen.dart';
import 'complete_profile_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _obscurePass = true;
  bool _obscureConfirm = true;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _googleLogin() async {
    final auth = context.read<AuthProvider>();
    final success = await auth.googleSignIn();
    if (!success || !mounted) return;
    if (auth.isNewGoogleUser) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const CompleteProfileScreen()),
      );
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const UserMainScreen()),
      );
    }
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    final success = await context.read<AuthProvider>().register(
      email: _emailCtrl.text.trim(),
      fullName: _nameCtrl.text.trim(),
      phone: _phoneCtrl.text.trim(),
      password: _passwordCtrl.text,
      confirmPassword: _confirmCtrl.text,
      preferredLanguage: context.read<LocaleProvider>().languageCode,
    );
    if (success && mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const UserMainScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      backgroundColor: Colors.white,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Stack(
          children: [
            // Artistic Background (different position than login)
            Positioned(
              top: -80,
              left: -80,
              child: Container(
                width: 350,
                height: 350,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.primary.withOpacity(0.06),
                      AppColors.primary.withOpacity(0.0),
                    ],
                  ),
                ),
              ),
            ),
            
            SafeArea(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    // Header Area
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Back Button
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.background,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary, size: 20),
                          ),
                        ),
                        // Language Selector
                        const LanguageSelector(isDark: true),
                      ],
                    ),
                    const SizedBox(height: 32),
                    // Title
                    Text(l10n.register,
                      style: GoogleFonts.poppins(
                        fontSize: 28, 
                        fontWeight: FontWeight.bold, 
                        color: AppColors.textPrimary,
                        letterSpacing: -0.5,
                      )),
                    const SizedBox(height: 8),
                    Text('Create an account to start contributing to a better, smarter city.',
                      style: GoogleFonts.poppins(
                        fontSize: 15, 
                        color: AppColors.textSecondary,
                        height: 1.5,
                      )),
                    const SizedBox(height: 40),
                    
                    // Form
                    Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionTitle(l10n.profile),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _nameCtrl,
                            style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                            decoration: InputDecoration(
                              labelText: l10n.fullName,
                              prefixIcon: const Icon(Icons.person_outline_rounded, size: 20),
                            ),
                            validator: (v) => v == null || v.isEmpty ? 'Please enter your full name' : null,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _emailCtrl,
                            keyboardType: TextInputType.emailAddress,
                            style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                            decoration: InputDecoration(
                              labelText: l10n.email,
                              prefixIcon: const Icon(Icons.alternate_email_rounded, size: 20),
                            ),
                            validator: (v) {
                              if (v == null || v.isEmpty) return 'Email is required';
                              if (!v.contains('@')) return 'Enter a valid email';
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _phoneCtrl,
                            keyboardType: TextInputType.phone,
                            style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                            decoration: InputDecoration(
                              labelText: l10n.phone,
                              prefixIcon: const Icon(Icons.phone_iphone_rounded, size: 20),
                              hintText: 'Optional',
                            ),
                          ),
                          
                          const SizedBox(height: 32),
                          _buildSectionTitle(l10n.settings),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _passwordCtrl,
                            obscureText: _obscurePass,
                            style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                            decoration: InputDecoration(
                              labelText: l10n.password,
                              prefixIcon: const Icon(Icons.lock_person_rounded, size: 20),
                              suffixIcon: IconButton(
                                icon: Icon(_obscurePass ? Icons.visibility_off_rounded : Icons.visibility_rounded, size: 20),
                                onPressed: () => setState(() => _obscurePass = !_obscurePass),
                              ),
                            ),
                            validator: (v) {
                              if (v == null || v.isEmpty) return 'Password is required';
                              if (v.length < 6) return 'At least 6 characters';
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _confirmCtrl,
                            obscureText: _obscureConfirm,
                            style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                            decoration: InputDecoration(
                              labelText: l10n.confirmPassword,
                              prefixIcon: const Icon(Icons.verified_user_rounded, size: 20),
                              suffixIcon: IconButton(
                                icon: Icon(_obscureConfirm ? Icons.visibility_off_rounded : Icons.visibility_rounded, size: 20),
                                onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                              ),
                            ),
                            validator: (v) => v != _passwordCtrl.text ? 'Passwords do not match' : null,
                          ),
                          
                          const SizedBox(height: 40),
                          // Error Display
                          if (auth.error != null) _buildErrorCard(auth.error!),

                          // Register Button
                          SizedBox(
                            width: double.infinity,
                            child: CustomButton(
                              label: l10n.register,
                              isLoading: auth.loading,
                              onPressed: _register,
                            ),
                          ),
                          const SizedBox(height: 24),

                          // OR divider
                          Row(
                            children: [
                              const Expanded(child: Divider(thickness: 1, color: Color(0xFFF1F1F1))),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                child: Text('OR', style: GoogleFonts.poppins(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.w500)),
                              ),
                              const Expanded(child: Divider(thickness: 1, color: Color(0xFFF1F1F1))),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // Google Sign-In
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton(
                              onPressed: auth.loading ? null : _googleLogin,
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(color: Colors.grey.shade200, width: 1.5),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Image.network(
                                    'https://www.gstatic.com/images/branding/product/1x/gsa_512dp.png',
                                    height: 20,
                                    errorBuilder: (_, __, ___) => const Icon(Icons.g_mobiledata_rounded, color: Colors.blue, size: 28),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(l10n.continueWithGoogle,
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textPrimary,
                                      fontSize: 15,
                                    )),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 30),

                          // Login link
                          Center(
                            child: RichText(
                              text: TextSpan(
                                style: GoogleFonts.poppins(color: AppColors.textSecondary, fontSize: 15),
                                children: [
                                  TextSpan(text: "${l10n.alreadyHaveAccount} "),
                                  WidgetSpan(
                                    alignment: PlaceholderAlignment.middle,
                                    child: GestureDetector(
                                      onTap: () => Navigator.pop(context),
                                      child: Text(l10n.login,
                                        style: GoogleFonts.poppins(
                                          color: AppColors.primary, 
                                          fontWeight: FontWeight.bold, 
                                          fontSize: 15,
                                        )),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title.toUpperCase(),
      style: GoogleFonts.poppins(
        fontSize: 11,
        fontWeight: FontWeight.bold,
        color: AppColors.primary,
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _buildErrorCard(String error) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: const Color(0xFFFFEBEE),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.error.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 20),
          const SizedBox(width: 12),
          Expanded(child: Text(error,
            style: GoogleFonts.poppins(color: AppColors.error, fontSize: 13, fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }
}
