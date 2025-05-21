import 'package:flutter/material.dart';

class PMIButtonStyles {
  static ButtonStyle primaryButton(BuildContext context) {
    return ElevatedButton.styleFrom(
      backgroundColor: Theme.of(context).colorScheme.primary, // Forest Green
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
    );
  }

  static ButtonStyle secondaryButton(BuildContext context) {
    return ElevatedButton.styleFrom(
      backgroundColor: Theme.of(context).colorScheme.tertiary, // PMI Blue
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
    );
  }

  static ButtonStyle destructiveButton(BuildContext context) {
    return ElevatedButton.styleFrom(
      backgroundColor: Theme.of(context).colorScheme.secondary, // Orange-Red
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
    );
  }

  static ButtonStyle textButton(BuildContext context) {
    return TextButton.styleFrom(
      foregroundColor: Theme.of(context).colorScheme.tertiary, // PMI Blue
      padding: const EdgeInsets.symmetric(horizontal: 16),
    );
  }
}
