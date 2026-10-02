class PotholeOccurrence {
  const PotholeOccurrence({
    required this.id,
    required this.latitude,
    required this.longitude,
    required this.detectedAt,
    required this.confidence,
    required this.className,
    required this.imagePath,
  });

  final String id;
  final double latitude;
  final double longitude;
  final DateTime detectedAt;
  final double confidence;
  final String className;
  final String imagePath;

  factory PotholeOccurrence.fromJson(Map<String, dynamic> json) {
    return PotholeOccurrence(
      id: json['id'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      detectedAt: DateTime.parse(json['detectedAt'] as String),
      confidence: (json['confidence'] as num).toDouble(),
      className: json['className'] as String,
      imagePath: json['imagePath'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'latitude': latitude,
    'longitude': longitude,
    'detectedAt': detectedAt.toUtc().toIso8601String(),
    'confidence': confidence,
    'className': className,
    'imagePath': imagePath,
  };
}
