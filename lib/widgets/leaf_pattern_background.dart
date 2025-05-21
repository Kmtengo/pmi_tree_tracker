import 'package:flutter/material.dart';
import '../utils/pmi_colors.dart';

class LeafPatternBackground extends StatelessWidget {
  final Widget child;
  final bool isFormPage;

  const LeafPatternBackground({
    super.key,
    required this.child,
    this.isFormPage = false,
  });  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Tea green background
        Container(
          decoration: BoxDecoration(
            color: isFormPage ? PMIColors.teaGreen.withOpacity(0.5) : PMIColors.teaGreen.withOpacity(0.3),
          ),
        ),
        // Main content
        child,
      ],
    );
  }
}
