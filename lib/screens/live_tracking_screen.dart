import 'package:flutter/material.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';
import '../models/fort_model.dart';
import '../theme.dart';

class LiveTrackingScreen extends StatelessWidget {
  final Fort? activeFort;

  const LiveTrackingScreen({super.key, this.activeFort});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Map Background
        Positioned.fill(
          child: Image.network(
            'https://lh3.googleusercontent.com/aida-public/AB6AXuCLp4EA1eMfEt54EaRLiLKAtI5EJa_lA5lHMsRKgJ854QnKLaAvaKLw4rZyBbkGCS_yb38X0mciHgmI_wxH6qMdLgdE5ahDFFH8y7n5Qo-AsKUi_SrqN-uZi5j4qBDU08OaOsNmOiEjN2LdJRd7d5Vf2Op93y-4wEw0TJkVFbR5frCgC6YoPGaKUUCnb8_KORA-cFV9Jpp8tS3v1qdpvHE7LIoSXDFe9duiLuJNmcbsdaeT3S9G_oHaRCoGwLOMbBkBQf5rw0gl6kY',
            fit: BoxFit.cover,
          ),
        ),

        // Path Overlay
        Center(
          child: Opacity(
            opacity: 0.8,
            child: Icon(Symbols.route, size: 300, color: AppColors.secondary.withValues(alpha: 0.5)),
          ),
        ),

        // Top Stats Bento
        Positioned(
          top: 16,
          left: 16,
          right: 16,
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(child: _buildStatCard(context, Symbols.distance, 'DISTANCE', '4.2', 'km')),
                  const SizedBox(width: 12),
                  Expanded(child: _buildStatCard(context, Symbols.timer, 'TIME', '01:15', ':30')),
                  const SizedBox(width: 12),
                  Expanded(child: _buildStatCard(context, Symbols.speed, 'SPEED', '3.5', 'km/h')),
                ],
              ),
              const SizedBox(height: 12),
              _buildElevationBanner(context),
            ],
          ),
        ),

        // Compass
        Positioned(
          top: 180,
          right: 16,
          child: _buildCompass(),
        ),

        // Action Controls
        Positioned(
          bottom: 160,
          left: 0,
          right: 0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildRoundAction(Symbols.stop, Colors.red, isOutlined: true),
              const SizedBox(width: 24),
              _buildMainAction(Symbols.pause),
              const SizedBox(width: 24),
              _buildRoundAction(Symbols.flag, AppColors.primary, isOutlined: true),
            ],
          ),
        ),

        // Progress Indicator
        Positioned(
          bottom: 110,
          left: 0,
          right: 0,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.6),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('TRAIL COMPLETION', style: Theme.of(context).textTheme.labelSmall?.copyWith(fontSize: 10)),
                    Text('65%', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.primary)),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  height: 4,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainer,
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: 0.65,
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.secondary,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(BuildContext context, IconData icon, String label, String value, String unit) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Row(
              children: [
                Icon(icon, size: 14, color: AppColors.onSurfaceVariant),
                const SizedBox(width: 4),
                Text(label, style: Theme.of(context).textTheme.labelSmall?.copyWith(fontSize: 10)),
              ],
            ),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(value, style: Theme.of(context).textTheme.displayMedium),
                const SizedBox(width: 2),
                Text(unit, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.onSurfaceVariant)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildElevationBanner(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.primaryContainer,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Symbols.filter_hdr, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('ELEVATION GAIN', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Colors.white.withValues(alpha: 0.6), fontSize: 10)),
                  Text('240m', style: Theme.of(context).textTheme.displaySmall?.copyWith(color: Colors.white)),
                ],
              ),
            ],
          ),
          // Simplified Sparkline
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(7, (index) {
              final heights = [0.2, 0.35, 0.5, 0.3, 0.65, 0.8, 0.95];
              return Container(
                margin: const EdgeInsets.only(left: 2),
                width: 4,
                height: 32 * heights[index],
                decoration: BoxDecoration(
                  color: index == 6 ? AppColors.secondary : Colors.white.withValues(alpha: 0.2 + (index * 0.1)),
                  borderRadius: BorderRadius.circular(2),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildCompass() {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
          ),
        ],
      ),
      child: Center(
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.surfaceContainerHigh),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              const Positioned(
                top: 2,
                child: Text('N', style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: AppColors.outline)),
              ),
              Transform.rotate(
                angle: 0.785, // 45 degrees
                child: Container(
                  width: 2,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.secondary,
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoundAction(IconData icon, Color color, {bool isOutlined = false}) {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: isOutlined ? Colors.white.withValues(alpha: 0.9) : color,
        shape: BoxShape.circle,
        border: isOutlined ? Border.all(color: color, width: 2) : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
          ),
        ],
      ),
      child: Icon(icon, color: isOutlined ? color : Colors.white, size: 32, fill: 1),
    );
  }

  Widget _buildMainAction(IconData icon) {
    return Container(
      width: 96,
      height: 96,
      decoration: BoxDecoration(
        color: AppColors.primary,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Icon(icon, color: Colors.white, size: 48, fill: 1),
    );
  }
}
