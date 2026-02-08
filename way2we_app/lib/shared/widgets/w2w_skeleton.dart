import 'package:flutter/material.dart';
import 'package:way2we_app/theme/theme.dart';

class W2WSkeleton extends StatelessWidget {
  const W2WSkeleton({
    this.height = 16,
    this.width = double.infinity,
    this.radius = AppSpacing.radiusLg,
    super.key,
  });

  final double height;
  final double width;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}
