import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';
import '../../providers/locale_provider.dart';

class LanguageSelector extends StatelessWidget {
  final bool isDark;
  const LanguageSelector({super.key, this.isDark = false});

  @override
  Widget build(BuildContext context) {
    final localeProvider = context.watch<LocaleProvider>();
    
    return PopupMenuButton<String>(
      tooltip: 'Change Language',
      offset: const Offset(0, 45),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      icon: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isDark ? Colors.black.withOpacity(0.1) : Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isDark ? AppColors.primary.withOpacity(0.2) : Colors.white.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.translate_rounded, 
              color: isDark ? AppColors.primary : Colors.white, 
              size: 18
            ),
            const SizedBox(width: 8),
            Text(
              AppConstants.indianLanguages[localeProvider.languageCode]?.split(' ').first ?? 'EN',
              style: TextStyle(
                color: isDark ? AppColors.textPrimary : Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            Icon(
              Icons.keyboard_arrow_down_rounded, 
              color: isDark ? AppColors.textSecondary : Colors.white70, 
              size: 18
            ),
          ],
        ),
      ),
      onSelected: (code) => localeProvider.setLocale(code),
      itemBuilder: (_) => AppConstants.indianLanguages.entries.map((e) {
        final isSelected = localeProvider.languageCode == e.key;
        return PopupMenuItem(
          value: e.key,
          child: Row(
            children: [
              Text(
                e.value,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? AppColors.primary : AppColors.textPrimary,
                ),
              ),
              if (isSelected) ...[
                const Spacer(),
                const Icon(Icons.check_circle, color: AppColors.primary, size: 16),
              ],
            ],
          ),
        );
      }).toList(),
    );
  }
}
