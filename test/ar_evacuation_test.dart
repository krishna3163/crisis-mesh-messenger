import 'package:flutter_test/flutter_test.dart';
import 'package:crisis_mesh/core/services/maps/ar_evacuation_service.dart';

void main() {
  late ArEvacuationService arService;

  setUp(() {
    arService = ArEvacuationService();
    arService.initialize();
  });

  test('Relative screen coordinate calculations project bearings onto screen correctly', () {
    const fov = 60.0;

    // 1. Device is facing 45° NE
    arService.setDeviceBearing(45.0);

    // Hazard at exactly 45° bearing -> should align perfectly at center (multiplier = 0.0)
    var offsetMultiplier = arService.calculateHorizontalScreenOffset(45.0, fov);
    expect(offsetMultiplier, 0.0);

    // Hazard at 75° (+30 degrees from device heading, which matches right edge of FOV) -> multiplier = 1.0
    offsetMultiplier = arService.calculateHorizontalScreenOffset(75.0, fov);
    expect(offsetMultiplier, 1.0);

    // Hazard at 15° (-30 degrees from device heading, which matches left edge of FOV) -> multiplier = -1.0
    offsetMultiplier = arService.calculateHorizontalScreenOffset(15.0, fov);
    expect(offsetMultiplier, -1.0);

    // Hazard at 90° (+45 degrees from device heading, which exceeds half-FOV limit of 30°) -> should return null (clipped)
    offsetMultiplier = arService.calculateHorizontalScreenOffset(90.0, fov);
    expect(offsetMultiplier, null);
  });

  test('Exit path calculations find shortest angle offset correctly', () {
    // Safe exit path is at bearing 140°
    expect(arService.safeExitBearing, 140.0);

    // 1. Device is facing 100°
    arService.setDeviceBearing(100.0);
    // Exit delta should be +40 degrees (turn right)
    expect(arService.getRelativeSafeExitDelta(), 40.0);

    // 2. Device is facing 180°
    arService.setDeviceBearing(180.0);
    // Exit delta should be -40 degrees (turn left)
    expect(arService.getRelativeSafeExitDelta(), -40.0);

    // 3. Wraparound boundaries: Device facing 10°
    arService.setDeviceBearing(10.0);
    // Exit delta: 140 - 10 = 130
    expect(arService.getRelativeSafeExitDelta(), 130.0);
  });
}
