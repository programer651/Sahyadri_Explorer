import 'package:flutter/material.dart';
import '../models/trek_session_model.dart';
import '../theme.dart';

class LiveTrekStatsWidget extends StatelessWidget {
  final TrekSession session;
  final double completionPercentage;

  const LiveTrekStatsWidget({
    super.key, 
    required this.session,
    required this.completionPercentage,
  });

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(d.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(d.inSeconds.remainder(60));
    return "${twoDigits(d.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1), 
            blurRadius: 15, 
            offset: const Offset(0, 6)
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                'Trek Progress',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.outline, fontSize: 11),
              ),
              Text(
                '${(completionPercentage * 100).toInt()}%',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.primary),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: completionPercentage,
              minHeight: 8,
              backgroundColor: AppColors.primaryFixedDim.withValues(alpha: 0.3),
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${session.distanceCoveredKm.toStringAsFixed(2)} KM',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.onSurface),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Text('•', style: TextStyle(color: AppColors.outline, fontWeight: FontWeight.bold)),
              ),
              Text(
                _formatDuration(session.timeElapsed),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.onSurface),
              ),
            ],
          )
        ],
      ),
    );
  }
}
