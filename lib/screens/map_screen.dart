import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:geolocator/geolocator.dart';
import '../models/fort_model.dart';
import '../repositories/fort_repository.dart';
import '../state/navigation_state_manager.dart';

class MapScreen extends StatefulWidget {
  final void Function(Fort)? onStartTrek;
  final VoidCallback? onStartWalk;

  const MapScreen({super.key, this.onStartTrek, this.onStartWalk});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> with TickerProviderStateMixin {
  final MapController _mapController = MapController();
  late final AnimationController _animationController;
  late final AnimationController _pulseController;

  final LatLng _indiaCenter = const LatLng(20.5937, 78.9629);

  List<Fort> _forts = [];
  bool _isLoading = true;
  Fort? _selectedFort;
  List<Fort> _nearbyForts = [];

  LatLng? _currentLocation;
  double? _currentAccuracy;
  StreamSubscription<Position>? _positionStreamSub;
  bool _isLocating = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    _loadForts();
    _initLocation(shouldAnimate: false, showFeedback: false);
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
    _positionStreamSub?.cancel();
    _animationController.dispose();
    _pulseController.dispose();
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

  Future<void> _initLocation({
    bool shouldAnimate = false,
    bool showFeedback = false,
  }) async {
    if (mounted) {
      setState(() {
        _isLocating = true;
      });
    }

    try {
      final isServiceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!isServiceEnabled) {
        if (showFeedback && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Location services are disabled. Please enable GPS in device settings.',
              ),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (showFeedback && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Location permissions are denied. We cannot show your current position.',
                ),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (showFeedback && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Location permissions are permanently denied. Please enable them in app settings.',
              ),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        return;
      }

      // 1. Check last known position for quick initial display
      final lastKnown = await Geolocator.getLastKnownPosition();
      if (lastKnown != null && mounted) {
        setState(() {
          _currentLocation = LatLng(lastKnown.latitude, lastKnown.longitude);
          _currentAccuracy = lastKnown.accuracy;
        });
        if (shouldAnimate) {
          _animatedMapMove(_currentLocation!, 14.0);
        }
      }

      // 2. Fetch fresh high-accuracy position
      final currentPos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      if (mounted) {
        setState(() {
          _currentLocation = LatLng(currentPos.latitude, currentPos.longitude);
          _currentAccuracy = currentPos.accuracy;
        });

        if (shouldAnimate) {
          _animatedMapMove(_currentLocation!, 14.0);
        }
      }

      // 3. Keep updating continuously as user moves
      _startLocationStream();
    } catch (e) {
      debugPrint('Location error: $e');
      if (showFeedback && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Unable to obtain location: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLocating = false;
        });
      }
    }
  }

  void _startLocationStream() {
    _positionStreamSub?.cancel();
    _positionStreamSub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 3,
      ),
    ).listen(
      (Position position) {
        if (!mounted) return;
        setState(() {
          _currentLocation = LatLng(position.latitude, position.longitude);
          _currentAccuracy = position.accuracy;
        });
      },
      onError: (e) {
        debugPrint('Location stream error: $e');
      },
    );
  }

  void _handleCurrentLocationPressed() {
    if (_currentLocation != null) {
      _animatedMapMove(_currentLocation!, 14.0);
    } else {
      _initLocation(shouldAnimate: true, showFeedback: true);
    }
  }

  Marker _buildCurrentLocationMarker() {
    return Marker(
      point: _currentLocation!,
      width: 52,
      height: 52,
      alignment: Alignment.center,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          if (widget.onStartWalk != null) {
            widget.onStartWalk!();
          } else {
            NavigationStateManager().navigateToLive(walkingMode: true);
          }
        },
        child: Tooltip(
          message: 'Start Walking Activity',
          child: AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              final pulse = _pulseController.value;
              return Stack(
                alignment: Alignment.center,
                children: [
                  // Pulsing accuracy halo / wave
                  Container(
                    width: 22 + (pulse * 24),
                    height: 22 + (pulse * 24),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF2196F3).withValues(
                        alpha: 0.35 * (1.0 - (pulse * 0.6)),
                      ),
                    ),
                  ),
                  // Crisp white ring with elevation for contrast
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                  // Solid vibrant blue location dot with walking figure
                  Container(
                    width: 17,
                    height: 17,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFF1E88E5),
                    ),
                    child: const Icon(
                      Icons.directions_walk,
                      size: 11,
                      color: Colors.white,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  void _handleFortTap(BuildContext context, Fort fort) {
    if (_selectedFort?.id == fort.id) {
      _showFortBottomSheet(context, fort);
      return;
    }

    const distanceCalculator = Distance();
    final List<Fort> withinRadius = _forts.where((f) {
      if (f.id == fort.id) return false;
      final dist = distanceCalculator.as(
        LengthUnit.Meter,
        fort.location,
        f.location,
      );
      return dist <= 50000; // 50 KM
    }).toList();

    setState(() {
      _selectedFort = fort;
      _nearbyForts = withinRadius;
    });

    _animatedMapMove(fort.location, 9.5);
  }

  Marker _buildFortMarker(
    BuildContext context,
    Fort fort, {
    required bool isSelected,
    required bool isDistant,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
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
                  color: isSelected
                      ? colorScheme.secondary
                      : colorScheme.primary,
                  shape: BoxShape.circle,
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: colorScheme.secondary.withValues(alpha: 0.6),
                            blurRadius: 16,
                            spreadRadius: 8,
                          ),
                        ]
                      : [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 6,
                            offset: const Offset(0, 3),
                          ),
                        ],
                  border: isSelected
                      ? Border.all(color: Colors.white, width: 2)
                      : null,
                ),
                child: Icon(
                  Icons.fort,
                  color: Colors.white,
                  size: markerSize * 0.6,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isSelected
                      ? colorScheme.secondary
                      : colorScheme.surface.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected
                        ? colorScheme.secondary
                        : colorScheme.outlineVariant,
                  ),
                ),
                child: Text(
                  fort.name,
                  style: TextStyle(
                    fontSize: isSelected ? 12 : 10,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? Colors.white : colorScheme.onSurface,
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
    final colorScheme = Theme.of(context).colorScheme;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                    color: colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              Text(fort.name, style: Theme.of(context).textTheme.displayMedium),
              const SizedBox(height: 16),

              Row(
                children: [
                  _buildPill(
                    context,
                    Icons.hiking,
                    fort.difficulty,
                    colorScheme.secondary,
                  ),
                  const SizedBox(width: 12),
                  _buildPill(
                    context,
                    Icons.timer,
                    fort.estimatedTime,
                    colorScheme.primary,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildPill(
                    context,
                    Icons.location_on,
                    fort.district,
                    const Color(0xFF0EA5E9),
                  ),
                  const SizedBox(width: 12),
                  _buildPill(
                    context,
                    Icons.height,
                    fort.height,
                    const Color(0xFFF59E0B),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              Text(
                fort.description,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    if (widget.onStartTrek != null) {
                      widget.onStartTrek!(fort);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
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

  Widget _buildPill(
    BuildContext context,
    IconData icon,
    String label,
    Color color,
  ) {
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
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final double bottomNavBarTop =
        40.0 + (bottomPadding > 0 ? 8.0 : 16.0) + bottomPadding;

    final List<Fort> distantForts = _forts.where((f) {
      if (_selectedFort == null) return true;
      return f.id != _selectedFort!.id &&
          !_nearbyForts.any((n) => n.id == f.id);
    }).toList();

    final List<Fort> explorationForts = _selectedFort != null
        ? [_selectedFort!, ..._nearbyForts]
        : [];

    return Scaffold(
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: colorScheme.primary))
          : Stack(
              children: [
                LayoutBuilder(
                  builder: (context, constraints) {
                    if (constraints.maxWidth == 0 ||
                        constraints.maxHeight == 0) {
                      return const SizedBox.shrink();
                    }
                    return FlutterMap(
                      key: const ValueKey('SathyadriMapV1'),
                      mapController: _mapController,
                      options: MapOptions(
                        initialCenter: _indiaCenter,
                        initialZoom: 5.0,
                        interactionOptions: const InteractionOptions(
                          flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                        ),
                        cameraConstraint: CameraConstraint.contain(
                          bounds: LatLngBounds(
                            const LatLng(6.0, 68.0),
                            const LatLng(37.0, 97.0),
                          ),
                        ),
                      ),
                      children: [
                        TileLayer(
                          urlTemplate: isDark
                              ? 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png' // OpenStreetMap doesn't have a built-in dark mode, but we could use Mapbox or similar. For now, sticking to OSM.
                              : 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'com.zenitrek.app',
                          tileBuilder: isDark
                              ? (context, tileWidget, tile) {
                                  return ColorFiltered(
                                    colorFilter: const ColorFilter.matrix([
                                      -1.0,
                                      0.0,
                                      0.0,
                                      0.0,
                                      255.0,
                                      0.0,
                                      -1.0,
                                      0.0,
                                      0.0,
                                      255.0,
                                      0.0,
                                      0.0,
                                      -1.0,
                                      0.0,
                                      255.0,
                                      0.0,
                                      0.0,
                                      0.0,
                                      1.0,
                                      0.0,
                                    ]),
                                    child: tileWidget,
                                  );
                                }
                              : null,
                        ),
                        if (_selectedFort != null || _currentLocation != null)
                          CircleLayer(
                            circles: [
                              if (_selectedFort != null)
                                CircleMarker(
                                  point: _selectedFort!.location,
                                  radius: 50000,
                                  useRadiusInMeter: true,
                                  color: colorScheme.primary.withValues(
                                    alpha: 0.05,
                                  ),
                                  borderColor: colorScheme.primary.withValues(
                                    alpha: 0.2,
                                  ),
                                  borderStrokeWidth: 2,
                                ),
                              if (_currentLocation != null)
                                CircleMarker(
                                  point: _currentLocation!,
                                  radius: (_currentAccuracy != null &&
                                          _currentAccuracy! > 0)
                                      ? _currentAccuracy!.clamp(15.0, 500.0)
                                      : 25.0,
                                  useRadiusInMeter: true,
                                  color: const Color(0xFF2196F3).withValues(
                                    alpha: 0.12,
                                  ),
                                  borderColor: const Color(0xFF2196F3).withValues(
                                    alpha: 0.35,
                                  ),
                                  borderStrokeWidth: 1.5,
                                ),
                            ],
                          ),
                        if (_selectedFort != null)
                          PolylineLayer(
                            polylines: _nearbyForts.map<Polyline>((nearby) {
                              return Polyline(
                                points: [
                                  _selectedFort!.location,
                                  nearby.location,
                                ],
                                color: colorScheme.primary,
                                strokeWidth: 3.0,
                              );
                            }).toList(),
                          ),
                        MarkerClusterLayerWidget(
                          options: MarkerClusterLayerOptions(
                            maxClusterRadius: 45,
                            size: const Size(60, 60),
                            markers: distantForts
                                .map(
                                  (fort) => _buildFortMarker(
                                    context,
                                    fort,
                                    isSelected: false,
                                    isDistant: _selectedFort != null,
                                  ),
                                )
                                .toList(),
                            builder: (context, markers) {
                              final double dynamicSize =
                                  40.0 +
                                  (markers.length * 1.5).clamp(0.0, 20.0);
                              Color clusterColor = markers.length <= 5
                                  ? const Color(0xFFF59E0B)
                                  : (markers.length <= 12
                                        ? const Color(0xFF10B981)
                                        : const Color(0xFFEF4444));

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
                                        color: clusterColor.withValues(
                                          alpha: 0.5,
                                        ),
                                        blurRadius: 10,
                                        spreadRadius: 2,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.fort,
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
                            markers: explorationForts
                                .map(
                                  (fort) => _buildFortMarker(
                                    context,
                                    fort,
                                    isSelected: fort.id == _selectedFort!.id,
                                    isDistant: false,
                                  ),
                                )
                                .toList(),
                          ),
                        if (_currentLocation != null)
                          MarkerLayer(
                            markers: [
                              _buildCurrentLocationMarker(),
                            ],
                          ),
                      ],
                    );
                  },
                ),
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.fastOutSlowIn,
                  bottom: _selectedFort != null
                      ? (bottomNavBarTop + 16.0)
                      : -150.0,
                  left: 24,
                  right: 24,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: colorScheme.outlineVariant.withValues(
                          alpha: 0.3,
                        ),
                      ),
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
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${_nearbyForts.length} nearby forts',
                              style: TextStyle(
                                fontSize: 12,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                        ElevatedButton(
                          onPressed: _selectedFort != null
                              ? () => _showFortBottomSheet(
                                  context,
                                  _selectedFort!,
                                )
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colorScheme.primary,
                            foregroundColor: colorScheme.onPrimary,
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
                  bottom: _selectedFort != null
                      ? (bottomNavBarTop + 16.0 + 88.0)
                      : (bottomNavBarTop + 16.0),
                  right: 16,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      FloatingActionButton.small(
                        heroTag: 'map_overview_btn',
                        onPressed: () => _animatedMapMove(_indiaCenter, 5.0),
                        backgroundColor: colorScheme.surface,
                        tooltip: 'Overview',
                        child: Icon(
                          Icons.zoom_out_map,
                          color: colorScheme.primary,
                          size: 20,
                        ),
                      ),
                      const SizedBox(height: 12),
                      FloatingActionButton(
                        heroTag: 'my_location_btn',
                        onPressed: _handleCurrentLocationPressed,
                        backgroundColor: colorScheme.surface,
                        tooltip: 'My Location',
                        child: _isLocating
                            ? SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: colorScheme.primary,
                                ),
                              )
                            : Icon(
                                _currentLocation != null
                                    ? Icons.my_location
                                    : Icons.location_searching,
                                color: _currentLocation != null
                                    ? const Color(0xFF2196F3)
                                    : colorScheme.primary,
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
