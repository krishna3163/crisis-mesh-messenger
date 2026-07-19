import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter/material.dart';

/// Custom TileProvider that synchronously serves cached tiles offline
/// and asynchronously fetches/caches tiles when online.
class CachedTileProvider extends TileProvider {
  final String cacheDirPath;

  CachedTileProvider({required this.cacheDirPath});

  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) {
    final url = getTileUrl(coordinates, options);
    final localPath = _getLocalTilePath(coordinates);
    final file = File(localPath);

    if (file.existsSync()) {
      return FileImage(file);
    }

    // Download in the background and return NetworkImage
    _downloadAndCacheTile(url, file);
    return NetworkImage(url, headers: headers);
  }

  String _getLocalTilePath(TileCoordinates coords) {
    return '$cacheDirPath/${coords.z}/${coords.x}/${coords.y}.png';
  }

  Future<void> _downloadAndCacheTile(String url, File file) async {
    try {
      // Ensure the parent directory (z/x/) exists
      await file.parent.create(recursive: true);

      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 5);

      final request = await client.getUrl(Uri.parse(url));
      request.headers.setUserAgent('com.crisis.mesh');

      final response = await request.close();
      if (response.statusCode == 200) {
        final bytes = await response.fold<List<int>>([], (previous, element) => previous..addAll(element));
        await file.writeAsBytes(bytes);
        debugPrint('Cached map tile: ${file.path}');
      }
    } catch (e) {
      // Silently catch errors as we are expected to be offline frequently
      debugPrint('Map tile caching skipped (offline/timeout): $e');
    }
  }
}
