import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

/// Service inti untuk generate tulisan tangan di atas foto kertas.
/// Semua proses berjalan 100% di device (offline-first).
class HandwritingService {
  /// Generate tulisan tangan [text] di atas foto [paperImagePath].
  /// Mengembalikan [Uint8List] berisi PNG hasil final.
  ///
  /// Proses:
  /// 1. Load & resize foto kertas (max 1500px) untuk cegah OOM
  /// 2. Load huruf A-Z dari folder documents/letters/
  /// 3. Skala proporsional huruf (10% dari tinggi kertas)
  /// 4. Word-wrap & layouting dengan efek natural (random rotasi, offset, spacing)
  /// 5. Composite ke foto kertas
  /// 6. Return sebagai PNG bytes
  static Future<Uint8List> generateHandwriting({
    required String text,
    required String paperImagePath,
  }) async {
    // ============================================================
    // 1. Load & Resize Foto Kertas (Cegah OOM)
    // ============================================================
    img.Image paper = img.decodeImage(
      await File(paperImagePath).readAsBytes(),
    )!;

    // Jika lebar > 1500px, resize ke 1500px
    if (paper.width > 1500) {
      paper = img.copyResize(paper,
          width: 1500, interpolation: img.Interpolation.cubic);
    }

    final int paperWidth = paper.width;
    final int paperHeight = paper.height;

    // ============================================================
    // 2. Load Huruf yang Sudah Didaftarkan (A-Z)
    // ============================================================
    final Map<String, img.Image> letterMap = {};
    final dir = await getApplicationDocumentsDirectory();
    final lettersDir = Directory('${dir.path}/letters');

    if (!await lettersDir.exists()) {
      throw Exception('Folder letters tidak ditemukan. Silakan registrasi huruf dulu.');
    }

    final List<FileSystemEntity> files = await lettersDir.list().toList();
    for (final entity in files) {
      if (entity is File && entity.path.endsWith('.png')) {
        try {
          // Ambil nama file tanpa ekstensi (contoh: "A", "B", "C")
          final String letterName = entity.uri.pathSegments.last
              .replaceAll('.png', '')
              .toUpperCase();

          final img.Image letterImage = img.decodeImage(
            await entity.readAsBytes(),
          )!;

          letterMap[letterName] = letterImage;
        } catch (e) {
          debugPrint('Gagal load huruf: ${entity.path} - $e');
        }
      }
    }

    if (letterMap.isEmpty) {
      throw Exception('Tidak ada huruf yang ditemukan. Silakan registrasi huruf dulu.');
    }

    // ============================================================
    // 3. Tentukan Skala Proporsional
    // ============================================================
    // Tinggi target huruf = 10% dari tinggi kertas
    final int targetHeight = (paperHeight * 0.10).round();
    final int lineHeight = (targetHeight * 1.5).round(); // Jarak antar baris

    // Ambil huruf 'A' sebagai acuan skala
    final img.Image referenceLetter = letterMap['A']!;
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

      // Ambil huruf dari map (fallback ke kapital jika huruf kecil tidak ada)
      final String letterKey = char.toUpperCase();
      img.Image? letter = scaledLetters[letterKey];

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

      // Composite ke foto kertas
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
    paper = img.Image(width: 1, height: 1); // Ganti dengan gambar dummy kecil

    return result;
  }
}