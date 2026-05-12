import 'package:flutter/material.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';
import '../models/trek_session_model.dart';
import '../state/navigation_state_manager.dart';

class TrekSummaryDialog extends StatelessWidget {
  final TrekSession session;
  final bool isVictory;
  final double completionPercentage;

  const TrekSummaryDialog({
    super.key,
    required this.session,
    required this.isVictory,
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
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      color: Colors.black.withValues(alpha: 0.8),
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 30,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isVictory ? Symbols.workspace_premium : Symbols.flag,
                size: 80,
                color: isVictory ? colorScheme.secondary : colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: 24),
              Text(
                isVictory ? 'FORT CONQUERED!' : 'Trek Abandoned',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: isVictory ? colorScheme.secondary : colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                session.activeFort.name,
                style: Theme.of(context).textTheme.displaySmall,
              ),
              const SizedBox(height: 24),
              // Stats Block
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildMiniStat(context, 'Completion', '${(completionPercentage * 100).toInt()}%'),
                    _buildMiniStat(context, 'Distance', '${session.distanceCoveredKm.toStringAsFixed(2)} km'),
                    _buildMiniStat(context, 'Time', _formatDuration(session.timeElapsed)),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    NavigationStateManager().navigateToProfile();
                  },
                  icon: const Icon(Symbols.person),
                  label: const Text('View Profile'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: TextButton.icon(
                  onPressed: () {
                    NavigationStateManager().navigateToMap();
                  },
                  icon: const Icon(Symbols.explore),
                  label: const Text('Return to Map'),
                  style: TextButton.styleFrom(
                    foregroundColor: colorScheme.onSurfaceVariant,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMiniStat(BuildContext context, String label, String value) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: colorScheme.onSurface),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 11),
        ),
      ],
    );
  }
}
