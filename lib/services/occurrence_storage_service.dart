import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';

import '../models/pothole_occurrence.dart';

class OccurrenceStorageService {
  static const _folderName = 'potholes';
  static const _indexFileName = 'occurrences.json';

  Future<PotholeOccurrence> save({
    required PotholeOccurrence occurrence,
    required Uint8List imageBytes,
  }) async {
    final root = await _rootDirectory();
    final images = Directory('${root.path}/images');
    await images.create(recursive: true);

    final image = File('${images.path}/${occurrence.id}.jpg');
    await image.writeAsBytes(imageBytes, flush: true);

    final saved = PotholeOccurrence(
      id: occurrence.id,
      latitude: occurrence.latitude,
      longitude: occurrence.longitude,
      detectedAt: occurrence.detectedAt,
      confidence: occurrence.confidence,
      className: occurrence.className,
      imagePath: image.path,
    );

    try {
      final occurrences = await loadAll()..add(saved);
      await _writeIndex(root, occurrences);
      return saved;
    } catch (_) {
      if (await image.exists()) await image.delete();
      rethrow;
    }
  }

  Future<List<PotholeOccurrence>> loadAll() async {
    final root = await _rootDirectory();
    final index = File('${root.path}/$_indexFileName');
    if (!await index.exists()) return <PotholeOccurrence>[];

    final content = await index.readAsString();
    if (content.trim().isEmpty) return <PotholeOccurrence>[];

    final items = jsonDecode(content) as List<dynamic>;
    return items
        .map(
          (item) => PotholeOccurrence.fromJson(
            item as Map<String, dynamic>,
          ),
        )
        .toList();
  }

  Future<Directory> _rootDirectory() async {
    final documents = await getApplicationDocumentsDirectory();
    final root = Directory('${documents.path}/$_folderName');
    await root.create(recursive: true);
    return root;
  }

  Future<void> _writeIndex(
    Directory root,
    List<PotholeOccurrence> occurrences,
  ) async {
    final index = File('${root.path}/$_indexFileName');
    const encoder = JsonEncoder.withIndent('  ');
    await index.writeAsString(
      encoder.convert(occurrences.map((item) => item.toJson()).toList()),
      flush: true,
    );
  }
}
