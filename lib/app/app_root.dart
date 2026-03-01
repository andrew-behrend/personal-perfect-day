import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../design/tokens/spacing.dart';
import '../design/tokens/typography.dart';
import '../features/home/home_screen.dart';
import '../features/history/history_screen.dart';
import '../features/onboarding/consent_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/settings/settings_view_model.dart';
import '../features/sources/mock_source_adapters.dart';
import '../features/sources/source_adapter.dart';
import '../features/sources/source_importer.dart';
import '../features/today/today_screen.dart';
import '../features/today/data/today_storage.dart';
import '../features/trends/trends_screen.dart';

class AppRoot extends StatefulWidget {
  const AppRoot({super.key});

  static const String termsAcceptedKey = 'perfect_day_terms_accepted_v1';
  static const String privacyAcceptedKey = 'perfect_day_privacy_accepted_v1';

  @override
  State<AppRoot> createState() => _AppRootState();
}

class _AppRootState extends State<AppRoot> {
  bool _isLoading = true;
  bool _isConsented = false;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadConsentState();
  }

  Future<void> _loadConsentState() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final bool termsAccepted = prefs.getBool(AppRoot.termsAcceptedKey) ?? false;
    final bool privacyAccepted =
        prefs.getBool(AppRoot.privacyAcceptedKey) ?? false;

    if (!mounted) {
      return;
    }

    setState(() {
      _isConsented = termsAccepted && privacyAccepted;
      _isLoading = false;
    });

    if (_isConsented) {
      _maybeAutoSyncOnOpen();
    }
  }

  Future<void> _handleConsentAccepted() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppRoot.termsAcceptedKey, true);
    await prefs.setBool(AppRoot.privacyAcceptedKey, true);

    if (!mounted) {
      return;
    }

    setState(() {
      _isConsented = true;
    });

    _maybeAutoSyncOnOpen();
  }

  Future<void> _maybeAutoSyncOnOpen() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final bool enabled = prefs.getBool(SettingsViewModel.autoSyncOnOpenKey) ?? false;
    if (!enabled) {
      return;
    }

    final Set<SourceType> sourceTypes = <SourceType>{};
    if (prefs.getBool(SettingsViewModel.healthKey) ?? true) {
      sourceTypes.add(SourceType.health);
    }
    if (prefs.getBool(SettingsViewModel.calendarKey) ?? true) {
      sourceTypes.add(SourceType.calendar);
    }
    if (prefs.getBool(SettingsViewModel.screenTimeKey) ?? true) {
      sourceTypes.add(SourceType.screenTime);
    }

    if (sourceTypes.isEmpty) {
      return;
    }

    final TodayStorage storage = await TodayStorage.create();
    final SourceImporter importer = SourceImporter(
      storage: storage,
      adapters: <SourceAdapter>[
        MockHealthSourceAdapter(),
        MockCalendarSourceAdapter(),
        MockScreenTimeSourceAdapter(),
      ],
    );

    final String? storedLookback = prefs.getString(SettingsViewModel.lookbackKey);
    final int lookbackDays = SettingsViewModel.lookbackDaysFromStored(storedLookback);
    final DateTime to = DateTime.now();
    final DateTime from = to.subtract(Duration(days: lookbackDays));
    await importer.importForRange(
      from: from,
      to: to,
      enabledSources: sourceTypes,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              TweenAnimationBuilder<double>(
                duration: const Duration(milliseconds: 900),
                tween: Tween<double>(begin: 0.9, end: 1.1),
                curve: Curves.easeInOut,
                builder: (context, value, child) {
                  return Transform.scale(scale: value, child: child);
                },
                child: const SizedBox(
                  height: 28,
                  width: 28,
                  child: CircularProgressIndicator(strokeWidth: 2.8),
                ),
              ),
              const SizedBox(height: PdSpacing.sm),
              Text('Loading Perfect Day...', style: PdTypography.body),
            ],
          ),
        ),
      );
    }

    if (!_isConsented) {
      return ConsentScreen(onAccepted: _handleConsentAccepted);
    }

    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: const <Widget>[
          HomeScreen(),
          TodayScreen(),
          HistoryScreen(),
          TrendsScreen(),
          SettingsScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        destinations: const <NavigationDestination>[
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.today_outlined),
            selectedIcon: Icon(Icons.today),
            label: 'Today',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_outlined),
            selectedIcon: Icon(Icons.history),
            label: 'History',
          ),
          NavigationDestination(
            icon: Icon(Icons.show_chart_outlined),
            selectedIcon: Icon(Icons.show_chart),
            label: 'Trends',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
      ),
    );
  }
}
