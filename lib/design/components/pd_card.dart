import 'package:flutter/material.dart';

import '../tokens/colors.dart';
import '../tokens/radius.dart';
import '../tokens/spacing.dart';

class PdCard extends StatelessWidget {
  const PdCard({
    required this.child,
    this.padding = const EdgeInsets.all(PdSpacing.md),
    this.elevation = 2,
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double elevation;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: PdColors.surface,
      elevation: elevation,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(PdRadius.lg),
        side: const BorderSide(color: PdColors.border),
      ),
      child: Padding(
        padding: padding,
        child: child,
      ),
    );
  }
}
