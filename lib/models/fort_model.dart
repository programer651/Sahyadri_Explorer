import 'package:latlong2/latlong.dart';

class Fort {
  final String id;
  final String name;
  final LatLng location;
  final String district;
  final String difficulty;
  final String estimatedTime;
  final String height;
  final String description;

  const Fort({
    required this.id,
    required this.name,
    required this.location,
    required this.district,
    required this.difficulty,
    required this.estimatedTime,
    required this.height,
    required this.description,
  });

  factory Fort.fromJson(Map<String, dynamic> json) {
    return Fort(
      id: json['id'] as String,
      name: json['name'] as String,
      location: LatLng(
        (json['latitude'] as num).toDouble(),
        (json['longitude'] as num).toDouble(),
      ),
      district: json['district'] as String? ?? 'Unknown',
      difficulty: json['difficulty'] as String? ?? 'Unknown',
      estimatedTime: json['estimatedTime'] as String? ?? 'Unknown',
      height: json['height'] as String? ?? 'Unknown',
      description: json['description'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'latitude': location.latitude,
      'longitude': location.longitude,
      'district': district,
      'difficulty': difficulty,
      'estimatedTime': estimatedTime,
      'height': height,
      'description': description,
    };
  }
}
