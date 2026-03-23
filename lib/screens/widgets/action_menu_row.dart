import 'package:flutter/material.dart';

import '../../core/app_theme.dart';

class ActionMenuRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;

  const ActionMenuRow({
    super.key,
    required this.icon,
    required this.label,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color ?? AppTheme.textMedium),
        const SizedBox(width: 10),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: color ?? AppTheme.textDark,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
