import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

/// Service for picking and compressing media files
class MediaPickerService {
  MediaPickerService._();
  static final MediaPickerService instance = MediaPickerService._();

  final ImagePicker _picker = ImagePicker();
  static const _uuid = Uuid();

  /// Picks an image from the specified source and compresses it
  Future<File?> pickImage(ImageSource source) async {
    final XFile? xfile = await _picker.pickImage(source: source);
    if (xfile == null) return null;

    return await _compressImage(File(xfile.path));
  }

  /// Picks a video from the specified source
  Future<File?> pickVideo(ImageSource source) async {
    final XFile? xfile = await _picker.pickVideo(source: source);
    if (xfile == null) return null;

    return File(xfile.path);
  }

  /// Compresses the image and returns the new file
  Future<File?> _compressImage(File file) async {
    final ext = p.extension(file.path).toLowerCase();
    
    // Only compress standard image types
    if (ext != '.jpg' && ext != '.jpeg' && ext != '.png') {
      return file;
    }

    final targetPath = '${file.parent.path}/${_uuid.v4()}_compressed.jpg';

    // Compress using flutter_image_compress
    final result = await FlutterImageCompress.compressAndGetFile(
      file.absolute.path,
      targetPath,
      quality: 75,
      minWidth: 1280,
      minHeight: 720,
      format: CompressFormat.jpeg,
    );

    if (result != null) {
      return File(result.path);
    }
    return file; // Return original if compression fails
  }
}
