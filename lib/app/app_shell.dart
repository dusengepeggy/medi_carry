import 'package:flutter/material.dart';

import '../features/cards/view/cards_screen.dart';
import '../features/dashboard/view/home_screen.dart';
import '../features/dashboard/widgets/medi_bottom_nav.dart';
import '../features/profile/view/profile_screen.dart';
import '../features/records/view/medical_records_screen.dart';
import '../features/share/view/share_records_screen.dart';

/// The authenticated app shell: four tabs over an [IndexedStack], each with
/// its own [Navigator], plus the single bottom bar.
///
/// This replaces the previous arrangement where every bottom-nav tap pushed a
/// new route, which grew the navigator stack without bound and made "Home"
/// mean three different things depending on the screen. Here, switching tabs
/// changes an index — it never pushes — and each tab keeps its own back stack
/// and scroll position.
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  /// Lets a descendant switch tabs — e.g. the dashboard's "See All", which
  /// means "show me the History tab" rather than pushing a second copy of the
  /// records screen on top of Home.
  static AppShellController? of(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<_AppShellScope>()
      ?.controller;

  @override
  State<AppShell> createState() => _AppShellState();
}

/// Tab-switching API handed to descendants by [AppShell.of].
class AppShellController {
  const AppShellController({required this.goToTab});

  final void Function(MediTab tab) goToTab;
}

class _AppShellScope extends InheritedWidget {
  const _AppShellScope({
    required this.controller,
    required this.activeTab,
    required super.child,
  });

  final AppShellController controller;
  final MediTab activeTab;

  @override
  bool updateShouldNotify(_AppShellScope oldWidget) =>
      activeTab != oldWidget.activeTab;
}

class _AppShellState extends State<AppShell> {
  static const _tabs = [
    MediTab.home,
    MediTab.history,
    MediTab.cards,
    MediTab.profile,
  ];

  final _navigatorKeys = <MediTab, GlobalKey<NavigatorState>>{
    for (final tab in _tabs) tab: GlobalKey<NavigatorState>(),
  };

  int _index = 0;

  MediTab get _currentTab => _tabs[_index];

  NavigatorState? get _currentNavigator =>
      _navigatorKeys[_currentTab]?.currentState;

  void _onTabSelected(MediTab tab) {
    final target = _tabs.indexOf(tab);
    if (target == _index) {
      // Re-tapping the active tab returns to that tab's root.
      _navigatorKeys[tab]?.currentState?.popUntil((r) => r.isFirst);
      return;
    }
    setState(() => _index = target);
  }

  /// Opens the QR scan-and-share hub inside the active tab's navigator, so the
  /// shell's bottom bar stays visible and the patient can navigate straight
  /// out of it rather than being trapped on a full-screen modal.
  void _openShareHub() {
    _currentNavigator?.push(
      MaterialPageRoute<void>(builder: (_) => const ShareRecordsScreen()),
    );
  }

  /// Back pops within the active tab; at a tab root it falls back to Home;
  /// on Home's root it lets the system close the app.
  Future<void> _handlePop(bool didPop) async {
    if (didPop) return;
    final navigator = _currentNavigator;
    if (navigator != null && navigator.canPop()) {
      navigator.pop();
      return;
    }
    if (_index != 0) {
      setState(() => _index = 0);
      return;
    }
    // At Home's root — allow the app to close.
    if (mounted) Navigator.of(context).maybePop();
  }

  Widget _rootFor(MediTab tab) => switch (tab) {
        MediTab.home => const HomeScreen(),
        MediTab.history => const MedicalRecordsScreen(),
        MediTab.cards => const CardsScreen(),
        MediTab.profile => const ProfileScreen(),
      };

  @override
  Widget build(BuildContext context) {
    return _AppShellScope(
      controller: AppShellController(goToTab: _onTabSelected),
      activeTab: _currentTab,
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) => _handlePop(didPop),
        child: Scaffold(
          extendBody: true,
          body: IndexedStack(
            index: _index,
            children: [
              for (final tab in _tabs)
                Navigator(
                  key: _navigatorKeys[tab],
                  onGenerateRoute: (settings) => MaterialPageRoute<void>(
                    settings: settings,
                    builder: (_) => _rootFor(tab),
                  ),
                ),
            ],
          ),
          bottomNavigationBar: MediBottomNav(
            active: _currentTab,
            onHome: () => _onTabSelected(MediTab.home),
            onHistory: () => _onTabSelected(MediTab.history),
            onCards: () => _onTabSelected(MediTab.cards),
            onProfile: () => _onTabSelected(MediTab.profile),
            // The QR scan-and-share hub is pushed into the *active tab's*
            // navigator rather than over the shell, so the bottom bar stays
            // visible and the patient can navigate straight out of it.
            onScan: _openShareHub,
          ),
        ),
      ),
    );
  }
}
