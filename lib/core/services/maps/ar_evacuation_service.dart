import 'package:flutter/foundation.dart';

class ArHazardAnchor {
  final String id;
  final String title;
  final String description;
  final double bearing; // Absolute direction angle in degrees (0 - 360)
  final double distanceMeters;
  final String hazardType; // 'FIRE', 'FLOOD', 'COLLAPSE', 'BLOCKAGE'

  const ArHazardAnchor({
    required this.id,
    required this.title,
    required this.description,
    required this.bearing,
    required this.distanceMeters,
    required this.hazardType,
  });
}

class ArEvacuationService extends ChangeNotifier {
  double _deviceBearing = 0.0; // Simulated device compass angle (0 - 360)
  final double _safeExitBearing = 140.0; // Hardcoded safe route heading
  final List<ArHazardAnchor> _anchors = [];

  double get deviceBearing => _deviceBearing;
  double get safeExitBearing => _safeExitBearing;
  List<ArHazardAnchor> get anchors => _anchors;

  void initialize() {
    _anchors.clear();
    // Populate standard crisis scenario hazards
    _anchors.addAll([
      const ArHazardAnchor(
        id: 'hazard_1',
        title: 'Active Fire Zone',
        description: 'Structural building fire, smoke plume.',
        bearing: 45.0,
        distanceMeters: 120.0,
        hazardType: 'FIRE',
      ),
      const ArHazardAnchor(
        id: 'hazard_2',
        title: 'Collapsed Overpass',
        description: 'Road blocked, concrete debris.',
        bearing: 270.0,
        distanceMeters: 350.0,
        hazardType: 'COLLAPSE',
      ),
      const ArHazardAnchor(
        id: 'hazard_3',
        title: 'Flash Flood Zone',
        description: 'Water depth 1.5m, fast currents.',
        bearing: 320.0,
        distanceMeters: 80.0,
        hazardType: 'FLOOD',
      ),
    ]);
  }

  void setDeviceBearing(double bearing) {
    // Normalize degree value between 0 and 360
    var norm = bearing % 360.0;
    if (norm < 0) norm += 360.0;
    _deviceBearing = norm;
    notifyListeners();
  }

  /// Calculates relative horizontal offset mapping of anchor relative to the device viewport center.
  /// Screen offset coordinate runs from -1.0 (left edge of screen) to +1.0 (right edge of screen).
  /// Returns null if the anchor is outside the current Field of View (FOV).
  double? calculateHorizontalScreenOffset(double anchorBearing, double fovDegrees) {
    var delta = anchorBearing - _deviceBearing;

    // Normalize delta to [-180, 180]
    while (delta < -180.0) {
      delta += 360.0;
    }
    while (delta > 180.0) {
      delta -= 360.0;
    }

    final halfFov = fovDegrees / 2.0;
    if (delta.abs() > halfFov) {
      return null; // Outside camera view field
    }

    // Map delta angle proportionally to screen offset [-1.0, 1.0]
    return delta / halfFov;
  }

  /// Calculates delta angle to the safe exit path
  double getRelativeSafeExitDelta() {
    var delta = _safeExitBearing - _deviceBearing;
    while (delta < -180.0) {
      delta += 360.0;
    }
    while (delta > 180.0) {
      delta -= 360.0;
    }
    return delta;
  }
}
