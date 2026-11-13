import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import 'user_dashboard.dart';
import 'my_complaints_screen.dart';
import 'register_complaint_screen.dart';
import 'profile_screen.dart';

class UserMainScreen extends StatefulWidget {
  const UserMainScreen({super.key});
  @override
  State<UserMainScreen> createState() => _UserMainScreenState();
}

class _UserMainScreenState extends State<UserMainScreen> {
  int _currentIndex = 0;

  void _switchTab(int index) => setState(() => _currentIndex = index);

  static const _items = [
    _NavItem(icon: Icons.home_outlined,      activeIcon: Icons.home_rounded,         label: 'Home'),
    _NavItem(icon: Icons.list_alt_outlined,  activeIcon: Icons.list_alt_rounded,     label: 'My Issues'),
    _NavItem(icon: Icons.add,                activeIcon: Icons.add,                  label: 'Report'),
    _NavItem(icon: Icons.person_outline,     activeIcon: Icons.person_rounded,       label: 'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    context.watch<AuthProvider>();

    final pages = [
      UserDashboard(onViewAll: () => _switchTab(1)),
      const MyComplaintsScreen(),
      const RegisterComplaintScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: pages),
      bottomNavigationBar: _BottomNav(
        currentIndex: _currentIndex,
        items: _items,
        onTap: _switchTab,
      ),
    );
  }
}

// ── Nav item model ──────────────────────────────────────────────────────────────

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  const _NavItem({required this.icon, required this.activeIcon, required this.label});
}

// ── Custom bottom nav ───────────────────────────────────────────────────────────

class _BottomNav extends StatelessWidget {
  final int currentIndex;
  final List<_NavItem> items;
  final ValueChanged<int> onTap;

  const _BottomNav({
    required this.currentIndex,
    required this.items,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE8ECF0))),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            children: List.generate(items.length, (i) {
              final item = items[i];
              final isActive = i == currentIndex;
              final isCenter = i == 2; // Report button

              if (isCenter) {
                return Expanded(
                  child: GestureDetector(
                    onTap: () => onTap(i),
                    child: Center(
                      child: Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(Icons.add, color: Colors.white, size: 28),
                      ),
                    ),
                  ),
                );
              }

              return Expanded(
                child: InkWell(
                  onTap: () => onTap(i),
                  borderRadius: BorderRadius.circular(12),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                        decoration: BoxDecoration(
                          color: isActive
                              ? AppColors.primary.withOpacity(0.1)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Icon(
                          isActive ? item.activeIcon : item.icon,
                          color: isActive ? AppColors.primary : const Color(0xFFADB5BD),
                          size: 22,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item.label,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                          color: isActive ? AppColors.primary : const Color(0xFFADB5BD),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
