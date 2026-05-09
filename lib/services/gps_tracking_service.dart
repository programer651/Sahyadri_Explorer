import 'dart:async';
import 'dart:math';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

abstract class LocationTrackingService {
  Stream<LatLng> get locationStream;
  Future<void> startTracking(LatLng destination);
  void pauseTracking();
  void resumeTracking();
  void stopTracking();
  void setSpeedMultiplier(double multiplier);
}

class GeolocatorTrackingService implements LocationTrackingService {
  final _locationController = StreamController<LatLng>.broadcast();
  StreamSubscription<Position>? _positionStream;
  bool _isPaused = false;

  @override
  Stream<LatLng> get locationStream => _locationController.stream;

  @override
  Future<void> startTracking(LatLng destination) async {
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

    // Permissions granted. Begin tracking.
    _isPaused = false;
    
    // Get initial position immediately
    final initialPos = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high)
    );
    _locationController.add(LatLng(initialPos.latitude, initialPos.longitude));

    // Listen to continuous stream
    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 2, // Emit every 2 meters of movement
      ),
    ).listen((Position position) {
      if (_isPaused) return;
      _locationController.add(LatLng(position.latitude, position.longitude));
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
  Future<void> startTracking(LatLng destination) async {
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
