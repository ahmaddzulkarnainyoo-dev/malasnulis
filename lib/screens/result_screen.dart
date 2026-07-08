import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import '../services/ad_service.dart';

/// Layar untuk menampilkan hasil generate tulisan tangan.
///
/// Menerima [imageBytes] dan [text] langsung (dari HomeScreen)
/// atau dari route arguments (backward compatibility).
class ResultScreen extends StatefulWidget {
  final Uint8List? imageBytes;
  final String? text;

  const ResultScreen({
    super.key,
    this.imageBytes,
    this.text,
  });

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  Uint8List? _resultBytes;
  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();

    // Cek apakah data dari constructor atau dari route arguments
    if (widget.imageBytes != null) {
      _resultBytes = widget.imageBytes;
      _isLoading = false;
    } else {
      _loadFromArguments();
    }
  }

  /// Load data dari route arguments (backward compatibility)
  Future<void> _loadFromArguments() async {
    try {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (args == null) {
        throw Exception('Data tidak ditemukan');
      }

      // Cek apakah ada imageBytes langsung
      final bytes = args['imageBytes'] as Uint8List?;
      if (bytes != null) {
        setState(() {
          _resultBytes = bytes;
          _isLoading = false;
        });
        return;
      }

      // Fallback: butuh generate ulang (ini seharusnya jarang terjadi)
      throw Exception('Data gambar tidak lengkap');
    } catch (e) {
      debugPrint('Error loading result: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
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
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Memproses...'),
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
                onPressed: _loadFromArguments,
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