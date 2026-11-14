import 'dart:async';
import 'package:material_ui/material_ui.dart';
import 'package:latlong2/latlong.dart';
import '../models/fort_model.dart';
import '../models/trek_session_model.dart';
import '../services/gps_tracking_service.dart';
import '../services/trek_progress_service.dart';
import '../services/conquest_storage_service.dart';
import '../services/trek_timer_service.dart';
import '../services/live_session_storage_service.dart';

enum TrekState { approaching, ready, trekking, paused, completed, abandoned }

class TrekStateManager extends ChangeNotifier {
  // Singleton instance
  static final TrekStateManager _instance = TrekStateManager._internal();
  factory TrekStateManager({LocationTrackingService? trackingService}) {
    if (trackingService != null) {
      _instance._trackingService = trackingService;
    }
    return _instance;
  }

  LocationTrackingService _trackingService = GeolocatorTrackingService();
  final ConquestStorageService _storageService = ConquestStorageService();
  final TrekTimerService _timerService = TrekTimerService();
  final LiveSessionStorageService _sessionStorage = LiveSessionStorageService();

  TrekSession? _session;
  TrekState _state = TrekState.approaching;

  StreamSubscription<LatLng>? _locationSubscription;
  StreamSubscription<Duration>? _timerSubscription;

  LatLng? currentLocation;
  String? errorMessage;

  double distanceToFortMeters = 0.0;
  double completionPercentage = 0.0;
  DateTime? _lastSaveTime;

  TrekStateManager._internal() {
    _timerSubscription = _timerService.durationStream.listen((duration) {
      if (_state == TrekState.trekking) {
        _session = _session?.copyWith(timeElapsed: duration);
        notifyListeners();
      }
    });
  }

  TrekSession? get session => _session;
  TrekState get state => _state;

  bool get isApproaching => _state == TrekState.approaching;
  bool get isReady => _state == TrekState.ready;
  bool get isTrekking => _state == TrekState.trekking;
  bool get isPaused => _state == TrekState.paused;
  bool get isCompleted => _state == TrekState.completed;
  bool get isAbandoned => _state == TrekState.abandoned;

  /// Restores active trek session from persistent storage
  Future<bool> restoreActiveSession() async {
    final activeData = await _sessionStorage.loadActiveTrekSession();
    if (activeData == null) return false;

    _session = activeData.session;
    _state = activeData.state;
    distanceToFortMeters = activeData.distanceToFortMeters;
    completionPercentage = activeData.completionPercentage;
    currentLocation = activeData.currentLocation;

    if (_state == TrekState.trekking) {
      // Resume timer and tracking with existing elapsed duration
      _timerService.start(initialDuration: _session!.timeElapsed);
      await _startTrackingStream(_session!.activeFort);
    } else if (_state == TrekState.approaching || _state == TrekState.ready) {
      await _startTrackingStream(_session!.activeFort);
    }

    notifyListeners();
    return true;
  }

  Future<void> initialize(Fort activeFort) async {
    // If a trek is already active or paused for the same fort, do not reset!
    if ((isTrekking || isPaused) && _session?.activeFort.id == activeFort.id) {
      return;
    }

    _session = TrekSession(activeFort: activeFort, startTime: DateTime.now());
    _state = TrekState.approaching;
    notifyListeners();

    await _startTrackingStream(activeFort);
    _persistSession();
  }

  Future<void> _startTrackingStream(Fort fort) async {
    try {
      _locationSubscription?.cancel();
      await _trackingService.startTracking(
        fort.location,
        notificationTitle: 'ZeniTrek Fort Trek: ${fort.name}',
        notificationText: 'Tracking your ascent to ${fort.name}...',
      );

      _locationSubscription = _trackingService.locationStream.listen((
        location,
      ) {
        currentLocation = location;

        const distanceCalc = Distance();
        distanceToFortMeters = distanceCalc.as(
          LengthUnit.Meter,
          location,
          _session!.activeFort.location,
        );

        if (_state == TrekState.approaching && distanceToFortMeters <= 1000) {
          _state = TrekState.ready;
          _persistSession();
        }

        if (_state == TrekState.trekking) {
          final updatedPoints = List<LatLng>.from(_session!.routePoints);

          // Prevent duplicate or micro-jitter points (< 2.0 meters)
          if (updatedPoints.isNotEmpty) {
            final deltaMeters = distanceCalc.as(
              LengthUnit.Meter,
              updatedPoints.last,
              location,
            );
            if (deltaMeters < 2.0) {
              notifyListeners();
              return;
            }
          }

          updatedPoints.add(location);

          double newDistance = _session!.distanceCoveredKm;
          if (updatedPoints.length > 1) {
            newDistance += distanceCalc.as(
              LengthUnit.Kilometer,
              updatedPoints[updatedPoints.length - 2],
              updatedPoints.last,
            );
          }

          double newSpeed = 0.0;
          final hours = _session!.timeElapsed.inSeconds / 3600.0;
          if (hours > 0) {
            newSpeed = newDistance / hours;
          }

          completionPercentage =
              TrekProgressService.calculateCompletionPercentage(
                newDistance,
                _session!.activeFort,
              );

          _session = _session!.copyWith(
            routePoints: updatedPoints,
            distanceCoveredKm: newDistance,
            currentSpeedKmh: newSpeed,
          );

          // Throttled persistence (save every 5 seconds during active movement)
          final now = DateTime.now();
          if (_lastSaveTime == null ||
              now.difference(_lastSaveTime!).inSeconds >= 5) {
            _lastSaveTime = now;
            _persistSession();
          }

          if (completionPercentage >= 0.90) {
            endTrek(isVictoryCheck: true);
          }
        }

        notifyListeners();
      });
    } catch (e) {
      errorMessage = e.toString();
      notifyListeners();
    }
  }

  void startTrek() {
    if (_state != TrekState.ready) return;

    _state = TrekState.trekking;
    _session!.startTime = DateTime.now();
    _session!.routePoints.clear();

    // Reset and Start Timer immediately
    _session = _session!.copyWith(timeElapsed: Duration.zero);
    _timerService.stop(); // Reset
    _timerService.start();

    if (currentLocation != null) {
      _session!.routePoints.add(currentLocation!);
    }

    _persistSession();
    notifyListeners();
  }

  void pauseTrek() {
    if (_state != TrekState.trekking) return;
    _trackingService.pauseTracking();
    _timerService.pause();
    _state = TrekState.paused;
    _session = _session!.copyWith(isPaused: true, currentSpeedKmh: 0.0);
    _persistSession();
    notifyListeners();
  }

  void resumeTrek() {
    if (_state != TrekState.paused) return;
    _trackingService.resumeTracking();
    _timerService.resume();
    _state = TrekState.trekking;
    _session = _session!.copyWith(isPaused: false);
    _persistSession();
    notifyListeners();
  }

  Future<void> endTrek({bool isVictoryCheck = false}) async {
    _trackingService.stopTracking();
    _timerService.stop();
    _locationSubscription?.cancel();

    // Clear active session from persistent storage on explicit end
    await _sessionStorage.clearActiveSession();

    if (completionPercentage >= 0.90 || isVictoryCheck) {
      _state = TrekState.completed;
      await _storageService.saveTrek(
        _session!.distanceCoveredKm,
        true,
        _session!.activeFort.id,
        _session!.activeFort.name,
        completionPercentage,
        _session!.timeElapsed,
      );
    } else {
      _state = TrekState.abandoned;
      await _storageService.saveTrek(
        _session!.distanceCoveredKm,
        false,
        _session!.activeFort.id,
        _session!.activeFort.name,
        completionPercentage,
        _session!.timeElapsed,
      );
    }

    notifyListeners();
  }

  void reset() {
    _session = null;
    _state = TrekState.approaching;
    currentLocation = null;
    distanceToFortMeters = 0.0;
    completionPercentage = 0.0;
    _sessionStorage.clearActiveSession();
    notifyListeners();
  }

  void saveCurrentState() {
    _persistSession();
  }

  void _persistSession() {
    if (_session == null) return;
    if (_state == TrekState.completed || _state == TrekState.abandoned) return;

    _sessionStorage.saveActiveTrekSession(
      session: _session!,
      state: _state,
      distanceToFortMeters: distanceToFortMeters,
      completionPercentage: completionPercentage,
      currentLocation: currentLocation,
    );
  }

  @override
  void dispose() {
    // Note: Do not stop tracking here if active, since TrekStateManager is a singleton
    _trackingService.stopTracking();
    _timerService.dispose();
    _locationSubscription?.cancel();
    _timerSubscription?.cancel();
    super.dispose();
  }
}
