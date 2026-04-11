// ============================================================
// widget utility: emoji_marker_utils.dart
// Renders an emoji string into a Google Maps BitmapDescriptor.
// Uses Flutter's Canvas + PictureRecorder – no asset files needed.
// ============================================================

import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Converts an [emoji] string into a [BitmapDescriptor] for use
/// as a custom Google Maps marker icon.
///
/// If [etaLabel] is provided, it draws a Zomato-style pill tag next to 
/// the marker (e.g. "2 min away").
Future<BitmapDescriptor> emojiToBitmapDescriptor(
  String emoji, {
  double size = 60,
  String? etaLabel,
}) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);

  final double circleRadius = size / 2;
  double totalWidth = size;
  double totalHeight = size;

  TextPainter? tagPainter;
  if (etaLabel != null && etaLabel.isNotEmpty) {
    tagPainter = TextPainter(
      text: TextSpan(
        text: etaLabel,
        style: TextStyle(
          fontSize: size * 0.45,
          color: const Color(0xFFD32F2F), // Red
          fontWeight: FontWeight.w800,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    // width = circle + padding + text width + right padding
    totalWidth = size + (size * 0.3) + tagPainter.width + (size * 0.5);
  }

  // 1. Draw the ETA pill (if exists)
  if (tagPainter != null) {
    final pillRect = Rect.fromLTWH(
      circleRadius, // Start from behind the circle
      size * 0.2, // Y offset
      circleRadius + (size * 0.3) + tagPainter.width + (size * 0.5), // Width
      size * 0.6, // Height
    );
    final rRect = RRect.fromRectAndRadius(pillRect, Radius.circular(size * 0.3));

    // Shadow
    canvas.drawRRect(
        rRect.shift(Offset(0, size * 0.05)),
        Paint()
          ..color = Colors.black.withValues(alpha: 0.15)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, size * 0.1));

    // Fill
    canvas.drawRRect(rRect, Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill);

    // Border
    canvas.drawRRect(
        rRect,
        Paint()
          ..color = const Color(0xFFD32F2F)
          ..strokeWidth = size * 0.04
          ..style = PaintingStyle.stroke);

    // Text
    tagPainter.paint(
      canvas,
      Offset(size + (size * 0.15), (size - tagPainter.height) / 2),
    );
  }

  // 2. Draw the main circle
  // Shadow
  canvas.drawCircle(
      Offset(circleRadius, circleRadius + (size * 0.05)),
      circleRadius,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.15)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, size * 0.1));

  // White background
  canvas.drawCircle(Offset(circleRadius, circleRadius), circleRadius,
      Paint()..color = Colors.white);

  // Red stroke (Zomato style)
  canvas.drawCircle(
      Offset(circleRadius, circleRadius),
      circleRadius,
      Paint()
        ..color = const Color(0xFFD32F2F)
        ..style = PaintingStyle.stroke
        ..strokeWidth = size * 0.08);

  // 3. Paint the emoji text centered in the circle
  final emojiPainter = TextPainter(
    text: TextSpan(
      text: emoji,
      style: TextStyle(fontSize: size * 0.55),
    ),
    textDirection: TextDirection.ltr,
  );
  emojiPainter.layout();
  emojiPainter.paint(
    canvas,
    Offset(
      (size - emojiPainter.width) / 2,
      (size - emojiPainter.height) / 2,
    ),
  );

  final picture = recorder.endRecording();
  final image = await picture.toImage(totalWidth.ceil(), totalHeight.ceil());
  final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
  final bytes = byteData!.buffer.asUint8List();

  return BitmapDescriptor.bytes(bytes);
}

/// Returns the right emoji for each responder type string.
String responderEmoji(String responderType) {
  switch (responderType) {
    case 'fire':
      return '🚒';
    case 'police':
      return '🚓';
    case 'ambulance':
    default:
      return '🚑';
  }
}
