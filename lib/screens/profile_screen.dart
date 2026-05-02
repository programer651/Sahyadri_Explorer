import 'package:flutter/material.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';
import '../theme.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profile Hero
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Stack(
                children: [
                  Container(
                    width: 128,
                    height: 128,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(32),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 24,
                        ),
                      ],
                      image: const DecorationImage(
                        image: NetworkImage('https://lh3.googleusercontent.com/aida-public/AB6AXuAShccApXRtrFGvAUyNKjB9wiTSdkVACJYU4CSv8BxeQoZe9CN2jjWKulCg8QFhkWUnukrGgg-HOpb8tQj3FfMky04TqnkZIe02-N70PI_lmfFYnTuFK7FJ3nsiQm3wHVD8HHfPh8sjydQ2v7mle69hWnvTmcDtLQ7kN2qrlWtl0QvAznQDMLPWbgksPYPJsDB9vXO-xgB7jkAPEVxQNHoYKqX-xmXurK1yPVdJULlXcjJnRfiIu7EW_Cg4cI0ycQ0j7sx_EsI8cHs'),
                        fit: BoxFit.cover,
                      ),
                      border: Border.all(color: Colors.white, width: 4),
                    ),
                  ),
                  Positioned(
                    bottom: -8,
                    right: -8,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.secondary,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.background, width: 4),
                      ),
                      child: const Icon(Symbols.verified, color: Colors.white, size: 14, fill: 1),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Aditya Kulkarni', style: Theme.of(context).textTheme.displayLarge),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primaryFixed,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            'LEVEL 12 EXPLORER',
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.onPrimaryFixed),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Symbols.location_on, size: 16, color: AppColors.outline),
                        const SizedBox(width: 4),
                        Text('Pune, MH', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.outline, fontSize: 14)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 40),

          // Stats Grid
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.05)),
            ),
            child: Column(
              children: [
                _buildStatRow(context, Symbols.route, 'TOTAL DISTANCE', '120', 'km', AppColors.primaryFixedDim.withValues(alpha: 0.2), AppColors.primary),
                const Divider(height: 1, color: Color(0x0D061B0E)),
                _buildStatRow(context, Symbols.fort, 'FORTS CONQUERED', '8', '', AppColors.secondaryFixed.withValues(alpha: 0.2), AppColors.secondary),
                const Divider(height: 1, color: Color(0x0D061B0E)),
                _buildStatRow(context, Symbols.landscape, 'TOTAL TREKS', '15', '', AppColors.tertiaryFixed.withValues(alpha: 0.3), AppColors.tertiary),
              ],
            ),
          ),

          const SizedBox(height: 40),

          // Achievement Badges
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Achievement Badges', style: Theme.of(context).textTheme.displayMedium),
                    Text('Your milestones in the Western Ghats', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.outline)),
                  ],
                ),
              ),
              TextButton.icon(
                onPressed: () {},
                icon: const Text('View All'),
                label: const Icon(Symbols.arrow_forward, size: 16),
                style: TextButton.styleFrom(foregroundColor: AppColors.secondary),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildBadge(context, Symbols.mountain_flag, 'Peak Performer', AppColors.primary, AppColors.primaryFixed),
                _buildBadge(context, Symbols.explore, 'Fort Finder', AppColors.secondary, AppColors.secondaryFixed),
                _buildBadge(context, Symbols.waterfall_chart, 'Waterfall Wiz', AppColors.tertiary, AppColors.tertiaryFixed),
                _buildBadge(context, Symbols.star, 'Cloud Chaser', AppColors.outline, AppColors.outlineVariant, isLocked: true),
              ],
            ),
          ),

          const SizedBox(height: 40),

          // Recent Expedition
          Text('Recent Expedition', style: Theme.of(context).textTheme.displaySmall),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.05)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 10,
                ),
              ],
            ),
            child: Column(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  child: Stack(
                    children: [
                      Image.network(
                        'https://lh3.googleusercontent.com/aida-public/AB6AXuCKQQ55mG27sesTEo4tTg4i0hsqdEcTjzJLh20hzHrBV_qRu_j_n8rnS6I2FaPgwZp1tKLiG_CkyTRU5yGfq3EW0oZfqYU6d9lka_qeeqFKYM-Alj7EVo9UBI5AQbWzueBjpRmseZfHD7SuQHI5LVN6W10x8LALxAgsJxa_BWaaHZaBRk_RFH5-zXGF26aRM7iKIExpP8hpwcXr3w6nev0u0g1zmpzufG6wX22tzuvni078wUr4TD7Q7xsYta1ydg574ZE12RBV-nc',
                        height: 192,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                      Positioned(
                        top: 16,
                        right: 16,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.9),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            '2 DAYS AGO',
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.primary, fontSize: 10),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(24),
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
                                Text('Torna Fort Expedition', style: Theme.of(context).textTheme.displaySmall),
                                const SizedBox(height: 4),
                                Text(
                                  'Difficult • 12.4 km total • 840m Elevation',
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.outline, fontSize: 14),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.secondaryFixed,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              'CONQUERED',
                              style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.onSecondaryFixed, fontSize: 10),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Wrap(
                        spacing: 8,
                        children: [
                          _buildTag('STEEP CLIMB'),
                          _buildTag('WATERFALL TRAIL'),
                          _buildTag('PHOTOGRAPHY'),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(BuildContext context, IconData icon, String label, String value, String unit, Color iconBg, Color iconColor) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor),
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: Theme.of(context).textTheme.labelSmall?.copyWith(letterSpacing: 1.5)),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(value, style: Theme.of(context).textTheme.displaySmall),
                    if (unit.isNotEmpty) ...[
                      const SizedBox(width: 4),
                      Text(unit, style: Theme.of(context).textTheme.bodyMedium),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const Icon(Symbols.chevron_right, color: Color(0x80737973), size: 20),
        ],
      ),
    );
  }

  Widget _buildBadge(BuildContext context, IconData icon, String title, Color iconColor, Color borderColor, {bool isLocked = false}) {
    return Container(
      width: 96,
      margin: const EdgeInsets.only(right: 24),
      child: Column(
        children: [
          Opacity(
            opacity: isLocked ? 0.4 : 1.0,
            child: Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Colors.white, Color(0xFFF7F9F7)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
                border: Border.all(color: Colors.white),
              ),
              child: Center(
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: borderColor, style: BorderStyle.solid),
                  ),
                  child: Icon(icon, color: iconColor, size: 36, fill: isLocked ? 0 : 1),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(color: isLocked ? AppColors.outline : AppColors.onSurface, letterSpacing: 0),
          ),
        ],
      ),
    );
  }

  Widget _buildTag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.onSurfaceVariant),
      ),
    );
  }
}
