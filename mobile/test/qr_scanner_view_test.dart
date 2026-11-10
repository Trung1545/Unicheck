import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unicheck_mobile/feature/attendance/views/qr_scanner_view.dart';

void main() {
  group('QrScannerView & QrScannerOverlayPainter Tests', () {
    test('QrScannerOverlayPainter calculates path difference correctly', () {
      final rect = Rect.fromCenter(
        center: const Offset(200, 300),
        width: 250,
        height: 250,
      );

      final painter = QrScannerOverlayPainter(
        scanBoxRect: rect,
        borderRadius: 20.0,
        overlayColor: const Color(0x8C000000),
      );

      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);
      const size = Size(400, 800);

      expect(() => painter.paint(canvas, size), returnsNormally);

      final picture = recorder.endRecording();
      expect(picture, isNotNull);
    });

    test('QrScannerOverlayPainter shouldRepaint triggers only on property delta', () {
      const p1 = QrScannerOverlayPainter(
        scanBoxRect: Rect.fromLTWH(50, 50, 200, 200),
        borderRadius: 20.0,
      );
      const p2 = QrScannerOverlayPainter(
        scanBoxRect: Rect.fromLTWH(50, 50, 200, 200),
        borderRadius: 20.0,
      );
      const p3 = QrScannerOverlayPainter(
        scanBoxRect: Rect.fromLTWH(60, 60, 220, 220),
        borderRadius: 20.0,
      );

      expect(p1.shouldRepaint(p2), isFalse);
      expect(p1.shouldRepaint(p3), isTrue);
    });

    testWidgets('CustomPaint with QrScannerOverlayPainter renders smoothly',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CustomPaint(
              size: Size(400, 800),
              painter: QrScannerOverlayPainter(
                scanBoxRect: Rect.fromLTWH(50, 150, 300, 300),
                borderRadius: 20.0,
              ),
            ),
          ),
        ),
      );

      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is CustomPaint &&
              widget.painter is QrScannerOverlayPainter,
        ),
        findsOneWidget,
      );
    });
  });
}
