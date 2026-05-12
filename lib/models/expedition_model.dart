class Expedition {
  final String fortId;
  final String fortName;
  final double completionPercentage;
  final DateTime date;
  final double distanceKm;
  final bool isConquered;
  final Duration duration;

  Expedition({
    required this.fortId,
    required this.fortName,
    required this.completionPercentage,
    required this.date,
    required this.distanceKm,
    required this.isConquered,
    required this.duration,
  });

  Map<String, dynamic> toJson() {
    return {
      'fortId': fortId,
      'fortName': fortName,
      'completionPercentage': completionPercentage,
      'date': date.toIso8601String(),
      'distanceKm': distanceKm,
      'isConquered': isConquered,
      'durationSeconds': duration.inSeconds,
    };
  }

  factory Expedition.fromJson(Map<String, dynamic> json) {
    return Expedition(
      fortId: json['fortId'] as String,
      fortName: json['fortName'] as String,
      completionPercentage: (json['completionPercentage'] as num).toDouble(),
      date: DateTime.parse(json['date'] as String),
      distanceKm: (json['distanceKm'] as num).toDouble(),
      isConquered: json['isConquered'] as bool,
      duration: Duration(seconds: json['durationSeconds'] as int? ?? 0),
    );
  }
}
