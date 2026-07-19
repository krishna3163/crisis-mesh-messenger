import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:crisis_mesh/core/services/mesh/mesh_network_service.dart';
import 'package:crisis_mesh/core/services/mesh/gateway_service.dart';

class NetworkStatusScreen extends StatelessWidget {
  const NetworkStatusScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final meshService = context.watch<MeshNetworkService>();
    final gatewayService = context.watch<GatewayService>();

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Network status'),
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.hub), text: 'Mesh Connections'),
              Tab(icon: Icon(Icons.router), text: 'Hardware Gateways'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildMeshConnectionsTab(context, meshService),
            _buildHardwareGatewaysTab(context, theme, gatewayService),
          ],
        ),
      ),
    );
  }

  Widget _buildMeshConnectionsTab(BuildContext context, MeshNetworkService meshService) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildStatusCard(
          context,
          'Mesh Status',
          [
            _statusRow('Scanning', meshService.isScanning ? 'Active' : 'Inactive'),
            _statusRow('Advertising', meshService.isAdvertising ? 'Active' : 'Inactive'),
            _statusRow('Device ID', meshService.deviceId ?? 'Not set'),
            _statusRow('Device Name', meshService.deviceName ?? 'Not set'),
          ],
        ),
        const SizedBox(height: 16),
        _buildStatusCard(
          context,
          'Connected Peers',
          [
            _statusRow('Total Peers', '${meshService.peers.length}'),
            _statusRow('Online', '${meshService.onlinePeers.length}'),
            _statusRow('Nearby', '${meshService.peers.where((p) => p.status.name == 'nearby').length}'),
          ],
        ),
        const SizedBox(height: 16),
        _buildPeersList(context, meshService),
      ],
    );
  }

  Widget _buildHardwareGatewaysTab(BuildContext context, ThemeData theme, GatewayService service) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Title info
        const Text(
          'Infrastructure Backhaul Gateways',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        const SizedBox(height: 4),
        const Text(
          'Manage external radio and satellite links connected to this device.',
          style: TextStyle(color: Colors.grey, fontSize: 12),
        ),
        const Divider(height: 32),

        // 1. Cellular Gateway Switch
        _buildGatewayToggleCard(
          theme,
          title: 'Cellular/Wi-Fi Interface',
          subtitle: 'Direct public internet access.',
          value: service.cellularConnected,
          onChanged: (val) => service.setCellularStatus(val),
          icon: Icons.cell_tower,
        ),
        const SizedBox(height: 12),

        // 2. LoRa Gateway Switch
        _buildGatewayToggleCard(
          theme,
          title: 'Sub-GHz LoRa Radio Module',
          subtitle: 'Paired transceiver (256-byte text chunking).',
          value: service.loraConnected,
          onChanged: (val) => service.setLoraStatus(val),
          icon: Icons.radio,
        ),
        const SizedBox(height: 12),

        // 3. Satellite Gateway Switch
        _buildGatewayToggleCard(
          theme,
          title: 'Garmin InReach Terminal',
          subtitle: 'constellation links (80-byte binary compressor).',
          value: service.satelliteConnected,
          onChanged: (val) => service.setSatelliteStatus(val),
          icon: Icons.settings_input_antenna,
        ),
        const SizedBox(height: 24),

        // Test payload triggers
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  service.routePayload(
                    type: 'SOS',
                    message: 'CRITICAL EMERGENCY: Need rescue assistance.',
                    senderId: 'usr_loc',
                    lat: 45.1234,
                    lon: -73.5678,
                  );
                },
                icon: const Icon(Icons.send),
                label: const Text('Test SOS Upload'),
              ),
            ),
            const SizedBox(width: 12),
            OutlinedButton(
              onPressed: () => service.clearLogs(),
              child: const Text('Wipe Logs'),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Console Log Output
        const Text(
          'Transmission Console Logs',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Container(
          height: 180,
          decoration: BoxDecoration(
            color: Colors.black87,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white10),
          ),
          padding: const EdgeInsets.all(12),
          child: service.transmissionLogs.isEmpty
              ? const Center(child: Text('No transmissions logged.', style: TextStyle(color: Colors.grey, fontFamily: 'monospace')))
              : ListView.builder(
                  itemCount: service.transmissionLogs.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6.0),
                      child: Text(
                        service.transmissionLogs[index],
                        style: const TextStyle(
                          color: Colors.greenAccent,
                          fontFamily: 'monospace',
                          fontSize: 11,
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildGatewayToggleCard(
    ThemeData theme, {
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required IconData icon,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: value ? Colors.green.withOpacity(0.1) : theme.colorScheme.surfaceVariant,
              child: Icon(icon, color: value ? Colors.green : Colors.grey),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text(subtitle, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                ],
              ),
            ),
            Switch(
              value: value,
              onChanged: onChanged,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard(BuildContext context, String title, List<Widget> children) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _statusRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeersList(BuildContext context, MeshNetworkService meshService) {
    final peers = meshService.peers;

    if (peers.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Center(
            child: Column(
              children: [
                Icon(Icons.devices_other, size: 48, color: Colors.grey),
                const SizedBox(height: 16),
                const Text(
                  'No peers discovered yet',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'Discovered Devices',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: peers.length,
            itemBuilder: (context, index) {
              final peer = peers[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: peer.status == PeerStatus.online
                      ? Colors.green.shade100
                      : Colors.orange.shade100,
                  child: Icon(
                    peer.status == PeerStatus.online ? Icons.wifi : Icons.wifi_off,
                    color: peer.status == PeerStatus.online ? Colors.green : Colors.orange,
                  ),
                ),
                title: Text(peer.name),
                subtitle: Text('ID: ${peer.id.substring(0, peer.id.length > 8 ? 8 : peer.id.length)}'),
                trailing: Text(
                  peer.status.name.toUpperCase(),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: peer.status == PeerStatus.online ? Colors.green : Colors.orange,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
