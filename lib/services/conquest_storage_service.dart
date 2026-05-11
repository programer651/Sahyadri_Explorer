import 'package:shared_preferences/shared_preferences.dart';

class ConquestStats {
  final int totalDistanceKm;
  final int totalTreks;
  final List<String> conqueredFortIds;

  ConquestStats({
    required this.totalDistanceKm,
    required this.totalTreks,
    required this.conqueredFortIds,
  });
}

class ConquestStorageService {
  static const String _keyTotalDistance = 'total_distance';
  static const String _keyTotalTreks = 'total_treks';
  static const String _keyConqueredForts = 'conquered_forts';

  Future<ConquestStats> getStats() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Default mock data initially if empty, but we will return 0 for now.
    // Actually, to make the UI look good initially if they haven't conquered anything,
    // we could leave it at 0.
    final totalDistance = prefs.getInt(_keyTotalDistance) ?? 0;
    final totalTreks = prefs.getInt(_keyTotalTreks) ?? 0;
    final conqueredForts = prefs.getStringList(_keyConqueredForts) ?? [];

    return ConquestStats(
      totalDistanceKm: totalDistance,
      totalTreks: totalTreks,
      conqueredFortIds: conqueredForts,
    );
  }

  Future<void> saveTrek(double distanceWalkedKm, bool isConquered, String fortId) async {
    final prefs = await SharedPreferences.getInstance();
    
    // Update Distance
    final currentDist = prefs.getInt(_keyTotalDistance) ?? 0;
    await prefs.setInt(_keyTotalDistance, currentDist + distanceWalkedKm.round());
    
    // Update Treks Count
    final currentTreks = prefs.getInt(_keyTotalTreks) ?? 0;
    await prefs.setInt(_keyTotalTreks, currentTreks + 1);

    // Update Conquered Forts
    if (isConquered) {
      final conquered = prefs.getStringList(_keyConqueredForts) ?? [];
      if (!conquered.contains(fortId)) {
        conquered.add(fortId);
        await prefs.setStringList(_keyConqueredForts, conquered);
      }
    }
  }
}
