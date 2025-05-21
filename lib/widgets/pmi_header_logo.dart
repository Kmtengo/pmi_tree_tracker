import 'package:flutter/material.dart';

class PMIHeaderLogo extends StatelessWidget {
  final double height;
  final bool withShadow;

  const PMIHeaderLogo({
    super.key,
    this.height = 30,
    this.withShadow = true,
  });

  @override
  Widget build(BuildContext context) {
    final logo = Image.asset(
      'assets/images/pmi_logo.png',
      height: height,
      errorBuilder: (context, error, stackTrace) => Icon(
        Icons.eco,
        color: Theme.of(context).colorScheme.primary,
        size: height,
      ),
    );

    if (withShadow) {
      return Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: logo,
      );
    }

    return logo;
  }
}
