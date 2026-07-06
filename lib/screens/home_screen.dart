import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

/// Layar utama setelah registrasi huruf selesai.
/// User bisa ambil foto kertas dan input teks untuk digenerate.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _textController = TextEditingController();

  String? _paperImagePath;

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
        maxWidth: 1920, // Batasi ukuran foto
        imageQuality: 85,
      );
      if (photo != null) {
        setState(() => _paperImagePath = photo.path);
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
        setState(() => _paperImagePath = image.path);
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
      _showAlert('Gagal memilih gambar. Coba lagi.');
    }
  }

  /// Cek apakah user sudah registrasi huruf
  Future<bool> _isLetterRegistered() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final letterFile = File('${dir.path}/letters/A.png');
      return await letterFile.exists();
    } catch (e) {
      return false;
    }
  }

  /// Navigasi ke ResultScreen untuk generate tulisan
  Future<void> _generateHandwriting() async {
    // Validasi: foto harus ada
    if (_paperImagePath == null) {
      _showAlert('Ambil foto kertas dulu!');
      return;
    }

    // Validasi: teks tidak boleh kosong
    final text = _textController.text.trim();
    if (text.isEmpty) {
      _showAlert('Masukkan teks terlebih dahulu!');
      return;
    }

    // Validasi: cek apakah huruf sudah diregistrasi
    final isRegistered = await _isLetterRegistered();
    if (!isRegistered) {
      _showAlert('Anda belum registrasi huruf. Silakan registrasi dulu.');
      return;
    }

    // Navigasi ke ResultScreen dengan data
    if (mounted) {
      Navigator.pushNamed(
        context,
        '/result',
        arguments: {
          'paperImagePath': _paperImagePath,
          'text': text,
        },
      );
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Malas Nulis'),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        actions: [
          // Tombol ke registrasi ulang
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
            // Bagian foto kertas
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
                                cacheWidth: 600, // Hemat memory
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
                onPressed: _generateHandwriting,
                icon: const Icon(Icons.auto_awesome),
                label: const Text(
                  'Buat Tulisan',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}