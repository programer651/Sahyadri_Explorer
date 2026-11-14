import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../models/walking_activity_model.dart';
import '../services/gps_tracking_service.dart';
import '../services/walking_storage_service.dart';
import '../services/trek_timer_service.dart';
import '../services/location_service.dart';

enum WalkingState { ready, walking, paused, completed }

class WalkingSession {
  DateTime startTime;
  DateTime? endTime;
  double distanceCoveredKm;
  Duration timeElapsed;
  double currentSpeedKmh;
  double avgSpeedKmh;
  double maxSpeedKmh;
  int steps;
  LatLng? startLocation;
  String? startLocationName;
  LatLng? endLocation;
  String? endLocationName;
  List<LatLng> routePoints;
  bool isPaused;

  WalkingSession({
    required this.startTime,
    this.endTime,
    this.distanceCoveredKm = 0.0,
    this.timeElapsed = Duration.zero,
    this.currentSpeedKmh = 0.0,
    this.avgSpeedKmh = 0.0,
    this.maxSpeedKmh = 0.0,
    this.steps = 0,
    this.startLocation,
    this.startLocationName,
    this.endLocation,
    this.endLocationName,
    this.routePoints = const [],
    this.isPaused = false,
  });

  WalkingSession copyWith({
    DateTime? startTime,
    DateTime? endTime,
    double? distanceCoveredKm,
    Duration? timeElapsed,
    double? currentSpeedKmh,
    double? avgSpeedKmh,
    double? maxSpeedKmh,
    int? steps,
    LatLng? startLocation,
    String? startLocationName,
    LatLng? endLocation,
    String? endLocationName,
    List<LatLng>? routePoints,
    bool? isPaused,
  }) {
    return WalkingSession(
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      distanceCoveredKm: distanceCoveredKm ?? this.distanceCoveredKm,
      timeElapsed: timeElapsed ?? this.timeElapsed,
      currentSpeedKmh: currentSpeedKmh ?? this.currentSpeedKmh,
      avgSpeedKmh: avgSpeedKmh ?? this.avgSpeedKmh,
      maxSpeedKmh: maxSpeedKmh ?? this.maxSpeedKmh,
      steps: steps ?? this.steps,
      startLocation: startLocation ?? this.startLocation,
      startLocationName: startLocationName ?? this.startLocationName,
      endLocation: endLocation ?? this.endLocation,
      endLocationName: endLocationName ?? this.endLocationName,
      routePoints: routePoints ?? this.routePoints,
      isPaused: isPaused ?? this.isPaused,
    );
  }
}

class WalkingStateManager extends ChangeNotifier {
  final GeolocatorTrackingService _trackingService;
  final WalkingStorageService _storageService = WalkingStorageService();
  final TrekTimerService _timerService = TrekTimerService();
  final LocationService _locationService = LocationService();

  WalkingSession? _session;
  WalkingState _state = WalkingState.ready;

  StreamSubscription<Position>? _positionSubscription;
  StreamSubscription<Duration>? _timerSubscription;

  LatLng? currentLocation;
  String? errorMessage;

  bool isGpsDisabled = false;
  bool isPermissionDenied = false;
  bool isPermissionPermanentlyDenied = false;
  bool hasPoorAccuracy = false;
  double gpsAccuracyMeters = 0.0;

  LatLng? _lastValidPoint;
  DateTime? _lastValidPointTime;

  WalkingStateManager({GeolocatorTrackingService? trackingService})
      : _trackingService = trackingService ?? GeolocatorTrackingService() {
    _timerSubscription = _timerService.durationStream.listen((duration) {
      if (_state == WalkingState.walking) {
        _session = _session?.copyWith(timeElapsed: duration);

        // Update average speed regularly based on elapsed time
        if (duration.inSeconds > 0 && (_session?.distanceCoveredKm ?? 0) > 0) {
          final hours = duration.inSeconds / 3600.0;
          final avgSpeed = _session!.distanceCoveredKm / hours;
          _session = _session?.copyWith(avgSpeedKmh: avgSpeed);
        }

        notifyListeners();
      }
    });
  }

  WalkingSession? get session => _session;
  WalkingState get state => _state;

  bool get isReady => _state == WalkingState.ready;
  bool get isWalking => _state == WalkingState.walking;
  bool get isPaused => _state == WalkingState.paused;
  bool get isCompleted => _state == WalkingState.completed;

  Future<void> initialize() async {
    _state = WalkingState.ready;
    _session = WalkingSession(startTime: DateTime.now());
    notifyListeners();

    final hasPermission = await checkAndRequestPermissions();
    if (!hasPermission) return;

    try {
      await _trackingService.startTracking(const LatLng(0, 0));

      _positionSubscription?.cancel();
      _positionSubscription = _trackingService.positionStream.listen(
        (Position position) {
          _processPositionUpdate(position);
        },
        onError: (e) {
          errorMessage = 'Location error: $e';
          notifyListeners();
        },
      );
    } catch (e) {
      errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<bool> checkAndRequestPermissions() async {
    isGpsDisabled = false;
    isPermissionDenied = false;
    isPermissionPermanentlyDenied = false;

    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      isGpsDisabled = true;
      errorMessage = 'Location services are disabled. Please enable GPS in device settings.';
      notifyListeners();
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        isPermissionDenied = true;
        errorMessage = 'Location permissions are denied. We need access to track your walk.';
        notifyListeners();
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      isPermissionPermanentlyDenied = true;
      errorMessage = 'Location permissions are permanently denied. Please enable them in app settings.';
      notifyListeners();
      return false;
    }

    errorMessage = null;
    notifyListeners();
    return true;
  }

  void _processPositionUpdate(Position position) {
    currentLocation = LatLng(position.latitude, position.longitude);
    gpsAccuracyMeters = position.accuracy;

    // Check accuracy threshold: ignore fixes with > 35m uncertainty for distance
    if (position.accuracy > 35.0 || position.accuracy <= 0) {
      hasPoorAccuracy = true;
      notifyListeners();
      return;
    }
    hasPoorAccuracy = false;

    // If not actively walking (e.g. ready or paused), update current position without distance accumulation
    if (_state != WalkingState.walking) {
      notifyListeners();
      return;
    }

    final newPoint = LatLng(position.latitude, position.longitude);

    // Initial point of the walk
    if (_session!.routePoints.isEmpty) {
      _lastValidPoint = newPoint;
      _lastValidPointTime = position.timestamp;

      _session = _session!.copyWith(
        startLocation: newPoint,
        endLocation: newPoint,
        routePoints: [newPoint],
      );

      // Asynchronously resolve start location name
      _resolveStartLocationName(newPoint);

      notifyListeners();
      return;
    }

    const distanceCalc = Distance();
    final deltaMeters = distanceCalc.as(LengthUnit.Meter, _lastValidPoint!, newPoint);

    // Filter 1: Duplicate or micro-jitter (less than 2.0 meters of movement)
    if (deltaMeters < 2.0) {
      return;
    }

    // Filter 2: Teleportation / Outlier spike check
    final timeDeltaSeconds = _lastValidPointTime != null
        ? position.timestamp.difference(_lastValidPointTime!).inMilliseconds / 1000.0
        : 1.0;

    if (timeDeltaSeconds > 0) {
      final calculatedSpeedMs = deltaMeters / timeDeltaSeconds;
      // Walking / running speed rarely exceeds 7 m/s (25 km/h)
      if (calculatedSpeedMs > 7.0 && deltaMeters > 20.0) {
        // Discard spike
        return;
      }
    }

    // Valid GPS walking point
    final updatedPoints = List<LatLng>.from(_session!.routePoints)..add(newPoint);
    final deltaKm = deltaMeters / 1000.0;
    final newDistance = _session!.distanceCoveredKm + deltaKm;

    // Instantaneous speed
    double speedKmh = 0.0;
    if (position.speed > 0) {
      speedKmh = position.speed * 3.6;
    } else if (timeDeltaSeconds > 0) {
      speedKmh = (deltaMeters / timeDeltaSeconds) * 3.6;
    }
    speedKmh = speedKmh.clamp(0.0, 20.0);

    final newMaxSpeed = max(_session!.maxSpeedKmh, speedKmh);

    // Average speed
    double avgSpeed = _session!.avgSpeedKmh;
    final hours = _session!.timeElapsed.inSeconds / 3600.0;
    if (hours > 0) {
      avgSpeed = newDistance / hours;
    }

    // Estimated steps: standard adult walking stride is ~0.762 meters (~1312 steps/km)
    final estimatedSteps = (newDistance * 1000 / 0.762).round();

    _lastValidPoint = newPoint;
    _lastValidPointTime = position.timestamp;

    _session = _session!.copyWith(
      distanceCoveredKm: newDistance,
      currentSpeedKmh: speedKmh,
      maxSpeedKmh: newMaxSpeed,
      avgSpeedKmh: avgSpeed,
      steps: estimatedSteps,
      endLocation: newPoint,
      routePoints: updatedPoints,
    );

    notifyListeners();
  }

  void _resolveStartLocationName(LatLng point) async {
    final name = await _locationService.getReadableLocationFromCoordinates(
      point.latitude,
      point.longitude,
    );
    if (name != null && _session != null) {
      _session = _session!.copyWith(startLocationName: name);
      notifyListeners();
    }
  }

  void startWalking() {
    _state = WalkingState.walking;
    final initialPoints = currentLocation != null ? [currentLocation!] : <LatLng>[];

    _lastValidPoint = currentLocation;
    _lastValidPointTime = DateTime.now();

    _session = WalkingSession(
      startTime: DateTime.now(),
      startLocation: currentLocation,
      endLocation: currentLocation,
      routePoints: initialPoints,
    );

    if (currentLocation != null) {
      _resolveStartLocationName(currentLocation!);
    }

    // Start timer immediately from 0
    _timerService.stop();
    _timerService.start();
    notifyListeners();
  }

  void pauseWalking() {
    if (_state != WalkingState.walking) return;
    _trackingService.pauseTracking();
    _timerService.pause();
    _state = WalkingState.paused;
    _session = _session?.copyWith(
      isPaused: true,
      currentSpeedKmh: 0.0,
    );
    notifyListeners();
  }

  void resumeWalking() {
    if (_state != WalkingState.paused) return;
    _trackingService.resumeTracking();
    _timerService.resume();
    _lastValidPointTime = DateTime.now();
    _state = WalkingState.walking;
    _session = _session?.copyWith(isPaused: false);
    notifyListeners();
  }

  Future<void> endWalking() async {
    _trackingService.stopTracking();
    _timerService.stop();
    _state = WalkingState.completed;

    final now = DateTime.now();
    final endLoc = currentLocation ?? _session?.endLocation ?? _session?.startLocation ?? const LatLng(0, 0);

    String? endName;
    if (endLoc.latitude != 0 && endLoc.longitude != 0) {
      endName = await _locationService.getReadableLocationFromCoordinates(
        endLoc.latitude,
        endLoc.longitude,
      );
    }

    final startLoc = _session?.startLocation ?? endLoc;
    String? startName = _session?.startLocationName;
    if (startName == null && startLoc.latitude != 0 && startLoc.longitude != 0) {
      startName = await _locationService.getReadableLocationFromCoordinates(
        startLoc.latitude,
        startLoc.longitude,
      );
    }

    _session = _session?.copyWith(
      endTime: now,
      endLocation: endLoc,
      endLocationName: endName,
      startLocationName: startName,
      currentSpeedKmh: 0.0,
    );

    // Save activity independently (does NOT count as fort trek, does NOT trigger conquest system)
    if (_session != null && _session!.distanceCoveredKm > 0) {
      final activity = WalkingActivity(
        id: 'walk_${now.millisecondsSinceEpoch}',
        startTime: _session!.startTime,
        endTime: now,
        duration: _session!.timeElapsed,
        distanceKm: _session!.distanceCoveredKm,
        avgSpeedKmh: _session!.avgSpeedKmh,
        maxSpeedKmh: _session!.maxSpeedKmh,
        steps: _session!.steps,
        startLocation: startLoc,
        startLocationName: startName,
        endLocation: endLoc,
        endLocationName: endName,
        routePoints: _session!.routePoints,
      );

      await _storageService.saveActivity(activity);
    }

    notifyListeners();
  }

  void reset() {
    _state = WalkingState.ready;
    _session = WalkingSession(startTime: DateTime.now());
    _lastValidPoint = null;
    _lastValidPointTime = null;
    initialize();
  }

  @override
  void dispose() {
    _trackingService.stopTracking();
    _timerService.dispose();
    _positionSubscription?.cancel();
    _timerSubscription?.cancel();
    super.dispose();
  }
}
