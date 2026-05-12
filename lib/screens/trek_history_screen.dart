import 'package:flutter/material.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';
import '../models/expedition_model.dart';
import '../app_theme.dart';

class TrekHistoryScreen extends StatelessWidget {
  final List<Expedition> expeditions;

  const TrekHistoryScreen({super.key, required this.expeditions});

  @override
  Widget build(BuildContext context) {
    final completed = expeditions.where((e) => e.isConquered).toList();
    final incomplete = expeditions.where((e) => !e.isConquered).toList();
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text('Expedition Journal', style: Theme.of(context).textTheme.displaySmall),
        centerTitle: true,
      ),
      body: CustomScrollView(
        slivers: [
          if (completed.isNotEmpty) ...[
            _buildSectionHeader(context, 'COMPLETED EXPEDITIONS', completed.length),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => _TrekDetailCard(expedition: completed[index]),
                childCount: completed.length,
              ),
            ),
          ],
          if (incomplete.isNotEmpty) ...[
            _buildSectionHeader(context, 'STARTED / INCOMPLETE', incomplete.length),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => _TrekDetailCard(expedition: incomplete[index]),
                childCount: incomplete.length,
              ),
            ),
          ],
          if (expeditions.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Symbols.explore, size: 64, color: colorScheme.outlineVariant),
                    const SizedBox(height: 16),
                    Text(
                      'No entries in your journal yet',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: colorScheme.onSurfaceVariant),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Start your first trek to see achievements!',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7)),
                    ),
                  ],
                ),
              ),
            ),
          const SliverPadding(padding: EdgeInsets.only(bottom: 40)),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, int count) {
    final colorScheme = Theme.of(context).colorScheme;
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
      sliver: SliverToBoxAdapter(
        child: Row(
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    letterSpacing: 1.5,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                count.toString(),
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: colorScheme.primary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TrekDetailCard extends StatelessWidget {
  final Expedition expedition;

  const _TrekDetailCard({required this.expedition});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      expedition.fortName,
                      style: Theme.of(context).textTheme.displaySmall?.copyWith(fontSize: 18),
                    ),
                    Text(
                      _formatDateTime(expedition.date),
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(fontSize: 11, color: colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              _buildStatusBadge(context),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatInfo(context, Symbols.route, '${expedition.distanceKm.toStringAsFixed(1)} KM', 'DISTANCE'),
              _buildStatInfo(context, Symbols.schedule, _formatDuration(expedition.duration), 'DURATION'),
              _buildStatInfo(context, Symbols.analytics, '${(expedition.completionPercentage * 100).toInt()}%', 'PROGRESS'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isConquered = expedition.isConquered;
    final bgColor = isConquered ? colorScheme.primary.withValues(alpha: 0.1) : colorScheme.secondary.withValues(alpha: 0.1);
    final textColor = isConquered ? colorScheme.primary : colorScheme.secondary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: textColor.withValues(alpha: 0.2)),
      ),
      child: Text(
        isConquered ? 'CONQUERED' : 'PARTIAL',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
      ),
    );
  }

  Widget _buildStatInfo(BuildContext context, IconData icon, String value, String label) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: colorScheme.onSurfaceVariant),
            const SizedBox(width: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(fontSize: 9, letterSpacing: 0.5, color: colorScheme.onSurfaceVariant),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: colorScheme.primary,
              ),
        ),
      ],
    );
  }

  String _formatDateTime(DateTime date) {
    return '${date.day}/${date.month}/${date.year} at ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    if (hours > 0) return '${hours}h ${minutes}m';
    if (minutes > 0) return '${minutes}m ${seconds}s';
    return '${seconds}s';
  }
}
