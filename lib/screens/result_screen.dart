import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import '../services/handwriting_service.dart';
import '../services/ad_service.dart';

/// Layar untuk menampilkan hasil generate tulisan tangan.
/// Menerima [paperImagePath] dan [text] dari arguments.
/// Menampilkan preview hasil, dan tombol download dengan iklan interstitial.
class ResultScreen extends StatefulWidget {
  const ResultScreen({super.key});

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  Uint8List? _resultBytes;
  bool _isGenerating = true;
  bool _isSaving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _generate();
  }

  /// Memulai proses generate tulisan tangan
  Future<void> _generate() async {
    setState(() {
      _isGenerating = true;
      _errorMessage = null;
    });

    try {
      // Ambil arguments dari navigasi
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (args == null) {
        throw Exception('Data tidak ditemukan');
      }

      final String paperImagePath = args['paperImagePath'] as String;
      final String text = args['text'] as String;

      // Panggil HandwritingService untuk generate
      final Uint8List result = await HandwritingService.generateHandwriting(
        text: text,
        paperImagePath: paperImagePath,
      );

      if (mounted) {
        setState(() {
          _resultBytes = result;
          _isGenerating = false;
        });
      }
    } catch (e) {
      debugPrint('Error generating handwriting: $e');
      if (mounted) {
        setState(() {
          _isGenerating = false;
          _errorMessage = 'Terjadi kesalahan: ${e.toString()}';
        });
      }
    }
  }

  /// Simpan hasil ke galeri dengan iklan interstitial
  Future<void> _saveToGallery() async {
    if (_resultBytes == null) return;

    setState(() => _isSaving = true);

    try {
      // Cek koneksi internet sederhana (coba ping)
      bool isOnline = false;
      try {
        final result = await InternetAddress.lookup('google.com')
            .timeout(const Duration(seconds: 3));
        isOnline = result.isNotEmpty && result[0].rawAddress.isNotEmpty;
      } catch (_) {
        isOnline = false;
      }

      // Jika online, tampilkan iklan interstitial dulu
      if (isOnline) {
        await AdService().showInterstitialAd();
      }

      // Simpan ke galeri
      final result = await ImageGallerySaver.saveImage(
        _resultBytes!,
        name: 'malas_nulis_${DateTime.now().millisecondsSinceEpoch}',
        quality: 100,
      );

      if (mounted) {
        if (result != null && result['isSuccess'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Berhasil disimpan ke galeri!'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Gagal menyimpan ke galeri'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error saving: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menyimpan: ${e.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hasil Tulisan'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        actions: [
          if (_resultBytes != null)
            IconButton(
              icon: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.download),
              tooltip: 'Simpan ke Galeri',
              onPressed: _isSaving ? null : _saveToGallery,
            ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    // State: Loading
    if (_isGenerating) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Memproses tulisan...'),
          ],
        ),
      );
    }

    // State: Error
    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _generate,
                icon: const Icon(Icons.refresh),
                label: const Text('Coba Lagi'),
              ),
            ],
          ),
        ),
      );
    }

    // State: Hasil
    if (_resultBytes != null) {
      return InteractiveViewer(
        minScale: 0.5,
        maxScale: 3.0,
        child: Center(
          child: Image.memory(
            _resultBytes!,
            cacheWidth: 800, // Hemat memory
            fit: BoxFit.contain,
          ),
        ),
      );
    }

    // Fallback
    return const Center(child: Text('Tidak ada data'));
  }
}