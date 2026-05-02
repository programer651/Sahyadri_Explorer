import 'package:flutter/material.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';
import '../theme.dart';

class MapScreen extends StatelessWidget {
  const MapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Map Placeholder Background
        Positioned.fill(
          child: Container(
            color: const Color(0xFFE4E2DE),
            child: Image.network(
              'https://lh3.googleusercontent.com/aida-public/AB6AXuC4VRf7jg21y_vH5EX5wRD7Q4jXKVStsuRGXA9zksSYI4Y155GX4yeOyUeBc2zd3mm2T_hu4v0lHjhPRStkwrE2OHr2pBIxtw7S6TThPWDAuokJmXCDPr8gAyzmY6pXOWkne3-6gFBSfnnL8gp5Ywh5enLYEwS-osiZ76fYYmrobfWNSGLpOtuI464_cfeTTjcPnwwge-P7bjPQS9z9PWbRdOSsyaGDFa9cKwH0jjaQjiDPnHhH7Xm6tAzeVvjS8D2LPdLvqiLId_E',
              fit: BoxFit.cover,
            ),
          ),
        ),

        // Map Markers
        const Positioned(
          top: 300,
          left: 180,
          child: MapMarker(title: 'Raigad Fort', isSelected: true),
        ),

        Positioned(
          top: 200,
          right: 80,
          child: _buildSecondaryMarker(),
        ),

        Positioned(
          bottom: 350,
          left: 60,
          child: _buildSecondaryMarker(),
        ),

        // Floating Action Buttons (Top Right)
        Positioned(
          top: 24,
          right: 24,
          child: Column(
            children: [
              _buildFloatingButton(Symbols.my_location),
              const SizedBox(height: 16),
              _buildFloatingButton(Symbols.layers),
            ],
          ),
        ),

        // Start Tracking Button
        Positioned(
          bottom: 260,
          right: 24,
          child: ElevatedButton.icon(
            onPressed: () {},
            icon: const Icon(Symbols.play_arrow, fill: 1),
            label: const Text('START TRACKING'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.secondary,
              foregroundColor: AppColors.onSecondary,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
              ),
              elevation: 8,
              shadowColor: AppColors.secondary.withValues(alpha: 0.3),
              textStyle: Theme.of(context).textTheme.displaySmall?.copyWith(
                fontSize: 16,
                letterSpacing: 1.2,
              ),
            ),
          ),
        ),

        // Bottom Detail Card
        Positioned(
          bottom: 110,
          left: 16,
          right: 16,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.95),
              borderRadius: BorderRadius.circular(32),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryContainer.withValues(alpha: 0.08),
                  blurRadius: 20,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 48,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Raigad Fort',
                          style: Theme.of(context).textTheme.displayMedium,
                        ),
                        Text(
                          'Capital of the Maratha Empire',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.onSurfaceVariant,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        color: AppColors.surfaceContainer,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Symbols.favorite, color: AppColors.primary),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: _buildInfoItem(
                        context,
                        Symbols.distance,
                        'DISTANCE',
                        '12km',
                        AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildInfoItem(
                        context,
                        Symbols.signal_cellular_alt,
                        'DIFFICULTY',
                        'Moderate',
                        AppColors.secondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: ElevatedButton(
                          onPressed: () {},
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 0,
                          ),
                          child: const Text('View Details'),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(Symbols.directions, color: AppColors.primary),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSecondaryMarker() {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.outline.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
          ),
        ],
      ),
      child: const Opacity(
        opacity: 0.6,
        child: Icon(Symbols.fort, size: 16, color: AppColors.primary),
      ),
    );
  }

  Widget _buildFloatingButton(IconData icon) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
          ),
        ],
      ),
      child: Icon(icon, color: AppColors.primary),
    );
  }

  Widget _buildInfoItem(BuildContext context, IconData icon, String label, String value, Color iconColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.05),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontSize: 10,
                    letterSpacing: 0.8,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(fontSize: 18),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class MapMarker extends StatelessWidget {
  final String title;
  final bool isSelected;

  const MapMarker({super.key, required this.title, this.isSelected = false});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            if (isSelected)
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(seconds: 2),
                builder: (context, value, child) {
                  return Container(
                    width: 40 + (20 * value),
                    height: 40 + (20 * value),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1 * (1 - value)),
                      shape: BoxShape.circle,
                    ),
                  );
                },
              ),
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: const Icon(Symbols.fort, size: 20, color: Colors.white, fill: 1),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: AppColors.outline.withValues(alpha: 0.1)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 4,
              ),
            ],
          ),
          child: Text(
            title,
            style: Theme.of(context).textTheme.displaySmall?.copyWith(fontSize: 12),
          ),
        ),
      ],
    );
  }
}
