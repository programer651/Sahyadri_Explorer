import 'package:material_ui/material_ui.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../models/fort_model.dart';
import '../state/trek_state_manager.dart';
import '../state/walking_state_manager.dart';
import '../state/navigation_state_manager.dart';
import '../widgets/live_trek_stats_widget.dart';
import '../widgets/trek_summary_dialog.dart';
import '../widgets/walk_summary_dialog.dart';
import '../services/gps_tracking_service.dart';

enum LiveTrackingMode { fortTrek, walking }

class LiveTrackingScreen extends StatefulWidget {
  final Fort? activeFort;
  final bool initialWalkingMode;
  final ValueChanged<bool>? onModeChanged;

  const LiveTrackingScreen({
    super.key,
    this.activeFort,
    this.initialWalkingMode = false,
    this.onModeChanged,
  });

  @override
  State<LiveTrackingScreen> createState() => _LiveTrackingScreenState();
}

class _LiveTrackingScreenState extends State<LiveTrackingScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  final MapController _mapController = MapController();
  late final TrekStateManager _trekStateManager;
  late final WalkingStateManager _walkingStateManager;

  late LiveTrackingMode _currentMode;
  bool _isFocusMode = false;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _trekStateManager = TrekStateManager();
    _walkingStateManager = WalkingStateManager();

    // Check if an active session is already ongoing
    if (_trekStateManager.isTrekking || _trekStateManager.isPaused) {
      _currentMode = LiveTrackingMode.fortTrek;
    } else if (_walkingStateManager.isWalking || _walkingStateManager.isPaused) {
      _currentMode = LiveTrackingMode.walking;
    } else {
      _currentMode = widget.initialWalkingMode || widget.activeFort == null
          ? LiveTrackingMode.walking
          : LiveTrackingMode.fortTrek;

      if (widget.activeFort != null) {
        _trekStateManager.initialize(widget.activeFort!);
      }
      _walkingStateManager.initialize();
    }

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _trekStateManager.addListener(_onTrekStateChanged);
    _walkingStateManager.addListener(_onWalkingStateChanged);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) {
      _trekStateManager.saveCurrentState();
      _walkingStateManager.saveCurrentState();
    } else if (state == AppLifecycleState.resumed) {
      if (_currentMode == LiveTrackingMode.fortTrek) {
        _onTrekStateChanged();
      } else {
        _onWalkingStateChanged();
      }
    }
  }

  @override
  void didUpdateWidget(LiveTrackingScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    final bool hasActiveTrek =
        _trekStateManager.isTrekking || _trekStateManager.isPaused;
    final bool hasActiveWalk =
        _walkingStateManager.isWalking || _walkingStateManager.isPaused;

    // Do not disrupt ongoing sessions on widget updates
    if (hasActiveTrek) {
      if (_currentMode != LiveTrackingMode.fortTrek) {
        setState(() => _currentMode = LiveTrackingMode.fortTrek);
      }
      return;
    }

    if (hasActiveWalk) {
      if (_currentMode != LiveTrackingMode.walking) {
        setState(() => _currentMode = LiveTrackingMode.walking);
      }
      return;
    }

    if (widget.initialWalkingMode != oldWidget.initialWalkingMode) {
      setState(() {
        _currentMode = widget.initialWalkingMode
            ? LiveTrackingMode.walking
            : LiveTrackingMode.fortTrek;
      });
    } else if (widget.activeFort != oldWidget.activeFort &&
        widget.activeFort != null) {
      _trekStateManager.initialize(widget.activeFort!);
      setState(() {
        _currentMode = LiveTrackingMode.fortTrek;
      });
    }
  }

  void _onTrekStateChanged() {
    if (!mounted) return;

    if (_currentMode == LiveTrackingMode.fortTrek &&
        _trekStateManager.currentLocation != null) {
      _mapController.move(_trekStateManager.currentLocation!, 16.0);
    }

    if (_trekStateManager.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_trekStateManager.errorMessage!),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      _trekStateManager.errorMessage = null;
    }

    setState(() {});
  }

  void _onWalkingStateChanged() {
    if (!mounted) return;

    if (_currentMode == LiveTrackingMode.walking &&
        _walkingStateManager.currentLocation != null) {
      _mapController.move(_walkingStateManager.currentLocation!, 16.0);
    }

    if (_walkingStateManager.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_walkingStateManager.errorMessage!),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      _walkingStateManager.errorMessage = null;
    }

    setState(() {});
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _trekStateManager.removeListener(_onTrekStateChanged);
    _walkingStateManager.removeListener(_onWalkingStateChanged);
    // Note: Do not dispose singleton state managers here so active sessions continue
    _pulseController.dispose();
    super.dispose();
  }

  void _toggleFocusMode() {
    if (_currentMode == LiveTrackingMode.fortTrek) {
      if (_trekStateManager.isApproaching || _trekStateManager.isReady) return;
    } else {
      if (_walkingStateManager.isReady) return;
    }
    setState(() {
      _isFocusMode = !_isFocusMode;
    });
  }

  void _switchMode(LiveTrackingMode mode) {
    if (_currentMode == mode) return;

    if (_currentMode == LiveTrackingMode.fortTrek &&
        (_trekStateManager.isTrekking || _trekStateManager.isPaused)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please pause or abandon your active fort trek first.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (_currentMode == LiveTrackingMode.walking &&
        (_walkingStateManager.isWalking || _walkingStateManager.isPaused)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please pause or finish your active walk first.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      _currentMode = mode;
    });

    final isWalking = mode == LiveTrackingMode.walking;
    widget.onModeChanged?.call(isWalking);
    NavigationStateManager().isWalkingMode.value = isWalking;

    // Recenter map on relevant point
    if (mode == LiveTrackingMode.walking &&
        _walkingStateManager.currentLocation != null) {
      _mapController.move(_walkingStateManager.currentLocation!, 16.0);
    } else if (mode == LiveTrackingMode.fortTrek && widget.activeFort != null) {
      _mapController.move(widget.activeFort!.location, 15.0);
    }
  }

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(d.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(d.inSeconds.remainder(60));
    return "${twoDigits(d.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
  }

  Widget _buildModeSelector() {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: colorScheme.surface.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.4),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => _switchMode(LiveTrackingMode.fortTrek),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: _currentMode == LiveTrackingMode.fortTrek
                      ? colorScheme.primary
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(26),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.fort,
                      size: 18,
                      color: _currentMode == LiveTrackingMode.fortTrek
                          ? colorScheme.onPrimary
                          : colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Fort Trek',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: _currentMode == LiveTrackingMode.fortTrek
                            ? colorScheme.onPrimary
                            : colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => _switchMode(LiveTrackingMode.walking),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: _currentMode == LiveTrackingMode.walking
                      ? const Color(0xFF0EA5E9)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(26),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.directions_walk,
                      size: 18,
                      color: _currentMode == LiveTrackingMode.walking
                          ? Colors.white
                          : colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Walking Activity',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: _currentMode == LiveTrackingMode.walking
                            ? Colors.white
                            : colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGpsAlertBanner() {
    if (!_walkingStateManager.isGpsDisabled &&
        !_walkingStateManager.isPermissionDenied &&
        !_walkingStateManager.isPermissionPermanentlyDenied) {
      return const SizedBox.shrink();
    }

    String message = 'GPS issue detected.';
    String actionText = 'Retry';
    if (_walkingStateManager.isGpsDisabled) {
      message = 'Location services are disabled.';
      actionText = 'Enable GPS';
    } else if (_walkingStateManager.isPermissionDenied ||
        _walkingStateManager.isPermissionPermanentlyDenied) {
      message = 'Location permission is required to track your walk.';
      actionText = 'Grant';
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.amber.shade900.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(
            onPressed: () => _walkingStateManager.initialize(),
            style: TextButton.styleFrom(
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              backgroundColor: Colors.black.withValues(alpha: 0.2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              actionText,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoFortSelectedView() {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Container(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: colorScheme.outlineVariant.withValues(alpha: 0.3),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.fort_outlined,
                size: 48,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Fort Trek Mode',
              style: Theme.of(context).textTheme.displaySmall,
            ),
            const SizedBox(height: 8),
            Text(
              'No fort selected yet.\nSelect a fort from the map to trek to its summit, or switch to Walking Activity mode to start a walk anywhere.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => NavigationStateManager().navigateToMap(),
                icon: const Icon(Icons.explore),
                label: const Text('Choose Fort on Map'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _switchMode(LiveTrackingMode.walking),
                icon: const Icon(Icons.directions_walk, color: Color(0xFF0EA5E9)),
                label: const Text(
                  'Switch to Walking Activity',
                  style: TextStyle(
                    color: Color(0xFF0EA5E9),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: const BorderSide(color: Color(0xFF0EA5E9)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildApproachBanner() {
    final colorScheme = Theme.of(context).colorScheme;
    final distKm = (_trekStateManager.distanceToFortMeters / 1000).toStringAsFixed(
      2,
    );
    final isReady = _trekStateManager.isReady;

    return Container(
      color: Colors.black.withValues(alpha: 0.6),
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: colorScheme.outlineVariant.withValues(alpha: 0.3),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 20,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isReady ? Icons.verified : Icons.hiking,
                size: 48,
                color: isReady ? colorScheme.secondary : colorScheme.primary,
              ),
              const SizedBox(height: 16),
              Text(
                _trekStateManager.session!.activeFort.name,
                style: Theme.of(context).textTheme.displaySmall,
              ),
              const SizedBox(height: 8),
              if (!isReady)
                Text(
                  'Distance to Fort Region: $distKm km\nGet within 1km to start trekking.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              if (isReady)
                Text(
                  'You have arrived at the base!\nReady to begin the ascent?',
                  textAlign: TextAlign.center,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
              const SizedBox(height: 24),
              SizedBox(
                width: 200,
                child: ElevatedButton.icon(
                  onPressed: isReady ? () => _trekStateManager.startTrek() : null,
                  icon: const Icon(Icons.explore),
                  label: const Text(
                    'Start Trek',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
                    disabledBackgroundColor: colorScheme.outlineVariant,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWalkingReadyBanner() {
    final colorScheme = Theme.of(context).colorScheme;
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 110),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: const Color(0xFF0EA5E9).withValues(alpha: 0.35),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0EA5E9).withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.directions_walk,
                    size: 32,
                    color: Color(0xFF0EA5E9),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Walking Activity',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Ready to start walking • No fort required',
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
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _walkingStateManager.startWalking(),
                icon: const Icon(Icons.play_arrow, size: 26),
                label: const Text(
                  'Start Walk',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0EA5E9),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWalkingStatsWidget(WalkingSession session) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: colorScheme.surface.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFF0EA5E9).withValues(alpha: 0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Activity status & GPS accuracy pill
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: session.isPaused
                          ? Colors.amber
                          : const Color(0xFF10B981),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    session.isPaused ? 'WALK PAUSED' : 'WALKING ACTIVE',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                      color: session.isPaused
                          ? Colors.amber
                          : const Color(0xFF0EA5E9),
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Icon(
                    _walkingStateManager.hasPoorAccuracy
                        ? Icons.gps_not_fixed
                        : Icons.gps_fixed,
                    size: 14,
                    color: _walkingStateManager.hasPoorAccuracy
                        ? Colors.amber
                        : const Color(0xFF10B981),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _walkingStateManager.hasPoorAccuracy
                        ? 'Weak GPS (±${_walkingStateManager.gpsAccuracyMeters.toInt()}m)'
                        : '±${_walkingStateManager.gpsAccuracyMeters.toInt()}m',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: _walkingStateManager.hasPoorAccuracy
                          ? Colors.amber
                          : colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Primary Stats: Distance, Duration, Current Speed
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Column(
                children: [
                  Text(
                    session.distanceCoveredKm.toStringAsFixed(2),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 22,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'KM',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              Container(
                width: 1,
                height: 32,
                color: colorScheme.outlineVariant.withValues(alpha: 0.5),
              ),
              Column(
                children: [
                  Text(
                    _formatDuration(session.timeElapsed),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 22,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Duration',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              Container(
                width: 1,
                height: 32,
                color: colorScheme.outlineVariant.withValues(alpha: 0.5),
              ),
              Column(
                children: [
                  Text(
                    session.currentSpeedKmh.toStringAsFixed(1),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 22,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Speed (km/h)',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Secondary Stats: Avg Speed, Max Speed, Steps
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildSmallStat('Avg Speed', '${session.avgSpeedKmh.toStringAsFixed(1)} km/h'),
                _buildSmallStat('Max Speed', '${session.maxSpeedKmh.toStringAsFixed(1)} km/h'),
                _buildSmallStat('Steps (~)', '${session.steps}'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSmallStat(String label, String value) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildPulseLocationMarker(LatLng point) {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        final pulse = _pulseController.value;
        return Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 20 + (pulse * 22),
              height: 20 + (pulse * 22),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF2196F3).withValues(
                  alpha: 1.0 - pulse,
                ),
              ),
            ),
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: const Color(0xFF1E88E5),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white,
                  width: 2.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.25),
                    blurRadius: 4,
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Marker _buildStartMarker(LatLng point) {
    return Marker(
      point: point,
      width: 36,
      height: 36,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF10B981),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 6,
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
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }

  Marker _buildEndMarker(LatLng point) {
    return Marker(
      point: point,
      width: 36,
      height: 36,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.redAccent,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 6,
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
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final isWalking = _currentMode == LiveTrackingMode.walking;
    final isFortTrek = _currentMode == LiveTrackingMode.fortTrek;

    // Check if Fort Trek mode has no active fort
    if (isFortTrek &&
        (widget.activeFort == null || _trekStateManager.session == null)) {
      return Scaffold(
        body: Stack(
          children: [
            _buildNoFortSelectedView(),
            SafeArea(
              child: Align(
                alignment: Alignment.topCenter,
                child: _buildModeSelector(),
              ),
            ),
          ],
        ),
      );
    }

    final trekSession = _trekStateManager.session;
    final walkingSession = _walkingStateManager.session;

    final LatLng initialCenter = isFortTrek
        ? (trekSession?.activeFort.location ?? const LatLng(20.5937, 78.9629))
        : (_walkingStateManager.currentLocation ?? const LatLng(20.5937, 78.9629));

    final LatLng? currentLocation = isFortTrek
        ? _trekStateManager.currentLocation
        : _walkingStateManager.currentLocation;

    final List<LatLng> activeRoutePoints = isFortTrek
        ? (trekSession?.routePoints ?? [])
        : (walkingSession?.routePoints ?? []);

    return Scaffold(
      body: Stack(
        children: [
          GestureDetector(
            onTap: _toggleFocusMode,
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: initialCenter,
                initialZoom: 15.0,
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                ),
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

                // Fort Flag (Only in Fort Trek Mode)
                if (isFortTrek && trekSession != null)
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: trekSession.activeFort.location,
                        width: 50,
                        height: 50,
                        child: const Icon(
                          Icons.flag,
                          color: Colors.red,
                          size: 40,
                        ),
                      ),
                    ],
                  ),

                // Active Route Polylines
                if (activeRoutePoints.isNotEmpty)
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: activeRoutePoints,
                        color: isFortTrek
                            ? colorScheme.secondary
                            : const Color(0xFF0EA5E9),
                        strokeWidth: 6.0,
                      ),
                    ],
                  ),

                // Markers Layer: Start/End Markers for Walking Activity
                if (isWalking && walkingSession != null)
                  MarkerLayer(
                    markers: [
                      if (walkingSession.startLocation != null &&
                          (walkingSession.routePoints.isNotEmpty ||
                              _walkingStateManager.isWalking ||
                              _walkingStateManager.isPaused ||
                              _walkingStateManager.isCompleted))
                        _buildStartMarker(walkingSession.startLocation!),
                      if (_walkingStateManager.isCompleted &&
                          walkingSession.endLocation != null)
                        _buildEndMarker(walkingSession.endLocation!),
                    ],
                  ),

                // Current Location Pulse Marker
                if (currentLocation != null)
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: currentLocation,
                        width: 44,
                        height: 44,
                        child: _buildPulseLocationMarker(currentLocation),
                      ),
                    ],
                  ),
              ],
            ),
          ),

          // Top Mode Selector
          SafeArea(
            child: Align(
              alignment: Alignment.topCenter,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 250),
                opacity: _isFocusMode ? 0.0 : 1.0,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildModeSelector(),
                    if (isWalking) _buildGpsAlertBanner(),
                  ],
                ),
              ),
            ),
          ),

          // Fort Trek Mode: Active Stats Widget
          if (isFortTrek &&
              trekSession != null &&
              (_trekStateManager.isTrekking || _trekStateManager.isPaused))
            AnimatedPositioned(
              duration: const Duration(milliseconds: 300),
              top: _isFocusMode ? -200 : 76,
              left: 0,
              right: 0,
              child: SafeArea(
                child: LiveTrekStatsWidget(
                  session: trekSession,
                  completionPercentage: _trekStateManager.completionPercentage,
                ),
              ),
            ),

          // Fort Trek Mode: Approach / Arrival Banner
          if (isFortTrek &&
              (_trekStateManager.isApproaching || _trekStateManager.isReady))
            _buildApproachBanner(),

          // Fort Trek Mode: Bottom Action Controls
          if (isFortTrek &&
              (_trekStateManager.isTrekking || _trekStateManager.isPaused))
            AnimatedPositioned(
              duration: const Duration(milliseconds: 300),
              bottom: _isFocusMode ? -150 : 120,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_trekStateManager.isTrekking)
                    FloatingActionButton.large(
                      heroTag: 'pause_trek',
                      onPressed: () => _trekStateManager.pauseTrek(),
                      backgroundColor: colorScheme.surface,
                      child: Icon(
                        Icons.pause,
                        color: colorScheme.primary,
                        size: 36,
                      ),
                    ),
                  if (_trekStateManager.isPaused)
                    FloatingActionButton.large(
                      heroTag: 'resume_trek',
                      onPressed: () => _trekStateManager.resumeTrek(),
                      backgroundColor: colorScheme.primary,
                      child: Icon(
                        Icons.play_arrow,
                        color: colorScheme.onPrimary,
                        size: 36,
                      ),
                    ),
                  const SizedBox(width: 32),
                  FloatingActionButton.extended(
                    heroTag: 'end_trek',
                    onPressed: () => _trekStateManager.endTrek(),
                    backgroundColor: colorScheme.error,
                    foregroundColor: colorScheme.onError,
                    icon: const Icon(Icons.stop),
                    label: const Text(
                      'Abandon',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),

          // Walking Activity Mode: Ready Banner
          if (isWalking && _walkingStateManager.isReady)
            _buildWalkingReadyBanner(),

          // Walking Activity Mode: Active Stats Widget
          if (isWalking &&
              walkingSession != null &&
              (_walkingStateManager.isWalking || _walkingStateManager.isPaused))
            AnimatedPositioned(
              duration: const Duration(milliseconds: 300),
              top: _isFocusMode ? -200 : 76,
              left: 0,
              right: 0,
              child: SafeArea(
                child: _buildWalkingStatsWidget(walkingSession),
              ),
            ),

          // Walking Activity Mode: Bottom Action Controls
          if (isWalking &&
              (_walkingStateManager.isWalking || _walkingStateManager.isPaused))
            AnimatedPositioned(
              duration: const Duration(milliseconds: 300),
              bottom: _isFocusMode ? -150 : 120,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_walkingStateManager.isWalking)
                    FloatingActionButton.large(
                      heroTag: 'pause_walk',
                      onPressed: () => _walkingStateManager.pauseWalking(),
                      backgroundColor: colorScheme.surface,
                      child: const Icon(
                        Icons.pause,
                        color: Color(0xFF0EA5E9),
                        size: 36,
                      ),
                    ),
                  if (_walkingStateManager.isPaused)
                    FloatingActionButton.large(
                      heroTag: 'resume_walk',
                      onPressed: () => _walkingStateManager.resumeWalking(),
                      backgroundColor: const Color(0xFF0EA5E9),
                      child: const Icon(
                        Icons.play_arrow,
                        color: Colors.white,
                        size: 36,
                      ),
                    ),
                  const SizedBox(width: 32),
                  FloatingActionButton.extended(
                    heroTag: 'end_walk',
                    onPressed: () => _walkingStateManager.endWalking(),
                    backgroundColor: colorScheme.error,
                    foregroundColor: colorScheme.onError,
                    icon: const Icon(Icons.stop),
                    label: const Text(
                      'Finish Walk',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),

          // Fort Trek Mode: Summary Dialog
          if (isFortTrek &&
              trekSession != null &&
              (_trekStateManager.isCompleted || _trekStateManager.isAbandoned))
            TrekSummaryDialog(
              session: trekSession,
              isVictory: _trekStateManager.isCompleted,
              completionPercentage: _trekStateManager.completionPercentage,
            ),

          // Walking Activity Mode: Summary Dialog
          if (isWalking &&
              walkingSession != null &&
              _walkingStateManager.isCompleted)
            WalkSummaryDialog(
              session: walkingSession,
              onStartAnother: () => _walkingStateManager.reset(),
            ),
        ],
      ),
    );
  }
}
