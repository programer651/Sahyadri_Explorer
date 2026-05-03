import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/fort_model.dart';

class FortRepository {
  /// Loads the list of forts from the local JSON asset.
  /// 
  /// In the future, this method can be easily modified to fetch data
  /// from a REST API or Firebase Firestore without breaking the UI.
  static Future<List<Fort>> loadForts() async {
    try {
      // Load the JSON string from assets
      final String jsonString = await rootBundle.loadString('assets/data/forts.json');
      
      // Decode the JSON string into a List of Maps
      final List<dynamic> jsonList = jsonDecode(jsonString);
      
      // Map the decoded JSON list to a List of Fort objects
      return jsonList.map((json) => Fort.fromJson(json as Map<String, dynamic>)).toList();
    } catch (e) {
      // Fallback or error handling
      print('Error loading forts: $e');
      return [];
    }
  }
}
