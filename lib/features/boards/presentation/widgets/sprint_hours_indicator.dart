import 'package:flutter/material.dart';

class SprintHoursIndicator extends StatelessWidget {
  final double totalHours;
  final bool isDark;

  const SprintHoursIndicator({
    super.key,
    required this.totalHours,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.blue.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.access_time,
            size: 16,
            color: Colors.blue,
          ),
          const SizedBox(width: 6),
          Text(
            '${totalHours.toStringAsFixed(1)}h',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.blue,
            ),
          ),
        ],
      ),
    );
  }
}
