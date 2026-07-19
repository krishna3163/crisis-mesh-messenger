import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:crisis_mesh/core/services/maps/map_service.dart';
import 'package:crisis_mesh/core/services/maps/cached_tile_provider.dart';
import 'package:crisis_mesh/core/services/rescue/emergency_service.dart';
import 'package:crisis_mesh/features/maps/ui/screens/ar_evacuation_screen.dart';

class MapScreen extends StatelessWidget {
  const MapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final mapService = context.watch<MapService>();
    final emergencyService = context.watch<EmergencyService>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Offline Map'),
        actions: [
          IconButton(
            icon: const Icon(Icons.videocam_outlined),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const ArEvacuationScreen(),
                ),
              );
            },
            tooltip: 'AR Evacuation Overlay',
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => _showCacheSettingsDialog(context, mapService),
            tooltip: 'Offline Cache Settings',
          ),
        ],
      ),
      body: FlutterMap(
        options: MapOptions(
          initialCenter: mapService.center,
          initialZoom: mapService.zoom,
          onPositionChanged: (position, hasGesture) {
            if (hasPositionChanged(position, mapService)) {
               // mapService.updateCenter(position.center!); // Avoid loop if watch is active
            }
          },
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.crisis.mesh',
            tileProvider: mapService.cachePath != null
                ? CachedTileProvider(cacheDirPath: mapService.cachePath!)
                : const NetworkTileProvider(),
          ),
          MarkerLayer(
            markers: [
              ..._buildEmergencyMarkers(context, emergencyService),
              _buildUserMarker(mapService.center),
            ],
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: 'map_sos',
            onPressed: () {
               // Quick SOS from map
            },
            backgroundColor: Colors.red,
            child: const Icon(Icons.emergency, color: Colors.white),
          ),
          const SizedBox(height: 16),
          FloatingActionButton(
            heroTag: 'map_center',
            onPressed: () {
               mapService.updateCenter(mapService.center); // Trigger redraw or realign
            },
            child: const Icon(Icons.my_location),
          ),
        ],
      ),
    );
  }

  void _showCacheSettingsDialog(BuildContext context, MapService service) {
    final size = service.getCacheSize();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Offline Map Cache'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Map tiles are automatically cached locally as you view different sectors of the map while online.'),
            const SizedBox(height: 16),
            Text('Current Cache Size: ${size.toStringAsFixed(2)} MB', style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await service.clearCache();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Offline map cache cleared!')),
                );
              }
            },
            child: const Text('Clear Cache', style: TextStyle(color: Colors.red)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  bool hasPositionChanged(MapCamera position, MapService service) {
    return (position.center.latitude - service.center.latitude).abs() > 0.0001 ||
           (position.center.longitude - service.center.longitude).abs() > 0.0001;
  }

  List<Marker> _buildEmergencyMarkers(BuildContext context, EmergencyService service) {
    return service.activeSignals.where((s) => s.latitude != null && s.longitude != null).map((signal) {
      return Marker(
        point: LatLng(signal.latitude!, signal.longitude!),
        width: 40,
        height: 40,
        child: GestureDetector(
          onTap: () => _showSignalInfo(context, signal),
          child: const Icon(
            Icons.warning,
            color: Colors.red,
            size: 32,
          ),
        ),
      );
    }).toList();
  }

  Marker _buildUserMarker(LatLng center) {
    return Marker(
      point: center,
      width: 40,
      height: 40,
      child: const Icon(
        Icons.person_pin_circle,
        color: Colors.blue,
        size: 40,
      ),
    );
  }

  void _showSignalInfo(BuildContext context, EmergencySignal signal) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(signal.getIconData(), style: const TextStyle(fontSize: 32)),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    signal.getDescription(),
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text('From: ${signal.senderName}'),
            const SizedBox(height: 8),
            Text('Message: ${signal.message}'),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ),
          ],
        ),
      ),
    );
  }
