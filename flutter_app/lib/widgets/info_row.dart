import 'package:flutter/material.dart';

import '../core/theme.dart';

/// "Label ........ Value" line used inside cards.
class InfoRow extends StatelessWidget {
  const InfoRow({
    super.key,
    required this.label,
    this.value,
    this.valueWidget,
    this.bold = false,
  });

  final String label;
  final String? value;

  /// Use instead of [value] to show a chip or button on the right.
  final Widget? valueWidget;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 124,
            child: Text(
              label,
              style: const TextStyle(color: AppColors.muted, fontSize: 14),
            ),
          ),
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child:
                  valueWidget ??
                  Text(
                    (value == null || value!.isEmpty) ? '-' : value!,
                    style: TextStyle(
                      color: AppColors.ink,
                      fontSize: 14,
                      fontWeight: bold ? FontWeight.w700 : FontWeight.w600,
                    ),
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
