import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:crisis_mesh/core/services/maps/ar_evacuation_service.dart';

class ArEvacuationScreen extends StatefulWidget {
  const ArEvacuationScreen({super.key});

  @override
  State<ArEvacuationScreen> createState() => _ArEvacuationScreenState();
}

class _ArEvacuationScreenState extends State<ArEvacuationScreen> {
  final double _fovDegrees = 60.0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final arService = context.watch<ArEvacuationService>();

    final exitDelta = arService.getRelativeSafeExitDelta();
    final isFacingExit = exitDelta.abs() < (_fovDegrees / 2);

    return Scaffold(
      appBar: AppBar(
        title: const Text('AR Evacuation HUD'),
      ),
      body: Stack(
        children: [
          // 1. SIMULATED CAMERA VIEWFINDER FEED
          Container(
            color: Colors.black87,
            child: Stack(
              children: [
                // Diagonal overlay lines to simulate scanning
                Positioned.fill(
                  child: Opacity(
                    opacity: 0.15,
                    child: CustomPaint(
                      painter: ViewfinderGridPainter(),
                    ),
                  ),
                ),
                // Camera target focus brackets
                const Center(
                  child: Icon(
                    Icons.filter_center_focus,
                    size: 80,
                    color: Colors.white24,
                  ),
                ),
              ],
            ),
          ),

          // 2. AUGMENTED REALITY CANVAS HUD OVERLAY
          Positioned.fill(
            child: CustomPaint(
              painter: ArOverlayPainter(
                arService: arService,
                fovDegrees: _fovDegrees,
                theme: theme,
              ),
            ),
          ),

          // 3. DIRECTIONAL ESCAPE ROUTE INDICATORS
          if (!isFacingExit)
            Positioned(
              left: exitDelta < 0 ? 16 : null,
              right: exitDelta > 0 ? 16 : null,
              top: MediaQuery.of(context).size.height * 0.35,
              child: _buildDirectionalArrow(exitDelta < 0 ? Icons.arrow_back : Icons.arrow_forward),
            ),

          // 4. BOTTOM ROTATION SIMULATOR CONTROL PANEL
          Positioned(
            left: 16,
            right: 16,
            bottom: 24,
            child: Card(
              color: Colors.black.withOpacity(0.85),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Simulate Phone Heading',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '${arService.deviceBearing.toStringAsFixed(0)}° ${_getBearingDirection(arService.deviceBearing)}',
                          style: const TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Slider(
                      value: arService.deviceBearing,
                      min: 0,
                      max: 360,
                      onChanged: (val) {
                        arService.setDeviceBearing(val);
                      },
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Safe Evacuation route Exit is located at bearing 140° SE.',
                      style: TextStyle(color: Colors.greenAccent, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDirectionalArrow(IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.greenAccent.withOpacity(0.2),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.greenAccent, width: 2),
      ),
      child: Icon(icon, color: Colors.greenAccent, size: 36),
    );
  }

  String _getBearingDirection(double angle) {
    if (angle >= 337.5 || angle < 22.5) return 'N';
    if (angle >= 22.5 && angle < 67.5) return 'NE';
    if (angle >= 67.5 && angle < 112.5) return 'E';
    if (angle >= 112.5 && angle < 157.5) return 'SE';
    if (angle >= 157.5 && angle < 202.5) return 'S';
    if (angle >= 202.5 && angle < 247.5) return 'SW';
    if (angle >= 247.5 && angle < 292.5) return 'W';
    return 'NW';
  }
}

class ViewfinderGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 1.0;

    // Draw scanlines
    for (double i = 0; i < size.height; i += 20) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class ArOverlayPainter extends CustomPainter {
  final ArEvacuationService arService;
  final double fovDegrees;
  final ThemeData theme;

  ArOverlayPainter({
    required this.arService,
    required this.fovDegrees,
    required this.theme,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2.0;
    final centerY = size.height / 2.0;

    // 1. Paint Compass heading tape at the top
    _paintCompassTape(canvas, size, centerX);

    // 2. Paint target crosshair HUD
    final hudPaint = Paint()
      ..color = Colors.blueAccent.withOpacity(0.5)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(Offset(centerX, centerY), 30, hudPaint);
    canvas.drawLine(Offset(centerX - 50, centerY), Offset(centerX - 10, centerY), hudPaint);
    canvas.drawLine(Offset(centerX + 10, centerY), Offset(centerX + 50, centerY), hudPaint);

    // 3. Paint Safe Exit direction arrow when facing it
    final exitDelta = arService.getRelativeSafeExitDelta();
    final halfFov = fovDegrees / 2.0;

    if (exitDelta.abs() < halfFov) {
      final exitX = centerX + (exitDelta / halfFov) * (size.width / 2.0);
      
      // Draw Safe Exit Portal Anchor
      final portalPaint = Paint()
        ..color = Colors.greenAccent
        ..style = PaintingStyle.fill;
      
      canvas.drawCircle(Offset(exitX, centerY - 60), 20, portalPaint);
      
      final textPainter = TextPainter(
        text: const TextSpan(
          text: 'SAFE EXIT\n140° SE',
          style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 13),
        ),
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      )..layout();
      
      textPainter.paint(canvas, Offset(exitX - (textPainter.width / 2.0), centerY - 110));
    }

    // 4. Paint Floating AR Hazard Anchors
    for (final anchor in arService.anchors) {
      final offsetMultiplier = arService.calculateHorizontalScreenOffset(anchor.bearing, fovDegrees);
      if (offsetMultiplier == null) continue; // Out of view

      final screenX = centerX + offsetMultiplier * (size.width / 2.0);
      final screenY = centerY + 30; // slightly lower than center

      // Hazard Container Paint
      final boxPaint = Paint()
        ..color = Colors.red.withOpacity(0.7)
        ..style = PaintingStyle.fill;
      final borderPaint = Paint()
        ..color = Colors.redAccent
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;

      final rect = Rect.fromCenter(center: Offset(screenX, screenY), width: 140, height: 75);
      canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(8)), boxPaint);
      canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(8)), borderPaint);

      // Label texts inside
      final titlePainter = TextPainter(
        text: TextSpan(
          text: anchor.title,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      titlePainter.paint(canvas, Offset(screenX - (titlePainter.width / 2), screenY - 24));

      final typePainter = TextPainter(
        text: TextSpan(
          text: '${anchor.hazardType} [${anchor.distanceMeters.toStringAsFixed(0)}m]',
          style: const TextStyle(color: Colors.yellowAccent, fontWeight: FontWeight.bold, fontSize: 10),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      typePainter.paint(canvas, Offset(screenX - (typePainter.width / 2), screenY - 6));
    }
  }

  void _paintCompassTape(Canvas canvas, Size size, double centerX) {
    final textPaint = Paint()..color = Colors.white;

    final double tapeY = 30.0;
    
    // N (0), NE (45), E (90), SE (135), S (180), SW (225), W (270), NW (315)
    final points = <double, String>{
      0: 'N',
      45: 'NE',
      90: 'E',
      135: 'SE',
      180: 'S',
      225: 'SW',
      270: 'W',
      315: 'NW',
    };

    points.forEach((bearing, label) {
      var delta = bearing - arService.deviceBearing;
      while (delta < -180.0) {
        delta += 360.0;
      }
      while (delta > 180.0) {
        delta -= 360.0;
      }

      final halfFov = fovDegrees / 2.0;
      if (delta.abs() < halfFov) {
        final tickX = centerX + (delta / halfFov) * (size.width / 2.0);

        // Tick line
        canvas.drawLine(Offset(tickX, tapeY), Offset(tickX, tapeY + 12), tickPaint());

        // Label
        final labelPainter = TextPainter(
          text: TextSpan(
            text: label,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        labelPainter.paint(canvas, Offset(tickX - (labelPainter.width / 2.0), tapeY - 18));
      }
    });
  }

  Paint tickPaint() {
    return Paint()
      ..color = Colors.white
      ..strokeWidth = 2.0;
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
