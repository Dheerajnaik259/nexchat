import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:mime/mime.dart';
import 'package:uuid/uuid.dart';

/// File utility functions
class FileUtils {
  FileUtils._();

  static const _uuid = Uuid();

  /// Get MIME type from file path
  static String? getMimeType(String filePath) {
    return lookupMimeType(filePath);
  }

  /// Check if file is an image
  static bool isImage(String filePath) {
    final mime = getMimeType(filePath);
    return mime?.startsWith('image/') ?? false;
  }

  /// Check if file is a video
  static bool isVideo(String filePath) {
    final mime = getMimeType(filePath);
    return mime?.startsWith('video/') ?? false;
  }

  /// Check if file is audio
  static bool isAudio(String filePath) {
    final mime = getMimeType(filePath);
    return mime?.startsWith('audio/') ?? false;
  }

  /// Generate unique filename preserving extension
  static String generateUniqueFilename(String originalPath) {
    final ext = p.extension(originalPath);
    return '${_uuid.v4()}$ext';
  }

  /// Get human-readable file size
  static String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  /// Get file size in MB
  static double fileSizeInMB(File file) {
    return file.lengthSync() / (1024 * 1024);
  }
}
