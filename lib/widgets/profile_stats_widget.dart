import 'package:flutter/material.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';

class ProfileStatsWidget extends StatelessWidget {
  final double totalDistance;
  final int totalTreks;
  final int fortsConquered;
  final VoidCallback? onTap;

  const ProfileStatsWidget({
    super.key,
    required this.totalDistance,
    required this.totalTreks,
    required this.fortsConquered,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
          border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatItem(context, Symbols.route, totalDistance.toStringAsFixed(1), 'KM DISTANCE'),
            _buildDivider(context),
            _buildStatItem(context, Symbols.fort, fortsConquered.toString(), 'FORTS'),
            _buildDivider(context),
            _buildStatItem(context, Symbols.landscape, totalTreks.toString(), 'TREKS'),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider(BuildContext context) {
    return Container(
      height: 40,
      width: 1,
      color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5),
    );
  }

  Widget _buildStatItem(BuildContext context, IconData icon, String value, String label) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        Icon(icon, color: colorScheme.primary, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(context).textTheme.displaySmall?.copyWith(fontSize: 20),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
            fontSize: 9,
            letterSpacing: 1.0,
          ),
        ),
      ],
    );
  }
}
