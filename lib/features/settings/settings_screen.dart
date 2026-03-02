import 'package:flutter/material.dart';

import '../../design/components/pd_button.dart';
import '../../design/components/pd_card.dart';
import '../../design/layout/pd_screen.dart';
import '../../design/tokens/spacing.dart';
import '../../design/tokens/typography.dart';
import 'legal_document_screen.dart';
import 'settings_view_model.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  SettingsViewModel? _viewModel;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final SettingsViewModel model = await SettingsViewModel.create();
    if (!mounted) {
      model.dispose();
      return;
    }
    setState(() {
      _viewModel = model;
    });
  }

  @override
  void dispose() {
    _viewModel?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final SettingsViewModel? model = _viewModel;
    return Scaffold(
      body: PdScreen(
        child: model == null
            ? Padding(
                padding: const EdgeInsets.only(top: PdSpacing.xl),
                child: Text('Loading settings...', style: PdTypography.body),
              )
            : AnimatedBuilder(
                animation: model,
                builder: (context, _) {
                  return SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: PdSpacing.lg),
                        Text('Settings', style: PdTypography.heading2),
                        const SizedBox(height: PdSpacing.xs),
                        Text(
                          'Manage source connections and import behavior.',
                          style: PdTypography.bodySmall,
                        ),
                        const SizedBox(height: PdSpacing.md),
                        _buildConnectedSources(model),
                        const SizedBox(height: PdSpacing.md),
                        _buildAvailableSources(model),
                        const SizedBox(height: PdSpacing.md),
                        _buildImportPolicy(model),
                        const SizedBox(height: PdSpacing.md),
                        _buildLegalCard(context),
                        const SizedBox(height: PdSpacing.xl),
                      ],
                    ),
                  );
                },
              ),
      ),
    );
  }

  Widget _buildConnectedSources(SettingsViewModel model) {
    return PdCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Connected sources', style: PdTypography.title),
          const SizedBox(height: PdSpacing.sm),
          ...model.connectedSources.map(
            (source) => SwitchListTile(
              value: source.enabled,
              contentPadding: EdgeInsets.zero,
              title: Text(source.name, style: PdTypography.body),
              subtitle: Text(
                '${source.detail}\n${model.sourceStateLabel(source.key)}',
                style: PdTypography.bodySmall,
              ),
              onChanged: (value) => model.setSourceEnabled(source.key, value),
            ),
          ),
          const SizedBox(height: PdSpacing.xs),
          PdButton(
            label: 'Connect Apple Health',
            variant: PdButtonVariant.secondary,
            isLoading: model.isRequestingHealthAccess,
            onPressed: model.requestHealthAccess,
          ),
          const SizedBox(height: PdSpacing.xs),
          PdButton(
            label: 'Refresh source status',
            variant: PdButtonVariant.secondary,
            onPressed: model.refreshSourceStates,
          ),
        ],
      ),
    );
  }

  Widget _buildAvailableSources(SettingsViewModel model) {
    return PdCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Available sources', style: PdTypography.title),
          const SizedBox(height: PdSpacing.sm),
          ...model.availableSources.map(
            (source) => Padding(
              padding: const EdgeInsets.only(bottom: PdSpacing.sm),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(source.name, style: PdTypography.body),
                  Text(source.detail, style: PdTypography.bodySmall),
                  const SizedBox(height: PdSpacing.xs),
                  const PdButton(
                    label: 'Coming soon',
                    variant: PdButtonVariant.secondary,
                    onPressed: null,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImportPolicy(SettingsViewModel model) {
    return PdCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Historical import', style: PdTypography.title),
          const SizedBox(height: PdSpacing.sm),
          SegmentedButton<ImportLookback>(
            segments: const <ButtonSegment<ImportLookback>>[
              ButtonSegment<ImportLookback>(
                value: ImportLookback.days7,
                label: Text('7d'),
              ),
              ButtonSegment<ImportLookback>(
                value: ImportLookback.days30,
                label: Text('30d'),
              ),
              ButtonSegment<ImportLookback>(
                value: ImportLookback.days90,
                label: Text('90d'),
              ),
            ],
            selected: <ImportLookback>{model.lookback},
            onSelectionChanged: (selection) {
              model.setLookback(selection.first);
            },
          ),
          const SizedBox(height: PdSpacing.sm),
          Text(model.importPolicySummary, style: PdTypography.body),
          const SizedBox(height: PdSpacing.xs),
          Text(model.lastSyncLabel, style: PdTypography.bodySmall),
          const SizedBox(height: PdSpacing.xs),
          Text(
            'Final policy is still pending product decision.',
            style: PdTypography.bodySmall,
          ),
          const SizedBox(height: PdSpacing.sm),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: model.autoSyncOnOpen,
            title: Text('Auto-sync on app open', style: PdTypography.body),
            subtitle: Text(
              'Runs source import automatically when app starts.',
              style: PdTypography.bodySmall,
            ),
            onChanged: model.setAutoSyncOnOpen,
          ),
          const SizedBox(height: PdSpacing.sm),
          PdButton(
            label: 'Sync now',
            isLoading: model.isSyncing,
            onPressed: model.syncNow,
          ),
          if (model.syncMessage != null) ...[
            const SizedBox(height: PdSpacing.xs),
            Text(model.syncMessage!, style: PdTypography.bodySmall),
          ],
        ],
      ),
    );
  }

  Widget _buildLegalCard(BuildContext context) {
    return PdCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Legal', style: PdTypography.title),
          const SizedBox(height: PdSpacing.sm),
          PdButton(
            label: 'Privacy Policy',
            variant: PdButtonVariant.secondary,
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const LegalDocumentScreen(
                  title: 'Privacy Policy',
                  placeholderText:
                      'Privacy policy placeholder page. This will describe data collection, storage, retention, and user controls.',
                ),
              ),
            ),
          ),
          const SizedBox(height: PdSpacing.xs),
          PdButton(
            label: 'Terms of Use',
            variant: PdButtonVariant.secondary,
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const LegalDocumentScreen(
                  title: 'Terms of Use',
                  placeholderText:
                      'Terms of use placeholder page. This will outline allowed use, limitations, and user responsibilities.',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
