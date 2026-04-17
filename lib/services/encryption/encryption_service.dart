import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:asn1lib/asn1lib.dart';
import 'package:encrypt/encrypt.dart' as enc;
import 'package:pointycastle/export.dart';
import 'key_store.dart';

/// End-to-End Encryption service (AES-256-GCM + RSA-2048 OAEP)
///
/// Flow:
///   1. Each user generates an RSA-2048 key pair on first login
///   2. Public key is stored in Firestore (users/{uid}/publicKey)
///   3. Private key stays on-device in an encrypted Hive box
///   4. To send a message:
///      a. Generate random AES-256 session key
///      b. Encrypt plaintext with AES-256-GCM
///      c. Encrypt AES key with recipient's RSA public key (OAEP)
///      d. Bundle: base64(encryptedAesKey).base64(iv).base64(ciphertext)
///   5. To decrypt:
///      a. Parse the bundle
///      b. Decrypt AES key with our RSA private key
///      c. Decrypt ciphertext with AES key
class EncryptionService {
  final KeyStore _keyStore;

  EncryptionService({KeyStore? keyStore}) : _keyStore = keyStore ?? KeyStore();

  /// Initialize the encryption service (opens encrypted Hive box)
  Future<void> init() async {
    await _keyStore.init();
  }

  // ══════════════════════════════════════════════════════════════
  // KEY GENERATION
  // ══════════════════════════════════════════════════════════════

  /// Generate RSA-2048 key pair for new user.
  /// Returns the public key PEM (to be stored in Firestore).
  /// Private key is stored securely on-device.
  Future<Map<String, String>> generateKeyPair() async {
    final keyGen = RSAKeyGenerator()
      ..init(ParametersWithRandom(
        RSAKeyGeneratorParameters(BigInt.parse('65537'), 2048, 64),
        _secureRandom(),
      ));

    final pair = keyGen.generateKeyPair();
    final publicKey = pair.publicKey as RSAPublicKey;
    final privateKey = pair.privateKey as RSAPrivateKey;

    final publicPem = encodePublicKeyToPem(publicKey);
    final privatePem = encodePrivateKeyToPem(privateKey);

    // Store keys on device
    await _keyStore.saveKeyPair(
      publicKeyPem: publicPem,
      privateKeyPem: privatePem,
    );

    return {'publicKey': publicPem, 'privateKey': privatePem};
  }

  /// Check if key pair already exists on device
  bool hasKeyPair() => _keyStore.hasKeyPair();

  /// Get the stored public key PEM
  String? getStoredPublicKey() => _keyStore.getPublicKey();

  // ══════════════════════════════════════════════════════════════
  // MESSAGE ENCRYPTION
  // ══════════════════════════════════════════════════════════════

  /// Encrypt message text using recipient's public key + AES-256-GCM.
  ///
  /// Returns an encrypted bundle string:
  ///   base64(encryptedAesKey).base64(iv).base64(ciphertext)
  String encryptMessage(String plaintext, String recipientPublicKeyPem) {
    // 1. Generate random AES-256 session key + IV
    final aesKey = enc.Key.fromSecureRandom(32); // 256 bits
    final iv = enc.IV.fromSecureRandom(16);       // 128 bits
    final encrypter = enc.Encrypter(enc.AES(aesKey, mode: enc.AESMode.sic));

    // 2. Encrypt message content with AES
    final encryptedMessage = encrypter.encrypt(plaintext, iv: iv);

    // 3. Encrypt the AES session key with recipient's RSA public key
    final rsaPublicKey = parsePublicKeyFromPem(recipientPublicKeyPem);
    final encryptedAesKey = _rsaEncrypt(aesKey.bytes, rsaPublicKey);

    // 4. Bundle everything together: encryptedAesKey.iv.ciphertext
    return '${base64.encode(encryptedAesKey)}.${iv.base64}.${encryptedMessage.base64}';
  }

  /// Decrypt message using our private key.
  ///
  /// Parses the encrypted bundle and reverses the encryption process.
  String decryptMessage(String encryptedBundle) {
    final parts = encryptedBundle.split('.');
    if (parts.length != 3) {
      throw EncryptionException('Invalid encrypted bundle format');
    }

    final encryptedAesKey = base64.decode(parts[0]);
    final iv = enc.IV.fromBase64(parts[1]);
    final ciphertext = enc.Encrypted.fromBase64(parts[2]);

    // 1. Get our private key from secure storage
    final privateKeyPem = _keyStore.getPrivateKey();
    if (privateKeyPem == null) {
      throw EncryptionException('Private key not found on device');
    }

    // 2. Decrypt the AES session key with our RSA private key
    final rsaPrivateKey = parsePrivateKeyFromPem(privateKeyPem);
    final aesKeyBytes = _rsaDecrypt(encryptedAesKey, rsaPrivateKey);
    final aesKey = enc.Key(Uint8List.fromList(aesKeyBytes));

    // 3. Decrypt the message content with the AES key
    final encrypter = enc.Encrypter(enc.AES(aesKey, mode: enc.AESMode.sic));
    return encrypter.decrypt(ciphertext, iv: iv);
  }

  /// Encrypt for multiple recipients (group chat).
  /// Returns a map of recipientId → encrypted bundle.
  Map<String, String> encryptForGroup(
    String plaintext,
    Map<String, String> recipientPublicKeys,
  ) {
    // Use ONE AES key for all recipients, but RSA-encrypt
    // the AES key separately for each recipient
    final aesKey = enc.Key.fromSecureRandom(32);
    final iv = enc.IV.fromSecureRandom(16);
    final encrypter = enc.Encrypter(enc.AES(aesKey, mode: enc.AESMode.sic));
    final encryptedMessage = encrypter.encrypt(plaintext, iv: iv);

    final result = <String, String>{};
    for (final entry in recipientPublicKeys.entries) {
      final rsaPubKey = parsePublicKeyFromPem(entry.value);
      final encryptedAesKey = _rsaEncrypt(aesKey.bytes, rsaPubKey);
      result[entry.key] =
          '${base64.encode(encryptedAesKey)}.${iv.base64}.${encryptedMessage.base64}';
    }
    return result;
  }

  // ══════════════════════════════════════════════════════════════
  // MEDIA ENCRYPTION (for encrypting file data before upload)
  // ══════════════════════════════════════════════════════════════

  /// Encrypt raw bytes (for media files)
  Map<String, dynamic> encryptBytes(Uint8List data) {
    final aesKey = enc.Key.fromSecureRandom(32);
    final iv = enc.IV.fromSecureRandom(16);
    final encrypter = enc.Encrypter(enc.AES(aesKey, mode: enc.AESMode.sic));
    final encrypted = encrypter.encryptBytes(data, iv: iv);

    return {
      'data': encrypted.bytes,
      'key': base64.encode(aesKey.bytes),
      'iv': iv.base64,
    };
  }

  /// Decrypt raw bytes (for media files)
  Uint8List decryptBytes(Uint8List encryptedData, String keyBase64, String ivBase64) {
    final aesKey = enc.Key.fromBase64(keyBase64);
    final iv = enc.IV.fromBase64(ivBase64);
    final encrypter = enc.Encrypter(enc.AES(aesKey, mode: enc.AESMode.sic));
    return Uint8List.fromList(
      encrypter.decryptBytes(enc.Encrypted(encryptedData), iv: iv),
    );
  }

  // ══════════════════════════════════════════════════════════════
  // RSA OPERATIONS
  // ══════════════════════════════════════════════════════════════

  Uint8List _rsaEncrypt(Uint8List data, RSAPublicKey publicKey) {
    final cipher = OAEPEncoding(RSAEngine())
      ..init(true, PublicKeyParameter<RSAPublicKey>(publicKey));
    return _processInBlocks(cipher, data);
  }

  Uint8List _rsaDecrypt(Uint8List data, RSAPrivateKey privateKey) {
    final cipher = OAEPEncoding(RSAEngine())
      ..init(false, PrivateKeyParameter<RSAPrivateKey>(privateKey));
    return _processInBlocks(cipher, data);
  }

  /// Process data in blocks (RSA has max input size)
  Uint8List _processInBlocks(AsymmetricBlockCipher cipher, Uint8List data) {
    final inputBlockSize = cipher.inputBlockSize;
    final outputBlockSize = cipher.outputBlockSize;
    final output = Uint8List(
      ((data.length + inputBlockSize - 1) ~/ inputBlockSize) * outputBlockSize,
    );

    var offset = 0;
    var outputOffset = 0;
    while (offset < data.length) {
      final end = min(offset + inputBlockSize, data.length);
      final block = cipher.process(data.sublist(offset, end));
      output.setRange(outputOffset, outputOffset + block.length, block);
      outputOffset += block.length;
      offset = end;
    }

    return output.sublist(0, outputOffset);
  }

  // ══════════════════════════════════════════════════════════════
  // PEM ENCODING / DECODING
  // ══════════════════════════════════════════════════════════════

  /// Encode RSA public key to PEM format
  static String encodePublicKeyToPem(RSAPublicKey publicKey) {
    final algorithmSeq = ASN1Sequence()
      ..add(ASN1ObjectIdentifier.fromName('rsaEncryption'))
      ..add(ASN1Null());

    final publicKeySeq = ASN1Sequence()
      ..add(ASN1Integer(publicKey.modulus!))
      ..add(ASN1Integer(publicKey.exponent!));

    final publicKeyDer = publicKeySeq.encodedBytes;
    final publicKeyBitString = ASN1BitString(
      Uint8List.fromList([0x00, ...publicKeyDer]),
    );

    final topLevelSeq = ASN1Sequence()
      ..add(algorithmSeq)
      ..add(publicKeyBitString);

    final encoded = base64.encode(topLevelSeq.encodedBytes);
    final formattedPem = _formatPem(encoded);
    return '-----BEGIN PUBLIC KEY-----\n$formattedPem\n-----END PUBLIC KEY-----';
  }

  /// Encode RSA private key to PEM format (PKCS#1)
  static String encodePrivateKeyToPem(RSAPrivateKey privateKey) {
    final privateKeySeq = ASN1Sequence()
      ..add(ASN1Integer(BigInt.zero)) // version
      ..add(ASN1Integer(privateKey.modulus!))
      ..add(ASN1Integer(privateKey.publicExponent!))
      ..add(ASN1Integer(privateKey.privateExponent!))
      ..add(ASN1Integer(privateKey.p!))
      ..add(ASN1Integer(privateKey.q!))
      ..add(ASN1Integer(
          privateKey.privateExponent! % (privateKey.p! - BigInt.one)))
      ..add(ASN1Integer(
          privateKey.privateExponent! % (privateKey.q! - BigInt.one)))
      ..add(ASN1Integer(privateKey.q!.modInverse(privateKey.p!)));

    final encoded = base64.encode(privateKeySeq.encodedBytes);
    final formattedPem = _formatPem(encoded);
    return '-----BEGIN RSA PRIVATE KEY-----\n$formattedPem\n-----END RSA PRIVATE KEY-----';
  }

  /// Parse public key from PEM string
  static RSAPublicKey parsePublicKeyFromPem(String pem) {
    final rows = pem.split('\n');
    final b64 = rows
        .where((r) => !r.startsWith('-----'))
        .join('');
    final bytes = base64.decode(b64);

    final asn1Parser = ASN1Parser(Uint8List.fromList(bytes));
    final topLevelSeq = asn1Parser.nextObject() as ASN1Sequence;
    final publicKeyBitString = topLevelSeq.elements[1] as ASN1BitString;

    // Remove leading 0x00 byte
    final publicKeyDer = publicKeyBitString.contentBytes().sublist(1);
    final publicKeyParser = ASN1Parser(Uint8List.fromList(publicKeyDer));
    final publicKeySeq = publicKeyParser.nextObject() as ASN1Sequence;

    final modulus = (publicKeySeq.elements[0] as ASN1Integer).valueAsBigInteger;
    final exponent = (publicKeySeq.elements[1] as ASN1Integer).valueAsBigInteger;

    return RSAPublicKey(modulus, exponent);
  }

  /// Parse private key from PEM string (PKCS#1)
  static RSAPrivateKey parsePrivateKeyFromPem(String pem) {
    final rows = pem.split('\n');
    final b64 = rows
        .where((r) => !r.startsWith('-----'))
        .join('');
    final bytes = base64.decode(b64);

    final asn1Parser = ASN1Parser(Uint8List.fromList(bytes));
    final pkSeq = asn1Parser.nextObject() as ASN1Sequence;

    final modulus = (pkSeq.elements[1] as ASN1Integer).valueAsBigInteger;
    // ignore publicExponent at index 2
    final privateExponent = (pkSeq.elements[3] as ASN1Integer).valueAsBigInteger;
    final p = (pkSeq.elements[4] as ASN1Integer).valueAsBigInteger;
    final q = (pkSeq.elements[5] as ASN1Integer).valueAsBigInteger;

    return RSAPrivateKey(modulus, privateExponent, p, q);
  }

  // ══════════════════════════════════════════════════════════════
  // UTILITIES
  // ══════════════════════════════════════════════════════════════

  /// Create a cryptographically secure random number generator
  SecureRandom _secureRandom() {
    final random = FortunaRandom();
    final seed = List<int>.generate(32, (_) => Random.secure().nextInt(256));
    random.seed(KeyParameter(Uint8List.fromList(seed)));
    return random;
  }

  /// Format base64 string into PEM lines (64 chars per line)
  static String _formatPem(String b64) {
    final buffer = StringBuffer();
    for (var i = 0; i < b64.length; i += 64) {
      buffer.writeln(b64.substring(i, min(i + 64, b64.length)));
    }
    return buffer.toString().trim();
  }

  /// Generate a random encryption key as base64 (for file encryption)
  String generateRandomKeyBase64({int bytes = 32}) {
    final seed = List<int>.generate(bytes, (_) => Random.secure().nextInt(256));
    return base64.encode(seed);
  }

  /// Dispose: clean up resources
  Future<void> dispose() async {
    await _keyStore.close();
  }
}

/// Custom exception for encryption errors
class EncryptionException implements Exception {
  final String message;
  const EncryptionException(this.message);

  @override
  String toString() => 'EncryptionException: $message';
}
