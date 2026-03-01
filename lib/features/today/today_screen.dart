import 'package:flutter/material.dart';

import '../../design/components/pd_button.dart';
import '../../design/components/pd_card.dart';
import '../../design/layout/pd_screen.dart';
import '../../design/tokens/colors.dart';
import '../../design/tokens/radius.dart';
import '../../design/tokens/spacing.dart';
import '../../design/tokens/typography.dart';
import 'models/day_models.dart';
import 'today_view_model.dart';

class TodayScreen extends StatefulWidget {
  const TodayScreen({super.key});

  @override
  State<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends State<TodayScreen> {
  TodayViewModel? _viewModel;
  DayDomain _selectedDomain = DayDomain.work;
  double _customDurationMinutes = 30;
  final TextEditingController _noteController = TextEditingController();
  double _noteFeeling = 3;

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
    _noteController.dispose();
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
                        _buildSourcesHintCard(),
                        const SizedBox(height: PdSpacing.md),
                        _buildTodayEventsCard(model),
                        const SizedBox(height: PdSpacing.md),
                        _buildAtAGlanceCard(model),
                        const SizedBox(height: PdSpacing.md),
                        _buildTimeBreakdownCard(model),
                        const SizedBox(height: PdSpacing.md),
                        _buildNotablesCard(model),
                        const SizedBox(height: PdSpacing.md),
                        _buildRatingCard(model),
                        const SizedBox(height: PdSpacing.md),
                        _buildMicroNotesCard(model),
                        const SizedBox(height: PdSpacing.md),
                        _buildQuickAddCard(model),
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
          Text('Manual add (temporary)', style: PdTypography.title),
          const SizedBox(height: PdSpacing.xs),
          Text(
            'Auto-collected data is the primary path. Use this only to patch gaps.',
            style: PdTypography.bodySmall,
          ),
          const SizedBox(height: PdSpacing.sm),
          ...model.quickAddOptions.map((option) {
            return Padding(
              padding: const EdgeInsets.only(bottom: PdSpacing.xs),
              child: PdButton(
                label: option.label,
                variant: PdButtonVariant.secondary,
                onPressed: model.isAddingEvent
                    ? null
                    : () => model.addQuickEventFromAction(option),
              ),
            );
          }),
          const SizedBox(height: PdSpacing.xs),
          Text('Custom event', style: PdTypography.label),
          const SizedBox(height: PdSpacing.xs),
          InputDecorator(
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: PdSpacing.sm,
                vertical: PdSpacing.xs,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(PdRadius.sm),
                borderSide: const BorderSide(color: PdColors.border),
              ),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<DayDomain>(
                value: _selectedDomain,
                isExpanded: true,
                items: model.trackableDomains.map((domain) {
                  return DropdownMenuItem<DayDomain>(
                    value: domain,
                    child: Text(
                      model.domainLabel(domain),
                      style: PdTypography.body,
                    ),
                  );
                }).toList(),
                onChanged: model.isAddingEvent
                    ? null
                    : (value) {
                        if (value == null) {
                          return;
                        }
                        setState(() {
                          _selectedDomain = value;
                        });
                      },
              ),
            ),
          ),
          const SizedBox(height: PdSpacing.xs),
          Text(
            'Duration: ${_customDurationMinutes.round()}m',
            style: PdTypography.bodySmall,
          ),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: PdColors.brand,
              inactiveTrackColor: PdColors.surfaceAlt,
              thumbColor: PdColors.brand,
            ),
            child: Slider(
              min: 10,
              max: 180,
              divisions: 34,
              value: _customDurationMinutes,
              onChanged: model.isAddingEvent
                  ? null
                  : (value) {
                      setState(() {
                        _customDurationMinutes = value;
                      });
                    },
            ),
          ),
          PdButton(
            label: 'Add custom event',
            variant: PdButtonVariant.secondary,
            isLoading: model.isAddingEvent,
            onPressed: model.isAddingEvent
                ? null
                : () => model.addQuickEvent(
                      _selectedDomain,
                      _customDurationMinutes.round(),
                    ),
          ),
          if (model.lastEventMessage != null) ...[
            const SizedBox(height: PdSpacing.xs),
            Text(model.lastEventMessage!, style: PdTypography.bodySmall),
          ],
        ],
      ),
    );
  }

  Widget _buildSourcesHintCard() {
    return PdCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Sources', style: PdTypography.title),
          const SizedBox(height: PdSpacing.xs),
          Text(
            'Source connections are managed in Settings.',
            style: PdTypography.bodySmall,
          ),
        ],
      ),
    );
  }

  Widget _buildTodayEventsCard(TodayViewModel model) {
    return PdCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Today\'s events', style: PdTypography.title),
          const SizedBox(height: PdSpacing.sm),
          ...model.todayEvents.map(
            (entry) => Padding(
              padding: const EdgeInsets.only(bottom: PdSpacing.xs),
              child: _buildTimeRow(entry.key, entry.value),
            ),
          ),
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
          const SizedBox(height: PdSpacing.xs),
          PdButton(
            label: 'Quick assessment',
            variant: PdButtonVariant.secondary,
            onPressed: model.addQuickAssessment,
          ),
          const SizedBox(height: PdSpacing.xs),
          Text(
            'Today pulse: ${model.pulseScore.toStringAsFixed(1)}/10',
            style: PdTypography.bodySmall,
          ),
          ...model.quickAssessments.map(
            (entry) => Padding(
              padding: const EdgeInsets.only(top: PdSpacing.xs),
              child: _buildTimeRow(entry.key, entry.value),
            ),
          ),
          if (model.isSaved) ...[
            const SizedBox(height: PdSpacing.xs),
            Text('Saved', style: PdTypography.bodySmall),
          ],
        ],
      ),
    );
  }

  Widget _buildMicroNotesCard(TodayViewModel model) {
    return PdCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Micro-notes', style: PdTypography.title),
          const SizedBox(height: PdSpacing.xs),
          Text(
            'What is happening now, and how does it feel?',
            style: PdTypography.bodySmall,
          ),
          const SizedBox(height: PdSpacing.sm),
          TextField(
            controller: _noteController,
            maxLines: 2,
            decoration: InputDecoration(
              hintText: 'Short note...',
              hintStyle: PdTypography.bodySmall,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(PdRadius.sm),
                borderSide: const BorderSide(color: PdColors.border),
              ),
            ),
            style: PdTypography.body,
          ),
          const SizedBox(height: PdSpacing.xs),
          Text(
            'Feeling: ${_noteFeeling.round()}/5',
            style: PdTypography.bodySmall,
          ),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: PdColors.brand,
              inactiveTrackColor: PdColors.surfaceAlt,
              thumbColor: PdColors.brand,
            ),
            child: Slider(
              min: 1,
              max: 5,
              divisions: 4,
              value: _noteFeeling,
              onChanged: model.isAddingNote
                  ? null
                  : (value) {
                      setState(() {
                        _noteFeeling = value;
                      });
                    },
            ),
          ),
          PdButton(
            label: 'Save note',
            variant: PdButtonVariant.secondary,
            isLoading: model.isAddingNote,
            onPressed: model.isAddingNote
                ? null
                : () async {
                    final String raw = _noteController.text.trim();
                    if (raw.isEmpty) {
                      return;
                    }
                    await model.addMicroNote(
                      text: raw,
                      feeling: _noteFeeling.round(),
                    );
                    _noteController.clear();
                  },
          ),
          if (model.lastNoteMessage != null) ...[
            const SizedBox(height: PdSpacing.xs),
            Text(model.lastNoteMessage!, style: PdTypography.bodySmall),
          ],
          if (model.recentNotes.isNotEmpty) ...[
            const SizedBox(height: PdSpacing.sm),
            ...model.recentNotes.map(
              (entry) => Padding(
                padding: const EdgeInsets.only(bottom: PdSpacing.xs),
                child: _buildTimeRow(entry.key, entry.value),
              ),
            ),
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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            label,
            style: PdTypography.body,
            overflow: TextOverflow.ellipsis,
            maxLines: 2,
          ),
        ),
        const SizedBox(width: PdSpacing.sm),
        Flexible(
          child: Text(
            value,
            style: PdTypography.label,
            textAlign: TextAlign.right,
            overflow: TextOverflow.ellipsis,
            maxLines: 2,
          ),
        ),
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
