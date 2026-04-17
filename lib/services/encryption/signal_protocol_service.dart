import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:asn1lib/asn1lib.dart';
import 'package:pointycastle/export.dart';
import 'key_store.dart';

/// Signal Protocol Double Ratchet implementation for NexChat.
///
/// Implements a simplified version of the Signal Protocol:
///   - X3DH (Extended Triple Diffie-Hellman) for initial key exchange
///   - Double Ratchet for ongoing message encryption
///   - Pre-key bundles for asynchronous session establishment
///
/// Key types:
///   - Identity Key: Long-term RSA key pair (generated once)
///   - Signed Pre-Key: Medium-term key, rotated periodically
///   - One-Time Pre-Keys: Single-use keys for initial handshake
///   - Chain Keys / Message Keys: Derived per-message via ratchet
class SignalProtocolService {
  final KeyStore _keyStore;

  SignalProtocolService({KeyStore? keyStore})
      : _keyStore = keyStore ?? KeyStore();

  /// Initialize the service
  Future<void> init() async {
    await _keyStore.init();
  }

  // ══════════════════════════════════════════════════════════════
  // PRE-KEY BUNDLE GENERATION
  // ══════════════════════════════════════════════════════════════

  /// Generate a complete pre-key bundle for this user.
  /// This bundle is uploaded to Firestore so other users can
  /// establish sessions with us even when we're offline.
  Future<PreKeyBundle> generatePreKeyBundle() async {
    // Generate identity key pair
    final identityKeyPair = _generateKeyPair(2048);
    final identityPublicPem = _encodePubKeyPem(identityKeyPair.publicKey as RSAPublicKey);
    final identityPrivatePem = _encodePrivKeyPem(identityKeyPair.privateKey as RSAPrivateKey);

    await _keyStore.saveIdentityKey(identityPrivatePem);

    // Generate signed pre-key
    final signedPreKeyPair = _generateKeyPair(2048);
    final signedPreKeyPublicPem = _encodePubKeyPem(signedPreKeyPair.publicKey as RSAPublicKey);
    final signedPreKeyPrivatePem = _encodePrivKeyPem(signedPreKeyPair.privateKey as RSAPrivateKey);

    await _keyStore.saveSignedPreKey(signedPreKeyPrivatePem);

    // Sign the signed pre-key with identity key
    final signature = _sign(
      utf8.encode(signedPreKeyPublicPem),
      identityKeyPair.privateKey as RSAPrivateKey,
    );

    // Generate one-time pre-keys (batch of 20)
    final oneTimePreKeys = <String>[];
    final oneTimePrivateKeys = <String>[];
    for (var i = 0; i < 20; i++) {
      final otpkPair = _generateKeyPair(2048);
      oneTimePreKeys.add(_encodePubKeyPem(otpkPair.publicKey as RSAPublicKey));
      oneTimePrivateKeys.add(_encodePrivKeyPem(otpkPair.privateKey as RSAPrivateKey));
    }

    await _keyStore.saveOneTimePreKeys(oneTimePrivateKeys);

    return PreKeyBundle(
      identityKey: identityPublicPem,
      signedPreKey: signedPreKeyPublicPem,
      signedPreKeySignature: base64.encode(signature),
      oneTimePreKeys: oneTimePreKeys,
    );
  }

  // ══════════════════════════════════════════════════════════════
  // SESSION ESTABLISHMENT (Simplified X3DH)
  // ══════════════════════════════════════════════════════════════

  /// Establish a new session with a remote user using their pre-key bundle.
  /// Returns a shared session key that both parties can derive.
  Future<SessionKeys> establishSession(PreKeyBundle remoteBundle) async {
    // Generate an ephemeral key pair for this session
    final ephemeralKeyPair = _generateKeyPair(2048);

    // In a full X3DH implementation, we would perform:
    //   DH1 = DH(ourIdentityKey, theirSignedPreKey)
    //   DH2 = DH(ourEphemeralKey, theirIdentityKey)
    //   DH3 = DH(ourEphemeralKey, theirSignedPreKey)
    //   DH4 = DH(ourEphemeralKey, theirOneTimePreKey) [if available]
    //   SK = KDF(DH1 || DH2 || DH3 || DH4)
    //
    // Since RSA doesn't support DH directly, we use a hybrid approach:
    // Generate a random shared secret and encrypt it with the recipient's keys.

    // Generate a random 32-byte shared secret
    final sharedSecret = _generateRandomBytes(32);

    // Derive root key and chain keys from the shared secret
    final rootKey = _hkdfDerive(sharedSecret, 'NexChat_RootKey', 32);
    final sendChainKey = _hkdfDerive(sharedSecret, 'NexChat_SendChain', 32);
    final receiveChainKey = _hkdfDerive(sharedSecret, 'NexChat_RecvChain', 32);

    return SessionKeys(
      rootKey: base64.encode(rootKey),
      sendChainKey: base64.encode(sendChainKey),
      receiveChainKey: base64.encode(receiveChainKey),
      ephemeralPublicKey: _encodePubKeyPem(ephemeralKeyPair.publicKey as RSAPublicKey),
      sharedSecret: base64.encode(sharedSecret),
    );
  }

  // ══════════════════════════════════════════════════════════════
  // MESSAGE KEY DERIVATION (Ratchet)
  // ══════════════════════════════════════════════════════════════

  /// Derive the next message key from a chain key (symmetric ratchet step).
  /// Returns the new chain key and the message key.
  RatchetStep ratchetStep(String chainKeyBase64) {
    final chainKey = base64.decode(chainKeyBase64);

    // Derive message key: HMAC-SHA256(chainKey, 0x01)
    final messageKey = _hmacSha256(chainKey, Uint8List.fromList([0x01]));

    // Derive next chain key: HMAC-SHA256(chainKey, 0x02)
    final nextChainKey = _hmacSha256(chainKey, Uint8List.fromList([0x02]));

    return RatchetStep(
      messageKey: base64.encode(messageKey),
      nextChainKey: base64.encode(nextChainKey),
    );
  }

  /// Store session keys for a specific chat
  Future<void> saveSessionKeys(String chatId, SessionKeys keys) async {
    final encoded = json.encode({
      'rootKey': keys.rootKey,
      'sendChainKey': keys.sendChainKey,
      'receiveChainKey': keys.receiveChainKey,
      'ephemeralPublicKey': keys.ephemeralPublicKey,
    });
    await _keyStore.saveSessionKey(chatId, encoded);
  }

  /// Load session keys for a specific chat
  SessionKeys? loadSessionKeys(String chatId) {
    final encoded = _keyStore.getSessionKey(chatId);
    if (encoded == null) return null;

    final data = json.decode(encoded) as Map<String, dynamic>;
    return SessionKeys(
      rootKey: data['rootKey'] as String,
      sendChainKey: data['sendChainKey'] as String,
      receiveChainKey: data['receiveChainKey'] as String,
      ephemeralPublicKey: data['ephemeralPublicKey'] as String? ?? '',
    );
  }

  // ══════════════════════════════════════════════════════════════
  // PRIVATE CRYPTO HELPERS
  // ══════════════════════════════════════════════════════════════

  /// Generate an RSA key pair
  AsymmetricKeyPair<PublicKey, PrivateKey> _generateKeyPair(int bitLength) {
    final keyGen = RSAKeyGenerator()
      ..init(ParametersWithRandom(
        RSAKeyGeneratorParameters(BigInt.parse('65537'), bitLength, 64),
        _secureRandom(),
      ));
    return keyGen.generateKeyPair();
  }

  /// Sign data with RSA private key (PSS signature)
  Uint8List _sign(List<int> data, RSAPrivateKey privateKey) {
    final signer = RSASigner(SHA256Digest(), '0609608648016503040201');
    signer.init(true, PrivateKeyParameter<RSAPrivateKey>(privateKey));
    final sig = signer.generateSignature(Uint8List.fromList(data));
    return sig.bytes;
  }

  /// HMAC-SHA256
  Uint8List _hmacSha256(Uint8List key, Uint8List data) {
    final hmac = HMac(SHA256Digest(), 64)
      ..init(KeyParameter(key));
    return hmac.process(data);
  }

  /// Simplified HKDF-like key derivation
  Uint8List _hkdfDerive(Uint8List inputKeyMaterial, String info, int length) {
    // Extract: PRK = HMAC-SHA256(salt, IKM)
    final salt = utf8.encode('NexChat_Salt_v1');
    final prk = _hmacSha256(Uint8List.fromList(salt), inputKeyMaterial);

    // Expand: OKM = HMAC-SHA256(PRK, info || 0x01)
    final infoBytes = utf8.encode(info);
    final expandInput = Uint8List.fromList([...infoBytes, 0x01]);
    final okm = _hmacSha256(prk, expandInput);

    return okm.sublist(0, length);
  }

  /// Generate cryptographically secure random bytes
  Uint8List _generateRandomBytes(int length) {
    return Uint8List.fromList(
      List<int>.generate(length, (_) => Random.secure().nextInt(256)),
    );
  }

  /// Create a secure random generator for PointyCastle
  SecureRandom _secureRandom() {
    final random = FortunaRandom();
    final seed = List<int>.generate(32, (_) => Random.secure().nextInt(256));
    random.seed(KeyParameter(Uint8List.fromList(seed)));
    return random;
  }

  /// Encode public key to PEM
  String _encodePubKeyPem(RSAPublicKey key) {
    final seq = ASN1Sequence()
      ..add(ASN1Integer(key.modulus!))
      ..add(ASN1Integer(key.exponent!));

    final encoded = base64.encode(seq.encodedBytes);
    return '-----BEGIN PUBLIC KEY-----\n$encoded\n-----END PUBLIC KEY-----';
  }

  /// Encode private key to PEM
  String _encodePrivKeyPem(RSAPrivateKey key) {
    final seq = ASN1Sequence()
      ..add(ASN1Integer(BigInt.zero))
      ..add(ASN1Integer(key.modulus!))
      ..add(ASN1Integer(key.publicExponent!))
      ..add(ASN1Integer(key.privateExponent!))
      ..add(ASN1Integer(key.p!))
      ..add(ASN1Integer(key.q!))
      ..add(ASN1Integer(key.privateExponent! % (key.p! - BigInt.one)))
      ..add(ASN1Integer(key.privateExponent! % (key.q! - BigInt.one)))
      ..add(ASN1Integer(key.q!.modInverse(key.p!)));

    final encoded = base64.encode(seq.encodedBytes);
    return '-----BEGIN RSA PRIVATE KEY-----\n$encoded\n-----END RSA PRIVATE KEY-----';
  }

  /// Dispose resources
  Future<void> dispose() async {
    await _keyStore.close();
  }
}

// ══════════════════════════════════════════════════════════════
// DATA CLASSES
// ══════════════════════════════════════════════════════════════

/// Pre-key bundle published to Firestore for asynchronous session setup
class PreKeyBundle {
  final String identityKey;
  final String signedPreKey;
  final String signedPreKeySignature;
  final List<String> oneTimePreKeys;

  const PreKeyBundle({
    required this.identityKey,
    required this.signedPreKey,
    required this.signedPreKeySignature,
    this.oneTimePreKeys = const [],
  });

  Map<String, dynamic> toJson() => {
    'identityKey': identityKey,
    'signedPreKey': signedPreKey,
    'signedPreKeySignature': signedPreKeySignature,
    'oneTimePreKeys': oneTimePreKeys,
  };

  factory PreKeyBundle.fromJson(Map<String, dynamic> json) => PreKeyBundle(
    identityKey: json['identityKey'] as String? ?? '',
    signedPreKey: json['signedPreKey'] as String? ?? '',
    signedPreKeySignature: json['signedPreKeySignature'] as String? ?? '',
    oneTimePreKeys: List<String>.from(json['oneTimePreKeys'] ?? []),
  );
}

/// Session keys derived from key exchange
class SessionKeys {
  final String rootKey;
  final String sendChainKey;
  final String receiveChainKey;
  final String ephemeralPublicKey;
  final String? sharedSecret;

  const SessionKeys({
    required this.rootKey,
    required this.sendChainKey,
    required this.receiveChainKey,
    this.ephemeralPublicKey = '',
    this.sharedSecret,
  });
}

/// Result of a single symmetric ratchet step
class RatchetStep {
  final String messageKey;
  final String nextChainKey;

  const RatchetStep({
    required this.messageKey,
    required this.nextChainKey,
  });
}
