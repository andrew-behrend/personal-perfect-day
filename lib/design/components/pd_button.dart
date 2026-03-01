import 'package:flutter/material.dart';

import '../tokens/colors.dart';
import '../tokens/radius.dart';
import '../tokens/spacing.dart';
import '../tokens/typography.dart';

enum PdButtonVariant { primary, secondary }

class PdButton extends StatelessWidget {
  const PdButton({
    required this.label,
    required this.onPressed,
    this.variant = PdButtonVariant.primary,
    this.isLoading = false,
    this.isSaved = false,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final PdButtonVariant variant;
  final bool isLoading;
  final bool isSaved;

  bool get _isDisabled => onPressed == null || isLoading || isSaved;

  @override
  Widget build(BuildContext context) {
    final VoidCallback? action = _isDisabled ? null : onPressed;

    if (variant == PdButtonVariant.primary) {
      return ElevatedButton(
        onPressed: action,
        style: ElevatedButton.styleFrom(
          backgroundColor: isSaved ? PdColors.success : PdColors.brand,
          foregroundColor: PdColors.textOnDark,
          disabledBackgroundColor: (isSaved ? PdColors.success : PdColors.brand)
              .withValues(alpha: 0.35),
          disabledForegroundColor: PdColors.textOnDark.withValues(alpha: 0.8),
          elevation: 0,
          minimumSize: const Size(double.infinity, 48),
          padding: const EdgeInsets.symmetric(
            horizontal: PdSpacing.lg,
            vertical: PdSpacing.sm,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(PdRadius.md),
          ),
          textStyle: PdTypography.label,
        ),
        child: _ButtonContent(
          label: label,
          loading: isLoading,
          saved: isSaved,
          dark: true,
        ),
      );
    }

    return OutlinedButton(
      onPressed: action,
      style: OutlinedButton.styleFrom(
        backgroundColor: PdColors.surface,
        foregroundColor: isSaved ? PdColors.success : PdColors.brand,
        disabledForegroundColor: PdColors.textSecondary.withValues(alpha: 0.8),
        side: BorderSide(
          color: _isDisabled
              ? PdColors.border
              : (isSaved ? PdColors.success : PdColors.brand),
        ),
        minimumSize: const Size(double.infinity, 48),
        padding: const EdgeInsets.symmetric(
          horizontal: PdSpacing.lg,
          vertical: PdSpacing.sm,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(PdRadius.md),
        ),
        textStyle: PdTypography.label,
      ),
      child: _ButtonContent(
        label: label,
        loading: isLoading,
        saved: isSaved,
        dark: false,
      ),
    );
  }
}

class _ButtonContent extends StatelessWidget {
  const _ButtonContent({
    required this.label,
    required this.loading,
    required this.saved,
    required this.dark,
  });

  final String label;
  final bool loading;
  final bool saved;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    final TextStyle contentTextStyle = PdTypography.label.copyWith(
      color: dark
          ? PdColors.textOnDark
          : (saved ? PdColors.success : PdColors.brand),
    );

    if (saved) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.check_rounded,
            size: 18,
            color: dark ? PdColors.textOnDark : PdColors.success,
          ),
          const SizedBox(width: PdSpacing.xs),
          Text('Saved', style: contentTextStyle),
        ],
      );
    }

    if (!loading) {
      return Text(label, style: contentTextStyle);
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 16,
          width: 16,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: dark ? PdColors.textOnDark : PdColors.brand,
          ),
        ),
        const SizedBox(width: PdSpacing.xs),
        Text('Loading', style: contentTextStyle),
      ],
    );
  }
}
