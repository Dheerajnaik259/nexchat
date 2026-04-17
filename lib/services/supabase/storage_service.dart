import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';
import '../../supabase_config.dart';

/// Storage service powered by Supabase Storage
///
/// Handles upload/download for:
/// - Profile avatars
/// - Chat media (images, videos, documents, audio)
/// - Status media
class StorageService {
  StorageService._();
  static final StorageService instance = StorageService._();

  SupabaseClient get _client => Supabase.instance.client;
  String? get _userId => _client.auth.currentUser?.id;
  static const _uuid = Uuid();

  // ─── AVATAR UPLOAD ─────────────────────────────────────────

  /// Upload a profile avatar and return its public URL
  Future<String> uploadAvatar(File file) async {
    if (_userId == null) throw Exception('Not authenticated');

    final ext = p.extension(file.path);
    final path = '$_userId/avatar$ext';

    await _client.storage
        .from(SupabaseConfig.avatarBucket)
        .upload(path, file, fileOptions: const FileOptions(upsert: true));

    final publicUrl = _client.storage
        .from(SupabaseConfig.avatarBucket)
        .getPublicUrl(path);

    debugPrint('[StorageService] Avatar uploaded: $publicUrl');
    return publicUrl;
  }

  // ─── CHAT MEDIA UPLOAD ─────────────────────────────────────

  /// Upload chat media (image, video, audio, document)
  /// Returns the public URL of the uploaded file
  Future<String> uploadChatMedia({
    required File file,
    required String chatId,
    String? customFileName,
  }) async {
    if (_userId == null) throw Exception('Not authenticated');

    final ext = p.extension(file.path);
    final fileName = customFileName ?? '${_uuid.v4()}$ext';
    final path = '$chatId/$_userId/$fileName';

    await _client.storage
        .from(SupabaseConfig.mediaBucket)
        .upload(path, file);

    final publicUrl = _client.storage
        .from(SupabaseConfig.mediaBucket)
        .getPublicUrl(path);

    debugPrint('[StorageService] Media uploaded: $publicUrl');
    return publicUrl;
  }

  /// Upload chat media from bytes (e.g., compressed image)
  Future<String> uploadChatMediaBytes({
    required Uint8List bytes,
    required String chatId,
    required String fileName,
  }) async {
    if (_userId == null) throw Exception('Not authenticated');

    final path = '$chatId/$_userId/$fileName';

    await _client.storage
        .from(SupabaseConfig.mediaBucket)
        .uploadBinary(path, bytes);

    final publicUrl = _client.storage
        .from(SupabaseConfig.mediaBucket)
        .getPublicUrl(path);

    return publicUrl;
  }

  // ─── STATUS MEDIA UPLOAD ───────────────────────────────────

  /// Upload status media (image/video)
  Future<String> uploadStatusMedia(File file) async {
    if (_userId == null) throw Exception('Not authenticated');

    final ext = p.extension(file.path);
    final fileName = '${_uuid.v4()}$ext';
    final path = '$_userId/$fileName';

    await _client.storage
        .from(SupabaseConfig.statusBucket)
        .upload(path, file);

    final publicUrl = _client.storage
        .from(SupabaseConfig.statusBucket)
        .getPublicUrl(path);

    debugPrint('[StorageService] Status media uploaded: $publicUrl');
    return publicUrl;
  }

  // ─── DOWNLOAD / DELETE ─────────────────────────────────────

  /// Download file as bytes
  Future<Uint8List> downloadFile(String bucket, String path) async {
    return await _client.storage.from(bucket).download(path);
  }

  /// Delete a file from storage
  Future<void> deleteFile(String bucket, String path) async {
    await _client.storage.from(bucket).remove([path]);
    debugPrint('[StorageService] Deleted: $bucket/$path');
  }

  /// Delete all status media for the user (cleanup expired)
  Future<void> cleanupExpiredStatusMedia() async {
    if (_userId == null) return;
    try {
      final files = await _client.storage
          .from(SupabaseConfig.statusBucket)
          .list(path: _userId!);

      if (files.isNotEmpty) {
        final paths = files.map((f) => '$_userId/${f.name}').toList();
        await _client.storage.from(SupabaseConfig.statusBucket).remove(paths);
        debugPrint('[StorageService] Cleaned up ${paths.length} expired status files');
      }
    } catch (e) {
      debugPrint('[StorageService] Cleanup error: $e');
    }
  }

  // ─── SIGNED URLs (for private media) ───────────────────────

  /// Get a temporary signed URL for private media
  Future<String> getSignedUrl(String bucket, String path, {int expiresIn = 3600}) async {
    final url = await _client.storage
        .from(bucket)
        .createSignedUrl(path, expiresIn);
    return url;
  }
}
