import 'package:flutter/material.dart';

import '../tokens/colors.dart';
import '../tokens/spacing.dart';

class PdScreen extends StatelessWidget {
  const PdScreen({
    required this.child,
    this.padding = const EdgeInsets.symmetric(horizontal: PdSpacing.md),
    this.backgroundColor = PdColors.background,
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: backgroundColor,
      child: SafeArea(
        child: Padding(
          padding: padding,
          child: child,
        ),
      ),
    );
  }
}
