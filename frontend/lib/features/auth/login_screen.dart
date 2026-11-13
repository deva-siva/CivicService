import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';
import '../../providers/auth_provider.dart';
import '../../providers/locale_provider.dart';
import '../../services/api_service.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/language_selector.dart';
import '../user/user_main_screen.dart';
import '../admin/admin_main_screen.dart';
import '../../generated/app_localizations.dart';
import 'register_screen.dart';
import 'complete_profile_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscurePassword = true;
  bool _rememberMe = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
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
    _passwordCtrl.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _navigateAfterLogin() {
    final user = context.read<AuthProvider>().user;
    if (user != null && (user.isAdmin || user.isStaff)) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const AdminMainScreen()),
      );
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const UserMainScreen()),
      );
    }
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    final success = await context.read<AuthProvider>().login(
      _emailCtrl.text.trim(), _passwordCtrl.text,
    );
    if (success && mounted) _navigateAfterLogin();
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
      _navigateAfterLogin();
    }
  }

  void _showForgotPasswordSheet(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final emailCtrl = TextEditingController(text: _emailCtrl.text.trim());
    bool sending = false;
    bool sent = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setModal) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 28, right: 28, top: 20,
          ),
          child: Column(mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start, children: [
            Center(child: Container(
              width: 50, height: 5,
              margin: const EdgeInsets.only(bottom: 30),
              decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(10)),
            )),
            if (!sent) ...[
              Text(l10n.forgotPassword,
                  style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
              const SizedBox(height: 12),
              Text(
                'Enter your email and we\'ll send you a recovery link.', // Could localize this later too
                style: GoogleFonts.poppins(fontSize: 14, color: AppColors.textSecondary, height: 1.5),
              ),
              const SizedBox(height: 30),
              TextField(
                controller: emailCtrl,
                keyboardType: TextInputType.emailAddress,
                style: GoogleFonts.poppins(),
                decoration: InputDecoration(
                  labelText: l10n.email,
                  prefixIcon: const Icon(Icons.alternate_email_rounded, size: 20),
                ),
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                child: CustomButton(
                  label: l10n.submitComplaint.replaceAll('Complaint', 'Request'), // Temporary fallback or refine ARB
                  isLoading: sending,
                  onPressed: () async {
                    if (emailCtrl.text.trim().isEmpty || !emailCtrl.text.contains('@')) return;
                    setModal(() => sending = true);
                    try {
                      await ApiService().requestPasswordReset(emailCtrl.text.trim());
                    } catch (_) {}
                    setModal(() { sending = false; sent = true; });
                  },
                ),
              ),
            ] else ...[
              Center(child: Column(children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                      color: AppColors.success.withOpacity(0.1), shape: BoxShape.circle),
                  child: const Icon(Icons.check_circle_outline_rounded,
                      color: AppColors.success, size: 48),
                ),
                const SizedBox(height: 24),
                Text(l10n.done,
                    style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Text(
                  'Instructions sent to ${emailCtrl.text}.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(fontSize: 14,
                      color: AppColors.textSecondary, height: 1.6),
                ),
                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: Text(l10n.back),
                  ),
                ),
              ])),
            ],
            const SizedBox(height: 40),
          ]),
        ),
      ),
    );
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
            // Artistic Background
            Positioned(
              top: -100,
              right: -100,
              child: Container(
                width: 400,
                height: 400,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.primary.withOpacity(0.08),
                      AppColors.primary.withOpacity(0.0),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: -50,
              left: -50,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.secondary.withOpacity(0.05),
                      AppColors.secondary.withOpacity(0.0),
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
                        // Logo
                        Hero(
                          tag: 'app_logo',
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Icon(Icons.gavel_rounded, color: AppColors.primary, size: 28),
                          ),
                        ),
                        // Language
                        const LanguageSelector(isDark: true),
                      ],
                    ),
                    const SizedBox(height: 40),
                    // Welcome Text
                    Text(l10n.welcome,
                      style: GoogleFonts.poppins(
                        fontSize: 32, 
                        fontWeight: FontWeight.bold, 
                        color: AppColors.textPrimary,
                        letterSpacing: -0.5,
                      )),
                    const SizedBox(height: 8),
                    Text(l10n.welcomeSubtitle,
                      style: GoogleFonts.poppins(
                        fontSize: 15, 
                        color: AppColors.textSecondary,
                        height: 1.5,
                      )),
                    const SizedBox(height: 50),
                    
                    // Form
                    Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Identifier
                          TextFormField(
                            controller: _emailCtrl,
                            keyboardType: TextInputType.text,
                            style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                            decoration: InputDecoration(
                              labelText: l10n.email,
                              prefixIcon: const Icon(Icons.person_pin_rounded, size: 20),
                            ),
                            validator: (v) => v == null || v.trim().isEmpty ? 'Please enter identifier' : null,
                          ),
                          const SizedBox(height: 20),
                          // Password
                          TextFormField(
                            controller: _passwordCtrl,
                            obscureText: _obscurePassword,
                            style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                            decoration: InputDecoration(
                              labelText: l10n.password,
                              prefixIcon: const Icon(Icons.lock_person_rounded, size: 20),
                              suffixIcon: IconButton(
                                icon: Icon(_obscurePassword ? Icons.visibility_off_rounded : Icons.visibility_rounded, size: 20),
                                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                              ),
                            ),
                            validator: (v) => v == null || v.isEmpty ? 'Password is required' : null,
                          ),
                          const SizedBox(height: 12),
                          // Remember + Forgot
                          // Remember Me & Forgot Password
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              InkWell(
                                onTap: () => setState(() => _rememberMe = !_rememberMe),
                                borderRadius: BorderRadius.circular(8),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 4),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      SizedBox(
                                        height: 24, width: 24,
                                        child: Checkbox(
                                          value: _rememberMe,
                                          onChanged: (v) => setState(() => _rememberMe = v!),
                                          activeColor: AppColors.primary,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(l10n.rememberMe, 
                                        style: GoogleFonts.poppins(fontSize: 14, color: AppColors.textSecondary),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 2),
                              TextButton(
                                onPressed: () => _showForgotPasswordSheet(context),
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 4), 
                                  minimumSize: Size.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: Text(l10n.forgotPassword,
                                  style: GoogleFonts.poppins(
                                    color: AppColors.primary, 
                                    fontSize: 14, 
                                    fontWeight: FontWeight.w600,
                                  )),
                              ),
                            ],
                          ),
                          const SizedBox(height: 32),
                          
                          // Error Display
                          if (auth.error != null) _buildErrorCard(auth.error!),

                          // Login Button
                          SizedBox(
                            width: double.infinity,
                            child: CustomButton(
                              label: l10n.login,
                              isLoading: auth.loading,
                              onPressed: _login,
                            ),
                          ),
                          const SizedBox(height: 30),
                          
                          // Social Divider
                          Row(
                            children: [
                              const Expanded(child: Divider(thickness: 1, color: Color(0xFFF1F1F1))),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                child: Text('OR', style: GoogleFonts.poppins(color: Colors.grey.shade400, fontSize: 13, fontWeight: FontWeight.w500)),
                              ),
                              const Expanded(child: Divider(thickness: 1, color: Color(0xFFF1F1F1))),
                            ],
                          ),
                          const SizedBox(height: 30),
                          
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
                                    errorBuilder: (context, error, stackTrace) => const Icon(Icons.g_mobiledata_rounded, color: Colors.blue, size: 28),
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
                          const SizedBox(height: 40),
                          
                          // Register link
                          Center(
                            child: RichText(
                              text: TextSpan(
                                style: GoogleFonts.poppins(color: AppColors.textSecondary, fontSize: 15),
                                children: [
                                  TextSpan(text: "${l10n.dontHaveAccount} "),
                                  WidgetSpan(
                                    alignment: PlaceholderAlignment.middle,
                                    child: GestureDetector(
                                      onTap: () => Navigator.of(context).push(
                                        MaterialPageRoute(builder: (_) => const RegisterScreen()),
                                      ),
                                      child: Text(l10n.register,
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
