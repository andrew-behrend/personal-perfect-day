import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:perfect_day/features/settings/settings_view_model.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('loads with connected source defaults enabled', () async {
    final SettingsViewModel viewModel = await SettingsViewModel.create();

    expect(viewModel.connectedSources, isNotEmpty);
    expect(viewModel.connectedSources.every((source) => source.enabled), isTrue);
  });

  test('source toggle persists', () async {
    final SettingsViewModel viewModel = await SettingsViewModel.create();
    final String key = viewModel.connectedSources.first.key;

    await viewModel.setSourceEnabled(key, false);

    final SettingsViewModel reloaded = await SettingsViewModel.create();
    expect(
      reloaded.connectedSources.firstWhere((source) => source.key == key).enabled,
      isFalse,
    );
  });

  test('lookback persists', () async {
    final SettingsViewModel viewModel = await SettingsViewModel.create();

    await viewModel.setLookback(ImportLookback.days90);

    final SettingsViewModel reloaded = await SettingsViewModel.create();
    expect(reloaded.lookback, ImportLookback.days90);
  });

  test('sync now sets success message', () async {
    final SettingsViewModel viewModel = await SettingsViewModel.create();

    await viewModel.syncNow();

    expect(viewModel.isSyncing, isFalse);
    expect(viewModel.syncMessage, isNotNull);
  });

  test('auto sync on open persists', () async {
    final SettingsViewModel viewModel = await SettingsViewModel.create();

    await viewModel.setAutoSyncOnOpen(true);

    final SettingsViewModel reloaded = await SettingsViewModel.create();
    expect(reloaded.autoSyncOnOpen, isTrue);
  });
}
