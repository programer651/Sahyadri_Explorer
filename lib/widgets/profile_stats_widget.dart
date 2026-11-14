import 'package:material_ui/material_ui.dart';

class ProfileStatsWidget extends StatelessWidget {
  final double totalDistance;
  final int totalTreks;
  final int fortsConquered;
  final int totalWalks;
  final VoidCallback? onTreksTap;
  final VoidCallback? onWalksTap;
  final VoidCallback? onTap;

  const ProfileStatsWidget({
    super.key,
    required this.totalDistance,
    required this.totalTreks,
    required this.fortsConquered,
    this.totalWalks = 0,
    this.onTreksTap,
    this.onWalksTap,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
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
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // KM Distance
          Expanded(
            child: _buildClickableStatItem(
              context,
              icon: Icons.alt_route,
              value: totalDistance.toStringAsFixed(1),
              label: 'KM DIST',
              onItemTap: onTap ?? onTreksTap,
            ),
          ),
          _buildDivider(context),

          // Forts Conquered
          Expanded(
            child: _buildClickableStatItem(
              context,
              icon: Icons.fort,
              value: fortsConquered.toString(),
              label: 'FORTS',
              onItemTap: onTreksTap ?? onTap,
            ),
          ),
          _buildDivider(context),

          // Total Treks
          Expanded(
            child: _buildClickableStatItem(
              context,
              icon: Icons.landscape,
              value: totalTreks.toString(),
              label: 'TREKS',
              onItemTap: onTreksTap ?? onTap,
            ),
          ),
          _buildDivider(context),

          // Walks (New 4th Metric)
          Expanded(
            child: _buildClickableStatItem(
              context,
              icon: Icons.directions_walk,
              value: totalWalks.toString(),
              label: 'WALKS',
              iconColor: const Color(0xFF0EA5E9),
              onItemTap: onWalksTap,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider(BuildContext context) {
    return Container(
      height: 36,
      width: 1,
      color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.4),
    );
  }

  Widget _buildClickableStatItem(
    BuildContext context, {
    required IconData icon,
    required String value,
    required String label,
    Color? iconColor,
    VoidCallback? onItemTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onItemTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: iconColor ?? colorScheme.primary, size: 22),
            const SizedBox(height: 6),
            Text(
              value,
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontSize: 9,
                    letterSpacing: 0.8,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
