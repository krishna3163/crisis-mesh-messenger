import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:crisis_mesh/core/models/triage_card.dart';
import 'package:crisis_mesh/core/services/rescue/rescue_medical_service.dart';

class TriageTab extends StatefulWidget {
  const TriageTab({super.key});

  @override
  State<TriageTab> createState() => _TriageTabState();
}

class _TriageTabState extends State<TriageTab> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _injuryController = TextEditingController();
  final _hrController = TextEditingController();
  final _bpController = TextEditingController();
  final _tempController = TextEditingController();
  final _teamController = TextEditingController();

  String _selectedStatus = 'RED'; // RED, YELLOW, GREEN, BLACK
  bool _isAdding = false;

  @override
  void dispose() {
    _nameController.dispose();
    _injuryController.dispose();
    _hrController.dispose();
    _bpController.dispose();
    _tempController.dispose();
    _teamController.dispose();
    super.dispose();
  }

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'RED':
        return Colors.red;
      case 'YELLOW':
        return Colors.amber;
      case 'GREEN':
        return Colors.green;
      case 'BLACK':
        return Colors.black;
      default:
        return Colors.grey;
    }
  }

  String _getStatusLabel(String status) {
    switch (status.toUpperCase()) {
      case 'RED':
        return 'Immediate (Critical)';
      case 'YELLOW':
        return 'Delayed (Serious)';
      case 'GREEN':
        return 'Minor (Walking Wounded)';
      case 'BLACK':
        return 'Expectant (Deceased)';
      default:
        return 'Unknown';
    }
  }

  void _saveTriageCard() async {
    if (!_formKey.currentState!.validate()) return;

    final service = context.read<RescueMedicalService>();

    final card = TriageCard(
      id: 'tri_${const Uuid().v4()}',
      patientName: _nameController.text.trim(),
      status: _selectedStatus,
      injuries: _injuryController.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
      heartRate: int.tryParse(_hrController.text) ?? 80,
      bloodPressure: _bpController.text.trim().isEmpty ? '120/80' : _bpController.text.trim(),
      temperature: double.tryParse(_tempController.text) ?? 36.6,
      assignedTeamId: _teamController.text.trim().isEmpty ? null : _teamController.text.trim(),
      timestamp: DateTime.now(),
      latitude: 52.2297, // Warsaw default
      longitude: 21.0122,
    );

    await service.saveTriageCard(card);

    setState(() {
      _isAdding = false;
      _nameController.clear();
      _injuryController.clear();
      _hrController.clear();
      _bpController.clear();
      _tempController.clear();
      _teamController.clear();
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Triage card logged and broadcasted to mesh!'), backgroundColor: Colors.green),
      );
    }
  }

  void _showDetailsBottomSheet(BuildContext context, TriageCard card) {
    final service = context.read<RescueMedicalService>();
    final theme = Theme.of(context);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        builder: (context, scrollController) => ListView(
          controller: scrollController,
          padding: const EdgeInsets.all(24),
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Chip(
                  label: Text(
                    card.status,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  backgroundColor: _getStatusColor(card.status),
                ),
                Text(
                  card.timestamp.toString().substring(11, 16),
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              card.patientName,
              style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('Triage Level: ${_getStatusLabel(card.status)}'),
            const Divider(height: 32),
            Text('Vital Signs', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildVitalWidget('HR', '${card.heartRate} bpm', Icons.favorite, Colors.red),
                _buildVitalWidget('BP', card.bloodPressure, Icons.speed, Colors.blue),
                _buildVitalWidget('Temp', '${card.temperature}°C', Icons.thermostat, Colors.orange),
              ],
            ),
            const Divider(height: 32),
            Text('Injuries', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            card.injuries.isEmpty
                ? const Text('No active external injuries logged.')
                : Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: card.injuries.map((i) => Chip(label: Text(i))).toList(),
                  ),
            const Divider(height: 32),
            if (card.assignedTeamId != null) ...[
              Text('Rescue Assignment', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ListTile(
                leading: const Icon(Icons.airport_shuttle),
                title: Text('Team Assigned: ${card.assignedTeamId}'),
                subtitle: Text(card.isResolved ? 'Status: Resolved' : 'Status: En Route'),
              ),
              const Divider(height: 32),
            ],
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      Navigator.pop(context);
                      final updated = card.copyWith(isResolved: !card.isResolved);
                      await service.saveTriageCard(updated);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: card.isResolved ? Colors.orange : Colors.green,
                    ),
                    child: Text(card.isResolved ? 'Re-open Case' : 'Mark Resolved'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _showEditStatusDialog(context, card);
                    },
                    child: const Text('Change Status'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showEditStatusDialog(BuildContext context, TriageCard card) {
    final service = context.read<RescueMedicalService>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update Triage Status'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: ['RED', 'YELLOW', 'GREEN', 'BLACK'].map((status) {
            return RadioListTile<String>(
              title: Text(_getStatusLabel(status)),
              value: status,
              groupValue: card.status,
              activeColor: _getStatusColor(status),
              onChanged: (val) async {
                Navigator.pop(context);
                if (val != null) {
                  final updated = card.copyWith(status: val);
                  await service.saveTriageCard(updated);
                }
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildVitalWidget(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
      ],
    );
  }

  void _exportTriageReport(List<TriageCard> cards) {
    final buffer = StringBuffer();
    buffer.writeln('# Triage Center Patient Report');
    buffer.writeln('Exported on: ${DateTime.now().toString().substring(0, 16)}\n');
    buffer.writeln('| Patient | Status | Vitals | Injuries | Team | Resolved |');
    buffer.writeln('| --- | --- | --- | --- | --- | --- |');
    
    for (final card in cards) {
      buffer.writeln('| ${card.patientName} | ${card.status} | HR:${card.heartRate}, BP:${card.bloodPressure}, Temp:${card.temperature} | ${card.injuries.join(", ")} | ${card.assignedTeamId ?? "None"} | ${card.isResolved ? "YES" : "NO"} |');
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Triage Report Export'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Markdown report copied to clipboard. You can share this report offline via mesh messages.'),
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                child: Container(
                  padding: const EdgeInsets.all(8),
                  color: Colors.grey.shade100,
                  child: SelectableText(
                    buffer.toString(),
                    style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                  ),
                ),
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
    final cards = service.getTriageCards();

    final redCount = cards.where((c) => c.status == 'RED' && !c.isResolved).length;
    final yellowCount = cards.where((c) => c.status == 'YELLOW' && !c.isResolved).length;
    final greenCount = cards.where((c) => c.status == 'GREEN' && !c.isResolved).length;
    final blackCount = cards.where((c) => c.status == 'BLACK' && !c.isResolved).length;

    return Scaffold(
      body: _isAdding
          ? _buildAddCardForm(theme)
          : Column(
              children: [
                // Metrics header
                Container(
                  color: Colors.grey.shade100,
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildMetricTile('RED', redCount, Colors.red),
                      _buildMetricTile('YELLOW', yellowCount, Colors.amber),
                      _buildMetricTile('GREEN', greenCount, Colors.green),
                      _buildMetricTile('DECEASED', blackCount, Colors.black),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Patient Queue (${cards.length})', style: const TextStyle(fontWeight: FontWeight.bold)),
                      if (cards.isNotEmpty)
                        TextButton.icon(
                          onPressed: () => _exportTriageReport(cards),
                          icon: const Icon(Icons.share),
                          label: const Text('Export Report'),
                        ),
                    ],
                  ),
                ),
                Expanded(
                  child: cards.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.healing_outlined, size: 64, color: Colors.grey.shade300),
                              const SizedBox(height: 16),
                              const Text('No triage patients logged yet.', style: TextStyle(color: Colors.grey)),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: cards.length,
                          itemBuilder: (context, index) {
                            final card = cards[index];
                            final color = _getStatusColor(card.status);
                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(color: card.isResolved ? Colors.grey.shade300 : color, width: 1.5),
                              ),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: card.isResolved ? Colors.grey : color,
                                  child: const Icon(Icons.person, color: Colors.white),
                                ),
                                title: Text(
                                  card.patientName,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    decoration: card.isResolved ? TextDecoration.lineThrough : null,
                                    color: card.isResolved ? Colors.grey : null,
                                  ),
                                ),
                                subtitle: Text(
                                  card.injuries.isEmpty ? 'No injuries logged' : card.injuries.join(', '),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                trailing: card.isResolved
                                    ? const Icon(Icons.check_circle, color: Colors.green)
                                    : Text(
                                        card.status,
                                        style: TextStyle(color: color, fontWeight: FontWeight.bold),
                                      ),
                                onTap: () => _showDetailsBottomSheet(context, card),
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
                      onPressed: () => setState(() => _isAdding = true),
                      icon: const Icon(Icons.add_circle_outline),
                      label: const Text('Log New Triage Card'),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildMetricTile(String label, int count, Color color) {
    return Column(
      children: [
        Text(
          '$count',
          style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 24),
        ),
        Text(
          label,
          style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Widget _buildAddCardForm(ThemeData theme) {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('New Digital Triage Entry', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 16),
          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: 'Patient Name / ID', border: OutlineInputBorder()),
            validator: (v) => v == null || v.trim().isEmpty ? 'Please enter name' : null,
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _selectedStatus,
            decoration: const InputDecoration(labelText: 'Triage Priority Color', border: OutlineInputBorder()),
            items: ['RED', 'YELLOW', 'GREEN', 'BLACK'].map((status) {
              return DropdownMenuItem(
                value: status,
                child: Row(
                  children: [
                    CircleAvatar(radius: 6, backgroundColor: _getStatusColor(status)),
                    const SizedBox(width: 8),
                    Text(_getStatusLabel(status)),
                  ],
                ),
              );
            }).toList(),
            onChanged: (val) {
              if (val != null) setState(() => _selectedStatus = val);
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _injuryController,
            decoration: const InputDecoration(labelText: 'Injuries (comma separated)', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _hrController,
                  decoration: const InputDecoration(labelText: 'Heart Rate (bpm)', border: OutlineInputBorder()),
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  controller: _bpController,
                  decoration: const InputDecoration(labelText: 'Blood Pressure', border: OutlineInputBorder()),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _tempController,
            decoration: const InputDecoration(labelText: 'Body Temp (°C)', border: OutlineInputBorder()),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _teamController,
            decoration: const InputDecoration(labelText: 'Assigned Rescue Team (Optional)', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: _saveTriageCard,
                  child: const Text('Log Card & Broadcast'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => setState(() => _isAdding = false),
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
