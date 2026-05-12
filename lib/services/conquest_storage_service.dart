import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/expedition_model.dart';

class ConquestStats {
  final double totalDistanceKm;
  final int totalTreks;
  final List<String> conqueredFortIds;
  final List<Expedition> expeditions;

  ConquestStats({
    required this.totalDistanceKm,
    required this.totalTreks,
    required this.conqueredFortIds,
    required this.expeditions,
  });
}

class ConquestStorageService {
  static const String _keyTotalDistance = 'total_distance_v2'; // Bumped for double support
  static const String _keyTotalTreks = 'total_treks';
  static const String _keyConqueredForts = 'conquered_forts';
  static const String _keyExpeditions = 'expeditions_history';

  Future<ConquestStats> getStats() async {
    final prefs = await SharedPreferences.getInstance();
    
    final totalDistance = prefs.getDouble(_keyTotalDistance) ?? 0.0;
    final totalTreks = prefs.getInt(_keyTotalTreks) ?? 0;
    final conqueredForts = prefs.getStringList(_keyConqueredForts) ?? [];
    
    final expeditionsJson = prefs.getStringList(_keyExpeditions) ?? [];
    final expeditions = expeditionsJson.map((e) => Expedition.fromJson(jsonDecode(e))).toList();
    
    // Sort expeditions by date descending (most recent first)
    expeditions.sort((a, b) => b.date.compareTo(a.date));

    return ConquestStats(
      totalDistanceKm: totalDistance,
      totalTreks: totalTreks,
      conqueredFortIds: conqueredForts,
      expeditions: expeditions,
    );
  }

  Future<void> saveTrek(double distanceWalkedKm, bool isConquered, String fortId, String fortName, double completionPercentage, Duration duration) async {
    final prefs = await SharedPreferences.getInstance();
    
    // Update Distance
    final currentDist = prefs.getDouble(_keyTotalDistance) ?? 0.0;
    await prefs.setDouble(_keyTotalDistance, currentDist + distanceWalkedKm);
    
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

    // Save to Expedition History
    final expedition = Expedition(
      fortId: fortId,
      fortName: fortName,
      completionPercentage: completionPercentage,
      date: DateTime.now(),
      distanceKm: distanceWalkedKm,
      isConquered: isConquered,
      duration: duration,
    );

    final expeditions = prefs.getStringList(_keyExpeditions) ?? [];
    expeditions.add(jsonEncode(expedition.toJson()));
    await prefs.setStringList(_keyExpeditions, expeditions);
  }
}
