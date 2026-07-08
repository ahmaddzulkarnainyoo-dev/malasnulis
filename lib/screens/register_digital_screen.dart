import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../services/storage_service.dart';
import '../widgets/drawing_canvas.dart';

/// Layar untuk mendaftarkan tulisan tangan digital A-Z dan a-z.
///
/// Flow:
/// 1. Tampilkan kanvas untuk menggambar huruf saat ini.
/// 2. User menggambar huruf, lalu klik "Simpan & Lanjut".
/// 3. Huruf disimpan sebagai PNG transparan di folder digital/.
/// 4. Lanjut ke huruf berikutnya sampai 52 huruf selesai.
/// 5. Setelah selesai, navigasi ke MainScreen.
class RegisterDigitalScreen extends StatefulWidget {
  const RegisterDigitalScreen({super.key});

  @override
  State<RegisterDigitalScreen> createState() => _RegisterDigitalScreenState();
}

class _RegisterDigitalScreenState extends State<RegisterDigitalScreen> {
  // Daftar 52 huruf: A-Z lalu a-z
  static const List<String> _letters = [
    'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J',
    'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'T',
    'U', 'V', 'W', 'X', 'Y', 'Z',
    'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j',
    'k', 'l', 'm', 'n', 'o', 'p', 'q', 'r', 's', 't',
    'u', 'v', 'w', 'x', 'y', 'z',
  ];

  int _currentIndex = 0;
  bool _isSaving = false;

  // Key untuk mengakses state DrawingCanvas
  final GlobalKey<DrawingCanvasState> _canvasKey = GlobalKey();

  // Storage service
  final StorageService _storageService = StorageService();

  String get _currentLetter => _letters[_currentIndex];
  double get _progress => _currentIndex / _letters.length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Daftar Huruf Digital'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _isSaving
              ? null
              : () => _showExitConfirmation(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Teks progress: "Daftar huruf digital: A (1/52)"
            Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Column(
                  children: [
                    Text(
                      'Daftar huruf digital: $_currentLetter (${_currentIndex + 1}/${_letters.length})',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Progress bar
                    LinearProgressIndicator(
                      value: _progress,
                      minHeight: 8,
                      borderRadius: BorderRadius.circular(4),
                      backgroundColor: Colors.grey.shade200,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${(_progress * 100).toStringAsFixed(0)}% selesai',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Petunjuk singkat
            Text(
              'Gambar huruf "$_currentLetter" di kanvas',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 8),

            // Canvas untuk menggambar
            Expanded(
              child: DrawingCanvas(key: _canvasKey),
            ),

            const SizedBox(height: 16),

            // Tombol aksi
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Tombol Hapus
                OutlinedButton.icon(
                  onPressed: _isSaving ? null : _clearCanvas,
                  icon: const Icon(Icons.delete),
                  label: const Text('Hapus'),
                ),
                // Tombol Simpan & Lanjut
                FilledButton.icon(
                  onPressed: _isSaving ? null : _saveAndNext,
                  icon: _isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
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

  /// Menghapus semua coretan di canvas.
  void _clearCanvas() {
    _canvasKey.currentState?.clear();
  }

  /// Menyimpan huruf saat ini dan lanjut ke huruf berikutnya.
  Future<void> _saveAndNext() async {
    final canvasState = _canvasKey.currentState;
    if (canvasState == null) return;

    // Ambil gambar dari canvas
    final Uint8List? pngBytes = await canvasState.captureTransparentImage();

    // Validasi: pastikan ada coretan berarti
    if (pngBytes == null) {
      _showAlert('Tulis huruf dulu!', 'Silakan gambar huruf "$_currentLetter" di kanvas.');
      return;
    }

    setState(() => _isSaving = true);

    try {
      // Simpan ke folder digital/
      await _storageService.saveDigitalLetter(_currentLetter, pngBytes);

      // Cek apakah masih ada huruf selanjutnya
      if (_currentIndex + 1 < _letters.length) {
        // Lanjut ke huruf berikutnya
        setState(() {
          _currentIndex++;
          _isSaving = false;
        });
        // Clear canvas untuk huruf baru
        _canvasKey.currentState?.clear();
      } else {
        // Semua 52 huruf selesai!
        if (mounted) {
          setState(() => _isSaving = false);
          _showCompletionDialog();
        }
      }
    } catch (e) {
      debugPrint('Error saving letter: $e');
      _showAlert('Gagal menyimpan', 'Terjadi kesalahan saat menyimpan huruf. Coba lagi.');
      setState(() => _isSaving = false);
    }
  }

  /// Tampilkan dialog konfirmasi jika user ingin keluar di tengah jalan.
  void _showExitConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi'),
        content: Text(
          'Anda baru menyelesaikan ${_currentIndex + 1}/${_letters.length} huruf. '
          'Jika keluar, progress akan hilang. Yakin ingin keluar?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Lanjutkan'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushReplacementNamed(context, '/home');
            },
            child: const Text('Keluar'),
          ),
        ],
      ),
    );
  }

  /// Tampilkan dialog sukses setelah semua huruf selesai.
  void _showCompletionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false, // Tidak bisa ditutup tanpa tombol
      builder: (context) => AlertDialog(
        title: const Icon(Icons.check_circle, color: Colors.green, size: 64),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Semua huruf digital berhasil didaftarkan!',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8),
            Text(
              '52 huruf (A-Z dan a-z) sudah siap digunakan.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              // Navigasi ke MainScreen
              Navigator.pushReplacementNamed(context, '/home');
            },
            child: const Text('Mulai'),
          ),
        ],
      ),
    );
  }

  /// Tampilkan alert sederhana.
  void _showAlert(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
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