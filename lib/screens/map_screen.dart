import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import '../models/fort_model.dart';
import '../repositories/fort_repository.dart';
import '../theme.dart';

class MapScreen extends StatefulWidget {
  final void Function(Fort)? onStartTrek;

  const MapScreen({super.key, this.onStartTrek});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> with TickerProviderStateMixin {
  final MapController _mapController = MapController();
  late final AnimationController _animationController;

  // Center roughly around India
  final LatLng _indiaCenter = const LatLng(20.5937, 78.9629);

  List<Fort> _forts = [];
  bool _isLoading = true;
  Fort? _selectedFort;
  List<Fort> _nearbyForts = [];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _loadForts();
  }

  Future<void> _loadForts() async {
    final forts = await FortRepository.loadForts();
    if (mounted) {
      setState(() {
        _forts = forts;
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _animatedMapMove(LatLng destLocation, double destZoom) {
    if (!mounted) return;

    final latTween = Tween<double>(
      begin: _mapController.camera.center.latitude,
      end: destLocation.latitude,
    );
    final lngTween = Tween<double>(
      begin: _mapController.camera.center.longitude,
      end: destLocation.longitude,
    );
    final zoomTween = Tween<double>(
      begin: _mapController.camera.zoom,
      end: destZoom,
    );

    final Animation<double> animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.fastOutSlowIn,
    );

    _animationController.reset();

    void listener() {
      _mapController.move(
        LatLng(latTween.evaluate(animation), lngTween.evaluate(animation)),
        zoomTween.evaluate(animation),
      );
    }

    animation.addListener(listener);
    _animationController.forward().whenComplete(() {
      animation.removeListener(listener);
    });
  }

  void _handleFortTap(BuildContext context, Fort fort) {
    if (_selectedFort?.id == fort.id) {
      _showFortBottomSheet(context, fort);
      return;
    }

    const distanceCalculator = Distance();
    final List<Fort> withinRadius = _forts.where((f) {
      if (f.id == fort.id) return false;
      final dist = distanceCalculator.as(LengthUnit.Meter, fort.location, f.location);
      return dist <= 50000; // 50 KM
    }).toList();
    
    setState(() {
      _selectedFort = fort;
      _nearbyForts = withinRadius;
    });
    
    _animatedMapMove(fort.location, 9.5);
  }

  Marker _buildFortMarker(BuildContext context, Fort fort, {required bool isSelected, required bool isDistant}) {
    final double markerSize = isSelected ? 40.0 : 30.0;
    final double opacity = isDistant ? 0.4 : 1.0;

    return Marker(
      point: fort.location,
      width: 120,
      height: 100,
      alignment: Alignment.topCenter,
      child: GestureDetector(
        onTap: () => _handleFortTap(context, fort),
        child: Opacity(
          opacity: opacity,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFFF59E0B) : AppColors.primary,
                  shape: BoxShape.circle,
                  boxShadow: isSelected ? [
                    BoxShadow(
                      color: const Color(0xFFF59E0B).withValues(alpha: 0.6),
                      blurRadius: 16,
                      spreadRadius: 8,
                    )
                  ] : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    ),
                  ],
                  border: isSelected ? Border.all(color: Colors.white, width: 2) : null,
                ),
                child: Icon(
                  Symbols.fort,
                  color: Colors.white,
                  size: markerSize * 0.6,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFFF59E0B) : Colors.white.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected ? const Color(0xFFF59E0B) : AppColors.outlineVariant,
                  ),
                ),
                child: Text(
                  fort.name,
                  style: TextStyle(
                    fontSize: isSelected ? 12 : 10,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? Colors.white : AppColors.onSurface,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showFortBottomSheet(BuildContext context, Fort fort) {

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                    color: AppColors.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              Text(
                fort.name,
                style: Theme.of(
                  context,
                ).textTheme.displayMedium?.copyWith(color: AppColors.onSurface),
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  _buildPill(
                    Symbols.hiking,
                    fort.difficulty,
                    AppColors.secondary,
                  ),
                  const SizedBox(width: 12),
                  _buildPill(
                    Symbols.timer,
                    fort.estimatedTime,
                    AppColors.primary,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildPill(
                    Symbols.location_on,
                    fort.district,
                    const Color(0xFF0EA5E9),
                  ),
                  const SizedBox(width: 12),
                  _buildPill(
                    Symbols.height,
                    fort.height,
                    const Color(0xFFF59E0B),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              Text(
                fort.description,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.onSurfaceVariant,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context); // Close the bottom sheet
                    if (widget.onStartTrek != null) {
                      widget.onStartTrek!(fort);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Start Trek',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPill(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Fort> distantForts = _forts.where((f) {
      if (_selectedFort == null) return true;
      return f.id != _selectedFort!.id && !_nearbyForts.any((n) => n.id == f.id);
    }).toList();

    final List<Fort> explorationForts = _selectedFort != null 
        ? [_selectedFort!, ..._nearbyForts] 
        : [];

    return Scaffold(
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : Stack(
              children: [
                LayoutBuilder(
                  builder: (context, constraints) {
                if (constraints.maxWidth == 0 || constraints.maxHeight == 0) {
                  return const SizedBox.shrink();
                }
                return FlutterMap(
                  key: const ValueKey('SathyadriMapV1'),
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _indiaCenter,
                    initialZoom: 5.0,
                    minZoom: 5.0,
                    maxZoom: 15.0,
                    interactionOptions: const InteractionOptions(
                      flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                    ),
                    cameraConstraint: CameraConstraint.contain(
                      bounds: LatLngBounds(
                        const LatLng(6.0, 68.0), // South-West
                        const LatLng(37.0, 97.0), // North-East
                      ),
                    ),
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.sahyadri_explorer',
                    ),
                    if (_selectedFort != null)
                      CircleLayer(
                        circles: [
                          CircleMarker(
                            point: _selectedFort!.location,
                            radius: 50000,
                            useRadiusInMeter: true,
                            color: AppColors.primary.withValues(alpha: 0.05),
                            borderColor: AppColors.primary.withValues(alpha: 0.2),
                            borderStrokeWidth: 2,
                          ),
                        ],
                      ),
                    if (_selectedFort != null)
                      PolylineLayer(
                        polylines: _nearbyForts.map<Polyline>((nearby) {
                          return Polyline(
                            points: [_selectedFort!.location, nearby.location],
                            color: AppColors.primary,
                            strokeWidth: 3.0,
                          );
                        }).toList(),
                      ),
                    MarkerClusterLayerWidget(
                      options: MarkerClusterLayerOptions(
                        maxClusterRadius: 45,
                        size: const Size(60, 60),
                        markers: distantForts.map((fort) {
                          return _buildFortMarker(context, fort, isSelected: false, isDistant: _selectedFort != null);
                        }).toList(),
                        builder: (context, markers) {
                          // Scale cluster size based on marker count
                          final double dynamicSize =
                              40.0 + (markers.length * 1.5).clamp(0.0, 20.0);

                          // Density-based color logic
                          Color clusterColor;
                          if (markers.length <= 5) {
                            clusterColor = const Color(0xFFF59E0B); // Green
                          } else if (markers.length <= 12) {
                            clusterColor = const Color(0xFF10B981); // Orange
                          } else {
                            clusterColor = const Color(0xFFEF4444); // Red
                          }

                          return Center(
                            child: Container(
                              width: dynamicSize,
                              height: dynamicSize,
                              decoration: BoxDecoration(
                                color: clusterColor,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 2.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: clusterColor.withValues(alpha: 0.5),
                                    blurRadius: 10,
                                    spreadRadius: 2,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Icon(
                                    Symbols.fort,
                                    color: Colors.white,
                                    size: dynamicSize * 0.35,
                                  ),
                                  const SizedBox(width: 2),
                                  Text(
                                    markers.length.toString(),
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: dynamicSize * 0.3,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    if (_selectedFort != null)
                      MarkerLayer(
                        markers: explorationForts.map((fort) {
                          final isSelected = fort.id == _selectedFort!.id;
                          return _buildFortMarker(context, fort, isSelected: isSelected, isDistant: false);
                        }).toList(),
                      ),
                  ],
                );
              },
            ),
            AnimatedPositioned(
              duration: const Duration(milliseconds: 300),
              curve: Curves.fastOutSlowIn,
              bottom: _selectedFort != null ? 100 : -100, // Slide up when active
              left: 24,
              right: 24,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '🏰 ${_selectedFort?.name ?? ''}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: AppColors.onSurface,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${_nearbyForts.length} nearby forts',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                    ElevatedButton(
                      onPressed: _selectedFort != null 
                          ? () => _showFortBottomSheet(context, _selectedFort!) 
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('View Trek'),
                    ),
                  ],
                ),
              ),
            ),
            AnimatedPositioned(
              duration: const Duration(milliseconds: 300),
              curve: Curves.fastOutSlowIn,
              bottom: _selectedFort != null ? 180 : 100, // Dodge the info bar
              right: 16,
              child: FloatingActionButton(
                onPressed: () {
                  // Animate back to India center
                  _animatedMapMove(_indiaCenter, 5.0);
                },
                backgroundColor: Colors.white,
                child: const Icon(Symbols.my_location, color: AppColors.primary),
              ),
            ),
          ],
        ),
    );
  }
}
