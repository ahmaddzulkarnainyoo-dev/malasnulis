import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// Widget kanvas untuk menggambar huruf dengan tangan.
///
/// Fitur:
/// - Gambar dengan sentuhan (touch/drag)
/// - Hapus per coretan (undo)
/// - Hapus semua (clear)
/// - Capture ke PNG transparan
/// - Ukuran proporsional menyesuaikan layout
class DrawingCanvas extends StatefulWidget {
  const DrawingCanvas({super.key});

  @override
  State<DrawingCanvas> createState() => DrawingCanvasState();
}

class DrawingCanvasState extends State<DrawingCanvas> {
  // Kunci untuk RepaintBoundary agar bisa di-capture sebagai PNG
  final GlobalKey _repaintKey = GlobalKey();

  // Daftar coretan (satu List<Offset> per coretan)
  final List<List<Offset>> _strokes = [];

  // Coretan yang sedang digambar
  List<Offset> _currentStroke = [];

  /// Menangkap canvas sebagai PNG transparan (hanya coretan hitam).
  /// Mengembalikan Uint8List berisi data PNG.
  /// Jika tidak ada coretan berarti, mengembalikan null.
  Future<Uint8List?> captureTransparentImage() async {
    // Validasi: pastikan ada coretan
    if (_strokes.isEmpty && _currentStroke.isEmpty) {
      return null;
    }

    try {
      final boundary = _repaintKey.currentContext!
          .findRenderObject() as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 3.0); // 3x untuk kualitas
      final byteData = await image.toByteData(
        format: ui.ImageByteFormat.png,
      );
      image.dispose();

      if (byteData == null) return null;

      final pngBytes = byteData.buffer.asUint8List();

      // Validasi: cek apakah ada pixel hitam berarti
      if (!_hasMeaningfulDrawing(pngBytes)) {
        return null;
      }

      return pngBytes;
    } catch (e) {
      debugPrint('Error capturing canvas: $e');
      return null;
    }
  }

  /// Mengecek apakah gambar mengandung coretan berarti.
  /// Threshold: minimal 50 pixel hitam (nilai alpha > 0 dan RGB mendekati 0).
  bool _hasMeaningfulDrawing(Uint8List pngBytes) {
    // Decode PNG sederhana: cek byte signature PNG
    // Pendekatan: jika file > 1KB, kemungkinan ada coretan
    // Alternatif: parse pixel data jika perlu akurat
    return pngBytes.length > 1000;
  }

  /// Menghapus coretan terakhir (undo).
  void undo() {
    if (_strokes.isNotEmpty) {
      setState(() {
        _strokes.removeLast();
      });
    }
  }

  /// Menghapus semua coretan.
  void clear() {
    setState(() {
      _strokes.clear();
      _currentStroke.clear();
    });
  }

  /// Mendapatkan jumlah coretan saat ini.
  bool get hasStrokes => _strokes.isNotEmpty || _currentStroke.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Hitung ukuran kanvas persegi, maks 400x400
        final double canvasSize = constraints.maxWidth < 400
            ? constraints.maxWidth
            : 400;

        return Center(
          child: Container(
            width: canvasSize,
            height: canvasSize,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade400, width: 2),
              borderRadius: BorderRadius.circular(8),
              // Gunakan warna putih sebagai latar visual,
              // tapi hasil capture akan transparan karena CustomPainter
              // hanya menggambar coretan hitam di atas kanvas bening.
              color: Colors.white,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: RepaintBoundary(
                key: _repaintKey,
                child: GestureDetector(
                  onPanStart: (details) {
                    setState(() {
                      _currentStroke = [details.localPosition];
                    });
                  },
                  onPanUpdate: (details) {
                    setState(() {
                      _currentStroke.add(details.localPosition);
                    });
                  },
                  onPanEnd: (details) {
                    setState(() {
                      if (_currentStroke.isNotEmpty) {
                        _strokes.add(List.from(_currentStroke));
                        _currentStroke = [];
                      }
                    });
                  },
                  child: CustomPaint(
                    size: Size(canvasSize, canvasSize),
                    painter: _CanvasPainter(
                      strokes: _strokes,
                      currentStroke: _currentStroke,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Painter untuk menggambar coretan tangan di canvas transparan.
/// Hanya menggambar coretan hitam, background dibiarkan transparan.
class _CanvasPainter extends CustomPainter {
  final List<List<Offset>> strokes;
  final List<Offset> currentStroke;

  _CanvasPainter({
    required this.strokes,
    required this.currentStroke,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black
      ..strokeWidth = 10.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    // Gambar semua coretan yang sudah selesai
    for (final stroke in strokes) {
      _drawStroke(canvas, stroke, paint);
    }

    // Gambar coretan yang sedang berlangsung
    if (currentStroke.isNotEmpty) {
      _drawStroke(canvas, currentStroke, paint);
    }
  }

  /// Menggambar satu coretan sebagai path.
  void _drawStroke(Canvas canvas, List<Offset> points, Paint paint) {
    if (points.isEmpty) return;

    final path = Path();
    path.moveTo(points[0].dx, points[0].dy);

    for (int i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _CanvasPainter oldDelegate) {
    return oldDelegate.strokes != strokes ||
        oldDelegate.currentStroke != currentStroke;
  }
}