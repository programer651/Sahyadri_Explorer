import 'dart:async';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../models/fort_model.dart';
import '../models/trek_session_model.dart';
import '../services/gps_tracking_service.dart';
import '../services/trek_progress_service.dart';
import '../services/conquest_storage_service.dart';
import '../services/trek_timer_service.dart';

enum TrekState { approaching, ready, trekking, paused, completed, abandoned }

class TrekStateManager extends ChangeNotifier {
  final LocationTrackingService _trackingService;
  final ConquestStorageService _storageService = ConquestStorageService();
  final TrekTimerService _timerService = TrekTimerService();
  
  TrekSession? _session;
  TrekState _state = TrekState.approaching;
  
  StreamSubscription<LatLng>? _locationSubscription;
  StreamSubscription<Duration>? _timerSubscription;
  
  LatLng? currentLocation;
  String? errorMessage;
  
  double distanceToFortMeters = 0.0;
  double completionPercentage = 0.0;

  TrekStateManager({LocationTrackingService? trackingService}) 
      : _trackingService = trackingService ?? GeolocatorTrackingService() {
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

  Future<void> initialize(Fort activeFort) async {
    _session = TrekSession(
      activeFort: activeFort,
      startTime: DateTime.now(),
    );
    _state = TrekState.approaching;
    notifyListeners();

    try {
      await _trackingService.startTracking(activeFort.location);
      
      _locationSubscription = _trackingService.locationStream.listen((location) {
        currentLocation = location;
        
        const distanceCalc = Distance();
        distanceToFortMeters = distanceCalc.as(
          LengthUnit.Meter, 
          location, 
          _session!.activeFort.location
        );

        if (_state == TrekState.approaching && distanceToFortMeters <= 1000) {
          _state = TrekState.ready;
        }

        if (_state == TrekState.trekking) {
          final updatedPoints = List<LatLng>.from(_session!.routePoints)..add(location);
          
          double newDistance = _session!.distanceCoveredKm;
          if (updatedPoints.length > 1) {
            newDistance += distanceCalc.as(
              LengthUnit.Kilometer, 
              updatedPoints[updatedPoints.length - 2], 
              updatedPoints.last
            );
          }

          double newSpeed = 0.0;
          final hours = _session!.timeElapsed.inSeconds / 3600.0;
          if (hours > 0) {
            newSpeed = newDistance / hours;
          }

          completionPercentage = TrekProgressService.calculateCompletionPercentage(
            newDistance, 
            _session!.activeFort
          );

          _session = _session!.copyWith(
            routePoints: updatedPoints,
            distanceCoveredKm: newDistance,
            currentSpeedKmh: newSpeed,
          );

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
    
    notifyListeners();
  }

  void pauseTrek() {
    if (_state != TrekState.trekking) return;
    _trackingService.pauseTracking();
    _timerService.pause();
    _state = TrekState.paused;
    _session = _session!.copyWith(isPaused: true);
    notifyListeners();
  }

  void resumeTrek() {
    if (_state != TrekState.paused) return;
    _trackingService.resumeTracking();
    _timerService.resume();
    _state = TrekState.trekking;
    _session = _session!.copyWith(isPaused: false);
    notifyListeners();
  }

  Future<void> endTrek({bool isVictoryCheck = false}) async {
    _trackingService.stopTracking();
    _timerService.stop();
    _locationSubscription?.cancel();
    
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

  @override
  void dispose() {
    _trackingService.stopTracking();
    _timerService.dispose();
    _locationSubscription?.cancel();
    _timerSubscription?.cancel();
    super.dispose();
  }
}
