import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/handwriting_service.dart';
import '../services/quota_service.dart';
import '../services/storage_service.dart';
import 'result_screen.dart';

/// Layar utama setelah registrasi huruf selesai.
/// User bisa pilih gaya huruf, background, input teks, lalu generate.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _textController = TextEditingController();
  final HandwritingService _handwritingService = HandwritingService();
  final QuotaService _quotaService = QuotaService();
  final StorageService _storageService = StorageService();

  // Pilihan font source: 'digital' atau 'scan'
  String _selectedFontSource = 'digital';

  // Pilihan background: 'scan' atau 'polos'/'bergaris'/'kotak'/'kuning'
  String _selectedBackground = 'scan';

  // Path foto kertas (jika background scan)
  String? _paperImagePath;

  // Bytes foto kertas (jika background scan)
  Uint8List? _scannedImageBytes;

  bool _isGenerating = false;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  /// Ambil foto dari kamera
  Future<void> _takePhoto() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        imageQuality: 85,
      );
      if (photo != null) {
        final bytes = await photo.readAsBytes();
        setState(() {
          _paperImagePath = photo.path;
          _scannedImageBytes = bytes;
        });
      }
    } catch (e) {
      debugPrint('Error taking photo: $e');
      _showAlert('Gagal mengambil foto. Coba lagi.');
    }
  }

  /// Ambil foto dari galeri
  Future<void> _pickFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        imageQuality: 85,
      );
      if (image != null) {
        final bytes = await image.readAsBytes();
        setState(() {
          _paperImagePath = image.path;
          _scannedImageBytes = bytes;
        });
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
      _showAlert('Gagal memilih gambar. Coba lagi.');
    }
  }

  /// Cek apakah user sudah registrasi huruf di folder tertentu
  Future<bool> _isLetterRegistered(String folder) async {
    try {
      final count = await _storageService.getRegisteredCount(folder: folder);
      return count >= 26; // Minimal 26 huruf (A-Z)
    } catch (e) {
      return false;
    }
  }

  /// Generate tulisan dan navigasi ke ResultScreen
  Future<void> _generateHandwriting() async {
    // Validasi: teks tidak boleh kosong
    final text = _textController.text.trim();
    if (text.isEmpty) {
      _showAlert('Masukkan teks terlebih dahulu!');
      return;
    }

    // Validasi: jika background scan, foto harus ada
    if (_selectedBackground == 'scan' && _scannedImageBytes == null) {
      _showAlert('Ambil foto kertas dulu!');
      return;
    }

    // Validasi: cek apakah huruf sudah diregistrasi
    final isRegistered = await _isLetterRegistered(_selectedFontSource);
    if (!isRegistered) {
      final sourceName = _selectedFontSource == 'digital' ? 'digital' : 'scan';
      _showAlert(
        'Anda belum registrasi huruf $sourceName. '
        'Silakan registrasi dulu.',
      );
      return;
    }

    // Cek kuota
    final remaining = await _quotaService.getRemainingQuota();
    if (remaining <= 0) {
      _showQuotaDialog();
      return;
    }

    setState(() => _isGenerating = true);

    try {
      // Generate handwriting
      final Uint8List result = await _handwritingService.generateHandwriting(
        text: text,
        fontSource: _selectedFontSource,
        backgroundSource: _selectedBackground,
        scannedImageBytes: _selectedBackground == 'scan'
            ? _scannedImageBytes
            : null,
      );

      // Kurangi kuota
      await _quotaService.useQuota();

      // Navigasi ke ResultScreen
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ResultScreen(
              imageBytes: result,
              text: text,
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error generating: $e');
      _showAlert('Gagal generate: $e');
    } finally {
      if (mounted) {
        setState(() => _isGenerating = false);
      }
    }
  }

  /// Dialog kuota habis
  void _showQuotaDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Kuota Habis'),
        content: const Text(
          'Kuota generate hari ini sudah habis. '
          'Nonton iklan untuk tambah kuota, atau upgrade ke premium.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Nanti'),
          ),
          FilledButton.icon(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Nonton iklan - akan diintegrasikan nanti
              _showAlert('Fitur iklan akan tersedia di update selanjutnya.');
            },
            icon: const Icon(Icons.play_circle),
            label: const Text('Nonton Iklan'),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Malas Nulis'),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_note),
            tooltip: 'Registrasi Ulang Huruf',
            onPressed: () {
              Navigator.pushReplacementNamed(context, '/');
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Baris 1: Pilih Gaya Huruf (Font Source)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.text_fields, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Gaya Huruf',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ChoiceChip(
                          label: const Text('✍️ Digital'),
                          selected: _selectedFontSource == 'digital',
                          onSelected: (s) {
                            setState(() => _selectedFontSource = 'digital');
                          },
                        ),
                        ChoiceChip(
                          label: const Text('📝 Scan Kertas'),
                          selected: _selectedFontSource == 'scan',
                          onSelected: (s) {
                            setState(() => _selectedFontSource = 'scan');
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Baris 2: Pilih Background
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.photo_size_select_large, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Background',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ChoiceChip(
                          label: const Text('📷 Scan'),
                          selected: _selectedBackground == 'scan',
                          onSelected: (s) {
                            setState(() => _selectedBackground = 'scan');
                          },
                        ),
                        ChoiceChip(
                          label: const Text('📄 Polos'),
                          selected: _selectedBackground == 'polos',
                          onSelected: (s) {
                            setState(() => _selectedBackground = 'polos');
                          },
                        ),
                        ChoiceChip(
                          label: const Text('📄 Bergaris'),
                          selected: _selectedBackground == 'bergaris',
                          onSelected: (s) {
                            setState(() => _selectedBackground = 'bergaris');
                          },
                        ),
                        ChoiceChip(
                          label: const Text('📄 Kotak'),
                          selected: _selectedBackground == 'kotak',
                          onSelected: (s) {
                            setState(() => _selectedBackground = 'kotak');
                          },
                        ),
                        ChoiceChip(
                          label: const Text('📄 Kuning'),
                          selected: _selectedBackground == 'kuning',
                          onSelected: (s) {
                            setState(() => _selectedBackground = 'kuning');
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Bagian foto kertas (hanya jika background = scan)
            if (_selectedBackground == 'scan')
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.photo_camera, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Foto Kertas',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Preview foto atau placeholder
                      Container(
                        height: 200,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: _paperImagePath != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: Image.file(
                                  File(_paperImagePath!),
                                  cacheWidth: 600,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return const Center(
                                      child: Text('Gagal memuat gambar'),
                                    );
                                  },
                                ),
                              )
                            : const Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.image_outlined,
                                      size: 48,
                                      color: Colors.grey,
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      'Belum ada foto',
                                      style: TextStyle(color: Colors.grey),
                                    ),
                                  ],
                                ),
                              ),
                      ),
                      const SizedBox(height: 12),

                      // Tombol ambil foto
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _takePhoto,
                              icon: const Icon(Icons.camera_alt),
                              label: const Text('Kamera'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _pickFromGallery,
                              icon: const Icon(Icons.photo_library),
                              label: const Text('Galeri'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 16),

            // Bagian input teks
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.text_fields, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Teks Tulisan',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _textController,
                      maxLines: 5,
                      minLines: 3,
                      decoration: const InputDecoration(
                        hintText: 'Ketik teks yang ingin ditulis tangan...',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.all(12),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Tombol generate
            SizedBox(
              height: 52,
              child: FilledButton.icon(
                onPressed: _isGenerating ? null : _generateHandwriting,
                icon: _isGenerating
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.auto_awesome),
                label: Text(
                  _isGenerating ? 'Memproses...' : 'Buat Tulisan',
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}