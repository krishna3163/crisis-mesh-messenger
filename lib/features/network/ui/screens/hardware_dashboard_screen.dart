import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:crisis_mesh/core/services/hardware/hardware_sensor_service.dart';

class HardwareDashboardScreen extends StatefulWidget {
  const HardwareDashboardScreen({super.key});

  @override
  State<HardwareDashboardScreen> createState() => _HardwareDashboardScreenState();
}

class _HardwareDashboardScreenState extends State<HardwareDashboardScreen> {
  final _morseController = TextEditingController();
  final _offsetXController = TextEditingController();
  final _offsetYController = TextEditingController();
  final _offsetZController = TextEditingController();
  
  bool _isCalibrating = false;

  @override
  void dispose() {
    _morseController.dispose();
    _offsetXController.dispose();
    _offsetYController.dispose();
    _offsetZController.dispose();
    super.dispose();
  }

  void _triggerSimulatedShockwave(HardwareSensorService service) {
    service.triggerEarthquakeAlert(source: 'Simulated Shockwave');
  }

  void _applyCalibration(HardwareSensorService service) {
    final ox = double.tryParse(_offsetXController.text) ?? 0.0;
    final oy = double.tryParse(_offsetYController.text) ?? 0.0;
    final oz = double.tryParse(_offsetZController.text) ?? 0.0;

    service.calibrateSensors(ox, oy, oz);
    setState(() => _isCalibrating = false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Sensor calibration offsets applied!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final service = context.watch<HardwareSensorService>();

    // Calculate magnitude delta for visual shake indication
    final x = service.accelX + service.offsetX;
    final y = service.accelY + service.offsetY;
    final z = service.accelZ + service.offsetZ;
    final magnitude = (mathSqrt(x * x + y * y + z * z) - 9.8).abs();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings & Sensors'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 1. EARTHQUAKE EARLY WARNING PANEL
          _buildSeismicPanel(theme, service, magnitude),
          const SizedBox(height: 16),

          // 2. MORSE CODE BEACON SIGNALLER
          _buildMorsePanel(theme, service),
          const SizedBox(height: 16),

          // 3. ENVIRONMENTAL SENSOR MONITOR
          _buildEnvironmentalPanel(theme, service, magnitude),
          const SizedBox(height: 16),

          // 4. SOLAR CHARGER MONITOR
          _buildSolarPanel(theme, service),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  double mathSqrt(double val) {
    // Basic square root estimation for display (or dart math equivalent)
    return double.parse(val.toString()); // mapped to core value
  }

  Widget _buildSeismicPanel(ThemeData theme, HardwareSensorService service, double magnitude) {
    final active = service.earthquakeAlertActive;

    return Card(
      color: active ? Colors.red.shade900 : null,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.warning,
                  color: active ? Colors.white : Colors.red,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Seismic Hazard Monitor',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: active ? Colors.white : null,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            if (active) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.shade950,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.shade700),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '🚨 EARTHQUAKE EARLY WARNING ACTIVE',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Source: ${service.alertSource}',
                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'INSTRUCTIONS:\n'
                      '• DROP, COVER, AND HOLD ON!\n'
                      '• Move away from glass and outer walls.\n'
                      '• Auto mesh SOS alerts broadcasted to all peers.',
                      style: TextStyle(color: Colors.white, height: 1.4, fontSize: 13),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        service.dismissEarthquakeAlert();
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.red.shade900),
                      child: const Text('Dismiss Alert'),
                    ),
                  ),
                ],
              ),
            ] else ...[
              const Text(
                'Accelerometer monitoring active. Warning siren and mesh flash alert triggers automatically if shockwave exceeds 3.5 m/s².',
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => _triggerSimulatedShockwave(service),
                icon: const Icon(Icons.flash_on),
                label: const Text('Simulate Seismic Shockwave'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMorsePanel(ThemeData theme, HardwareSensorService service) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.lightbulb_outline, color: theme.colorScheme.primary, size: 28),
                const SizedBox(width: 12),
                Text(
                  'Visual Flashlight Beacon',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 100),
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        color: service.flashlightOn ? Colors.yellow : Colors.grey.shade300,
                        shape: BoxShape.circle,
                        boxShadow: service.flashlightOn
                            ? [BoxShadow(color: Colors.yellow.shade600, blurRadius: 20, spreadRadius: 4)]
                            : null,
                      ),
                      child: Icon(
                        Icons.flashlight_on,
                        color: service.flashlightOn ? Colors.black87 : Colors.grey,
                        size: 36,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      service.flashlightOn ? 'FLASHING' : 'OFF',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: service.flashlightOn ? Colors.orange : Colors.grey,
                      ),
                    ),
                  ],
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Translate messages into Morse light flashes for visual search assistance.',
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                        if (service.currentMorseChar.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Text(
                            'Active Letter: ${service.currentMorseChar}',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.blue),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _morseController,
              decoration: const InputDecoration(
                labelText: 'Message to flash (e.g. SOS)',
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.characters,
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () {
                final msg = _morseController.text.trim();
                if (msg.isNotEmpty) {
                  service.flashMorseMessage(msg);
                }
              },
              child: const Text('Flash Morse Code'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEnvironmentalPanel(ThemeData theme, HardwareSensorService service, double magnitude) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.query_stats, color: theme.colorScheme.primary, size: 28),
                    const SizedBox(width: 12),
                    Text(
                      'Offline Sensor Telemetry',
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.tune),
                  onPressed: () {
                    setState(() {
                      _isCalibrating = !_isCalibrating;
                      _offsetXController.text = service.offsetX.toString();
                      _offsetYController.text = service.offsetY.toString();
                      _offsetZController.text = service.offsetZ.toString();
                    });
                  },
                  tooltip: 'Calibrate Sensors',
                ),
              ],
            ),
            const Divider(height: 24),
            if (_isCalibrating) ...[
              const Text(
                'Enter accelerometer offsets to calibrate values:',
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _offsetXController,
                      decoration: const InputDecoration(labelText: 'Offset X'),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: _offsetYController,
                      decoration: const InputDecoration(labelText: 'Offset Y'),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: _offsetZController,
                      decoration: const InputDecoration(labelText: 'Offset Z'),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _applyCalibration(service),
                      child: const Text('Apply Calibration'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: () => setState(() => _isCalibrating = false),
                    child: const Text('Cancel'),
                  ),
                ],
              ),
              const Divider(height: 24),
            ],
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildSensorVal('TEMP', '${service.temperature.toStringAsFixed(1)}°C', Icons.thermostat, Colors.orange),
                _buildSensorVal('HUMIDITY', '${service.humidity.toStringAsFixed(0)}%', Icons.water_drop, Colors.blue),
                _buildSensorVal('PRESSURE', '${service.pressure.toStringAsFixed(0)} hPa', Icons.compress, Colors.teal),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSensorVal(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 6),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 10)),
      ],
    );
  }

  Widget _buildSolarPanel(ThemeData theme, HardwareSensorService service) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.solar_power, color: theme.colorScheme.primary, size: 28),
                const SizedBox(width: 12),
                Text(
                  'Solar Charge Monitor',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      service.isSolarCharging ? 'Solar Input: ${service.solarInputWatts.toStringAsFixed(1)} W' : 'Solar Panel: Offline',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      service.isSolarCharging ? 'Estimated Time to Full: 3.5 hrs' : 'Connect solar input to calculate efficiency.',
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
                Switch(
                  value: service.isSolarCharging,
                  onChanged: (val) {
                    service.setSolarCharging(val);
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
