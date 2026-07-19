import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';
import 'package:crisis_mesh/core/services/mesh/mesh_network_service.dart';

class HardwareSensorService extends ChangeNotifier {
  final Logger _logger = Logger();
  final MeshNetworkService _meshService;
  Timer? _sensorTimer;

  // Real-time simulated sensor parameters
  double _accelX = 0.0;
  double _accelY = 0.0;
  double _accelZ = 9.8;

  double _offsetX = 0.0;
  double _offsetY = 0.0;
  double _offsetZ = 0.0;

  double _temperature = 24.5;
  double _humidity = 58.0;
  double _pressure = 1012.25;

  double _solarInputWatts = 0.0;
  bool _isSolarCharging = false;

  bool _earthquakeAlertActive = false;
  String _alertSource = '';

  bool _flashlightOn = false;
  String _currentMorseChar = '';

  HardwareSensorService(this._meshService);

  // Getters
  double get accelX => _accelX;
  double get accelY => _accelY;
  double get accelZ => _accelZ;
  double get offsetX => _offsetX;
  double get offsetY => _offsetY;
  double get offsetZ => _offsetZ;
  double get temperature => _temperature;
  double get humidity => _humidity;
  double get pressure => _pressure;
  double get solarInputWatts => _solarInputWatts;
  bool get isSolarCharging => _isSolarCharging;
  bool get earthquakeAlertActive => _earthquakeAlertActive;
  String get alertSource => _alertSource;
  bool get flashlightOn => _flashlightOn;
  String get currentMorseChar => _currentMorseChar;

  void initialize() {
    _logger.i('Initializing Hardware & Sensor Service...');
    startSensorPolling();
  }

  void startSensorPolling() {
    _sensorTimer?.cancel();
    final random = math.Random();

    _sensorTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      // Simulate minor sensor noise
      _accelX = (random.nextDouble() - 0.5) * 0.2;
      _accelY = (random.nextDouble() - 0.5) * 0.2;
      // Normal gravity + noise
      _accelZ = 9.8 + (random.nextDouble() - 0.5) * 0.2;

      _temperature += (random.nextDouble() - 0.5) * 0.1;
      _humidity += (random.nextDouble() - 0.5) * 0.5;
      _pressure += (random.nextDouble() - 0.5) * 0.15;

      if (_isSolarCharging) {
        // Solar panels generate 0 to 12 watts depending on cloud simulation
        _solarInputWatts = 5.0 + random.nextDouble() * 5.0;
      } else {
        _solarInputWatts = 0.0;
      }

      _evaluateSeismicAlert();
      notifyListeners();
    });
  }

  void stopSensorPolling() {
    _sensorTimer?.cancel();
  }

  void calibrateSensors(double ox, double oy, double oz) {
    _offsetX = ox;
    _offsetY = oy;
    _offsetZ = oz;
    _logger.i('Calibrated accelerometer offsets: X=$ox, Y=$oy, Z=$oz');
    notifyListeners();
  }

  void setSolarCharging(bool charging) {
    _isSolarCharging = charging;
    notifyListeners();
  }

  /// Calculates total ground acceleration magnitude and checks seismic threshold
  void _evaluateSeismicAlert() {
    final x = _accelX + _offsetX;
    final y = _accelY + _offsetY;
    final z = _accelZ + _offsetZ;

    final magnitude = math.sqrt(x * x + y * y + z * z);
    final delta = (magnitude - 9.8).abs();

    // 3.5 m/s^2 corresponds to Moderate ground shaking (Modified Mercalli V)
    if (delta > 3.5 && !_earthquakeAlertActive) {
      triggerEarthquakeAlert(source: 'Local Accelerometer');
    }
  }

  /// Trigger earthquake warning and broadcast over mesh
  void triggerEarthquakeAlert({required String source, bool broadcast = true}) async {
    _earthquakeAlertActive = true;
    _alertSource = source;
    _logger.w('EARTHQUAKE EARLY WARNING ACTIVE! Source: $source');
    notifyListeners();

    if (broadcast) {
      await _meshService.broadcastPayload('seismic_warning', {
        'source': source,
        'timestamp': DateTime.now().toIso8601String(),
      });
    }
  }

  void dismissEarthquakeAlert() {
    _earthquakeAlertActive = false;
    _alertSource = '';
    notifyListeners();
  }

  // --- Morse Code Sync Flashlight Blinking ---
  final Map<String, String> _morseDictionary = {
    'A': '.-', 'B': '-...', 'C': '-.-.', 'D': '-..', 'E': '.', 'F': '..-.',
    'G': '--.', 'H': '....', 'I': '..', 'J': '.---', 'K': '-.-', 'L': '.-..',
    'M': '--', 'N': '-.', 'O': '---', 'P': '.--.', 'Q': '--.-', 'R': '.-.',
    'S': '...', 'T': '-', 'U': '..-', 'V': '...-', 'W': '.--', 'X': '-..-',
    'Y': '-.--', 'Z': '--..',
    '1': '.----', '2': '..---', '3': '...--', '4': '....-', '5': '.....',
    '6': '-....', '7': '--...', '8': '---..', '9': '----.', '0': '-----',
  };

  /// Translate text message to Morse code pulses and toggle flashlight state
  Future<void> flashMorseMessage(String message) async {
    final clean = message.trim().toUpperCase();
    _logger.i('Translating to Morse and flashing: $clean');

    const dotDuration = Duration(milliseconds: 200);
    const dashDuration = Duration(milliseconds: 600);
    const elementSpace = Duration(milliseconds: 200);
    const letterSpace = Duration(milliseconds: 600);
    const wordSpace = Duration(milliseconds: 1400);

    for (int i = 0; i < clean.length; i++) {
      final char = clean[i];
      if (char == ' ') {
        _currentMorseChar = ' ';
        notifyListeners();
        await Future.delayed(wordSpace);
        continue;
      }

      final morseSymbol = _morseDictionary[char];
      if (morseSymbol == null) continue;

      _currentMorseChar = '$char: $morseSymbol';
      notifyListeners();

      for (int s = 0; s < morseSymbol.length; s++) {
        final symbol = morseSymbol[s];
        
        // Turn Flashlight ON
        _flashlightOn = true;
        notifyListeners();

        if (symbol == '.') {
          await Future.delayed(dotDuration);
        } else if (symbol == '-') {
          await Future.delayed(dashDuration);
        }

        // Turn Flashlight OFF
        _flashlightOn = false;
        notifyListeners();

        // Space between dots and dashes of the same letter
        await Future.delayed(elementSpace);
      }

      // Space between letters
      await Future.delayed(letterSpace);
    }

    _currentMorseChar = '';
    _flashlightOn = false;
    notifyListeners();
  }

  @override
  void dispose() {
    stopSensorPolling();
    super.dispose();
  }
}
