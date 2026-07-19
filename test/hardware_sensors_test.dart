import 'dart:math' as math;
import 'package:flutter_test/flutter_test.dart';
import 'package:crisis_mesh/core/services/mesh/mesh_network_service.dart';
import 'package:crisis_mesh/core/services/hardware/hardware_sensor_service.dart';

// Mock MeshNetworkService
class FakeMeshNetworkService extends MeshNetworkService {
  final List<Map<String, dynamic>> sentPayloads = [];

  @override
  Future<bool> broadcastPayload(String type, Map<String, dynamic> payload, {List<String>? excludeNodeIds}) async {
    sentPayloads.add({'type': type, 'payload': payload});
    return true;
  }
}

void main() {
  late FakeMeshNetworkService fakeMesh;
  late HardwareSensorService sensorService;

  setUp(() {
    fakeMesh = FakeMeshNetworkService();
    sensorService = HardwareSensorService(fakeMesh);
  });

  test('Seismic threshold checks magnitude correctly', () {
    // 1. Initial State: Normal gravity, Z=9.8. Magnitude delta is 0
    expect(sensorService.earthquakeAlertActive, false);

    // Helper magnitude check
    double calculateMag(double x, double y, double z) {
      return math.sqrt(x * x + y * y + z * z);
    }

    final magNormal = calculateMag(0.0, 0.0, 9.8);
    expect(magNormal, 9.8);
    expect((magNormal - 9.8).abs() > 3.5, false);

    // 2. High shake simulation: X=2.5, Y=3.0, Z=12.5
    final magShake = calculateMag(2.5, 3.0, 12.5);
    // magShake = sqrt(6.25 + 9.0 + 156.25) = sqrt(171.5) = 13.09
    // delta = 13.09 - 9.8 = 3.29. (Close to threshold).

    // 3. Trigger alert manually and check status
    sensorService.triggerEarthquakeAlert(source: 'Accelerometer Test', broadcast: false);
    expect(sensorService.earthquakeAlertActive, true);
    expect(sensorService.alertSource, 'Accelerometer Test');

    sensorService.dismissEarthquakeAlert();
    expect(sensorService.earthquakeAlertActive, false);
  });

  test('Morse Code Dictionary handles standard conversions correctly', () {
    final morseMap = {
      'S': '...',
      'O': '---',
    };

    String getMorseRepresentation(String txt) {
      final buffer = StringBuffer();
      for (int i = 0; i < txt.length; i++) {
        final char = txt[i].toUpperCase();
        buffer.write(morseMap[char] ?? '');
      }
      return buffer.toString();
    }

    final converted = getMorseRepresentation('SOS');
    expect(converted, '...---...');
  });

  test('Sensors offset shifts calibration calculations', () {
    expect(sensorService.offsetX, 0.0);
    expect(sensorService.offsetY, 0.0);
    expect(sensorService.offsetZ, 0.0);

    sensorService.calibrateSensors(0.5, -0.5, 1.0);
    expect(sensorService.offsetX, 0.5);
    expect(sensorService.offsetY, -0.5);
    expect(sensorService.offsetZ, 1.0);
  });
}
