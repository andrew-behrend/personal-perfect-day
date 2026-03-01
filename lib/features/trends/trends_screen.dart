import 'package:flutter/material.dart';

import '../../design/components/pd_card.dart';
import '../../design/layout/pd_screen.dart';
import '../../design/tokens/colors.dart';
import '../../design/tokens/spacing.dart';
import '../../design/tokens/typography.dart';
import 'trends_view_model.dart';

class TrendsScreen extends StatefulWidget {
  const TrendsScreen({super.key});

  @override
  State<TrendsScreen> createState() => _TrendsScreenState();
}

class _TrendsScreenState extends State<TrendsScreen> {
  TrendsViewModel? _viewModel;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final TrendsViewModel model = await TrendsViewModel.create();
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
    final TrendsViewModel? model = _viewModel;
    return Scaffold(
      body: PdScreen(
        child: model == null
            ? Padding(
                padding: const EdgeInsets.only(top: PdSpacing.xl),
                child: Text('Loading trends...', style: PdTypography.body),
              )
            : AnimatedBuilder(
                animation: model,
                builder: (context, _) {
                  if (model.isLoading) {
                    return Padding(
                      padding: const EdgeInsets.only(top: PdSpacing.xl),
                      child: Text('Loading trends...', style: PdTypography.body),
                    );
                  }

                  return SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: PdSpacing.lg),
                        Text('Trends', style: PdTypography.heading2),
                        const SizedBox(height: PdSpacing.xs),
                        Text(
                          'Look for patterns over week, month, and year.',
                          style: PdTypography.bodySmall,
                        ),
                        const SizedBox(height: PdSpacing.md),
                        PdCard(
                          child: SegmentedButton<TrendRange>(
                            segments: const <ButtonSegment<TrendRange>>[
                              ButtonSegment<TrendRange>(
                                value: TrendRange.week,
                                label: Text('Week'),
                              ),
                              ButtonSegment<TrendRange>(
                                value: TrendRange.month,
                                label: Text('Month'),
                              ),
                              ButtonSegment<TrendRange>(
                                value: TrendRange.year,
                                label: Text('Year'),
                              ),
                            ],
                            selected: <TrendRange>{model.range},
                            onSelectionChanged: (selection) {
                              model.setRange(selection.first);
                            },
                          ),
                        ),
                        const SizedBox(height: PdSpacing.md),
                        if (!model.hasData)
                          PdCard(
                            child: Text(
                              'No data available for this range yet.',
                              style: PdTypography.body,
                            ),
                          )
                        else ...[
                          _buildSummaryCard(model),
                          const SizedBox(height: PdSpacing.md),
                          _buildRatingTrendCard(model),
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

  Widget _buildSummaryCard(TrendsViewModel model) {
    return PdCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${model.rangeLabel} summary', style: PdTypography.title),
          const SizedBox(height: PdSpacing.sm),
          _summaryRow('Average rating', '${model.averageRating.toStringAsFixed(1)}/10'),
          const SizedBox(height: PdSpacing.xs),
          _summaryRow('Best day', model.bestDay),
          const SizedBox(height: PdSpacing.xs),
          _summaryRow('Consistency', model.consistencySummary),
          const SizedBox(height: PdSpacing.xs),
          _summaryRow('Quick assessments', model.assessmentCount.toString()),
          const SizedBox(height: PdSpacing.xs),
          _summaryRow('Micro-notes', model.noteCount.toString()),
        ],
      ),
    );
  }

  Widget _buildRatingTrendCard(TrendsViewModel model) {
    return PdCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Daily ratings', style: PdTypography.title),
          const SizedBox(height: PdSpacing.sm),
          ...model.trendPoints.map(
            (point) => Padding(
              padding: const EdgeInsets.only(bottom: PdSpacing.sm),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(point.label, style: PdTypography.body),
                      Text('${point.rating.toStringAsFixed(1)}/10', style: PdTypography.label),
                    ],
                  ),
                  const SizedBox(height: PdSpacing.xs),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: point.rating / 10,
                      minHeight: 8,
                      backgroundColor: PdColors.surfaceAlt,
                      color: PdColors.brand,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(child: Text(label, style: PdTypography.body)),
        const SizedBox(width: PdSpacing.sm),
        Flexible(
          child: Text(
            value,
            style: PdTypography.bodySmall,
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }
}
