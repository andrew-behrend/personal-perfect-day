# Perfect Day Backlog

## High Priority

1. Home page legal consent
- Add required checkboxes on the home page for acceptance of Terms of Use and Privacy Policy.
- Define whether both checkboxes are mandatory before continuing.
- Add links or in-app views for both documents.

2. Historical data policy
- Decide whether Perfect Day should ingest historical data from source apps during onboarding.
- If yes, define lookback window policy (for example: 7 days, 30 days, 90 days, or full available history).
- Define how historical imports should affect baseline insights and first-time user experience.

3. Source management settings page
- Move source-management concerns off the Today page into a dedicated Settings page.
- Support both currently connected and potential future sources.
- Define source-level controls (connect/disconnect, permissions status, sync scope).

4. Quick assessment + composite day score
- Add a lightweight "quick assessment" action for "How is your day going right now?"
- Support multiple ratings during a single day.
- Define how intraday ratings combine into the final "How was your day?" score.

5. Perfect Day target assessment
- Add an onboarding/assessment flow to capture each user's target "perfect day".
- Collect preferred activities and relative importance/weights.
- Use as a future baseline for guidance and comparison.

6. Micro-notes for sentiment context
- Allow quick notes: "what's happening now?" and "how does it make me feel?"
- Treat notes as potential source data for future sentiment analysis and pattern extraction.

7. Upcoming commitments impact view
- Surface upcoming events and commitments that could affect the user's chance of having a "perfect day".
- Connect commitments to day-quality domains (workload, social, travel, focus time, recovery windows).
- Use this as a planning aid, not just retrospective analysis.

8. Perfect-day behavior gamification
- Explore lightweight gamification for completing actions/events associated with a user's perfect day.
- Define mechanics carefully to reinforce healthy behavior without creating noisy or stressful UX.
- Consider streaks, milestones, and progress cues tied to user-defined priorities.

9. Trends page with time-range selector
- Add a dedicated Trends page.
- Include week, month, and year selectors.
- Show rating and domain trends over time with clear, non-clinical summaries.

10. History day selection UX
- Replace History page day dropdown with a calendar-based day selector.
- Support quick navigation across months and clear indication of days with data.
- Preserve selected-day detail cards beneath the calendar.

11. Deferred: background sync architecture
- Keep current behavior as manual sync + optional auto-sync on app open.
- Design true background sync scheduling for supported platforms later.
- Define retry/backoff strategy and user-visible sync status.

12. Deferred: platform/source constraints for live integrations
- Document iOS/Android background execution limits and entitlement requirements.
- Define source-specific permissions and failure handling (HealthKit, Calendar, Screen Time equivalents).
- Add compliance/privacy review before enabling live source ingestion.

13. Optional dark mode
- Add an optional dark theme setting in app settings.
- Persist user theme preference and apply across all pages.
- Ensure design tokens/components support light and dark variants consistently.

## Product Direction Notes

- Current development preference: prioritize automatically gathered data from connected sources over manual user event entry.
- Manual quick/custom event capture should remain lightweight and temporary until source integrations are introduced.
