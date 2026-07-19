import 'package:flutter_test/flutter_test.dart';
import 'package:crisis_mesh/core/services/mesh/gateway_service.dart';

void main() {
  late GatewayService gatewayService;

  setUp(() {
    gatewayService = GatewayService();
    gatewayService.initialize();
  });

  test('Garmin InReach Compressor compresses coordinates and text fields accurately', () {
    const lat = 45.4215;
    const lon = -75.6972;
    const sender = 'USR_ALPH';
    const sosMsg = 'Flash floods rising quickly, need boat extraction.';

    // Compress
    final hexPayload = gatewayService.compressSatellitePayload(lat, lon, sender, sosMsg);

    // HEX payload length must be exactly 160 characters (80 bytes)
    expect(hexPayload.length, 160);

    // Decompress for verification checks
    final decompressed = gatewayService.decompressSatellitePayload(hexPayload);

    // Compare values (floating delta matching)
    expect(((decompressed['lat'] as double) - lat).abs() < 0.0001, true);
    expect(((decompressed['lon'] as double) - lon).abs() < 0.0001, true);
    expect(decompressed['senderId'], sender);
    
    // Verify padding and matching
    expect(decompressed['sosText'], sosMsg.padRight(64).substring(0, 64).trim());
  });

  test('Dynamic Backhaul selector routes according to interface priority criteria', () {
    const sender = 'user_id';
    const msg = 'Need assistance';

    // 1. Initial State: All interfaces offline -> should fail
    var route = gatewayService.routePayload(type: 'SOS', message: msg, senderId: sender);
    expect(route, 'FAILED');

    // 2. Garmin Satellite paired -> choose Satellite
    gatewayService.setSatelliteStatus(true);
    route = gatewayService.routePayload(type: 'SOS', message: msg, senderId: sender, lat: 24.0, lon: 45.0);
    expect(route, 'SATELLITE_GARMIN');

    // 3. LoRa module connected -> choose LoRa (takes priority over Satellite)
    gatewayService.setLoraStatus(true);
    route = gatewayService.routePayload(type: 'SOS', message: msg, senderId: sender);
    expect(route, 'LORA_RADIO');

    // 4. Cellular interface connected -> choose Cellular (takes priority over all)
    gatewayService.setCellularStatus(true);
    route = gatewayService.routePayload(type: 'SOS', message: msg, senderId: sender);
    expect(route, 'CELLULAR_LTE');
  });

  test('LoRa chunker divides long messages by 256-byte limits', () {
    // Generate a long text payload of 600 bytes
    final text = 'A' * 600;
    
    final chunks = gatewayService.chunkLoRaMessage(text);
    
    // 600 / 256 = 3 chunks (256 + 256 + 88)
    expect(chunks.length, 3);
    expect(chunks[0].length, 256);
    expect(chunks[1].length, 256);
    expect(chunks[2].length, 88);
  });
}
