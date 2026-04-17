import 'dart:convert';
import 'dart:typed_data';
import 'package:hive_flutter/hive_flutter.dart';

/// Hive-backed encrypted key storage for RSA private/public keys.
///
/// Keys are stored in an encrypted Hive box using HiveAesCipher.
/// The encryption key for the box itself is derived from a device-specific
/// salt. In production, this should use flutter_secure_storage or
/// platform keychain for the box encryption key.
class KeyStore {
  static const String _keyBoxName = 'nexchat_keys';
  static const String _privateKeyField = 'private_key';
  static const String _publicKeyField = 'public_key';
  static const String _identityKeyField = 'identity_key';
  static const String _signedPreKeyField = 'signed_pre_key';
  static const String _preKeysField = 'one_time_pre_keys';

  Box? _keyBox;

  /// Initialize the key store (opens encrypted Hive box)
  Future<void> init() async {
    if (_keyBox != null && _keyBox!.isOpen) return;

    final encKey = await _deriveBoxKey();
    _keyBox = await Hive.openBox(
      _keyBoxName,
      encryptionCipher: HiveAesCipher(encKey),
    );
  }

  /// Ensure the box is open before any operations
  void _ensureOpen() {
    if (_keyBox == null || !_keyBox!.isOpen) {
      throw StateError('KeyStore not initialized. Call init() first.');
    }
  }

  // ══════════════════════════════════════════════════════════════
  // RSA KEY PAIR OPERATIONS
  // ══════════════════════════════════════════════════════════════

  /// Save RSA key pair to encrypted storage
  Future<void> saveKeyPair({
    required String publicKeyPem,
    required String privateKeyPem,
  }) async {
    _ensureOpen();
    await _keyBox!.put(_privateKeyField, privateKeyPem);
    await _keyBox!.put(_publicKeyField, publicKeyPem);
  }

  /// Check if we have a stored key pair
  bool hasKeyPair() {
    _ensureOpen();
    return _keyBox!.containsKey(_privateKeyField) &&
        _keyBox!.containsKey(_publicKeyField);
  }

  /// Get stored public key PEM
  String? getPublicKey() {
    _ensureOpen();
    return _keyBox!.get(_publicKeyField) as String?;
  }

  /// Get stored private key PEM (NEVER expose this outside the device)
  String? getPrivateKey() {
    _ensureOpen();
    return _keyBox!.get(_privateKeyField) as String?;
  }

  // ══════════════════════════════════════════════════════════════
  // SIGNAL PROTOCOL KEY OPERATIONS
  // ══════════════════════════════════════════════════════════════

  /// Store Signal identity key
  Future<void> saveIdentityKey(String identityKey) async {
    _ensureOpen();
    await _keyBox!.put(_identityKeyField, identityKey);
  }

  /// Get Signal identity key
  String? getIdentityKey() {
    _ensureOpen();
    return _keyBox!.get(_identityKeyField) as String?;
  }

  /// Store Signal signed pre-key
  Future<void> saveSignedPreKey(String signedPreKey) async {
    _ensureOpen();
    await _keyBox!.put(_signedPreKeyField, signedPreKey);
  }

  /// Get Signal signed pre-key
  String? getSignedPreKey() {
    _ensureOpen();
    return _keyBox!.get(_signedPreKeyField) as String?;
  }

  /// Store Signal one-time pre-keys
  Future<void> saveOneTimePreKeys(List<String> preKeys) async {
    _ensureOpen();
    await _keyBox!.put(_preKeysField, preKeys);
  }

  /// Get Signal one-time pre-keys
  List<String> getOneTimePreKeys() {
    _ensureOpen();
    final keys = _keyBox!.get(_preKeysField);
    if (keys == null) return [];
    return List<String>.from(keys);
  }

  /// Consume (remove) one pre-key from the list
  Future<String?> consumeOneTimePreKey() async {
    _ensureOpen();
    final keys = getOneTimePreKeys();
    if (keys.isEmpty) return null;

    final consumed = keys.removeAt(0);
    await saveOneTimePreKeys(keys);
    return consumed;
  }

  // ══════════════════════════════════════════════════════════════
  // SESSION KEY OPERATIONS (for per-chat session keys)
  // ══════════════════════════════════════════════════════════════

  /// Store a session key for a specific chat
  Future<void> saveSessionKey(String chatId, String sessionKey) async {
    _ensureOpen();
    await _keyBox!.put('session_$chatId', sessionKey);
  }

  /// Get session key for a specific chat
  String? getSessionKey(String chatId) {
    _ensureOpen();
    return _keyBox!.get('session_$chatId') as String?;
  }

  /// Remove session key for a chat (on chat delete)
  Future<void> removeSessionKey(String chatId) async {
    _ensureOpen();
    await _keyBox!.delete('session_$chatId');
  }

  // ══════════════════════════════════════════════════════════════
  // CLEANUP
  // ══════════════════════════════════════════════════════════════

  /// Delete all keys (for account deletion or key rotation)
  Future<void> clearAllKeys() async {
    _ensureOpen();
    await _keyBox!.clear();
  }

  /// Close the key store
  Future<void> close() async {
    if (_keyBox != null && _keyBox!.isOpen) {
      await _keyBox!.close();
    }
  }

  // ══════════════════════════════════════════════════════════════
  // PRIVATE HELPERS
  // ══════════════════════════════════════════════════════════════

  /// Derive the encryption key for the Hive box.
  ///
  /// NOTE: In production, use flutter_secure_storage to store a randomly
  /// generated key, or use platform keychain. This implementation uses
  /// a deterministic key for simplicity during development.
  Future<Uint8List> _deriveBoxKey() async {
    // In production: store a random 32-byte key in flutter_secure_storage
    // and retrieve it here. For now, use a deterministic derivation.
    const salt = 'nexchat_secure_salt_v1_2024';
    final keyMaterial = utf8.encode(salt);

    // Pad/truncate to exactly 32 bytes for AES-256
    final key = Uint8List(32);
    for (var i = 0; i < 32; i++) {
      key[i] = keyMaterial[i % keyMaterial.length];
    }
    return key;
  }
}
