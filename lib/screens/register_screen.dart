import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';

/// Layar untuk mendaftarkan tulisan tangan A-Z.
/// User menggambar setiap huruf (A-Z) di atas canvas transparan.
/// Hasilnya disimpan sebagai PNG transparan di folder documents/letters/.
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  // Daftar huruf yang perlu didaftarkan
  static const List<String> _letters = [
    'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J',
    'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'T',
    'U', 'V', 'W', 'X', 'Y', 'Z',
  ];

  int _currentIndex = 0;
  // Coretan untuk huruf saat ini
  final List<List<Offset>> _strokes = [];
  List<Offset> _currentStroke = [];

  // GlobalKey untuk RepaintBoundary agar bisa di-capture sebagai PNG
  final GlobalKey _repaintKey = GlobalKey();

  bool _isSaving = false;

  String get _currentLetter => _letters[_currentIndex];
  double get _progress => (_currentIndex / _letters.length);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Registrasi Huruf $_currentLetter (${_currentIndex + 1}/${_letters.length})'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Progress bar
            LinearProgressIndicator(
              value: _progress,
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
            ),
            const SizedBox(height: 8),
            Text(
              '${_currentIndex + 1}/${_letters.length} - Gambar huruf $_currentLetter',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 16),

            // Canvas untuk menggambar
            Expanded(
              child: Center(
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade400, width: 2),
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.white, // Background putih visual untuk user
                  ),
                  width: 320,
                  height: 320,
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
                            _strokes.add(List.from(_currentStroke));
                            _currentStroke = [];
                          });
                        },
                        child: CustomPaint(
                          size: const Size(320, 320),
                          painter: _HandwritingPainter(
                            strokes: _strokes,
                            currentStroke: _currentStroke,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Tombol aksi
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                OutlinedButton.icon(
                  onPressed: _isSaving ? null : _clearStrokes,
                  icon: const Icon(Icons.delete),
                  label: const Text('Hapus'),
                ),
                FilledButton.icon(
                  onPressed: _isSaving ? null : _saveAndNext,
                  icon: _isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save),
                  label: const Text('Simpan & Lanjut'),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _clearStrokes() {
    setState(() {
      _strokes.clear();
      _currentStroke.clear();
    });
  }

  Future<void> _saveAndNext() async {
    // Validasi: pastikan user sudah menggambar
    if (_strokes.isEmpty && _currentStroke.isEmpty) {
      _showAlert('Tulis huruf dulu!');
      return;
    }

    setState(() => _isSaving = true);

    try {
      // Capture RepaintBoundary ke PNG transparan
      final boundary = _repaintKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 2.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final pngBytes = byteData!.buffer.asUint8List();

      // Simpan ke folder documents/letters/
      final dir = await getApplicationDocumentsDirectory();
      final lettersDir = Directory('${dir.path}/letters');
      if (!await lettersDir.exists()) {
        await lettersDir.create(recursive: true);
      }

      final file = File('${lettersDir.path}/$_currentLetter.png');
      await file.writeAsBytes(pngBytes);

      // Hapus resource untuk GC
      image.dispose();

      // Cek apakah masih ada huruf selanjutnya
      if (_currentIndex + 1 < _letters.length) {
        setState(() {
          _currentIndex++;
          _strokes.clear();
          _currentStroke.clear();
          _isSaving = false;
        });
      } else {
        // Semua huruf selesai! Navigasi ke Home
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/home');
        }
      }
    } catch (e) {
      debugPrint('Error saving letter: $e');
      _showAlert('Terjadi kesalahan saat menyimpan. Coba lagi.');
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _showAlert(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Info'),
        content: Text(message),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

/// Painter untuk menggambar coretan tangan di canvas transparan.
class _HandwritingPainter extends CustomPainter {
  final List<List<Offset>> strokes;
  final List<Offset> currentStroke;

  _HandwritingPainter({
    required this.strokes,
    required this.currentStroke,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black
      ..strokeWidth = 8.0
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
  bool shouldRepaint(covariant _HandwritingPainter oldDelegate) {
    return oldDelegate.strokes != strokes || oldDelegate.currentStroke != currentStroke;
  }
}