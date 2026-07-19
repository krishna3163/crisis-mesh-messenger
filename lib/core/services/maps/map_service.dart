import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';
import 'package:path_provider/path_provider.dart';

/// Service for managing map state and offline marker data
class MapService extends ChangeNotifier {
  LatLng _center = const LatLng(52.2297, 21.0122); // Default center (Warsaw)
  double _zoom = 13.0;
  bool _isFollowUserEnabled = true;
  String? _cachePath;

  LatLng get center => _center;
  double get zoom => _zoom;
  bool get isFollowUserEnabled => _isFollowUserEnabled;
  String? get cachePath => _cachePath;

  /// Update map center
  void updateCenter(LatLng newCenter) {
    _center = newCenter;
    notifyListeners();
  }

  /// Update zoom level
  void updateZoom(double newZoom) {
    _zoom = newZoom;
    notifyListeners();
  }

  /// Toggle user following
  void setFollowUser(bool enabled) {
    _isFollowUserEnabled = enabled;
    notifyListeners();
  }

  /// Setup offline tile directory and default center
  Future<void> initialize() async {
    try {
      final appSupportDir = await getApplicationSupportDirectory();
      _cachePath = '${appSupportDir.path}/map_tiles';
      final dir = Directory(_cachePath!);
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
    } catch (e) {
      debugPrint('Failed to initialize map cache directory: $e');
    }

    _center = const LatLng(52.2297, 21.0122); // Warsaw
    notifyListeners();
  }

  /// Get offline cache directory size in MB
  double getCacheSize() {
    if (_cachePath == null) return 0.0;
    try {
      final dir = Directory(_cachePath!);
      if (!dir.existsSync()) return 0.0;

      int totalBytes = 0;
      final files = dir.listSync(recursive: true);
      for (final file in files) {
        if (file is File) {
          totalBytes += file.lengthSync();
        }
      }
      return totalBytes / (1024 * 1024); // Convert to MB
    } catch (e) {
      debugPrint('Error calculating map cache size: $e');
      return 0.0;
    }
  }

  /// Clear map tiles cache
  Future<void> clearCache() async {
    if (_cachePath == null) return;
    try {
      final dir = Directory(_cachePath!);
      if (await dir.exists()) {
        await dir.delete(recursive: true);
        await dir.create(recursive: true);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error clearing map cache: $e');
    }
  }
}
