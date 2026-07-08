import 'package:image/image.dart' as img;

/// 4 Template kertas digital yang dibuat oleh sistem (tanpa aset eksternal).
///
/// Ukuran: 1200 x 1600 pixel (proporsi A4 portrait).
/// Semua template di-generate menggunakan package `image` (pure Dart).
class PaperTemplates {
  /// Mendapatkan template kertas berdasarkan tipe.
  /// [type] bisa: 'polos', 'bergaris', 'kotak', 'kuning'.
  /// Default: polos.
  static img.Image getPaperTemplate(String type) {
    switch (type) {
      case 'polos':
        return _createPolos();
      case 'bergaris':
        return _createBergaris();
      case 'kotak':
        return _createKotak();
      case 'kuning':
        return _createKuning();
      default:
        return _createPolos();
    }
  }

  /// Template 1: Polos Putih
  /// Background putih polos tanpa garis apapun.
  static img.Image _createPolos() {
    final image = img.Image(width: 1200, height: 1600);
    // Fill putih
    img.fill(image, color: img.ColorRgb8(255, 255, 255));
    return image;
  }

  /// Template 2: Bergaris (Folio)
  /// Background putih dengan garis horizontal biru muda (#B0C4DE).
  /// Jarak antar garis: 40px, dari y=100 sampai y=1500.
  static img.Image _createBergaris() {
    final image = img.Image(width: 1200, height: 1600);
    // Fill putih
    img.fill(image, color: img.ColorRgb8(255, 255, 255));

    // Garis horizontal biru muda
    final lineColor = img.ColorRgb8(176, 196, 222); // #B0C4DE
    for (int y = 100; y <= 1500; y += 40) {
      img.drawLine(
        image,
        x1: 40,
        y1: y,
        x2: 1160,
        y2: y,
        color: lineColor,
        thickness: 1,
      );
    }

    return image;
  }

  /// Template 3: Kotak-Kotak (Grid)
  /// Background putih dengan garis horizontal + vertikal abu-abu (#D3D3D3).
  /// Jarak antar garis: 40px, membentuk grid.
  static img.Image _createKotak() {
    final image = img.Image(width: 1200, height: 1600);
    // Fill putih
    img.fill(image, color: img.ColorRgb8(255, 255, 255));

    final gridColor = img.ColorRgb8(211, 211, 211); // #D3D3D3

    // Garis horizontal
    for (int y = 40; y < 1600; y += 40) {
      img.drawLine(
        image,
        x1: 0,
        y1: y,
        x2: 1199,
        y2: y,
        color: gridColor,
        thickness: 1,
      );
    }

    // Garis vertikal
    for (int x = 40; x < 1200; x += 40) {
      img.drawLine(
        image,
        x1: x,
        y1: 0,
        x2: x,
        y2: 1599,
        color: gridColor,
        thickness: 1,
      );
    }

    return image;
  }

  /// Template 4: Kuning (Vintage/Nota)
  /// Background kuning muda (#FFF8DC).
  static img.Image _createKuning() {
    final image = img.Image(width: 1200, height: 1600);
    // Fill kuning muda vintage
    img.fill(image, color: img.ColorRgb8(255, 248, 220)); // #FFF8DC

    // Opsional: tambah garis horizontal tipis untuk efek nota
    final lineColor = img.ColorRgba8(200, 190, 160, 80); // semi-transparan
    for (int y = 100; y <= 1500; y += 40) {
      img.drawLine(
        image,
        x1: 40,
        y1: y,
        x2: 1160,
        y2: y,
        color: lineColor,
        thickness: 1,
      );
    }

    return image;
  }
}