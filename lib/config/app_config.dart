abstract final class AppConfig {
  static const modelAssetPath = 'assets/models/nome_do_modelo.tflite';
  static const confidenceThreshold = 0.5;
  static const targetInferenceFps = 5;
  static const detectionCooldown = Duration(seconds: 3);
  static const maxCachedLocationAge = Duration(seconds: 10);

  // Ajuste conforme os nomes de classes gravados nos metadados do modelo.
  static const potholeClassNames = {'buraco', 'pothole'};
}
