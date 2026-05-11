import 'package:latlong2/latlong.dart';
import 'fort_model.dart';

class TrekSession {
  final Fort activeFort;
  DateTime startTime;
  
  double distanceCoveredKm;
  Duration timeElapsed;
  double currentSpeedKmh;
  double elevationGainMeters;
  List<LatLng> routePoints;
  bool isPaused;

  TrekSession({
    required this.activeFort,
    required this.startTime,
    this.distanceCoveredKm = 0.0,
    this.timeElapsed = Duration.zero,
    this.currentSpeedKmh = 0.0,
    this.elevationGainMeters = 0.0,
    this.routePoints = const [],
    this.isPaused = false,
  });

  TrekSession copyWith({
    double? distanceCoveredKm,
    Duration? timeElapsed,
    double? currentSpeedKmh,
    double? elevationGainMeters,
    List<LatLng>? routePoints,
    bool? isPaused,
  }) {
    return TrekSession(
      activeFort: activeFort,
      startTime: startTime,
      distanceCoveredKm: distanceCoveredKm ?? this.distanceCoveredKm,
      timeElapsed: timeElapsed ?? this.timeElapsed,
      currentSpeedKmh: currentSpeedKmh ?? this.currentSpeedKmh,
      elevationGainMeters: elevationGainMeters ?? this.elevationGainMeters,
      routePoints: routePoints ?? this.routePoints,
      isPaused: isPaused ?? this.isPaused,
    );
  }
}
