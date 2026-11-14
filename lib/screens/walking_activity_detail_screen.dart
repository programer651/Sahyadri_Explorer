import 'package:material_ui/material_ui.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../models/walking_activity_model.dart';

class WalkingActivityDetailScreen extends StatefulWidget {
  final WalkingActivity activity;

  const WalkingActivityDetailScreen({super.key, required this.activity});

  @override
  State<WalkingActivityDetailScreen> createState() =>
      _WalkingActivityDetailScreenState();
}

class _WalkingActivityDetailScreenState
    extends State<WalkingActivityDetailScreen> {
  late final MapController _mapController;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  void _recenterMap() {
    final activity = widget.activity;
    final points = activity.routePoints.isNotEmpty
        ? activity.routePoints
        : [activity.startLocation, activity.endLocation];

    if (points.isEmpty) return;

    if (points.length == 1) {
      _mapController.move(points.first, 15.0);
      return;
    }

    final bounds = LatLngBounds.fromPoints(points);
    _mapController.fitCamera(
      CameraFit.bounds(
        bounds: bounds,
        padding: const EdgeInsets.all(40),
      ),
    );
  }

  LatLng _getInitialCenter() {
    final activity = widget.activity;
    if (activity.routePoints.isNotEmpty) {
      double totalLat = 0;
      double totalLng = 0;
      for (final p in activity.routePoints) {
        totalLat += p.latitude;
        totalLng += p.longitude;
      }
      return LatLng(
        totalLat / activity.routePoints.length,
        totalLng / activity.routePoints.length,
      );
    }
    return activity.startLocation;
  }

  String _formatDateTime(DateTime dt) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    final month = months[dt.month - 1];
    final hour = dt.hour == 0 ? 12 : (dt.hour > 12 ? dt.hour - 12 : dt.hour);
    final minute = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    return '$month ${dt.day}, ${dt.year} • $hour:$minute $period';
  }

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(d.inHours);
    final minutes = twoDigits(d.inMinutes.remainder(60));
    final seconds = twoDigits(d.inSeconds.remainder(60));
    if (d.inHours > 0) {
      return '$hours:$minutes:$seconds';
    }
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activity = widget.activity;

    final List<LatLng> polylinePoints = activity.routePoints.isNotEmpty
        ? activity.routePoints
        : [activity.startLocation, activity.endLocation];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Walking Session',
          style: Theme.of(context).textTheme.displaySmall,
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Map Card
            Container(
              height: 280,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                children: [
                  FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: _getInitialCenter(),
                      initialZoom: 15.0,
                      onMapReady: () {
                        // Fit bounds smoothly once map is ready
                        _recenterMap();
                      },
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            'https://{s}.tile.opentopomap.org/{z}/{x}/{y}.png',
                        subdomains: const ['a', 'b', 'c'],
                        userAgentPackageName: 'com.zenitrek.app',
                        tileBuilder: isDark
                            ? (context, tileWidget, tile) {
                                return ColorFiltered(
                                  colorFilter: const ColorFilter.matrix([
                                    -1.0, 0.0, 0.0, 0.0, 255.0,
                                    0.0, -1.0, 0.0, 0.0, 255.0,
                                    0.0, 0.0, -1.0, 0.0, 255.0,
                                    0.0, 0.0, 0.0, 1.0, 0.0,
                                  ]),
                                  child: tileWidget,
                                );
                              }
                            : null,
                      ),
                      if (polylinePoints.length >= 2)
                        PolylineLayer(
                          polylines: [
                            Polyline(
                              points: polylinePoints,
                              color: const Color(0xFF0EA5E9),
                              strokeWidth: 5.0,
                            ),
                          ],
                        ),
                      MarkerLayer(
                        markers: [
                          // Start Marker (A)
                          Marker(
                            point: activity.startLocation,
                            width: 34,
                            height: 34,
                            child: Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFF10B981),
                                shape: BoxShape.circle,
                                border:
                                    Border.all(color: Colors.white, width: 2),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.3),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: const Center(
                                child: Text(
                                  'A',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          // End Marker (B)
                          Marker(
                            point: activity.endLocation,
                            width: 34,
                            height: 34,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.redAccent,
                                shape: BoxShape.circle,
                                border:
                                    Border.all(color: Colors.white, width: 2),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.3),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: const Center(
                                child: Text(
                                  'B',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Positioned(
                    bottom: 12,
                    right: 12,
                    child: FloatingActionButton.small(
                      heroTag: 'detail_recenter',
                      onPressed: _recenterMap,
                      backgroundColor: colorScheme.surface,
                      foregroundColor: const Color(0xFF0EA5E9),
                      child: const Icon(Icons.crop_free, size: 20),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Performance Metrics Section
            Text(
              'PERFORMANCE SUMMARY',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    letterSpacing: 1.5,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 12),

            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _buildMetricTile(
                          context,
                          icon: Icons.straighten,
                          title: 'Distance',
                          value: '${activity.distanceKm.toStringAsFixed(2)} KM',
                          color: const Color(0xFF0EA5E9),
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 48,
                        color:
                            colorScheme.outlineVariant.withValues(alpha: 0.4),
                      ),
                      Expanded(
                        child: _buildMetricTile(
                          context,
                          icon: Icons.timer_outlined,
                          title: 'Duration',
                          value: _formatDuration(activity.duration),
                          color: Colors.amber.shade700,
                        ),
                      ),
                    ],
                  ),
                  Divider(
                    height: 28,
                    color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: _buildMetricTile(
                          context,
                          icon: Icons.speed,
                          title: 'Avg Speed',
                          value:
                              '${activity.avgSpeedKmh.toStringAsFixed(1)} km/h',
                          color: Colors.purple.shade400,
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 48,
                        color:
                            colorScheme.outlineVariant.withValues(alpha: 0.4),
                      ),
                      Expanded(
                        child: _buildMetricTile(
                          context,
                          icon: Icons.bolt,
                          title: 'Max Speed',
                          value:
                              '${activity.maxSpeedKmh.toStringAsFixed(1)} km/h',
                          color: Colors.deepOrangeAccent,
                        ),
                      ),
                    ],
                  ),
                  if (activity.steps > 0) ...[
                    Divider(
                      height: 28,
                      color:
                          colorScheme.outlineVariant.withValues(alpha: 0.3),
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: _buildMetricTile(
                            context,
                            icon: Icons.directions_walk,
                            title: 'Total Steps',
                            value: '${activity.steps}',
                            color: const Color(0xFF10B981),
                          ),
                        ),
                        Container(
                          width: 1,
                          height: 48,
                          color: colorScheme.outlineVariant
                              .withValues(alpha: 0.4),
                        ),
                        Expanded(
                          child: _buildMetricTile(
                            context,
                            icon: Icons.timeline,
                            title: 'GPS Points',
                            value: '${activity.routePoints.length}',
                            color: colorScheme.secondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Start & End Details Section
            Text(
              'LOCATION & TIMESTAMPS',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    letterSpacing: 1.5,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 12),

            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Start Location
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.play_circle_fill,
                          color: Color(0xFF10B981),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'START LOCATION',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              activity.startLocationName ??
                                  '${activity.startLocation.latitude.toStringAsFixed(4)}, ${activity.startLocation.longitude.toStringAsFixed(4)}',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _formatDateTime(activity.startTime),
                              style: TextStyle(
                                fontSize: 12,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  Padding(
                    padding: const EdgeInsets.only(left: 17, top: 4, bottom: 4),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        width: 2,
                        height: 24,
                        color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                      ),
                    ),
                  ),

                  // End Location
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.redAccent.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.stop_circle,
                          color: Colors.redAccent,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'END LOCATION',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              activity.endLocationName ??
                                  '${activity.endLocation.latitude.toStringAsFixed(4)}, ${activity.endLocation.longitude.toStringAsFixed(4)}',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _formatDateTime(activity.endTime),
                              style: TextStyle(
                                fontSize: 12,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        Icon(icon, size: 22, color: color),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          title,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

