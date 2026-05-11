import '../models/fort_model.dart';

class TrekProgressService {
  /// Calculates the expected trekking distance based on the fort's estimated time.
  /// Standard hiking speed on steep terrain is roughly 2km/h.
  /// E.g. "3 Hours" -> 6 km.
  static double _calculateEstimatedTrekDistance(String estimatedTimeStr) {
    // Basic extraction of hours from a string like "3 Hours" or "2.5 hrs"
    final RegExp regex = RegExp(r'([\d.]+)');
    final match = regex.firstMatch(estimatedTimeStr);
    
    double hours = 2.0; // default fallback
    if (match != null) {
      hours = double.tryParse(match.group(1) ?? '2.0') ?? 2.0;
    }
    
    // Typical Sahyadri trek: 2 km per hour average
    return hours * 2.0; 
  }

  /// Calculates completion percentage [0.0 to 1.0]
  static double calculateCompletionPercentage(double distanceCoveredKm, Fort fort) {
    final expectedDistance = _calculateEstimatedTrekDistance(fort.estimatedTime);
    
    // We add a tiny buffer so they don't have to walk exactly 6.000km to get 100%.
    // If they walked expectedDistance, they are at 100%.
    double progress = distanceCoveredKm / expectedDistance;
    
    if (progress > 1.0) progress = 1.0;
    if (progress < 0.0) progress = 0.0;
    
    return progress;
  }
}
