import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class PickedImageData {
  final Uint8List bytes;
  final String name;
  final String mimeType;

  PickedImageData({
    required this.bytes,
    required this.name,
    required this.mimeType,
  });
}

class StorageService {
  /// Opens the native file/folder explorer or gallery dialog on Android, iOS, Web, and Desktop.
  static Future<PickedImageData?> pickImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        final bytes = await image.readAsBytes();
        return PickedImageData(
          bytes: bytes,
          name: image.name,
          mimeType: image.mimeType ?? 'image/jpeg',
        );
      }
    } catch (e) {
      debugPrint('Error in ImagePicker: $e');
    }
    return null;
  }

  /// Uploads [PickedImageData] to Firebase Storage or returns Base64 Data URL as reliable fallback.
  static Future<String?> uploadImage({
    required PickedImageData file,
    required String folderPath,
    required String filename,
  }) async {
    try {
      final Uint8List bytes = file.bytes;
      final String mimeType = file.mimeType;

      // 1. Try Firebase Storage upload
      try {
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('$folderPath/$filename');

        final metadata = SettableMetadata(
          contentType: mimeType,
          customMetadata: {'picked-file-name': file.name},
        );

        final uploadTask = await storageRef.putData(bytes, metadata);
        final downloadUrl = await uploadTask.ref.getDownloadURL();
        return downloadUrl;
      } catch (storageError) {
        debugPrint('Firebase Storage error ($storageError). Falling back to Base64 data URL.');
        // Reliable fallback: inline base64 data URI
        final base64String = base64Encode(bytes);
        return 'data:$mimeType;base64,$base64String';
      }
    } catch (e) {
      debugPrint('Error uploading image: $e');
      return null;
    }
  }
}
