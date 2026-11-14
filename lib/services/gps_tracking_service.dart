import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

abstract class LocationTrackingService {
  Stream<LatLng> get locationStream;
  Future<void> startTracking(
    LatLng destination, {
    String? notificationTitle,
    String? notificationText,
  });
  void pauseTracking();
  void resumeTracking();
  void stopTracking();
  void setSpeedMultiplier(double multiplier);
}

class GeolocatorTrackingService implements LocationTrackingService {
  final _locationController = StreamController<LatLng>.broadcast();
  final _positionController = StreamController<Position>.broadcast();
  StreamSubscription<Position>? _positionStream;
  bool _isPaused = false;

  @override
  Stream<LatLng> get locationStream => _locationController.stream;

  Stream<Position> get positionStream => _positionController.stream;

  @override
  Future<void> startTracking(
    LatLng destination, {
    String? notificationTitle,
    String? notificationText,
  }) async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled. Please enable them in your device settings.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permissions are denied. We need access to track your trek.');
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      throw Exception('Location permissions are permanently denied. We cannot request permissions. Please enable them in app settings.');
    }

    // Cancel existing stream before starting a new one
    _positionStream?.cancel();

    // Permissions granted. Begin tracking.
    _isPaused = false;
    
    // Get initial position immediately
    final initialPos = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high)
    );
    _locationController.add(LatLng(initialPos.latitude, initialPos.longitude));
    _positionController.add(initialPos);

    // Build location settings with Android foreground service notification support
    late final LocationSettings locationSettings;
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      locationSettings = AndroidSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 2, // Emit every 2 meters of movement
        intervalDuration: const Duration(seconds: 2),
        foregroundNotificationConfig: ForegroundNotificationConfig(
          notificationTitle: notificationTitle ?? 'ZeniTrek Active Session',
          notificationText: notificationText ?? 'Live tracking is active in the background',
          notificationIcon: const AndroidResource(
            name: 'ic_launcher',
            defType: 'mipmap',
          ),
          enableWakeLock: true,
          setOngoing: true,
        ),
      );
    } else {
      locationSettings = const LocationSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 2,
      );
    }

    // Listen to continuous stream
    _positionStream = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen((Position position) {
      if (_isPaused) return;
      _locationController.add(LatLng(position.latitude, position.longitude));
      _positionController.add(position);
    });
  }

  @override
  void pauseTracking() {
    _isPaused = true;
  }

  @override
  void resumeTracking() {
    _isPaused = false;
  }

  @override
  void stopTracking() {
    _positionStream?.cancel();
  }

  @override
  void setSpeedMultiplier(double multiplier) {
    // Not applicable for real GPS
  }
}

/// Simulated tracking service for development/testing
class MockGpsTrackingService implements LocationTrackingService {
  final _locationController = StreamController<LatLng>.broadcast();
  Timer? _timer;
  LatLng? _currentLocation;
  LatLng? _destination;
  double _speedMetersPerSecond = 5.0; 
  bool _isPaused = false;

  @override
  Stream<LatLng> get locationStream => _locationController.stream;

  @override
  Future<void> startTracking(
    LatLng destination, {
    String? notificationTitle,
    String? notificationText,
  }) async {
    _destination = destination;
    _currentLocation = LatLng(
      destination.latitude - 0.015,
      destination.longitude - 0.015,
    );
    _isPaused = false;
    _locationController.add(_currentLocation!);

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_isPaused || _currentLocation == null || _destination == null) return;
      _updateLocation();
    });
  }

  void _updateLocation() {
    const distanceCalculator = Distance();
    final double distanceToDest = distanceCalculator.as(
      LengthUnit.Meter, 
      _currentLocation!, 
      _destination!
    );

    if (distanceToDest < 10.0) {
      _locationController.add(_destination!);
      pauseTracking();
      return;
    }

    final double bearing = distanceCalculator.bearing(_currentLocation!, _destination!);
    final LatLng newLocation = distanceCalculator.offset(_currentLocation!, _speedMetersPerSecond, bearing);
    
    final random = Random();
    final LatLng noisyLocation = LatLng(
      newLocation.latitude + (random.nextDouble() - 0.5) * 0.0001,
      newLocation.longitude + (random.nextDouble() - 0.5) * 0.0001,
    );

    _currentLocation = noisyLocation;
    _locationController.add(noisyLocation);
  }

  @override
  void pauseTracking() {
    _isPaused = true;
  }

  @override
  void resumeTracking() {
    _isPaused = false;
  }

  @override
  void stopTracking() {
    _timer?.cancel();
  }

  @override
  void setSpeedMultiplier(double multiplier) {
    _speedMetersPerSecond = 5.0 * multiplier;
  }
}
