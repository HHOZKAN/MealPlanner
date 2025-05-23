import 'package:flutter/material.dart';

class FilledTonalIconButton extends StatelessWidget {
  final VoidCallback onPressed;
  final Icon icon;
  final String? tooltip;

  const FilledTonalIconButton({
    Key? key,
    required this.onPressed,
    required this.icon,
    this.tooltip,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return IconButton(
      onPressed: onPressed,
      icon: icon,
      tooltip: tooltip,
      style: IconButton.styleFrom(
        backgroundColor: colorScheme.secondaryContainer,
        foregroundColor: colorScheme.onSecondaryContainer,
        minimumSize: const Size(48, 40),
        padding: const EdgeInsets.all(12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}
