import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

class GatewayService extends ChangeNotifier {
  final Logger _logger = Logger();

  // Simulated hardware connection statuses
  bool _cellularConnected = false;
  bool _loraConnected = false;
  bool _satelliteConnected = false;

  final List<String> _transmissionLogs = [];

  bool get cellularConnected => _cellularConnected;
  bool get loraConnected => _loraConnected;
  bool get satelliteConnected => _satelliteConnected;
  List<String> get transmissionLogs => List.unmodifiable(_transmissionLogs);

  void initialize() {
    _logger.i('Initializing Infrastructure Gateway Service...');
    _transmissionLogs.add('Gateway system initialized.');
  }

  void setCellularStatus(bool active) {
    _cellularConnected = active;
    _transmissionLogs.add('Cellular/Wi-Fi interface: ${active ? "CONNECTED" : "DISCONNECTED"}.');
    notifyListeners();
  }

  void setLoraStatus(bool active) {
    _loraConnected = active;
    _transmissionLogs.add('Sub-GHz LoRa Hardware Module: ${active ? "CONNECTED" : "DISCONNECTED"}.');
    notifyListeners();
  }

  void setSatelliteStatus(bool active) {
    _satelliteConnected = active;
    _transmissionLogs.add('Garmin Satellite InReach Terminal: ${active ? "CONNECTED" : "DISCONNECTED"}.');
    notifyListeners();
  }

  void clearLogs() {
    _transmissionLogs.clear();
    notifyListeners();
  }

  /// Dynamic Backhaul Selection Protocol routing decision
  String routePayload({
    required String type, // 'TXT', 'SOS', 'EMAIL'
    required String message,
    required String senderId,
    double? lat,
    double? lon,
  }) {
    String route = 'FAILED';
    String detail = 'No active infrastructure backhauls detected.';

    if (_cellularConnected) {
      // Priority 1: High Bandwidth Cellular/Wi-Fi
      route = 'CELLULAR_LTE';
      detail = 'Dispatched full payload over Cellular backhaul (Unlimited Bandwidth).';
    } else if (_loraConnected) {
      // Priority 2: Sub-GHz LoRa modules (Text chunking)
      route = 'LORA_RADIO';
      final chunks = chunkLoRaMessage(message);
      detail = 'Chunked message into ${chunks.length} packets (256-byte limit) and broadcasted via Sub-GHz LoRa Radio.';
    } else if (_satelliteConnected) {
      // Priority 3: Garmin InReach Satellite (SOS / Triage coordinates only)
      route = 'SATELLITE_GARMIN';
      final compressed = compressSatellitePayload(
        lat ?? 0.0,
        lon ?? 0.0,
        senderId,
        message,
      );
      detail = 'Compressed coordinates and text into an 80-byte binary packet ($compressed) and uploaded to Satellite constellation.';
    }

    final log = '[${DateTime.now().toString().substring(11, 19)}] [$route] $detail';
    _transmissionLogs.add(log);
    _logger.i(log);
    notifyListeners();

    return route;
  }

  /// Garmin InReach Compressor: Packs coordinate floats and short text into 80 bytes
  String compressSatellitePayload(double lat, double lon, String senderId, String sosText) {
    final buffer = ByteData(80);

    // 1. Pack Latitude (float32, 4 bytes) -> offset 0
    buffer.setFloat32(0, lat, Endian.big);

    // 2. Pack Longitude (float32, 4 bytes) -> offset 4
    buffer.setFloat32(4, lon, Endian.big);

    // 3. Pack Sender ID (8-char ASCII string, 8 bytes) -> offset 8
    final cleanId = senderId.padRight(8).substring(0, 8);
    final idBytes = ascii.encode(cleanId);
    for (int i = 0; i < 8; i++) {
      buffer.setUint8(8 + i, idBytes[i]);
    }

    // 4. Pack SOS Alert text (64-char UTF-8 string, 64 bytes) -> offset 16
    final cleanText = sosText.padRight(64).substring(0, 64);
    final textBytes = utf8.encode(cleanText);
    for (int i = 0; i < 64; i++) {
      buffer.setUint8(16 + i, textBytes[i]);
    }

    // Convert complete 80-byte buffer into HEX string representation
    final hexString = buffer.buffer.asUint8List()
        .map((b) => b.toRadixString(16).padLeft(2, '0'))
        .join('');
    
    return hexString.toUpperCase();
  }

  /// Garmin InReach Decompressor (Useful for verification testing)
  Map<String, dynamic> decompressSatellitePayload(String hexString) {
    final bytes = Uint8List(80);
    for (int i = 0; i < 80; i++) {
      final hexByte = hexString.substring(i * 2, i * 2 + 2);
      bytes[i] = int.parse(hexByte, radix: 16);
    }

    final buffer = ByteData.sublistView(bytes);
    final lat = buffer.getFloat32(0, Endian.big);
    final lon = buffer.getFloat32(4, Endian.big);

    final idBytes = bytes.sublist(8, 16);
    final senderId = ascii.decode(idBytes).trim();

    final textBytes = bytes.sublist(16, 80);
    final sosText = utf8.decode(textBytes).trim();

    return {
      'lat': lat,
      'lon': lon,
      'senderId': senderId,
      'sosText': sosText,
    };
  }

  /// Splits text message into chunks of 256 bytes for Sub-GHz radio frames
  List<String> chunkLoRaMessage(String message) {
    final List<String> chunks = [];
    final bytes = utf8.encode(message);
    const chunkSize = 256;

    for (int i = 0; i < bytes.length; i += chunkSize) {
      final end = (i + chunkSize < bytes.length) ? i + chunkSize : bytes.length;
      final sublist = bytes.sublist(i, end);
      chunks.add(utf8.decode(sublist));
    }

    return chunks;
  }
}
