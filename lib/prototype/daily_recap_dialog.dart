import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'daily_progress.dart';

/// Acknowledges a persisted update. It never grants or settles earnings.
class DailyRecapDialog extends StatelessWidget {
  final DailyProgress progress;
  final int earnedGross;
  final double earnedHours;
  final String note;

  const DailyRecapDialog({
    super.key,
    required this.progress,
    required this.earnedGross,
    required this.earnedHours,
    required this.note,
  });

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(progress.state.label),
    content: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${progress.actualMinutes} focused minutes recorded today'),
          Text('${progress.completionPercent}% of today’s target'),
          const SizedBox(height: 16),
          const Text('Added by this update'),
          Text('+${earnedHours.toStringAsFixed(2)} simulated work hours'),
          Text(
            '+${NumberFormat.currency(symbol: r'$', decimalDigits: 2).format(earnedGross / 100)} pending gross',
          ),
          const SizedBox(height: 8),
          const Text('Pending earnings become spendable at weekly payday.'),
          if (progress.actualMinutes > progress.targetMinutes) ...[
            const SizedBox(height: 8),
            const Text(
              'All your minutes are saved. Pay is capped at your target.',
            ),
          ],
          if (note.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text('What you moved forward'),
            Text(note),
          ],
        ],
      ),
    ),
    actions: [
      FilledButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Done'),
      ),
    ],
  );
}
