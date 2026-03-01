import 'package:flutter/material.dart';

import '../../design/components/pd_card.dart';
import '../../design/layout/pd_screen.dart';
import '../../design/tokens/spacing.dart';
import '../../design/tokens/typography.dart';

class LegalDocumentScreen extends StatelessWidget {
  const LegalDocumentScreen({
    required this.title,
    required this.placeholderText,
    super.key,
  });

  final String title;
  final String placeholderText;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PdScreen(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: PdSpacing.lg),
              Text(title, style: PdTypography.heading2),
              const SizedBox(height: PdSpacing.sm),
              PdCard(
                child: Text(placeholderText, style: PdTypography.body),
              ),
              const SizedBox(height: PdSpacing.md),
              Text(
                'Placeholder content: final legal copy pending.',
                style: PdTypography.bodySmall,
              ),
              const SizedBox(height: PdSpacing.xl),
            ],
          ),
        ),
      ),
    );
  }
}
