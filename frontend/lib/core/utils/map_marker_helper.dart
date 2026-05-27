import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

class MapMarkerHelper {
  static final Map<String, BitmapDescriptor> _cache = {};

  static Future<BitmapDescriptor> getCustomMarker(String? imageUrl, String name, {Color color = Colors.blueAccent}) async {
    final String cacheKey = '${imageUrl}_$name';
    if (_cache.containsKey(cacheKey)) return _cache[cacheKey]!;

    final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);
    const double size = 100.0;
    const double radius = size / 2;

    // Draw the bubble (circle)
    final Paint paint = Paint()..color = color;
    canvas.drawCircle(const Offset(radius, radius), radius, paint);
    
    // Draw white border
    final Paint whitePaint = Paint()..color = Colors.white..style = PaintingStyle.stroke..strokeWidth = 6;
    canvas.drawCircle(const Offset(radius, radius), radius - 3, whitePaint);

    // Load and draw avatar
    if (imageUrl != null && imageUrl.isNotEmpty) {
      try {
        final ui.Image image = await _loadImage(imageUrl);
        final Rect rect = Rect.fromLTWH(10, 10, size - 20, size - 20);
        
        // Clip to circle
        canvas.save();
        canvas.clipPath(Path()..addOval(rect));
        canvas.drawImageRect(
          image,
          Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
          rect,
          Paint()..filterQuality = ui.FilterQuality.high,
        );
        canvas.restore();
      } catch (e) {
        _drawInitials(canvas, name, size);
      }
    } else {
      _drawInitials(canvas, name, size);
    }

    final ui.Image markerAsImage = await pictureRecorder.endRecording().toImage(size.toInt(), size.toInt());
    final byteData = await markerAsImage.toByteData(format: ui.ImageByteFormat.png);
    final descriptor = BitmapDescriptor.bytes(byteData!.buffer.asUint8List());
    
    _cache[cacheKey] = descriptor;
    return descriptor;
  }

  static void _drawInitials(Canvas canvas, String name, double size) {
     final textPainter = TextPainter(textDirection: TextDirection.ltr);
     String initials = name.isNotEmpty ? name[0].toUpperCase() : '?';
     if (name.contains(' ')) {
       final parts = name.split(' ');
       if (parts.length > 1 && parts[1].isNotEmpty) {
         initials = (parts[0][0] + parts[1][0]).toUpperCase();
       }
     }

     textPainter.text = TextSpan(
       text: initials,
       style: TextStyle(fontSize: size * 0.4, fontWeight: FontWeight.bold, color: Colors.white),
     );
     textPainter.layout();
     textPainter.paint(canvas, Offset((size - textPainter.width) / 2, (size - textPainter.height) / 2));
  }

  static Future<ui.Image> _loadImage(String url) async {
    final response = await http.get(Uri.parse(url));
    final Completer<ui.Image> completer = Completer();
    ui.decodeImageFromList(response.bodyBytes, (ui.Image img) => completer.complete(img));
    return completer.future;
  }
}
