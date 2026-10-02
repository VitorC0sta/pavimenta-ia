import 'dart:async';

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:ultralytics_yolo/ultralytics_yolo.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../config/app_config.dart';
import '../models/pothole_occurrence.dart';
import '../services/detection_service.dart';
import '../services/location_service.dart';
import '../services/occurrence_storage_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with WidgetsBindingObserver {
  final _yoloController = YOLOViewController();
  final _detectionService = DetectionService();
  final _locationService = LocationService();
  final _storageService = OccurrenceStorageService();

  bool _isRunning = false;
  bool _isStarting = false;
  bool _isSavingDetection = false;
  bool _modelLoaded = false;
  int _sessionCount = 0;
  double _fps = 0;
  String _status = 'Pronto para iniciar';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_isRunning && state != AppLifecycleState.resumed) {
      unawaited(_stopSession(status: 'Captura pausada em segundo plano'));
    }
  }

  Future<void> _startSession() async {
    if (_isStarting || _isRunning) return;
    setState(() {
      _isStarting = true;
      _status = 'Verificando permissões...';
    });

    try {
      final cameraStatus = await Permission.camera.request();
      if (!cameraStatus.isGranted) {
        final message = cameraStatus.isPermanentlyDenied
            ? 'Libere a câmera nas configurações do Android.'
            : 'A permissão de câmera é obrigatória.';
        throw StateError(message);
      }

      await _locationService.startTracking();
      await WakelockPlus.enable();
      _detectionService.reset();

      if (!mounted) return;
      setState(() {
        _isRunning = true;
        _isStarting = false;
        _modelLoaded = false;
        _sessionCount = 0;
        _fps = 0;
        _status = 'Carregando modelo...';
      });
    } catch (error) {
      await _locationService.stopTracking();
      await WakelockPlus.disable();
      if (!mounted) return;
      setState(() {
        _isStarting = false;
        _status = _friendlyError(error);
      });
    }
  }

  Future<void> _stopSession({String status = 'Captura encerrada'}) async {
    if (!_isRunning && !_isStarting) return;

    if (mounted) {
      setState(() {
        _isRunning = false;
        _isStarting = false;
        _modelLoaded = false;
        _fps = 0;
        _status = status;
      });
    }

    await _locationService.stopTracking();
    await WakelockPlus.disable();
  }

  Future<void> _handleResults(List<YOLOResult> results) async {
    if (!_isRunning || _isSavingDetection) return;

    final now = DateTime.now();
    final accepted = _detectionService.tryAccept(results, now);
    if (accepted == null) return;

    _isSavingDetection = true;
    try {
      final imageBytes = await _yoloController.captureFrame();
      if (imageBytes == null) {
        throw StateError('Não foi possível capturar o frame detectado.');
      }

      final position = await _locationService.positionForOccurrence();
      final id = now.toUtc().microsecondsSinceEpoch.toString();
      final occurrence = PotholeOccurrence(
        id: id,
        latitude: position.latitude,
        longitude: position.longitude,
        detectedAt: now.toUtc(),
        confidence: accepted.confidence,
        className: accepted.className,
        imagePath: '',
      );
      await _storageService.save(
        occurrence: occurrence,
        imageBytes: imageBytes,
      );

      if (!mounted) return;
      setState(() {
        _sessionCount++;
        _status =
            'Buraco salvo (${(accepted.confidence * 100).toStringAsFixed(0)}%)';
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _status = 'Falha ao salvar: ${_friendlyError(error)}');
    } finally {
      _isSavingDetection = false;
    }
  }

  void _handleModelLoaded(String modelPath, YOLOTask? task) {
    if (!mounted) return;
    setState(() {
      _modelLoaded = true;
      _status = 'Detectando buracos';
    });
  }

  void _handleModelError(Object error, String modelPath, YOLOTask? task) {
    if (!mounted) return;
    setState(() {
      _modelLoaded = false;
      _status = 'Erro no modelo: ${_friendlyError(error)}';
    });
  }

  String _friendlyError(Object error) {
    if (error is LocationServiceException) return error.message;
    if (error is StateError) return error.message;
    return error.toString().replaceFirst('Exception: ', '');
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_locationService.dispose());
    unawaited(WakelockPlus.disable());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pavimenta IA'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ColoredBox(
                    color: Colors.black,
                    child: _isRunning
                        ? YOLOView(
                            modelPath: AppConfig.modelAssetPath,
                            task: YOLOTask.detect,
                            controller: _yoloController,
                            cameraResolution: '720p',
                            lensFacing: LensFacing.back,
                            useGpu: true,
                            confidenceThreshold:
                                AppConfig.confidenceThreshold,
                            streamingConfig:
                                YOLOStreamingConfig.powerSaving(
                                  inferenceFrequency:
                                      AppConfig.targetInferenceFps,
                                  maxFPS: AppConfig.targetInferenceFps,
                                ),
                            onResult: _handleResults,
                            onModelLoad: _handleModelLoaded,
                            onModelError: _handleModelError,
                            onPerformanceMetrics: (metrics) {
                              if (!mounted) return;
                              setState(() => _fps = metrics.fps);
                            },
                          )
                        : const _CameraPlaceholder(),
                  ),
                  Positioned(
                    top: 12,
                    left: 12,
                    right: 12,
                    child: _StatusPill(
                      status: _status,
                      isRunning: _isRunning,
                      modelLoaded: _modelLoaded,
                    ),
                  ),
                ],
              ),
            ),
            _ControlPanel(
              sessionCount: _sessionCount,
              fps: _fps,
              isRunning: _isRunning,
              isStarting: _isStarting,
              onPressed: _isRunning ? _stopSession : _startSession,
            ),
          ],
        ),
      ),
    );
  }
}

class _CameraPlaceholder extends StatelessWidget {
  const _CameraPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.videocam_off_outlined, size: 72, color: Colors.white54),
          SizedBox(height: 12),
          Text('Câmera parada', style: TextStyle(color: Colors.white70)),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({
    required this.status,
    required this.isRunning,
    required this.modelLoaded,
  });

  final String status;
  final bool isRunning;
  final bool modelLoaded;

  @override
  Widget build(BuildContext context) {
    final color = modelLoaded
        ? Colors.green
        : isRunning
        ? Colors.orange
        : Colors.blueGrey;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            Icon(Icons.circle, size: 12, color: color),
            const SizedBox(width: 8),
            Expanded(
              child: Text(status, maxLines: 2, overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
      ),
    );
  }
}

class _ControlPanel extends StatelessWidget {
  const _ControlPanel({
    required this.sessionCount,
    required this.fps,
    required this.isRunning,
    required this.isStarting,
    required this.onPressed,
  });

  final int sessionCount;
  final double fps;
  final bool isRunning;
  final bool isStarting;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _Metric(
                  label: 'Buracos na sessão',
                  value: sessionCount.toString(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _Metric(
                  label: 'Inferência',
                  value: '${fps.toStringAsFixed(1)} FPS',
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: FilledButton.icon(
              onPressed: isStarting ? null : onPressed,
              style: FilledButton.styleFrom(
                backgroundColor: isRunning ? Colors.red : Colors.green,
                foregroundColor: Colors.white,
              ),
              icon: isStarting
                  ? const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(isRunning ? Icons.stop : Icons.play_arrow),
              label: Text(
                isStarting ? 'Preparando...' : (isRunning ? 'Parar' : 'Iniciar'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Text(label, textAlign: TextAlign.center),
            const SizedBox(height: 4),
            Text(
              value,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
