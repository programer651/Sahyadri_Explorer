import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/walking_activity_model.dart';

class WalkingStorageService {
  final FirebaseAuth _auth;

  WalkingStorageService({FirebaseAuth? auth})
      : _auth = auth ?? FirebaseAuth.instance;

  String get _userId {
    final uid = _auth.currentUser?.uid;
    if (uid != null && uid.isNotEmpty) {
      return uid;
    }
    return 'guest';
  }

  String get _keyWalkingHistory => 'walking_activities_history_v1_$_userId';
  String get _keyWalkingTotalDist => 'walking_total_distance_km_v1_$_userId';
  String get _keyWalkingTotalCount => 'walking_total_walks_count_v1_$_userId';

  Future<void> saveActivity(WalkingActivity activity) async {
    final prefs = await SharedPreferences.getInstance();

    final currentDist = prefs.getDouble(_keyWalkingTotalDist) ?? 0.0;
    await prefs.setDouble(_keyWalkingTotalDist, currentDist + activity.distanceKm);

    final currentCount = prefs.getInt(_keyWalkingTotalCount) ?? 0;
    await prefs.setInt(_keyWalkingTotalCount, currentCount + 1);

    final historyJson = prefs.getStringList(_keyWalkingHistory) ?? [];
    historyJson.add(jsonEncode(activity.toJson()));
    await prefs.setStringList(_keyWalkingHistory, historyJson);
  }

  Future<List<WalkingActivity>> getActivities() async {
    final prefs = await SharedPreferences.getInstance();
    final historyJson = prefs.getStringList(_keyWalkingHistory) ?? [];
    final list = historyJson
        .map((str) => WalkingActivity.fromJson(jsonDecode(str)))
        .toList();
    list.sort((a, b) => b.startTime.compareTo(a.startTime));
    return list;
  }

  Future<double> getTotalDistance() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_keyWalkingTotalDist) ?? 0.0;
  }

  Future<int> getTotalWalks() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyWalkingTotalCount) ?? 0;
  }
}
