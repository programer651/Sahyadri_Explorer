import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/fort_model.dart';
import '../models/trek_session_model.dart';
import '../state/trek_state_manager.dart';
import '../state/walking_state_manager.dart';

enum ActiveSessionType { none, fortTrek, walking }

class ActiveTrekData {
  final TrekSession session;
  final TrekState state;
  final double distanceToFortMeters;
  final double completionPercentage;
  final LatLng? currentLocation;
  final DateTime lastSavedTime;

  ActiveTrekData({
    required this.session,
    required this.state,
    required this.distanceToFortMeters,
    required this.completionPercentage,
    this.currentLocation,
    required this.lastSavedTime,
  });
}

class ActiveWalkingData {
  final WalkingSession session;
  final WalkingState state;
  final LatLng? currentLocation;
  final DateTime lastSavedTime;

  ActiveWalkingData({
    required this.session,
    required this.state,
    this.currentLocation,
    required this.lastSavedTime,
  });
}

class LiveSessionStorageService {
  final FirebaseAuth _auth;

  LiveSessionStorageService({FirebaseAuth? auth})
      : _auth = auth ?? FirebaseAuth.instance;

  String get _userId {
    final uid = _auth.currentUser?.uid;
    if (uid != null && uid.isNotEmpty) {
      return uid;
    }
    return 'guest';
  }

  String get _keyActiveSessionType => 'live_session_type_v1_$_userId';
  String get _keyActiveTrekSession => 'live_session_trek_v1_$_userId';
  String get _keyActiveWalkingSession => 'live_session_walking_v1_$_userId';

  /// Save active fort trek session state
  Future<void> saveActiveTrekSession({
    required TrekSession session,
    required TrekState state,
    required double distanceToFortMeters,
    required double completionPercentage,
    required LatLng? currentLocation,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    final data = {
      'activeFort': session.activeFort.toJson(),
      'startTime': session.startTime.toIso8601String(),
      'distanceCoveredKm': session.distanceCoveredKm,
      'timeElapsedSeconds': session.timeElapsed.inSeconds,
      'currentSpeedKmh': session.currentSpeedKmh,
      'elevationGainMeters': session.elevationGainMeters,
      'isPaused': session.isPaused,
      'state': state.name,
      'distanceToFortMeters': distanceToFortMeters,
      'completionPercentage': completionPercentage,
      'currentLocation': currentLocation != null
          ? {'lat': currentLocation.latitude, 'lng': currentLocation.longitude}
          : null,
      'routePoints': session.routePoints
          .map((p) => {'lat': p.latitude, 'lng': p.longitude})
          .toList(),
      'lastSavedTime': DateTime.now().toIso8601String(),
    };

    await prefs.setString(_keyActiveSessionType, 'fortTrek');
    await prefs.setString(_keyActiveTrekSession, jsonEncode(data));
  }

  /// Save active walking session state
  Future<void> saveActiveWalkingSession({
    required WalkingSession session,
    required WalkingState state,
    required LatLng? currentLocation,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    final data = {
      'startTime': session.startTime.toIso8601String(),
      'endTime': session.endTime?.toIso8601String(),
      'distanceCoveredKm': session.distanceCoveredKm,
      'timeElapsedSeconds': session.timeElapsed.inSeconds,
      'currentSpeedKmh': session.currentSpeedKmh,
      'avgSpeedKmh': session.avgSpeedKmh,
      'maxSpeedKmh': session.maxSpeedKmh,
      'steps': session.steps,
      'isPaused': session.isPaused,
      'state': state.name,
      'startLocation': session.startLocation != null
          ? {
              'lat': session.startLocation!.latitude,
              'lng': session.startLocation!.longitude
            }
          : null,
      'startLocationName': session.startLocationName,
      'endLocation': session.endLocation != null
          ? {
              'lat': session.endLocation!.latitude,
              'lng': session.endLocation!.longitude
            }
          : null,
      'endLocationName': session.endLocationName,
      'currentLocation': currentLocation != null
          ? {'lat': currentLocation.latitude, 'lng': currentLocation.longitude}
          : null,
      'routePoints': session.routePoints
          .map((p) => {'lat': p.latitude, 'lng': p.longitude})
          .toList(),
      'lastSavedTime': DateTime.now().toIso8601String(),
    };

    await prefs.setString(_keyActiveSessionType, 'walking');
    await prefs.setString(_keyActiveWalkingSession, jsonEncode(data));
  }

  /// Clear any active session state
  Future<void> clearActiveSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyActiveSessionType);
    await prefs.remove(_keyActiveTrekSession);
    await prefs.remove(_keyActiveWalkingSession);
  }

  /// Get current active session type
  Future<ActiveSessionType> getActiveSessionType() async {
    final prefs = await SharedPreferences.getInstance();
    final typeStr = prefs.getString(_keyActiveSessionType);
    if (typeStr == 'fortTrek') return ActiveSessionType.fortTrek;
    if (typeStr == 'walking') return ActiveSessionType.walking;
    return ActiveSessionType.none;
  }

  /// Load active fort trek session
  Future<ActiveTrekData?> loadActiveTrekSession() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_keyActiveTrekSession);
    if (jsonStr == null || jsonStr.isEmpty) return null;

    try {
      final map = jsonDecode(jsonStr) as Map<String, dynamic>;

      final fort = Fort.fromJson(map['activeFort'] as Map<String, dynamic>);
      final startTime = DateTime.parse(map['startTime'] as String);
      final lastSavedTime = DateTime.parse(map['lastSavedTime'] as String);
      final timeElapsed = Duration(seconds: map['timeElapsedSeconds'] as int? ?? 0);
      final distanceCoveredKm = (map['distanceCoveredKm'] as num? ?? 0.0).toDouble();
      final currentSpeedKmh = (map['currentSpeedKmh'] as num? ?? 0.0).toDouble();
      final elevationGainMeters = (map['elevationGainMeters'] as num? ?? 0.0).toDouble();
      final isPaused = map['isPaused'] as bool? ?? false;

      final stateStr = map['state'] as String? ?? 'approaching';
      TrekState state = TrekState.approaching;
      for (final s in TrekState.values) {
        if (s.name == stateStr) {
          state = s;
          break;
        }
      }

      final distanceToFortMeters = (map['distanceToFortMeters'] as num? ?? 0.0).toDouble();
      final completionPercentage = (map['completionPercentage'] as num? ?? 0.0).toDouble();

      LatLng? currentLocation;
      if (map['currentLocation'] != null) {
        final locMap = map['currentLocation'] as Map<String, dynamic>;
        currentLocation = LatLng(
          (locMap['lat'] as num).toDouble(),
          (locMap['lng'] as num).toDouble(),
        );
      }

      final routePointsList = (map['routePoints'] as List<dynamic>?)
              ?.map((p) => LatLng(
                    (p['lat'] as num).toDouble(),
                    (p['lng'] as num).toDouble(),
                  ))
              .toList() ??
          <LatLng>[];

      final session = TrekSession(
        activeFort: fort,
        startTime: startTime,
        distanceCoveredKm: distanceCoveredKm,
        timeElapsed: timeElapsed,
        currentSpeedKmh: currentSpeedKmh,
        elevationGainMeters: elevationGainMeters,
        routePoints: routePointsList,
        isPaused: isPaused,
      );

      return ActiveTrekData(
        session: session,
        state: state,
        distanceToFortMeters: distanceToFortMeters,
        completionPercentage: completionPercentage,
        currentLocation: currentLocation,
        lastSavedTime: lastSavedTime,
      );
    } catch (e) {
      return null;
    }
  }

  /// Load active walking session
  Future<ActiveWalkingData?> loadActiveWalkingSession() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_keyActiveWalkingSession);
    if (jsonStr == null || jsonStr.isEmpty) return null;

    try {
      final map = jsonDecode(jsonStr) as Map<String, dynamic>;

      final startTime = DateTime.parse(map['startTime'] as String);
      final lastSavedTime = DateTime.parse(map['lastSavedTime'] as String);
      final endTime = map['endTime'] != null ? DateTime.parse(map['endTime'] as String) : null;
      final timeElapsed = Duration(seconds: map['timeElapsedSeconds'] as int? ?? 0);
      final distanceCoveredKm = (map['distanceCoveredKm'] as num? ?? 0.0).toDouble();
      final currentSpeedKmh = (map['currentSpeedKmh'] as num? ?? 0.0).toDouble();
      final avgSpeedKmh = (map['avgSpeedKmh'] as num? ?? 0.0).toDouble();
      final maxSpeedKmh = (map['maxSpeedKmh'] as num? ?? 0.0).toDouble();
      final steps = map['steps'] as int? ?? 0;
      final isPaused = map['isPaused'] as bool? ?? false;

      final stateStr = map['state'] as String? ?? 'ready';
      WalkingState state = WalkingState.ready;
      for (final s in WalkingState.values) {
        if (s.name == stateStr) {
          state = s;
          break;
        }
      }

      LatLng? startLocation;
      if (map['startLocation'] != null) {
        final locMap = map['startLocation'] as Map<String, dynamic>;
        startLocation = LatLng(
          (locMap['lat'] as num).toDouble(),
          (locMap['lng'] as num).toDouble(),
        );
      }

      LatLng? endLocation;
      if (map['endLocation'] != null) {
        final locMap = map['endLocation'] as Map<String, dynamic>;
        endLocation = LatLng(
          (locMap['lat'] as num).toDouble(),
          (locMap['lng'] as num).toDouble(),
        );
      }

      LatLng? currentLocation;
      if (map['currentLocation'] != null) {
        final locMap = map['currentLocation'] as Map<String, dynamic>;
        currentLocation = LatLng(
          (locMap['lat'] as num).toDouble(),
          (locMap['lng'] as num).toDouble(),
        );
      }

      final routePointsList = (map['routePoints'] as List<dynamic>?)
              ?.map((p) => LatLng(
                    (p['lat'] as num).toDouble(),
                    (p['lng'] as num).toDouble(),
                  ))
              .toList() ??
          <LatLng>[];

      final session = WalkingSession(
        startTime: startTime,
        endTime: endTime,
        distanceCoveredKm: distanceCoveredKm,
        timeElapsed: timeElapsed,
        currentSpeedKmh: currentSpeedKmh,
        avgSpeedKmh: avgSpeedKmh,
        maxSpeedKmh: maxSpeedKmh,
        steps: steps,
        isPaused: isPaused,
        startLocation: startLocation,
        startLocationName: map['startLocationName'] as String?,
        endLocation: endLocation,
        endLocationName: map['endLocationName'] as String?,
        routePoints: routePointsList,
      );

      return ActiveWalkingData(
        session: session,
        state: state,
        currentLocation: currentLocation,
        lastSavedTime: lastSavedTime,
      );
    } catch (e) {
      return null;
    }
  }
}
