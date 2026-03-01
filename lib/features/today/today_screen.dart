import 'package:flutter/material.dart';

import '../../design/components/pd_button.dart';
import '../../design/components/pd_card.dart';
import '../../design/layout/pd_screen.dart';
import '../../design/tokens/colors.dart';
import '../../design/tokens/spacing.dart';
import '../../design/tokens/typography.dart';
import 'today_view_model.dart';

class TodayScreen extends StatefulWidget {
  const TodayScreen({super.key});

  @override
  State<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends State<TodayScreen> {
  TodayViewModel? _viewModel;

  @override
  void initState() {
    super.initState();
    _loadViewModel();
  }

  Future<void> _loadViewModel() async {
    final TodayViewModel model = await TodayViewModel.create();
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
    final TodayViewModel? model = _viewModel;
    return Scaffold(
      body: PdScreen(
        child: model == null
            ? Padding(
                padding: const EdgeInsets.only(top: PdSpacing.xl),
                child: Text('Loading today...', style: PdTypography.body),
              )
            : AnimatedBuilder(
                animation: model,
                builder: (context, _) {
                  if (model.isInitializing) {
                    return Padding(
                      padding: const EdgeInsets.only(top: PdSpacing.xl),
                      child: Text('Loading today...', style: PdTypography.body),
                    );
                  }
                  return SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: PdSpacing.lg),
                        Text(_greetingText(), style: PdTypography.heading2),
                        const SizedBox(height: PdSpacing.xs),
                        Text(_formattedDate(), style: PdTypography.bodySmall),
                        const SizedBox(height: PdSpacing.lg),
                        _buildQuickAddCard(model),
                        const SizedBox(height: PdSpacing.md),
                        _buildAtAGlanceCard(model),
                        const SizedBox(height: PdSpacing.md),
                        _buildTimeBreakdownCard(model),
                        const SizedBox(height: PdSpacing.md),
                        _buildNotablesCard(model),
                        const SizedBox(height: PdSpacing.md),
                        _buildRatingCard(model),
                        const SizedBox(height: PdSpacing.md),
                        _buildRecentDaysCard(model),
                        const SizedBox(height: PdSpacing.md),
                        _buildInsightsCard(model),
                        const SizedBox(height: PdSpacing.xl),
                      ],
                    ),
                  );
                },
              ),
      ),
    );
  }

  Widget _buildQuickAddCard(TodayViewModel model) {
    return PdCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Quick add event', style: PdTypography.title),
          const SizedBox(height: PdSpacing.xs),
          Text(
            'Capture meaningful chunks from your day.',
            style: PdTypography.bodySmall,
          ),
          const SizedBox(height: PdSpacing.sm),
          ...model.quickAddOptions.map((option) {
            return Padding(
              padding: const EdgeInsets.only(bottom: PdSpacing.xs),
              child: PdButton(
                label: option.key,
                variant: PdButtonVariant.secondary,
                onPressed: () => model.addQuickEventFromLabel(
                  option.key,
                  option.value,
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildAtAGlanceCard(TodayViewModel model) {
    return PdCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Today at a glance', style: PdTypography.title),
          const SizedBox(height: PdSpacing.sm),
          ...model.atAGlance.map(
            (line) => Padding(
              padding: const EdgeInsets.only(bottom: PdSpacing.xs),
              child: Text('• $line', style: PdTypography.body),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeBreakdownCard(TodayViewModel model) {
    return PdCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Time breakdown', style: PdTypography.title),
          const SizedBox(height: PdSpacing.sm),
          ...model.timeBreakdown.map(
            (entry) => Padding(
              padding: const EdgeInsets.only(bottom: PdSpacing.xs),
              child: _buildTimeRow(entry.key, entry.value),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotablesCard(TodayViewModel model) {
    return PdCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Notable moments', style: PdTypography.title),
          const SizedBox(height: PdSpacing.sm),
          ...model.notables.map(
            (line) => Padding(
              padding: const EdgeInsets.only(bottom: PdSpacing.xs),
              child: Text('• $line', style: PdTypography.body),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingCard(TodayViewModel model) {
    return PdCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('How was your day?', style: PdTypography.title),
          const SizedBox(height: PdSpacing.sm),
          Text(
            'Rating: ${model.rating.round()}/10',
            style: PdTypography.body,
          ),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: PdColors.brand,
              inactiveTrackColor: PdColors.surfaceAlt,
              thumbColor: PdColors.brand,
              overlayColor: PdColors.brand.withValues(alpha: 0.12),
              valueIndicatorColor: PdColors.brand,
              valueIndicatorTextStyle: PdTypography.label.copyWith(
                color: PdColors.textOnDark,
              ),
            ),
            child: Slider(
              min: 1,
              max: 10,
              divisions: 9,
              label: model.rating.round().toString(),
              value: model.rating,
              onChanged: model.isSaving ? null : model.updateRating,
            ),
          ),
          const SizedBox(height: PdSpacing.sm),
          PdButton(
            label: 'Save rating',
            onPressed: model.saveRating,
            isLoading: model.isSaving,
            isSaved: model.isSaved,
          ),
          if (model.isSaved) ...[
            const SizedBox(height: PdSpacing.xs),
            Text('Saved', style: PdTypography.bodySmall),
          ],
        ],
      ),
    );
  }

  Widget _buildRecentDaysCard(TodayViewModel model) {
    return PdCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Recent days', style: PdTypography.title),
          const SizedBox(height: PdSpacing.sm),
          ...model.recentDays.map(
            (entry) => Padding(
              padding: const EdgeInsets.only(bottom: PdSpacing.xs),
              child: _buildTimeRow(entry.key, entry.value),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInsightsCard(TodayViewModel model) {
    return PdCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Patterns', style: PdTypography.title),
          const SizedBox(height: PdSpacing.sm),
          ...model.insights.map(
            (line) => Padding(
              padding: const EdgeInsets.only(bottom: PdSpacing.xs),
              child: Text('• $line', style: PdTypography.body),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: PdTypography.body),
        Text(value, style: PdTypography.label),
      ],
    );
  }

  String _formattedDate() {
    final DateTime now = DateTime.now();
    const List<String> weekdays = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    const List<String> months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

    final String weekday = weekdays[now.weekday - 1];
    final String month = months[now.month - 1];
    return '$weekday, $month ${now.day}';
  }

  String _greetingText() {
    final int hour = DateTime.now().hour;

    if (hour < 12) {
      return 'Good morning, Andrew';
    }
    if (hour < 17) {
      return 'Good afternoon, Andrew';
    }
    return 'Good evening, Andrew';
  }
}
