import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

class LocationService {
  Future<String?> getReadableLocation(Position position) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        
        // Build readable string: Locality, City, State
        // Example: Kothrud, Pune, Maharashtra
        final parts = [
          place.subLocality ?? place.locality,
          place.subAdministrativeArea ?? place.administrativeArea,
        ].where((s) => s != null && s.isNotEmpty).toList();

        return parts.join(', ');
      }
    } catch (e) {
      print('Reverse geocoding error: $e');
    }
    return null;
  }
}
