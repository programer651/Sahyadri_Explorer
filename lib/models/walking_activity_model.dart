import 'package:latlong2/latlong.dart';

class WalkingActivity {
  final String id;
  final DateTime startTime;
  final DateTime endTime;
  final Duration duration;
  final double distanceKm;
  final double avgSpeedKmh;
  final double maxSpeedKmh;
  final int steps;
  final LatLng startLocation;
  final String? startLocationName;
  final LatLng endLocation;
  final String? endLocationName;
  final List<LatLng> routePoints;

  WalkingActivity({
    required this.id,
    required this.startTime,
    required this.endTime,
    required this.duration,
    required this.distanceKm,
    required this.avgSpeedKmh,
    required this.maxSpeedKmh,
    required this.steps,
    required this.startLocation,
    this.startLocationName,
    required this.endLocation,
    this.endLocationName,
    required this.routePoints,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'durationSeconds': duration.inSeconds,
      'distanceKm': distanceKm,
      'avgSpeedKmh': avgSpeedKmh,
      'maxSpeedKmh': maxSpeedKmh,
      'steps': steps,
      'startLat': startLocation.latitude,
      'startLng': startLocation.longitude,
      'startLocationName': startLocationName,
      'endLat': endLocation.latitude,
      'endLng': endLocation.longitude,
      'endLocationName': endLocationName,
      'routePoints': routePoints
          .map((p) => {'lat': p.latitude, 'lng': p.longitude})
          .toList(),
    };
  }

  factory WalkingActivity.fromJson(Map<String, dynamic> json) {
    final routeList = (json['routePoints'] as List<dynamic>?)
            ?.map((p) => LatLng(
                  (p['lat'] as num).toDouble(),
                  (p['lng'] as num).toDouble(),
                ))
            .toList() ??
        [];

    return WalkingActivity(
      id: json['id'] as String,
      startTime: DateTime.parse(json['startTime'] as String),
      endTime: DateTime.parse(json['endTime'] as String),
      duration: Duration(seconds: json['durationSeconds'] as int? ?? 0),
      distanceKm: (json['distanceKm'] as num).toDouble(),
      avgSpeedKmh: (json['avgSpeedKmh'] as num).toDouble(),
      maxSpeedKmh: (json['maxSpeedKmh'] as num).toDouble(),
      steps: json['steps'] as int? ?? 0,
      startLocation: LatLng(
        (json['startLat'] as num).toDouble(),
        (json['startLng'] as num).toDouble(),
      ),
      startLocationName: json['startLocationName'] as String?,
      endLocation: LatLng(
        (json['endLat'] as num).toDouble(),
        (json['endLng'] as num).toDouble(),
      ),
      endLocationName: json['endLocationName'] as String?,
      routePoints: routeList,
    );
  }
}

