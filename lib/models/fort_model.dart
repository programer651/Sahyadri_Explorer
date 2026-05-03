import 'package:latlong2/latlong.dart';

class Fort {
  final String id;
  final String name;
  final LatLng location;
  final String difficulty;
  final String estimatedTime;
  final String description;

  const Fort({
    required this.id,
    required this.name,
    required this.location,
    required this.difficulty,
    required this.estimatedTime,
    required this.description,
  });

  // Hardcoded list of famous Maharashtrian forts in the Sahyadri range
  static const List<Fort> staticForts = [
    Fort(
      id: 'f1',
      name: 'Rajgad Fort',
      location: LatLng(18.2464, 73.6811),
      difficulty: 'Hard',
      estimatedTime: '3-4 hours',
      description: 'Once the capital of the Maratha Empire, known for its sheer scale and the perilous Suvela Machi.',
    ),
    Fort(
      id: 'f2',
      name: 'Torna Fort',
      location: LatLng(18.2778, 73.6219),
      difficulty: 'Medium-Hard',
      estimatedTime: '3 hours',
      description: 'The first fort captured by Shivaji Maharaj. It features steep climbs and magnificent views.',
    ),
    Fort(
      id: 'f3',
      name: 'Sinhagad Fort',
      location: LatLng(18.3663, 73.7559),
      difficulty: 'Easy-Medium',
      estimatedTime: '1.5 hours',
      description: 'A popular fort near Pune with immense historical significance and a relatively easy trek.',
    ),
    Fort(
      id: 'f4',
      name: 'Lohagad Fort',
      location: LatLng(18.7057, 73.4754),
      difficulty: 'Easy',
      estimatedTime: '1 hour',
      description: 'An excellent fort for beginners with wide pathways and the famous Vinchu Kata.',
    ),
  ];
}
