import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:crisis_mesh/core/models/offline_email.dart';
import 'package:crisis_mesh/core/services/mesh/mesh_routing_service.dart';

class OfflineEmailScreen extends StatefulWidget {
  const OfflineEmailScreen({super.key});

  @override
  State<OfflineEmailScreen> createState() => _OfflineEmailScreenState();
}

class _OfflineEmailScreenState extends State<OfflineEmailScreen> {
  final _formKey = GlobalKey<FormState>();
  final _recipientController = TextEditingController();
  final _subjectController = TextEditingController();
  final _bodyController = TextEditingController();
  bool _isComposing = false;

  @override
  void dispose() {
    _recipientController.dispose();
    _subjectController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  void _sendEmail() async {
    if (!_formKey.currentState!.validate()) return;

    final routingService = context.read<MeshRoutingService>();

    setState(() => _isComposing = false);

    await routingService.sendOfflineEmail(
      _recipientController.text.trim(),
      _subjectController.text.trim(),
      _bodyController.text.trim(),
    );

    _recipientController.clear();
    _subjectController.clear();
    _bodyController.clear();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Email queued for store-and-forward mesh delivery!'),
          backgroundColor: Colors.blueAccent,
        ),
      );
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'SENT':
        return Colors.green;
      case 'RELAYED':
        return Colors.orange;
      case 'QUEUED':
      default:
        return Colors.blue;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final routingService = context.watch<MeshRoutingService>();
    final emails = routingService.getEmails();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Offline Mail Client'),
      ),
      body: Column(
        children: [
          // Gateway Simulation Header
          Container(
            color: theme.colorScheme.primaryContainer.withOpacity(0.4),
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.router, color: theme.colorScheme.primary, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Internet Backhaul Gateway',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        routingService.isGateway
                            ? 'Simulating Active connection. Dispatching mail to SMTP...'
                            : 'Offline mesh mode. Emails carry node-to-node.',
                        style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: routingService.isGateway,
                  onChanged: (val) {
                    routingService.setGatewayStatus(val);
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: _isComposing
                ? _buildComposeForm(theme)
                : _buildEmailList(theme, emails, routingService),
          ),
        ],
      ),
    );
  }

  Widget _buildEmailList(ThemeData theme, List<OfflineEmail> emails, MeshRoutingService service) {
    final bestRoutes = service.getBestRelayRoutes();

    return Column(
      children: [
        // Routing statistics summary
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Available Relay Paths (${bestRoutes.length})',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              if (bestRoutes.isNotEmpty)
                Tooltip(
                  message: 'Routes prioritized by high battery and relay capacity.',
                  child: Icon(Icons.info_outline, size: 18, color: theme.colorScheme.primary),
                ),
            ],
          ),
        ),
        if (bestRoutes.isNotEmpty)
          SizedBox(
            height: 50,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: bestRoutes.length,
              itemBuilder: (context, index) {
                final node = bestRoutes[index];
                return Container(
                  margin: const EdgeInsets.only(right: 8),
                  child: Chip(
                    avatar: Icon(
                      node.peerType == 'DRONE_RELAY'
                          ? Icons.flight
                          : (node.peerType == 'VEHICLE_RELAY' ? Icons.directions_car : Icons.smartphone),
                      size: 14,
                    ),
                    label: Text('${node.name} (${node.batteryLevel}%)'),
                    backgroundColor: theme.colorScheme.secondaryContainer.withOpacity(0.3),
                  ),
                );
              },
            ),
          ),
        const Divider(),
        Expanded(
          child: emails.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.mail_outline, size: 64, color: theme.colorScheme.primary.withOpacity(0.3)),
                      const SizedBox(height: 16),
                      const Text(
                        'No emails drafted or queued.',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: emails.length,
                  itemBuilder: (context, index) {
                    final email = emails[index];
                    final color = _getStatusColor(email.status);

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ExpansionTile(
                        leading: CircleAvatar(
                          backgroundColor: color.withOpacity(0.1),
                          child: Icon(Icons.mail, color: color),
                        ),
                        title: Text(email.subject, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('To: ${email.recipientEmail}'),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            email.status,
                            style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 11),
                          ),
                        ),
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('From: ${email.senderEmail}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                                const SizedBox(height: 8),
                                Text(email.body, style: const TextStyle(fontSize: 14)),
                                const Divider(height: 24),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Mesh Hops: ${email.hopCount}',
                                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                                    ),
                                    Text(
                                      'Path: ${email.routePath.join(" → ")}',
                                      style: const TextStyle(fontSize: 11, fontFamily: 'monospace', color: Colors.blue),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
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
              onPressed: () => setState(() => _isComposing = true),
              icon: const Icon(Icons.edit),
              label: const Text('Draft Offline Email'),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildComposeForm(ThemeData theme) {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Draft Offline Email',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _recipientController,
            decoration: const InputDecoration(
              labelText: 'Recipient Email (e.g. contact@domain.com)',
              border: OutlineInputBorder(),
            ),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Enter recipient email';
              if (!v.contains('@')) return 'Enter a valid email address';
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _subjectController,
            decoration: const InputDecoration(
              labelText: 'Subject',
              border: OutlineInputBorder(),
            ),
            validator: (v) => v == null || v.trim().isEmpty ? 'Enter subject' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _bodyController,
            decoration: const InputDecoration(
              labelText: 'Email Body',
              border: OutlineInputBorder(),
            ),
            maxLines: 5,
            validator: (v) => v == null || v.trim().isEmpty ? 'Enter email body' : null,
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: _sendEmail,
                  child: const Text('Queue Mail'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => setState(() => _isComposing = false),
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
