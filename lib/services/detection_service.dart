import 'package:ultralytics_yolo/ultralytics_yolo.dart';

import '../config/app_config.dart';

class AcceptedDetection {
  const AcceptedDetection({
    required this.className,
    required this.confidence,
  });

  final String className;
  final double confidence;
}

class DetectionService {
  DetectionService({
    this.confidenceThreshold = AppConfig.confidenceThreshold,
    this.cooldown = AppConfig.detectionCooldown,
    Set<String> acceptedClassNames = AppConfig.potholeClassNames,
  }) : _acceptedClassNames = acceptedClassNames
           .map((name) => name.trim().toLowerCase())
           .toSet();

  final double confidenceThreshold;
  final Duration cooldown;
  final Set<String> _acceptedClassNames;

  DateTime? _lastAcceptedAt;

  AcceptedDetection? tryAccept(List<YOLOResult> results, DateTime now) {
    final lastAcceptedAt = _lastAcceptedAt;
    if (lastAcceptedAt != null && now.difference(lastAcceptedAt) < cooldown) {
      return null;
    }

    YOLOResult? best;
    for (final result in results) {
      final normalizedClass = result.className.trim().toLowerCase();
      final isPothole = _acceptedClassNames.contains(normalizedClass);
      final isConfident = result.confidence >= confidenceThreshold;
      if (isPothole && isConfident) {
        if (best == null || result.confidence > best.confidence) {
          best = result;
        }
      }
    }

    if (best == null) return null;

    // Reserva o cooldown antes das operações assíncronas de foto e GPS.
    _lastAcceptedAt = now;
    return AcceptedDetection(
      className: best.className,
      confidence: best.confidence,
    );
  }

  void reset() => _lastAcceptedAt = null;
}
