import 'package:flutter/material.dart';

import '../../design/components/pd_button.dart';
import '../../design/components/pd_card.dart';
import '../../design/layout/pd_screen.dart';
import '../../design/tokens/colors.dart';
import '../../design/tokens/radius.dart';
import '../../design/tokens/spacing.dart';
import '../../design/tokens/typography.dart';
import '../today/today_view_model.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  TodayViewModel? _viewModel;
  double _quickRating = 7;
  final TextEditingController _noteController = TextEditingController();
  double _noteFeeling = 3;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final TodayViewModel model = await TodayViewModel.create();
    if (!mounted) {
      model.dispose();
      return;
    }
    setState(() {
      _viewModel = model;
      _quickRating = model.rating;
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
                child: Text('Loading home...', style: PdTypography.body),
              )
            : AnimatedBuilder(
                animation: model,
                builder: (context, _) {
                  return SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: PdSpacing.lg),
                        Text('Home', style: PdTypography.heading2),
                        const SizedBox(height: PdSpacing.xs),
                        Text(
                          'Quickly capture your day in real time.',
                          style: PdTypography.bodySmall,
                        ),
                        const SizedBox(height: PdSpacing.lg),
                        _buildQuickAssessmentCard(model),
                        const SizedBox(height: PdSpacing.md),
                        _buildMicroNoteCard(model),
                        const SizedBox(height: PdSpacing.md),
                        _buildPulseSnapshotCard(model),
                        const SizedBox(height: PdSpacing.xl),
                      ],
                    ),
                  );
                },
              ),
      ),
    );
  }

  Widget _buildQuickAssessmentCard(TodayViewModel model) {
    return PdCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Quick assessment', style: PdTypography.title),
          const SizedBox(height: PdSpacing.xs),
          Text(
            'How is your day going right now?',
            style: PdTypography.bodySmall,
          ),
          const SizedBox(height: PdSpacing.sm),
          Text(
            'Current: ${_quickRating.round()}/10',
            style: PdTypography.body,
          ),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: PdColors.brand,
              inactiveTrackColor: PdColors.surfaceAlt,
              thumbColor: PdColors.brand,
            ),
            child: Slider(
              min: 1,
              max: 10,
              divisions: 9,
              value: _quickRating,
              onChanged: (value) {
                setState(() {
                  _quickRating = value;
                });
              },
            ),
          ),
          PdButton(
            label: 'Save quick assessment',
            onPressed: () => model.addQuickAssessment(
              withRating: _quickRating,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMicroNoteCard(TodayViewModel model) {
    return PdCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Micro-note', style: PdTypography.title),
          const SizedBox(height: PdSpacing.xs),
          Text(
            'What is happening now, and how do you feel?',
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
            label: 'Save micro-note',
            variant: PdButtonVariant.secondary,
            isLoading: model.isAddingNote,
            onPressed: model.isAddingNote
                ? null
                : () async {
                    final String text = _noteController.text.trim();
                    if (text.isEmpty) {
                      return;
                    }
                    await model.addMicroNote(
                      text: text,
                      feeling: _noteFeeling.round(),
                    );
                    _noteController.clear();
                  },
          ),
          if (model.lastNoteMessage != null) ...[
            const SizedBox(height: PdSpacing.xs),
            Text(model.lastNoteMessage!, style: PdTypography.bodySmall),
          ],
        ],
      ),
    );
  }

  Widget _buildPulseSnapshotCard(TodayViewModel model) {
    return PdCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Today pulse', style: PdTypography.title),
          const SizedBox(height: PdSpacing.xs),
          Text(
            '${model.pulseScore.toStringAsFixed(1)}/10',
            style: PdTypography.heading2,
          ),
          const SizedBox(height: PdSpacing.xs),
          Text(
            '${model.quickAssessments.length} quick assessments logged today',
            style: PdTypography.bodySmall,
          ),
          Text(
            '${model.recentNotes.length} recent micro-notes',
            style: PdTypography.bodySmall,
          ),
        ],
      ),
    );
  }
}
