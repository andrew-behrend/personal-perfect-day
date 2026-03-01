import 'package:flutter/material.dart';

import '../../design/components/pd_button.dart';
import '../../design/components/pd_card.dart';
import '../../design/layout/pd_screen.dart';
import '../../design/tokens/spacing.dart';
import '../../design/tokens/typography.dart';

class ConsentScreen extends StatefulWidget {
  const ConsentScreen({required this.onAccepted, super.key});

  final Future<void> Function() onAccepted;

  @override
  State<ConsentScreen> createState() => _ConsentScreenState();
}

class _ConsentScreenState extends State<ConsentScreen> {
  bool _acceptedTerms = false;
  bool _acceptedPrivacy = false;
  bool _submitting = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PdScreen(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: PdSpacing.xl),
              Text('Perfect Day', style: PdTypography.heading2),
              const SizedBox(height: PdSpacing.xs),
              Text(
                'Before you continue, review and accept the terms below.',
                style: PdTypography.bodySmall,
              ),
              const SizedBox(height: PdSpacing.lg),
              PdCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Consent', style: PdTypography.title),
                    const SizedBox(height: PdSpacing.sm),
                    CheckboxListTile(
                      value: _acceptedTerms,
                      contentPadding: EdgeInsets.zero,
                      title: Text('I accept the Terms of Use', style: PdTypography.body),
                      onChanged: _submitting
                          ? null
                          : (value) {
                              setState(() {
                                _acceptedTerms = value ?? false;
                              });
                            },
                    ),
                    CheckboxListTile(
                      value: _acceptedPrivacy,
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        'I accept the Privacy Policy',
                        style: PdTypography.body,
                      ),
                      onChanged: _submitting
                          ? null
                          : (value) {
                              setState(() {
                                _acceptedPrivacy = value ?? false;
                              });
                            },
                    ),
                    const SizedBox(height: PdSpacing.sm),
                    PdButton(
                      label: 'Continue',
                      isLoading: _submitting,
                      onPressed: _acceptedTerms && _acceptedPrivacy
                          ? () async {
                              setState(() {
                                _submitting = true;
                              });
                              await widget.onAccepted();
                              if (!mounted) {
                                return;
                              }
                              setState(() {
                                _submitting = false;
                              });
                            }
                          : null,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: PdSpacing.xl),
            ],
          ),
        ),
      ),
    );
  }
}
