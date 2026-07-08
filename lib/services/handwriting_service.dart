import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import '../widgets/paper_templates.dart';

/// Service inti untuk generate tulisan tangan di atas background (foto/template).
/// Semua proses berjalan 100% di device (offline-first).
class HandwritingService {
  /// Generate tulisan tangan [text] dengan berbagai opsi.
  ///
  /// Parameter:
  /// - [text]: teks yang akan ditulis tangan.
  /// - [fontSource]: 'digital' atau 'scan' (sumber huruf).
  /// - [backgroundSource]: 'scan' (foto) atau 'polos'/'bergaris'/'kotak'/'kuning'.
  /// - [scannedImageBytes]: bytes foto jika backgroundSource == 'scan'.
  ///
  /// Mengembalikan [Uint8List] berisi PNG hasil final.
  Future<Uint8List> generateHandwriting({
    required String text,
    required String fontSource,
    required String backgroundSource,
    Uint8List? scannedImageBytes,
  }) async {
    // ============================================================
    // 1. Tentukan Background
    // ============================================================
    img.Image paper;

    if (backgroundSource == 'scan') {
      // Pakai foto yang di-scan user
      if (scannedImageBytes == null) {
        throw Exception('scannedImageBytes wajib diisi jika backgroundSource = scan');
      }
      paper = img.decodeImage(scannedImageBytes)!;

      // Jika lebar > 1500px, resize ke 1500px untuk cegah OOM
      if (paper.width > 1500) {
        paper = img.copyResize(paper,
            width: 1500, interpolation: img.Interpolation.cubic);
      }
    } else {
      // Pakai template digital dari sistem
      paper = PaperTemplates.getPaperTemplate(backgroundSource);
    }

    final int paperWidth = paper.width;
    final int paperHeight = paper.height;

    // ============================================================
    // 2. Load Huruf dari Folder Sesuai fontSource
    // ============================================================
    final Map<String, img.Image> letterMap = {};

    if (fontSource == 'digital' || fontSource == 'scan') {
      final dir = await getApplicationDocumentsDirectory();
      final lettersDir = Directory('${dir.path}/malasnulis/$fontSource');

      if (!await lettersDir.exists()) {
        throw Exception(
          'Folder $fontSource tidak ditemukan. '
          'Silakan registrasi huruf $fontSource dulu.',
        );
      }

      final List<FileSystemEntity> files = await lettersDir.list().toList();
      for (final entity in files) {
        if (entity is File && entity.path.endsWith('.png')) {
          try {
            // Ambil nama file tanpa ekstensi
            final String letterName = entity.uri.pathSegments.last
                .replaceAll('.png', '');

            final img.Image letterImage = img.decodeImage(
              await entity.readAsBytes(),
            )!;

            letterMap[letterName] = letterImage;
          } catch (e) {
            debugPrint('Gagal load huruf: ${entity.path} - $e');
          }
        }
      }
    }

    if (letterMap.isEmpty) {
      throw Exception(
        'Tidak ada huruf yang ditemukan di folder $fontSource. '
        'Silakan registrasi huruf dulu.',
      );
    }

    // ============================================================
    // 3. Tentukan Skala Proporsional
    // ============================================================
    // Tinggi target huruf = 10% dari tinggi kertas
    final int targetHeight = (paperHeight * 0.10).round();
    final int lineHeight = (targetHeight * 1.5).round(); // Jarak antar baris

    // Ambil huruf pertama sebagai acuan skala (fallback jika 'A' tidak ada)
    final img.Image referenceLetter = letterMap.values.first;
    final double scaleFactor = targetHeight / referenceLetter.height.toDouble();

    // Resize SEMUA huruf dalam letterMap dengan skala yang sama
    final Map<String, img.Image> scaledLetters = {};
    for (final entry in letterMap.entries) {
      final int newWidth = (entry.value.width * scaleFactor).round();
      final int newHeight = (entry.value.height * scaleFactor).round();

      scaledLetters[entry.key] = img.copyResize(
        entry.value,
        width: newWidth > 0 ? newWidth : 1,
        height: newHeight > 0 ? newHeight : 1,
        interpolation: img.Interpolation.linear,
      );
    }

    // Hapus letterMap dari memory (biar GC bisa membersihkan)
    letterMap.clear();

    // ============================================================
    // 4. Word-Wrap & Layouting dengan Efek Natural
    // ============================================================
    // Margin
    final int startX = (paperWidth * 0.08).round();
    final int maxWidth = (paperWidth * 0.90).round();
    final int startY = (paperHeight * 0.10).round();

    int currentX = startX;
    int currentY = startY;

    // Random generator untuk efek natural
    final Random random = Random();

    // Loop setiap karakter di text
    for (int i = 0; i < text.length; i++) {
      final String char = text[i];

      // Handle newline
      if (char == '\n') {
        currentY += lineHeight;
        currentX = startX;
        continue;
      }

      // Handle spasi
      if (char == ' ') {
        currentX += 20; // Lebar spasi fix
        continue;
      }

      // Coba ambil huruf persis (case-sensitive), fallback ke uppercase
      img.Image? letter = scaledLetters[char] ?? scaledLetters[char.toUpperCase()];

      // Jika huruf tidak ditemukan, skip
      if (letter == null) {
        continue;
      }

      // Cek apakah perlu pindah baris
      if (currentX + letter.width > maxWidth) {
        currentY += lineHeight;
        currentX = startX;
      }

      // --- Terapkan Efek Natural ---
      // Rotasi: -3° sampai +3°
      final double angle = (random.nextDouble() * 6) - 3;
      // Offset X: -2 sampai 2
      final int offsetX = random.nextInt(5) - 2;
      // Offset Y: -2 sampai 2
      final int offsetY = random.nextInt(5) - 2;
      // Extra spacing antar huruf: 0-2 px
      final int extraSpacing = random.nextInt(3);

      // Rotasi huruf
      final img.Image rotatedLetter = img.copyRotate(
        letter,
        angle: angle,
      );

      // Composite ke background
      img.compositeImage(
        paper,
        rotatedLetter,
        dstX: currentX + offsetX,
        dstY: currentY + offsetY,
        blend: img.BlendMode.alpha,
      );

      // Update posisi X untuk huruf berikutnya
      currentX += letter.width + extraSpacing;
    }

    // ============================================================
    // 5. Konversi ke PNG dan Return
    // ============================================================
    final Uint8List result = Uint8List.fromList(img.encodePng(paper));

    // Hapus paper dari memory untuk membantu GC
    paper = img.Image(width: 1, height: 1);

    return result;
  }
}