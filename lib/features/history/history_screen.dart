import 'package:flutter/material.dart';

import '../../design/components/pd_card.dart';
import '../../design/layout/pd_screen.dart';
import '../../design/tokens/spacing.dart';
import '../../design/tokens/typography.dart';
import 'history_view_model.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  HistoryViewModel? _viewModel;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final HistoryViewModel model = await HistoryViewModel.create();
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
    final HistoryViewModel? model = _viewModel;
    return Scaffold(
      body: PdScreen(
        child: model == null
            ? Padding(
                padding: const EdgeInsets.only(top: PdSpacing.xl),
                child: Text('Loading history...', style: PdTypography.body),
              )
            : AnimatedBuilder(
                animation: model,
                builder: (context, _) {
                  if (model.isLoading) {
                    return Padding(
                      padding: const EdgeInsets.only(top: PdSpacing.xl),
                      child: Text('Loading history...', style: PdTypography.body),
                    );
                  }

                  if (model.records.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.only(top: PdSpacing.xl),
                      child: Text('No past days yet.', style: PdTypography.body),
                    );
                  }

                  return SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: PdSpacing.lg),
                        Text('History', style: PdTypography.heading2),
                        const SizedBox(height: PdSpacing.xs),
                        Text(
                          'Review previous days and their outcomes.',
                          style: PdTypography.bodySmall,
                        ),
                        const SizedBox(height: PdSpacing.md),
                        _buildDayPickerCard(model),
                        const SizedBox(height: PdSpacing.md),
                        if (model.selectedRecord == null)
                          PdCard(
                            child: Text(
                              'No data for this day yet.',
                              style: PdTypography.body,
                            ),
                          )
                        else ...[
                          _buildSummaryCard(model),
                          const SizedBox(height: PdSpacing.md),
                          _buildTimeBreakdownCard(model),
                        ],
                        const SizedBox(height: PdSpacing.xl),
                      ],
                    ),
                  );
                },
              ),
      ),
    );
  }

  Widget _buildDayPickerCard(HistoryViewModel model) {
    final DateTime now = DateTime.now();
    return PdCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Pick day', style: PdTypography.title),
          const SizedBox(height: PdSpacing.xs),
          Text(model.selectedDateLabel, style: PdTypography.bodySmall),
          const SizedBox(height: PdSpacing.sm),
          CalendarDatePicker(
            initialDate: model.initialCalendarDate,
            firstDate: DateTime(
              model.firstAvailableDate.year,
              model.firstAvailableDate.month,
              model.firstAvailableDate.day,
            ),
            lastDate: DateTime(now.year, now.month, now.day),
            onDateChanged: (value) {
              model.selectDate(model.dateKeyFromDate(value));
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(HistoryViewModel model) {
    return PdCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Day summary', style: PdTypography.title),
          const SizedBox(height: PdSpacing.sm),
          _row('Rating', model.selectedRating),
          const SizedBox(height: PdSpacing.xs),
          _row('Quick assessments', model.selectedAssessmentCount.toString()),
          const SizedBox(height: PdSpacing.xs),
          _row('Micro-notes', model.selectedNotesCount.toString()),
        ],
      ),
    );
  }

  Widget _buildTimeBreakdownCard(HistoryViewModel model) {
    return PdCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Time breakdown', style: PdTypography.title),
          const SizedBox(height: PdSpacing.sm),
          ...model.timeBreakdown.map(
            (entry) => Padding(
              padding: const EdgeInsets.only(bottom: PdSpacing.xs),
              child: _row(entry.key, entry.value),
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            label,
            style: PdTypography.body,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: PdSpacing.sm),
        Flexible(
          child: Text(
            value,
            style: PdTypography.label,
            textAlign: TextAlign.right,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

}
