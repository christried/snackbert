import 'dart:io';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';

import 'package:snackbert/models/meal.dart';

class MealAnalysisService {
  MealAnalysisService({FirebaseFunctions? functions, FirebaseStorage? storage})
    : _functions = functions ?? FirebaseFunctions.instance,
      _storage = storage ?? FirebaseStorage.instance;

  final FirebaseFunctions _functions;
  final FirebaseStorage _storage;

  Future<MealAnalysisResult> analyzeMeal({
    String? text,
    File? image,
    File? audio,
  }) async {
    final trimmedText = text?.trim();
    final hasText = trimmedText != null && trimmedText.isNotEmpty;

    if (!hasText && image == null && audio == null) {
      throw ArgumentError(
        'Irgendein Input muss schon da sein - Bild, Text oder Audio.',
      );
    }

    final uploadId = Uuid().v4();
    String? imageUrl;
    String? audioUrl;

    if (image != null) {
      final extension = _extensionFromPath(image.path, fallback: 'jpg');
      imageUrl = await _uploadFile(
        image,
        destinationPath: 'meal-uploads/$uploadId/image.$extension',
        contentType: _contentTypeFor('image', extension),
      );
    }

    if (audio != null) {
      final extension = _extensionFromPath(audio.path, fallback: 'm4a');
      audioUrl = await _uploadFile(
        audio,
        destinationPath: 'meal-uploads/$uploadId/audio.$extension',
        contentType: _contentTypeFor('audio', extension),
      );
    }

    final callable = _functions.httpsCallable('analyzeMeal');
    final response = await callable.call(<String, Object?>{
      'text': hasText ? trimmedText : null,
      'imageUrl': imageUrl,
      'audioUrl': audioUrl,
    });

    final data = response.data;
    if (data is! Map) {
      throw StateError('Unerwartete Antwort vom Backend.');
    }

    return MealAnalysisResult.fromMap(Map<String, dynamic>.from(data));
  }

  Future<String> _uploadFile(
    File file, {
    required String destinationPath,
    String? contentType,
  }) async {
    final ref = _storage.ref().child(destinationPath);
    final metadata = contentType == null
        ? null
        : SettableMetadata(contentType: contentType);
    await ref.putFile(file, metadata);
    return ref.getDownloadURL();
  }

  String _extensionFromPath(String path, {required String fallback}) {
    final dot = path.lastIndexOf('.');
    if (dot == -1 || dot == path.length - 1) {
      return fallback;
    }
    return path.substring(dot + 1).toLowerCase();
  }

  String? _contentTypeFor(String category, String extension) {
    final normalized = extension.toLowerCase();
    if (category == 'image') {
      return switch (normalized) {
        'png' => 'image/png',
        'jpg' || 'jpeg' => 'image/jpeg',
        'webp' => 'image/webp',
        _ => null,
      };
    }
    if (category == 'audio') {
      return switch (normalized) {
        'm4a' => 'audio/mp4',
        'aac' => 'audio/aac',
        'mp3' => 'audio/mpeg',
        'wav' => 'audio/wav',
        _ => null,
      };
    }
    return null;
  }
}
