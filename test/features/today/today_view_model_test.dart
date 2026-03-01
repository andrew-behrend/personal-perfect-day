import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:perfect_day/features/today/models/day_models.dart';
import 'package:perfect_day/features/today/today_view_model.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('initializes with seeded today data', () async {
    final TodayViewModel viewModel = await TodayViewModel.create();

    expect(viewModel.isInitializing, isFalse);
    expect(
      viewModel.timeBreakdown.firstWhere((entry) => entry.key == 'Exercise').value,
      '52m',
    );
  });

  test('quick add action updates time totals', () async {
    final TodayViewModel viewModel = await TodayViewModel.create();
    final QuickAddAction exerciseAction = viewModel.quickAddOptions.firstWhere(
      (action) => action.domain == DayDomain.exercise,
    );

    await viewModel.addQuickEventFromAction(exerciseAction);

    expect(
      viewModel.timeBreakdown.firstWhere((entry) => entry.key == 'Exercise').value,
      '1h 12m',
    );
    expect(viewModel.lastEventMessage, 'Added 20m Exercise');
  });

  test('save rating persists for today', () async {
    final TodayViewModel viewModel = await TodayViewModel.create();

    viewModel.updateRating(9);
    await viewModel.saveRating();

    final TodayViewModel reloaded = await TodayViewModel.create();
    expect(reloaded.rating, 9);
    expect(reloaded.isSaved, isFalse);
  });

  test('today events expose recent entries', () async {
    final TodayViewModel viewModel = await TodayViewModel.create();
    expect(viewModel.todayEvents, isNotEmpty);
    expect(viewModel.todayEvents.first.key, isNotEmpty);
    expect(viewModel.todayEvents.first.value, contains('•'));
  });

  test('trackable domains include reflection for future capture', () async {
    final TodayViewModel viewModel = await TodayViewModel.create();
    expect(viewModel.trackableDomains, contains(DayDomain.reflection));
  });

  test('quick assessments contribute to pulse score', () async {
    final TodayViewModel viewModel = await TodayViewModel.create();
    viewModel.updateRating(8);

    await viewModel.addQuickAssessment();

    expect(viewModel.quickAssessments, isNotEmpty);
    expect(viewModel.pulseScore, 8);
    expect(viewModel.quickAssessments.first.value, 'Rated 8/10');
  });

  test('micro note is stored and exposed in recent notes', () async {
    final TodayViewModel viewModel = await TodayViewModel.create();

    await viewModel.addMicroNote(
      text: 'Focused writing sprint after lunch',
      feeling: 4,
    );

    expect(viewModel.recentNotes, isNotEmpty);
    expect(viewModel.recentNotes.first.value, contains('Feeling 4/5'));
    expect(viewModel.lastNoteMessage, 'Note saved');
  });
}
