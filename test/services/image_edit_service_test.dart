import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sinhvien_app/services/image_edit_service.dart';

void main() {
  test('containSize preserves aspect ratio inside the bounds', () {
    const service = ImageEditService();

    final contained = service.containSize(
      const Size(1600, 900),
      const Size(300, 300),
    );

    expect(contained.width, 300);
    expect(contained.height, closeTo(168.75, 0.01));
  });

  test('hitTestAction and hitTestTextAction resolve overlay selection', () {
    const service = ImageEditService();
    final actions = <ImageOverlayAction>[
      const ImageTextAction(
        text: 'ABC',
        position: Offset(0.20, 0.20),
        color: Color(0xFFD32F2F),
        fontSize: 24,
      ),
      const ImageStrokeAction(
        color: Color(0xFF1976D2),
        thickness: 4,
        points: [Offset(0.70, 0.70), Offset(0.75, 0.75)],
      ),
    ];

    final textHit = service.hitTestTextAction(
      const Offset(0.21, 0.22),
      const Size(200, 200),
      actions,
    );
    final strokeHit = service.hitTestAction(
      const Offset(0.70, 0.70),
      const Size(200, 200),
      actions,
    );

    expect(textHit, 0);
    expect(strokeHit, 1);
  });

  test(
    'mapPointIntoCrop projects normalized points into the cropped image',
    () {
      const service = ImageEditService();

      final mapped = service.mapPointIntoCrop(
        const Offset(0.4, 0.5),
        const Rect.fromLTWH(0.2, 0.2, 0.6, 0.6),
        const Size(300, 200),
      );

      expect(mapped, isNotNull);
      expect(mapped!.dx, closeTo(100, 0.01));
      expect(mapped.dy, closeTo(100, 0.01));
    },
  );

  test('resizeCropRect keeps minimum size and stays within bounds', () {
    const service = ImageEditService();

    final resized = service.resizeCropRect(
      cropRect: const Rect.fromLTWH(0.2, 0.2, 0.4, 0.4),
      normalized: const Offset(1.2, 1.2),
      minSize: 0.18,
    );

    expect(resized.left, 0.2);
    expect(resized.top, 0.2);
    expect(resized.right, 1.0);
    expect(resized.bottom, 1.0);
  });
}
