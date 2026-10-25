import 'package:flutter/material.dart';

import '../models/stop.dart';
import '../theme/app_theme.dart';

/// Offline "drawn" route map. Used as a fallback when there is no internet
/// for the real map tiles, and as a clean view for slides.
class SchematicMap extends StatelessWidget {
  final List<Stop> stops;
  final double busLat;
  final double busLng;
  final int nextStopIndex;

  const SchematicMap({
    super.key,
    required this.stops,
    required this.busLat,
    required this.busLng,
    required this.nextStopIndex,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFEFF4F9),
      child: CustomPaint(
        painter: _RoutePainter(stops, busLat, busLng, nextStopIndex),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _RoutePainter extends CustomPainter {
  final List<Stop> stops;
  final double busLat;
  final double busLng;
  final int nextStopIndex;

  _RoutePainter(this.stops, this.busLat, this.busLng, this.nextStopIndex);

  @override
  void paint(Canvas canvas, Size size) {
    if (stops.length < 2) return;

    // Background grid, so it reads as a "map".
    final grid = Paint()
      ..color = const Color(0xFFDDE6F0)
      ..strokeWidth = 1;
    for (double x = 0; x < size.width; x += 40) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), grid);
    }
    for (double y = 0; y < size.height; y += 40) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }

    // Fit all stops into the box (simple equirectangular projection).
    final lats = stops.map((s) => s.lat).toList();
    final lngs = stops.map((s) => s.lng).toList();
    final minLat = lats.reduce((a, b) => a < b ? a : b);
    final maxLat = lats.reduce((a, b) => a > b ? a : b);
    final minLng = lngs.reduce((a, b) => a < b ? a : b);
    final maxLng = lngs.reduce((a, b) => a > b ? a : b);
    const pad = 60.0;
    final w = size.width - pad * 2;
    final h = size.height - pad * 2;
    final spanLat = (maxLat - minLat).abs() < 1e-6 ? 1e-3 : maxLat - minLat;
    final spanLng = (maxLng - minLng).abs() < 1e-6 ? 1e-3 : maxLng - minLng;

    Offset project(double lat, double lng) => Offset(
          pad + (lng - minLng) / spanLng * w,
          pad + (maxLat - lat) / spanLat * h,
        );

    final points = [for (final s in stops) project(s.lat, s.lng)];

    // Route line
    final line = Paint()
      ..color = AppColors.primary
      ..strokeWidth = 6
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (final p in points.skip(1)) {
      path.lineTo(p.dx, p.dy);
    }
    canvas.drawPath(path, line);

    // Stops + labels
    for (var i = 0; i < stops.length; i++) {
      final passed = i < nextStopIndex;
      canvas.drawCircle(points[i], 9, Paint()..color = Colors.white);
      canvas.drawCircle(
        points[i],
        9,
        Paint()
          ..color = passed ? AppColors.accent : AppColors.primary
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4,
      );
      final tp = TextPainter(
        text: TextSpan(
          text: '${stops[i].time}  ${stops[i].name}',
          style: const TextStyle(color: Color(0xFF1B2A3D), fontSize: 12, fontWeight: FontWeight.w600),
        ),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: 180);
      var dx = points[i].dx + 14;
      if (dx + tp.width > size.width - 4) dx = points[i].dx - 14 - tp.width;
      tp.paint(canvas, Offset(dx, points[i].dy - tp.height / 2));
    }

    // Bus
    final bus = project(busLat, busLng);
    canvas.drawCircle(bus, 18, Paint()..color = AppColors.accent.withAlpha(60));
    canvas.drawCircle(bus, 11, Paint()..color = AppColors.accent);
    canvas.drawCircle(bus, 4, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant _RoutePainter old) =>
      old.busLat != busLat || old.busLng != busLng || old.stops != stops || old.nextStopIndex != nextStopIndex;
}
