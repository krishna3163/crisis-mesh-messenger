import 'dart:convert';
import 'package:cryptography/cryptography.dart';
import 'package:logger/logger.dart';
import 'package:crisis_mesh/core/models/message.dart';
import 'package:crisis_mesh/core/models/peer.dart';

/// Service for handling end-to-end encryption and key management
class EncryptionService {
  final Logger _logger = Logger();
  final _algorithm = AesGcm.with256bits();

  // Local key pair for this device
  SimpleKeyPair? _keyPair;
  final Map<String, SecretKey> _sessionKeys = {}; // peerId -> shared secret key

  /// Generate a new key pair for this device
  Future<void> initialize() async {
    final x25519 = X25519();
    _keyPair = await x25519.newKeyPair();
    _logger.i('Encryption service initialized. Public key generated.');
  }

  /// Get the public key to share with peers
  Future<String?> getPublicKey() async {
    if (_keyPair == null) return null;
    final publicKey = await _keyPair!.extractPublicKey();
    return base64Encode(publicKey.bytes);
  }

  /// Derive a shared secret key from our private key and a peer's public key
  Future<void> establishSession(String peerId, String peerPublicKeyBase64) async {
    try {
      final x25519 = X25519();
      final peerPublicKey = SimplePublicKey(
        base64Decode(peerPublicKeyBase64),
        type: KeyPairType.x25519,
      );

      final sharedSecret = await x25519.sharedSecretKey(
        keyPair: _keyPair!,
        remotePublicKey: peerPublicKey,
      );

      _sessionKeys[peerId] = sharedSecret;
      _logger.i('Shared session key established with peer: $peerId');
    } catch (e) {
      _logger.e('Failed to establish session with peer $peerId: $e');
    }
  }

  /// Encrypt a message for a specific peer
  Future<String?> encrypt(String peerId, String plainText) async {
    final sessionKey = _sessionKeys[peerId];
    if (sessionKey == null) {
      _logger.w('No session key found for peer $peerId. Message cannot be encrypted.');
      return null;
    }

    try {
      final secretBox = await _algorithm.encrypt(
        utf8.encode(plainText),
        secretKey: sessionKey,
      );

      // Combine nonce + mac + cipherText into a single base64 string
      final combined = [
        ...secretBox.nonce,
        ...secretBox.mac.bytes,
        ...secretBox.cipherText,
      ];

      return base64Encode(combined);
    } catch (e) {
      _logger.e('Encryption failed: $e');
      return null;
    }
  }

  /// Decrypt a message from a specific peer
  Future<String?> decrypt(String peerId, String encryptedDataBase64) async {
    final sessionKey = _sessionKeys[peerId];
    if (sessionKey == null) {
      _logger.w('No session key found for peer $peerId. Message cannot be decrypted.');
      return null;
    }

    try {
      final combined = base64Decode(encryptedDataBase64);

      // AES-GCM in cryptography package: nonce (12 bytes), MAC (16 bytes), cipherText (remaining)
      final nonce = combined.sublist(0, 12);
      final macBytes = combined.sublist(12, 28);
      final cipherText = combined.sublist(28);

      final secretBox = SecretBox(
        cipherText,
        nonce: nonce,
        mac: Mac(macBytes),
      );

      final clearTextBytes = await _algorithm.decrypt(
        secretBox,
        secretKey: sessionKey,
      );

      return utf8.decode(clearTextBytes);
    } catch (e) {
      _logger.e('Decryption failed for peer $peerId: $e');
      return null;
    }
  }

  /// Clear session keys on disconnect
  void clearSession(String peerId) {
    _sessionKeys.remove(peerId);
  }
}
