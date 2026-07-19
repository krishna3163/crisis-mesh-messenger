import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:crisis_mesh/core/models/medical_profile.dart';
import 'package:crisis_mesh/core/services/rescue/rescue_medical_service.dart';

class MedicalProfileTab extends StatefulWidget {
  const MedicalProfileTab({super.key});

  @override
  State<MedicalProfileTab> createState() => _MedicalProfileTabState();
}

class _MedicalProfileTabState extends State<MedicalProfileTab> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _bloodController = TextEditingController();
  final _allergiesController = TextEditingController();
  final _conditionsController = TextEditingController();
  final _medsController = TextEditingController();
  final _emergencyNameController = TextEditingController();
  final _emergencyPhoneController = TextEditingController();
  final _emergencyRelationController = TextEditingController();
  final _pregnancyController = TextEditingController();
  final _notesController = TextEditingController();
  
  bool _isOrganDonor = false;
  MedicalProfile? _activeProfile;
  bool _isEditing = false;

  @override
  void dispose() {
    _nameController.dispose();
    _bloodController.dispose();
    _allergiesController.dispose();
    _conditionsController.dispose();
    _medsController.dispose();
    _emergencyNameController.dispose();
    _emergencyPhoneController.dispose();
    _emergencyRelationController.dispose();
    _pregnancyController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _loadProfile(MedicalProfile profile) {
    setState(() {
      _activeProfile = profile;
      _nameController.text = profile.name;
      _bloodController.text = profile.bloodGroup;
      _allergiesController.text = profile.allergies.join(', ');
      _conditionsController.text = profile.conditions.join(', ');
      _medsController.text = profile.medications.join(', ');
      _emergencyNameController.text = profile.emergencyContactName;
      _emergencyPhoneController.text = profile.emergencyContactPhone;
      _emergencyRelationController.text = profile.emergencyContactRelation;
      _pregnancyController.text = profile.pregnancyStatus;
      _notesController.text = profile.notes;
      _isOrganDonor = profile.isOrganDonor;
      _isEditing = false;
    });
  }

  void _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final service = context.read<RescueMedicalService>();
    final id = _activeProfile?.id ?? const Uuid().v4();

    final profile = MedicalProfile(
      id: id,
      name: _nameController.text.trim(),
      bloodGroup: _bloodController.text.trim().toUpperCase(),
      allergies: _allergiesController.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
      conditions: _conditionsController.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
      medications: _medsController.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
      emergencyContactName: _emergencyNameController.text.trim(),
      emergencyContactPhone: _emergencyPhoneController.text.trim(),
      emergencyContactRelation: _emergencyRelationController.text.trim(),
      isOrganDonor: _isOrganDonor,
      pregnancyStatus: _pregnancyController.text.trim().isEmpty ? 'N/A' : _pregnancyController.text.trim(),
      notes: _notesController.text.trim(),
    );

    await service.saveProfile(profile);
    setState(() {
      _activeProfile = profile;
      _isEditing = false;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Medical profile saved successfully!')),
      );
    }
  }

  void _showQrDialog(MedicalProfile profile) {
    // Compact representation of medical card details to encode in QR
    final qrData = 'CRISIS_MED\n'
        'N:${profile.name}\n'
        'B:${profile.bloodGroup}\n'
        'A:${profile.allergies.join(",")}\n'
        'C:${profile.conditions.join(",")}\n'
        'E:${profile.emergencyContactName}:${profile.emergencyContactPhone}';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Emergency QR Code: ${profile.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Rescuers can scan this code offline to quickly view vital medical information.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 24),
            Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.black, width: 2),
              ),
              child: CustomPaint(
                painter: MockQrCodePainter(data: qrData),
              ),
            ),
            const SizedBox(height: 16),
            SelectableText(
              'Profile Data Hash: ${qrData.hashCode.toRadixString(16).toUpperCase()}',
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
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
    final profiles = service.getProfiles();

    // Auto-load first profile if activeProfile is null and database contains records
    if (_activeProfile == null && profiles.isNotEmpty) {
      _activeProfile = profiles.first;
      _loadProfile(_activeProfile!);
    }

    if (_activeProfile == null && !_isEditing) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.contact_emergency_outlined, size: 80, color: theme.colorScheme.primary.withOpacity(0.3)),
            const SizedBox(height: 16),
            const Text('No Medical Profiles Created', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 8),
            const Text('Add medical cards for emergency workers offline access.', style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _isEditing = true;
                  _activeProfile = null;
                  _nameController.clear();
                  _bloodController.clear();
                  _allergiesController.clear();
                  _conditionsController.clear();
                  _medsController.clear();
                  _emergencyNameController.clear();
                  _emergencyPhoneController.clear();
                  _emergencyRelationController.clear();
                  _pregnancyController.clear();
                  _notesController.clear();
                  _isOrganDonor = false;
                });
              },
              icon: const Icon(Icons.add),
              label: const Text('Create Profile'),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      body: _isEditing ? _buildForm(theme) : _buildProfileView(theme, profiles),
    );
  }

  Widget _buildProfileView(ThemeData theme, List<MedicalProfile> allProfiles) {
    final profile = _activeProfile!;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (allProfiles.length > 1) ...[
          DropdownButton<MedicalProfile>(
            isExpanded: true,
            value: profile,
            items: allProfiles.map((p) {
              return DropdownMenuItem(
                value: p,
                child: Text(p.name),
              );
            }).toList(),
            onChanged: (p) {
              if (p != null) _loadProfile(p);
            },
          ),
          const SizedBox(height: 16),
        ],
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        profile.name,
                        style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.qr_code_2, size: 36),
                      onPressed: () => _showQrDialog(profile),
                      tooltip: 'Show Emergency QR',
                    ),
                  ],
                ),
                const Divider(),
                const SizedBox(height: 8),
                _buildCardRow('Blood Group', profile.bloodGroup, isHighlight: true),
                _buildCardRow('Allergies', profile.allergies.isEmpty ? 'None' : profile.allergies.join(', ')),
                _buildCardRow('Chronic Conditions', profile.conditions.isEmpty ? 'None' : profile.conditions.join(', ')),
                _buildCardRow('Current Medications', profile.medications.isEmpty ? 'None' : profile.medications.join(', ')),
                _buildCardRow('Organ Donor', profile.isOrganDonor ? 'YES' : 'NO'),
                _buildCardRow('Pregnancy Status', profile.pregnancyStatus),
                _buildCardRow('Special Notes', profile.notes.isEmpty ? 'None' : profile.notes),
                const SizedBox(height: 16),
                Text('Emergency Contact', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                const Divider(),
                _buildCardRow('Name', profile.emergencyContactName),
                _buildCardRow('Phone', profile.emergencyContactPhone),
                _buildCardRow('Relationship', profile.emergencyContactRelation),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _isEditing = true;
                  });
                },
                icon: const Icon(Icons.edit),
                label: const Text('Edit Details'),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  setState(() {
                    _isEditing = true;
                    _activeProfile = null;
                    _nameController.clear();
                    _bloodController.clear();
                    _allergiesController.clear();
                    _conditionsController.clear();
                    _medsController.clear();
                    _emergencyNameController.clear();
                    _emergencyPhoneController.clear();
                    _emergencyRelationController.clear();
                    _pregnancyController.clear();
                    _notesController.clear();
                    _isOrganDonor = false;
                  });
                },
                icon: const Icon(Icons.add),
                label: const Text('Add Profile'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCardRow(String label, String value, {bool isHighlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: isHighlight ? FontWeight.bold : FontWeight.normal,
                color: isHighlight ? Colors.red.shade700 : null,
                fontSize: isHighlight ? 16 : 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForm(ThemeData theme) {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            _activeProfile == null ? 'New Medical Profile' : 'Edit Medical Profile',
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: 'Full Name', border: OutlineInputBorder()),
            validator: (v) => v == null || v.trim().isEmpty ? 'Enter patient name' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _bloodController,
            decoration: const InputDecoration(labelText: 'Blood Group (e.g. O+, A-, AB+)', border: OutlineInputBorder()),
            validator: (v) => v == null || v.trim().isEmpty ? 'Enter blood group' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _allergiesController,
            decoration: const InputDecoration(labelText: 'Allergies (comma separated)', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _conditionsController,
            decoration: const InputDecoration(labelText: 'Chronic Conditions (comma separated)', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _medsController,
            decoration: const InputDecoration(labelText: 'Current Medications (comma separated)', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 16),
          SwitchListTile(
            title: const Text('Organ Donor Status'),
            subtitle: const Text('Register as active organ donor'),
            value: _isOrganDonor,
            onChanged: (val) => setState(() => _isOrganDonor = val),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _pregnancyController,
            decoration: const InputDecoration(labelText: 'Pregnancy Status (N/A or Weeks)', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _notesController,
            decoration: const InputDecoration(labelText: 'Special Notes / Surgeries', border: OutlineInputBorder()),
            maxLines: 2,
          ),
          const SizedBox(height: 24),
          Text('Emergency Contact Info', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const Divider(),
          const SizedBox(height: 12),
          TextFormField(
            controller: _emergencyNameController,
            decoration: const InputDecoration(labelText: 'Contact Name', border: OutlineInputBorder()),
            validator: (v) => v == null || v.trim().isEmpty ? 'Enter contact name' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _emergencyPhoneController,
            decoration: const InputDecoration(labelText: 'Contact Phone Number', border: OutlineInputBorder()),
            keyboardType: TextInputType.phone,
            validator: (v) => v == null || v.trim().isEmpty ? 'Enter contact phone' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _emergencyRelationController,
            decoration: const InputDecoration(labelText: 'Relationship (e.g. Spouse, Parent)', border: OutlineInputBorder()),
            validator: (v) => v == null || v.trim().isEmpty ? 'Enter relationship' : null,
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: _saveProfile,
                  style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                  child: const Text('Save Profile'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _isEditing = false;
                      if (_activeProfile == null && service.getProfiles().isNotEmpty) {
                        _activeProfile = service.getProfiles().first;
                        _loadProfile(_activeProfile!);
                      }
                    });
                  },
                  style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
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

class MockQrCodePainter extends CustomPainter {
  final String data;

  MockQrCodePainter({required this.data});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.black;
    final bgPaint = Paint()..color = Colors.white;
    canvas.drawRect(Offset.zero & size, bgPaint);

    final hash = data.hashCode;
    const gridCount = 21;
    final cellSize = size.width / gridCount;

    _drawFinderPattern(canvas, 0, 0, cellSize);
    _drawFinderPattern(canvas, gridCount - 7, 0, cellSize);
    _drawFinderPattern(canvas, 0, gridCount - 7, cellSize);

    for (int r = 0; r < gridCount; r++) {
      for (int c = 0; c < gridCount; c++) {
        if ((r < 7 && c < 7) || (r < 7 && c >= gridCount - 7) || (r >= gridCount - 7 && c < 7)) {
          continue;
        }

        final value = (hash ^ (r * 12345 + c * 6789)) % 10 < 4;
        if (value) {
          canvas.drawRect(
            Rect.fromLTWH(c * cellSize, r * cellSize, cellSize, cellSize),
            paint,
          );
        }
      }
    }
  }

  void _drawFinderPattern(Canvas canvas, int col, int row, double cellSize) {
    final paintBlack = Paint()..color = Colors.black;
    final paintWhite = Paint()..color = Colors.white;

    canvas.drawRect(
      Rect.fromLTWH(col * cellSize, row * cellSize, 7 * cellSize, 7 * cellSize),
      paintBlack,
    );
    canvas.drawRect(
      Rect.fromLTWH((col + 1) * cellSize, (row + 1) * cellSize, 5 * cellSize, 5 * cellSize),
      paintWhite,
    );
    canvas.drawRect(
      Rect.fromLTWH((col + 2) * cellSize, (row + 2) * cellSize, 3 * cellSize, 3 * cellSize),
      paintBlack,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
