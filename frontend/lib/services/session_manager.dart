import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'api_service.dart';

class SessionManager extends StatefulWidget {
  final Widget child;

  const SessionManager({super.key, required this.child});

  @override
  State<SessionManager> createState() => _SessionManagerState();
}

class _SessionManagerState extends State<SessionManager> with WidgetsBindingObserver {
  static const String _lastActiveKey = 'last_active_timestamp';
  // If inactive for 3 days, logout
  static const Duration _inactivityTimeout = Duration(days: 3);
  
  DateTime? _lastActiveTime;
  Timer? _throttleTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadLastActiveTime();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _throttleTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadLastActiveTime() async {
    final prefs = await SharedPreferences.getInstance();
    final timestamp = prefs.getInt(_lastActiveKey);
    if (timestamp != null) {
      _lastActiveTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
      _checkInactivity();
    } else {
      _updateLastActiveTime();
    }
  }

  void _updateLastActiveTime() {
    final now = DateTime.now();
    _lastActiveTime = now;
    // Throttle writing to SharedPreferences to once every 5 minutes
    if (_throttleTimer == null || !_throttleTimer!.isActive) {
      _throttleTimer = Timer(const Duration(minutes: 5), () async {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt(_lastActiveKey, _lastActiveTime!.millisecondsSinceEpoch);
      });
    }
  }

  Future<void> _checkInactivity() async {
    if (_lastActiveTime == null) return;
    
    final authProvider = context.read<AuthProvider>();
    if (!authProvider.isLoggedIn) return; // Not logged in, no need to check

    final now = DateTime.now();
    if (now.difference(_lastActiveTime!) >= _inactivityTimeout) {
      // Inactive for more than 3 days, auto-logout
      await authProvider.logout();
      ApiService.navigatorKey?.currentState?.pushNamedAndRemoveUntil('/login', (_) => false);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkInactivity();
    } else if (state == AppLifecycleState.paused) {
      // Immediately write the last active time when app goes to background
      _throttleTimer?.cancel();
      if (_lastActiveTime != null) {
        SharedPreferences.getInstance().then((prefs) {
          prefs.setInt(_lastActiveKey, _lastActiveTime!.millisecondsSinceEpoch);
        });
      }
    }
  }

  void _onUserInteraction(PointerEvent details) {
    _updateLastActiveTime();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: _onUserInteraction,
      onPointerMove: _onUserInteraction,
      behavior: HitTestBehavior.translucent,
      child: widget.child,
    );
  }
}
