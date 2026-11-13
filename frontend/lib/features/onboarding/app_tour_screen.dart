import 'package:flutter/material.dart';
import 'package:introduction_screen/introduction_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';
import '../../generated/app_localizations.dart';
import '../auth/login_screen.dart';

class AppTourScreen extends StatelessWidget {
  const AppTourScreen({super.key});

  Future<void> _onDone(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.tourSeenKey, true);
    if (context.mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const bodyStyle = TextStyle(fontSize: 15, color: AppColors.textSecondary, height: 1.5);
    const titleStyle = TextStyle(
      fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textPrimary,
    );
    final l10n = AppLocalizations.of(context)!;

    final pages = [
      PageViewModel(
        title: l10n.appTourTitle1,
        body: l10n.appTourDesc1,
        image: _buildImage(Icons.report_problem_rounded, const Color(0xFF1565C0)),
        decoration: const PageDecoration(
          titleTextStyle: titleStyle,
          bodyTextStyle: bodyStyle,
          imagePadding: EdgeInsets.only(top: 40, bottom: 20),
          pageColor: Colors.white,
        ),
      ),
      PageViewModel(
        title: l10n.appTourTitle2,
        body: l10n.appTourDesc2,
        image: _buildImage(Icons.psychology_rounded, const Color(0xFF7B1FA2)),
        decoration: const PageDecoration(
          titleTextStyle: titleStyle,
          bodyTextStyle: bodyStyle,
          imagePadding: EdgeInsets.only(top: 40, bottom: 20),
          pageColor: Colors.white,
        ),
      ),
      PageViewModel(
        title: l10n.appTourTitle3,
        body: l10n.appTourDesc3,
        image: _buildImage(Icons.track_changes_rounded, const Color(0xFFE65100)),
        decoration: const PageDecoration(
          titleTextStyle: titleStyle,
          bodyTextStyle: bodyStyle,
          imagePadding: EdgeInsets.only(top: 40, bottom: 20),
          pageColor: Colors.white,
        ),
      ),
      PageViewModel(
        title: l10n.appTourTitle4,
        body: l10n.appTourDesc4,
        image: _buildImage(Icons.notifications_active_rounded, const Color(0xFF2E7D32)),
        decoration: const PageDecoration(
          titleTextStyle: titleStyle,
          bodyTextStyle: bodyStyle,
          imagePadding: EdgeInsets.only(top: 40, bottom: 20),
          pageColor: Colors.white,
        ),
      ),
      PageViewModel(
        title: l10n.appTourTitle5,
        body: l10n.appTourDesc5,
        image: _buildImage(Icons.language_rounded, const Color(0xFF00838F)),
        decoration: const PageDecoration(
          titleTextStyle: titleStyle,
          bodyTextStyle: bodyStyle,
          imagePadding: EdgeInsets.only(top: 40, bottom: 20),
          pageColor: Colors.white,
        ),
      ),
    ];

    return Scaffold(
      body: IntroductionScreen(
        pages: pages,
        onDone: () => _onDone(context),
        onSkip: () => _onDone(context),
        showSkipButton: true,
        skip: TextButton(
          onPressed: () => _onDone(context),
          child: Text(l10n.skip, style: const TextStyle(color: AppColors.textSecondary, fontSize: 15)),
        ),
        next: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primary, AppColors.primaryDark],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: const Icon(Icons.arrow_forward, color: Colors.white, size: 24),
        ),
        done: Container(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primary, AppColors.primaryDark],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Text(
            l10n.getStarted,
            softWrap: false,
            overflow: TextOverflow.visible,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
              letterSpacing: 0.5,
            ),
          ),
        ),
        dotsDecorator: const DotsDecorator(
          size: Size(8, 8),
          activeSize: Size(24, 8),
          activeColor: AppColors.primary,
          color: AppColors.border,
          activeShape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(4)),
          ),
        ),
        globalBackgroundColor: Colors.white,
        safeAreaList: const [true, false, false, false],
      ),
    );
  }

  static Widget _buildImage(IconData icon, Color color) {
    return Container(
      width: 200,
      height: 200,
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, size: 100, color: color),
    );
  }
}
