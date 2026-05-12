import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../models/fort_model.dart';
import '../repositories/fort_repository.dart';
import 'location_service.dart';

class UserProfileService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final LocationService _locationService = LocationService();

  User? get currentUser => _auth.currentUser;

  Future<String?> getReadableLocation(Position position) async {
    return await _locationService.getReadableLocation(position);
  }

  Future<Position?> getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return null;

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return null;
    }

    if (permission == LocationPermission.deniedForever) return null;

    return await Geolocator.getCurrentPosition();
  }

  Future<List<Fort>> getNearbyFortSuggestions(LatLng userLocation) async {
    final allForts = await FortRepository.loadForts();
    
    // Sort by distance
    const distance = Distance();
    allForts.sort((a, b) {
      final distA = distance.as(LengthUnit.Meter, userLocation, a.location);
      final distB = distance.as(LengthUnit.Meter, userLocation, b.location);
      return distA.compareTo(distB);
    });

    // Return top 3
    return allForts.take(3).toList();
  }
}
