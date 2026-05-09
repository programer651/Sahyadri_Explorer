import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';
import '../models/fort_model.dart';
import '../state/trek_state_manager.dart';
import '../widgets/live_trek_stats_widget.dart';
import '../widgets/trek_summary_dialog.dart';
import '../theme.dart';
// Note: You can still swap between MockGpsTrackingService and GeolocatorTrackingService in TrekStateManager!
import '../services/gps_tracking_service.dart';

class LiveTrackingScreen extends StatefulWidget {
  final Fort? activeFort;

  const LiveTrackingScreen({super.key, this.activeFort});

  @override
  State<LiveTrackingScreen> createState() => _LiveTrackingScreenState();
}

class _LiveTrackingScreenState extends State<LiveTrackingScreen> with SingleTickerProviderStateMixin {
  final MapController _mapController = MapController();
  late final TrekStateManager _stateManager;
  
  bool _isFocusMode = false;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    // Real production GPS tracking. 
    _stateManager = TrekStateManager(trackingService: GeolocatorTrackingService());
    
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    if (widget.activeFort != null) {
      _stateManager.initialize(widget.activeFort!);
    }

    _stateManager.addListener(_onStateChanged);
  }

  void _onStateChanged() {
    if (!mounted) return;
    
    if (_stateManager.currentLocation != null) {
      _mapController.move(_stateManager.currentLocation!, 16.0);
    }
    
    if (_stateManager.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_stateManager.errorMessage!),
          backgroundColor: Colors.red,
        ),
      );
      _stateManager.errorMessage = null; // Clear it so it doesn't spam
    }
    
    setState(() {}); // Rebuild UI
  }

  @override
  void dispose() {
    _stateManager.removeListener(_onStateChanged);
    _stateManager.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _toggleFocusMode() {
    if (_stateManager.isApproaching || _stateManager.isReady) return;
    setState(() {
      _isFocusMode = !_isFocusMode;
    });
  }

  Widget _buildApproachBanner() {
    final distKm = (_stateManager.distanceToFortMeters / 1000).toStringAsFixed(2);
    final isReady = _stateManager.isReady;

    return Container(
      color: Colors.black.withValues(alpha: 0.4),
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 20)
            ]
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isReady ? Symbols.verified : Symbols.directions_walk,
                size: 48,
                color: isReady ? AppColors.secondary : AppColors.primary,
              ),
              const SizedBox(height: 16),
              Text(
                _stateManager.session!.activeFort.name,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              if (!isReady)
                Text(
                  'Distance to Fort Region: $distKm km\nGet within 1km to start trekking.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.grey, height: 1.5),
                ),
              if (isReady)
                const Text(
                  'You have arrived at the base!\nReady to begin the ascent?',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w500, height: 1.5),
                ),
              const SizedBox(height: 24),
              SizedBox(
                width: 200,
                child: ElevatedButton.icon(
                  onPressed: isReady ? () => _stateManager.startTrek() : null,
                  icon: const Icon(Symbols.explore),
                  label: const Text('Start Trek', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey.shade300,
                    disabledForegroundColor: Colors.grey.shade500,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.activeFort == null || _stateManager.session == null) {
      return const Center(child: Text('No Active Trek.'));
    }

    final session = _stateManager.session!;
    final currentLocation = _stateManager.currentLocation;

    return Scaffold(
      body: Stack(
        children: [
          // FlutterMap
          GestureDetector(
            onTap: _toggleFocusMode,
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: session.activeFort.location,
                initialZoom: 15.0,
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                ),
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://{s}.tile.opentopomap.org/{z}/{x}/{y}.png',
                  subdomains: const ['a', 'b', 'c'],
                  userAgentPackageName: 'com.example.sahyadri_explorer',
                ),
                
                MarkerLayer(
                  markers: [
                    Marker(
                      point: session.activeFort.location,
                      width: 50,
                      height: 50,
                      child: const Icon(Symbols.flag, color: Colors.red, size: 40),
                    ),
                  ],
                ),

                if (_stateManager.isTrekking || _stateManager.isPaused)
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: session.routePoints,
                        color: const Color(0xFFF97316),
                        strokeWidth: 6.0,
                      ),
                    ],
                  ),

                if (currentLocation != null)
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: currentLocation,
                        width: 40,
                        height: 40,
                        child: AnimatedBuilder(
                          animation: _pulseController,
                          builder: (context, child) {
                            return Stack(
                              alignment: Alignment.center,
                              children: [
                                Container(
                                  width: 20 + (_pulseController.value * 20),
                                  height: 20 + (_pulseController.value * 20),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.blue.withValues(alpha: 1.0 - _pulseController.value),
                                  ),
                                ),
                                Container(
                                  width: 16,
                                  height: 16,
                                  decoration: BoxDecoration(
                                    color: Colors.blue,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white, width: 2),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),

          // Top Progress Bar & Stats
          if (_stateManager.isTrekking || _stateManager.isPaused)
            AnimatedPositioned(
              duration: const Duration(milliseconds: 300),
              top: _isFocusMode ? -200 : 50,
              left: 0,
              right: 0,
              child: SafeArea(
                child: LiveTrekStatsWidget(
                  session: session, 
                  completionPercentage: _stateManager.completionPercentage,
                ),
              ),
            ),

          // Approach Banner
          if (_stateManager.isApproaching || _stateManager.isReady)
            _buildApproachBanner(),

          // Bottom Controls
          if (_stateManager.isTrekking || _stateManager.isPaused)
            AnimatedPositioned(
              duration: const Duration(milliseconds: 300),
              bottom: _isFocusMode ? -150 : 120,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_stateManager.isTrekking)
                    FloatingActionButton.large(
                      heroTag: 'pause',
                      onPressed: () => _stateManager.pauseTrek(),
                      backgroundColor: Colors.white,
                      child: const Icon(Symbols.pause, color: AppColors.primary, size: 36),
                    ),
                  if (_stateManager.isPaused)
                    FloatingActionButton.large(
                      heroTag: 'resume',
                      onPressed: () => _stateManager.resumeTrek(),
                      backgroundColor: AppColors.primary,
                      child: const Icon(Symbols.play_arrow, color: Colors.white, size: 36),
                    ),
                  const SizedBox(width: 32),
                  FloatingActionButton.extended(
                    heroTag: 'end',
                    onPressed: () => _stateManager.endTrek(),
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    icon: const Icon(Symbols.stop),
                    label: const Text('Abandon', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
            
          // Victory / Defeat Overlay (TrekSummaryDialog)
          if (_stateManager.isCompleted || _stateManager.isAbandoned)
            TrekSummaryDialog(
              session: session, 
              isVictory: _stateManager.isCompleted, 
              completionPercentage: _stateManager.completionPercentage,
            ),
        ],
      ),
    );
  }
}
