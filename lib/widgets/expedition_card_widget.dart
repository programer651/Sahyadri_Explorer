import 'package:flutter/material.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';
import '../models/expedition_model.dart';
import '../models/fort_model.dart';
import '../theme.dart';

enum ExpeditionCardType { recent, suggested }

class ExpeditionCardWidget extends StatelessWidget {
  final Expedition? expedition;
  final Fort? fort;
  final ExpeditionCardType type;
  final double? distanceToUser;

  const ExpeditionCardWidget.recent({
    super.key,
    required this.expedition,
  }) : fort = null, type = ExpeditionCardType.recent, distanceToUser = null;

  const ExpeditionCardWidget.suggested({
    super.key,
    required this.fort,
    required this.distanceToUser,
  }) : expedition = null, type = ExpeditionCardType.suggested;

  @override
  Widget build(BuildContext context) {
    final title = type == ExpeditionCardType.recent ? expedition!.fortName : fort!.name;
    final subtitle = type == ExpeditionCardType.recent 
        ? '${expedition!.distanceKm.toStringAsFixed(1)} km • ${expedition!.completionPercentage >= 0.9 ? 'Conquered' : 'Abandoned'}'
        : '${fort!.difficulty} • ${(distanceToUser! / 1000).toStringAsFixed(1)} km away';
    
    final dateOrTime = type == ExpeditionCardType.recent
        ? _formatDate(expedition!.date)
        : fort!.estimatedTime;

    return Container(
      width: 280,
      margin: const EdgeInsets.only(right: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.3)),
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
          // Header Icon or Image placeholder
          Container(
            height: 120,
            decoration: BoxDecoration(
              color: type == ExpeditionCardType.recent ? AppColors.primaryFixedDim : AppColors.secondaryFixedDim,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              gradient: LinearGradient(
                colors: type == ExpeditionCardType.recent 
                  ? [AppColors.primary, AppColors.primaryFixed]
                  : [AppColors.secondary, AppColors.secondaryFixed],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Center(
              child: Icon(
                type == ExpeditionCardType.recent ? Symbols.mountain_flag : Symbols.explore,
                color: Colors.white,
                size: 48,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: Theme.of(context).textTheme.displaySmall?.copyWith(fontSize: 16),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      dateOrTime,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.outline, fontSize: 9),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.outline, fontSize: 12),
                ),
                if (type == ExpeditionCardType.suggested) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _buildTag(fort!.difficulty.toUpperCase()),
                      const SizedBox(width: 8),
                      _buildTag('NEARBY'),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays == 0) return 'TODAY';
    if (diff.inDays == 1) return 'YESTERDAY';
    return '${diff.inDays} DAYS AGO';
  }

  Widget _buildTag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.onSurfaceVariant),
      ),
    );
  }
}
