import 'dart:async';

import 'package:geolocator/geolocator.dart';

import '../config/app_config.dart';

class LocationService {
  StreamSubscription<Position>? _subscription;
  Position? _lastPosition;

  Position? get lastPosition => _lastPosition;

  Future<void> ensureReady() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw const LocationServiceException(
        'Ative a localização/GPS antes de iniciar.',
      );
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      throw const LocationServiceException(
        'A permissão de localização foi negada.',
      );
    }
    if (permission == LocationPermission.deniedForever) {
      throw const LocationServiceException(
        'Libere a localização nas configurações do Android.',
      );
    }
  }

  Future<void> startTracking() async {
    await ensureReady();
    if (_subscription != null) return;

    const settings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 0,
    );
    _subscription = Geolocator.getPositionStream(
      locationSettings: settings,
    ).listen((position) => _lastPosition = position);
  }

  Future<Position> positionForOccurrence() async {
    final cached = _lastPosition;
    if (cached != null &&
        DateTime.now().difference(cached.timestamp) <=
            AppConfig.maxCachedLocationAge) {
      return cached;
    }

    try {
      final current = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
        timeLimit: const Duration(seconds: 5),
      );
      _lastPosition = current;
      return current;
    } on TimeoutException {
      if (cached != null) return cached;
      throw const LocationServiceException(
        'GPS ainda sem posição. Aguarde alguns segundos e tente novamente.',
      );
    }
  }

  Future<void> stopTracking() async {
    await _subscription?.cancel();
    _subscription = null;
  }

  Future<void> dispose() => stopTracking();
}

class LocationServiceException implements Exception {
  const LocationServiceException(this.message);

  final String message;

  @override
  String toString() => message;
}
