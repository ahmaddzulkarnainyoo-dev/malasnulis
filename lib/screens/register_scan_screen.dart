import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import '../services/storage_service.dart';

/// Layar untuk registrasi huruf via scan kertas (grid 4x13).
///
/// Flow:
/// 1. Tampilkan instruksi + ilustrasi grid 4x13.
/// 2. User foto kertas fisik yang sudah ditulisi A-Z & a-z.
/// 3. Tampilkan foto dengan overlay grid 4x13 yang bisa di-adjust.
/// 4. User crop & simpan -> sistem split 4x13 jadi 52 PNG huruf.
/// 5. Simpan ke folder scan/.
class RegisterScanScreen extends StatefulWidget {
  const RegisterScanScreen({super.key});

  @override
  State<RegisterScanScreen> createState() => _RegisterScanScreenState();
}

class _RegisterScanScreenState extends State<RegisterScanScreen> {
  final ImagePicker _picker = ImagePicker();
  final StorageService _storageService = StorageService();

  // State: 'instruction' -> 'preview'
  String _state = 'instruction';

  // Path foto yang diambil
  String? _photoPath;

  // Koordinat grid (dapat di-adjust user via drag handle)
  // gridRect mendefinisikan area grid di dalam foto
  double _gridLeft = 0.1;
  double _gridTop = 0.05;
  double _gridRight = 0.9;
  double _gridBottom = 0.95;

  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registrasi Scan Kertas'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      ),
      body: _state == 'instruction'
          ? _buildInstructionState()
          : _buildPreviewState(),
    );
  }

  /// State 1: Instruksi + ilustrasi grid 4x13
  Widget _buildInstructionState() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Ilustrasi grid 4x13
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Text(
                    'Ilustrasi Grid 4×13',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Gambar grid sederhana pakai CustomPaint
                  Container(
                    width: 260,
                    height: 340,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey, width: 1),
                      color: Colors.white,
                    ),
                    child: CustomPaint(
                      size: const Size(260, 340),
                      painter: _GridIllustrationPainter(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '4 baris × 13 kolom = 52 kotak',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Teks instruksi
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Petunjuk',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '1. Siapkan kertas kosong.\n'
                    '2. Tulis huruf A-Z (kapital) di baris 1-2.\n'
                    '3. Tulis huruf a-z (kecil) di baris 3-4.\n'
                    '4. Pastikan tulisan tidak menyentuh garis.\n'
                    '5. Foto kertas dengan posisi rata & cukup cahaya.',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Tombol ambil foto
          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton.icon(
              onPressed: _takePhoto,
              icon: const Icon(Icons.camera_alt),
              label: const Text(
                'Ambil Foto',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Atau dari galeri
          SizedBox(
            width: double.infinity,
            height: 44,
            child: OutlinedButton.icon(
              onPressed: _pickFromGallery,
              icon: const Icon(Icons.photo_library),
              label: const Text('Pilih dari Galeri'),
            ),
          ),
        ],
      ),
    );
  }

  /// State 2: Preview foto dengan overlay grid yang bisa di-adjust
  Widget _buildPreviewState() {
    if (_photoPath == null) {
      return const Center(child: Text('Tidak ada foto'));
    }

    return Column(
      children: [
        // Preview foto dengan overlay grid
        Expanded(
          child: InteractiveViewer(
            minScale: 1.0,
            maxScale: 4.0,
            child: Stack(
              children: [
                // Foto
                Positioned.fill(
                  child: Image.file(
                    File(_photoPath!),
                    fit: BoxFit.contain,
                  ),
                ),
                // Overlay grid 4x13 (garis merah)
                Positioned.fill(
                  child: CustomPaint(
                    painter: _GridOverlayPainter(
                      left: _gridLeft,
                      top: _gridTop,
                      right: _gridRight,
                      bottom: _gridBottom,
                      rows: 4,
                      cols: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Kontrol penyesuaian grid
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            children: [
              Text(
                'Sesuaikan grid agar pas dengan kotak di kertas',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 8),
              // Slider untuk geser grid
              Row(
                children: [
                  const Text('Kiri', style: TextStyle(fontSize: 12)),
                  Expanded(
                    child: Slider(
                      value: _gridLeft,
                      min: 0.0,
                      max: 0.4,
                      onChanged: (v) => setState(() => _gridLeft = v),
                    ),
                  ),
                  const Text('Kanan', style: TextStyle(fontSize: 12)),
                  Expanded(
                    child: Slider(
                      value: _gridRight,
                      min: 0.6,
                      max: 1.0,
                      onChanged: (v) => setState(() => _gridRight = v),
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  const Text('Atas', style: TextStyle(fontSize: 12)),
                  Expanded(
                    child: Slider(
                      value: _gridTop,
                      min: 0.0,
                      max: 0.3,
                      onChanged: (v) => setState(() => _gridTop = v),
                    ),
                  ),
                  const Text('Bawah', style: TextStyle(fontSize: 12)),
                  Expanded(
                    child: Slider(
                      value: _gridBottom,
                      min: 0.7,
                      max: 1.0,
                      onChanged: (v) => setState(() => _gridBottom = v),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Tombol crop & simpan
              SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton.icon(
                  onPressed: _isProcessing ? null : _cropAndSave,
                  icon: _isProcessing
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.crop),
                  label: Text(
                    _isProcessing ? 'Memproses...' : 'Crop & Simpan',
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ],
    );
  }

  /// Ambil foto dari kamera
  Future<void> _takePhoto() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        imageQuality: 90,
      );
      if (photo != null) {
        setState(() {
          _photoPath = photo.path;
          _state = 'preview';
          // Reset grid
          _gridLeft = 0.1;
          _gridTop = 0.05;
          _gridRight = 0.9;
          _gridBottom = 0.95;
        });
      }
    } catch (e) {
      debugPrint('Error taking photo: $e');
      _showAlert('Gagal mengambil foto');
    }
  }

  /// Ambil foto dari galeri
  Future<void> _pickFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        imageQuality: 90,
      );
      if (image != null) {
        setState(() {
          _photoPath = image.path;
          _state = 'preview';
          _gridLeft = 0.1;
          _gridTop = 0.05;
          _gridRight = 0.9;
          _gridBottom = 0.95;
        });
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
      _showAlert('Gagal memilih gambar');
    }
  }

  /// Crop grid dan simpan 52 huruf ke folder scan/
  Future<void> _cropAndSave() async {
    if (_photoPath == null) return;

    setState(() => _isProcessing = true);

    try {
      // Load foto
      final img.Image photo = img.decodeImage(
        await File(_photoPath!).readAsBytes(),
      )!;

      // Hitung area grid dalam pixel
      final int photoW = photo.width;
      final int photoH = photo.height;

      final int gridX = (_gridLeft * photoW).round();
      final int gridY = (_gridTop * photoH).round();
      final int gridW = (_gridRight * photoW).round() - gridX;
      final int gridH = (_gridBottom * photoH).round() - gridY;

      // Crop area grid dari foto
      final img.Image gridArea = img.copyCrop(photo, x: gridX, y: gridY, width: gridW, height: gridH);

      // Bagi grid menjadi 4 baris x 13 kolom
      final int rowHeight = gridArea.height ~/ 4;
      final int colWidth = gridArea.width ~/ 13;

      // Daftar 52 huruf: A-Z lalu a-z
      const List<String> letters = [
        'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J',
        'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'T',
        'U', 'V', 'W', 'X', 'Y', 'Z',
        'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j',
        'k', 'l', 'm', 'n', 'o', 'p', 'q', 'r', 's', 't',
        'u', 'v', 'w', 'x', 'y', 'z',
      ];

      int letterIndex = 0;

      for (int row = 0; row < 4; row++) {
        for (int col = 0; col < 13; col++) {
          if (letterIndex >= letters.length) break;

          // Crop per kotak
          final int cropX = col * colWidth;
          final int cropY = row * rowHeight;

          // Beri margin 5% di setiap sisi untuk menghindari garis grid
          final int marginX = (colWidth * 0.05).round();
          final int marginY = (rowHeight * 0.05).round();

          final int actualCropX = cropX + marginX;
          final int actualCropY = cropY + marginY;
          final int actualCropW = colWidth - (marginX * 2);
          final int actualCropH = rowHeight - (marginY * 2);

          if (actualCropW <= 0 || actualCropH <= 0) continue;

          // Crop kotak huruf
          final img.Image letterImage = img.copyCrop(
            gridArea,
            x: actualCropX,
            y: actualCropY,
            width: actualCropW,
            height: actualCropH,
          );

          // Konversi ke PNG
          final Uint8List pngBytes = Uint8List.fromList(
            img.encodePng(letterImage),
          );

          // Simpan ke folder scan/
          await _storageService.saveDigitalLetter(
            letters[letterIndex],
            pngBytes,
            folder: 'scan',
          );

          letterIndex++;
        }
      }

      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
        _showSuccessDialog();
      }
    } catch (e) {
      debugPrint('Error crop & save: $e');
      _showAlert('Gagal memproses gambar. Pastikan foto jelas dan coba lagi.');
      setState(() => _isProcessing = false);
    }
  }

  /// Dialog sukses
  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Icon(Icons.check_circle, color: Colors.green, size: 64),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Huruf hasil scan berhasil disimpan!',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8),
            Text(
              '52 huruf (A-Z dan a-z) dari scan kertas sudah siap.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushReplacementNamed(context, '/home');
            },
            child: const Text('Selesai'),
          ),
        ],
      ),
    );
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

/// Painter untuk ilustrasi grid 4x13 di halaman instruksi.
class _GridIllustrationPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.blue.withOpacity(0.3)
      ..strokeWidth = 1;

    final double colW = size.width / 13;
    final double rowH = size.height / 4;

    // Garis vertikal
    for (int i = 0; i <= 13; i++) {
      final double x = i * colW;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    // Garis horizontal
    for (int i = 0; i <= 4; i++) {
      final double y = i * rowH;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

    // Label baris
    final textStyle = TextStyle(color: Colors.grey.shade600, fontSize: 10);
    for (int i = 0; i < 4; i++) {
      final textPainter = TextPainter(
        text: TextSpan(
          text: 'Baris ${i + 1}',
          style: textStyle,
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(2, i * rowH + 2));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Painter untuk overlay grid 4x13 di atas foto (garis merah).
class _GridOverlayPainter extends CustomPainter {
  final double left, top, right, bottom;
  final int rows, cols;

  _GridOverlayPainter({
    required this.left,
    required this.top,
    required this.right,
    required this.bottom,
    required this.rows,
    required this.cols,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.red.withOpacity(0.5)
      ..strokeWidth = 2;

    final double gridX = left * size.width;
    final double gridY = top * size.height;
    final double gridW = (right - left) * size.width;
    final double gridH = (bottom - top) * size.height;

    final double colW = gridW / cols;
    final double rowH = gridH / rows;

    // Border luar grid
    canvas.drawRect(
      Rect.fromLTWH(gridX, gridY, gridW, gridH),
      paint..style = PaintingStyle.stroke,
    );

    // Garis vertikal
    for (int i = 1; i < cols; i++) {
      final double x = gridX + (i * colW);
      canvas.drawLine(Offset(x, gridY), Offset(x, gridY + gridH), paint);
    }

    // Garis horizontal
    for (int i = 1; i < rows; i++) {
      final double y = gridY + (i * rowH);
      canvas.drawLine(Offset(gridX, y), Offset(gridX + gridW, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _GridOverlayPainter oldDelegate) {
    return oldDelegate.left != left ||
        oldDelegate.top != top ||
        oldDelegate.right != right ||
        oldDelegate.bottom != bottom;
  }
}