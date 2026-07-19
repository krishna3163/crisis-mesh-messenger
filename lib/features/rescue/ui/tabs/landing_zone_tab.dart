import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:crisis_mesh/core/models/landing_zone.dart';
import 'package:crisis_mesh/core/services/rescue/rescue_medical_service.dart';

class LandingZoneTab extends StatefulWidget {
  const LandingZoneTab({super.key});

  @override
  State<LandingZoneTab> createState() => _LandingZoneTabState();
}

class _LandingZoneTabState extends State<LandingZoneTab> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _slopeController = TextEditingController();
  final _sizeController = TextEditingController();
  
  String _selectedSurface = 'GRASS'; // CONCRETE, ASPHALT, GRASS, DIRT, SAND, OTHER
  bool _isEvaluating = false;

  @override
  void dispose() {
    _nameController.dispose();
    _slopeController.dispose();
    _sizeController.dispose();
    super.dispose();
  }

  void _saveLandingZone() async {
    if (!_formKey.currentState!.validate()) return;

    final service = context.read<RescueMedicalService>();

    final slope = double.tryParse(_slopeController.text) ?? 0.0;
    final size = double.tryParse(_sizeController.text) ?? 20.0;
    final score = service.calculateLandingZoneScore(slope, _selectedSurface, size);

    final lz = LandingZone(
      id: 'lz_${const Uuid().v4()}',
      name: _nameController.text.trim(),
      latitude: 52.2297 + (const Uuid().v4().hashCode % 100) * 0.0001, // Warsaw offsets
      longitude: 21.0122 + (const Uuid().v4().hashCode % 100) * 0.0001,
      slope: slope,
      surfaceType: _selectedSurface,
      sizeMeters: size,
      score: score,
      isMarked: false,
      timestamp: DateTime.now(),
    );

    await service.saveLandingZone(lz);

    setState(() {
      _isEvaluating = false;
      _nameController.clear();
      _slopeController.clear();
      _sizeController.clear();
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Landing Zone evaluated and saved!'), backgroundColor: Colors.green),
      );
    }
  }

  Color _getScoreColor(double score) {
    if (score >= 80) return Colors.green;
    if (score >= 50) return Colors.amber;
    return Colors.red;
  }

  String _getRecommendation(double score, String surface, double size) {
    if (score >= 80) {
      return 'Excellent. Fully suitable for heavy transport (e.g. Chinook) and rescue helicopters.';
    } else if (score >= 50) {
      if (size < 20) {
        return 'Marginal. Suitable for light/medium utility helicopters only (e.g. Bell 206) due to size limitations.';
      }
      return 'Marginal. Ground slope or surface texture requires caution. Best for experienced pilots.';
    } else {
      if (slopeExceeded(slope: score)) {
        return 'Dangerous. Surface slope exceeds the safe 15-degree threshold.';
      }
      if (size < 15) {
        return 'Unsuitable. Area size is less than the minimum 15m safety diameter.';
      }
      return 'Dangerous. Surface type and obstacle profile present major safety hazards.';
    }
  }

  bool slopeExceeded({required double slope}) => slope == 0.0; // dummy mapping for helper

  void _shareCoordinates(LandingZone lz) {
    final text = 'HELICOPTER LANDING ZONE recommendation:\n'
        'Name: ${lz.name}\n'
        'GPS: ${lz.latitude.toStringAsFixed(5)}, ${lz.longitude.toStringAsFixed(5)}\n'
        'Surface: ${lz.surfaceType}\n'
        'Score: ${lz.score.toStringAsFixed(0)}/100';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Share Landing Site'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Share coordinates over mesh chat or emergency signals:'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(8),
              color: Colors.grey.shade100,
              child: SelectableText(
                text,
                style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final service = context.watch<RescueMedicalService>();
    final zones = service.getLandingZones();

    return Scaffold(
      body: _isEvaluating
          ? _buildEvaluationForm(theme)
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Assessed Landing Zones (${zones.length})', style: const TextStyle(fontWeight: FontWeight.bold)),
                      const Icon(Icons.flight_land, color: Colors.blue),
                    ],
                  ),
                ),
                Expanded(
                  child: zones.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.landscape, size: 64, color: Colors.grey.shade300),
                              const SizedBox(height: 16),
                              const Text('No landing zones evaluated yet.', style: TextStyle(color: Colors.grey)),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: zones.length,
                          itemBuilder: (context, index) {
                            final lz = zones[index];
                            final color = _getScoreColor(lz.score);
                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            lz.name,
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: color.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            '${lz.score.toStringAsFixed(0)} pts',
                                            style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 16),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'GPS Coords: ${lz.latitude.toStringAsFixed(5)}, ${lz.longitude.toStringAsFixed(5)}',
                                      style: const TextStyle(fontFamily: 'monospace', color: Colors.blue, fontSize: 12),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        _buildSpecBadge('Surface', lz.surfaceType),
                                        const SizedBox(width: 8),
                                        _buildSpecBadge('Slope', '${lz.slope}°'),
                                        const SizedBox(width: 8),
                                        _buildSpecBadge('Size', '${lz.sizeMeters}m'),
                                      ],
                                    ),
                                    const Divider(height: 24),
                                    Text(
                                      _getRecommendation(lz.score, lz.surfaceType, lz.sizeMeters),
                                      style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.share, color: Colors.blue),
                                          onPressed: () => _shareCoordinates(lz),
                                          tooltip: 'Export Coordinates',
                                        ),
                                        IconButton(
                                          icon: Icon(
                                            lz.isMarked ? Icons.pin_drop : Icons.pin_drop_outlined,
                                            color: lz.isMarked ? Colors.green : Colors.grey,
                                          ),
                                          onPressed: () async {
                                            final updated = lz.copyWith(isMarked: !lz.isMarked);
                                            await service.saveLandingZone(updated);
                                          },
                                          tooltip: 'Mark on Ground',
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => setState(() => _isEvaluating = true),
                      icon: const Icon(Icons.add_location_alt_outlined),
                      label: const Text('Evaluate New LZ Area'),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildSpecBadge(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Text(
        '$label: $value',
        style: const TextStyle(fontSize: 11, color: Colors.black87),
      ),
    );
  }

  Widget _buildEvaluationForm(ThemeData theme) {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Helicopter Landing Zone Suitability Analysis', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 16),
          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: 'Landing Site Location Name', border: OutlineInputBorder()),
            validator: (v) => v == null || v.trim().isEmpty ? 'Please enter name' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _slopeController,
            decoration: const InputDecoration(labelText: 'Ground Slope In Degrees (e.g. 0 to 30)', border: OutlineInputBorder()),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            validator: (v) => v == null || v.trim().isEmpty ? 'Please enter ground slope' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _sizeController,
            decoration: const InputDecoration(labelText: 'Clearing Size/Diameter in Meters (e.g. 10 to 50)', border: OutlineInputBorder()),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            validator: (v) => v == null || v.trim().isEmpty ? 'Please enter clearance diameter' : null,
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _selectedSurface,
            decoration: const InputDecoration(labelText: 'Surface Quality Type', border: OutlineInputBorder()),
            items: ['CONCRETE', 'ASPHALT', 'GRASS', 'DIRT', 'SAND', 'OTHER'].map((surface) {
              return DropdownMenuItem(
                value: surface,
                child: Text(surface),
              );
            }).toList(),
            onChanged: (val) {
              if (val != null) setState(() => _selectedSurface = val);
            },
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: _saveLandingZone,
                  child: const Text('Calculate & Log LZ'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => setState(() => _isEvaluating = false),
                  child: const Text('Cancel'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
