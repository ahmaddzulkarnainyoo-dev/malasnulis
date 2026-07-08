import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

/// Service untuk menyimpan dan memuat file PNG huruf digital.
/// Semua huruf disimpan di folder: Documents/malasnulis/digital/
class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  /// Mendapatkan direktori utama aplikasi: Documents/malasnulis/
  Future<Directory> getAppDirectory() async {
    final appDocDir = await getApplicationDocumentsDirectory();
    final dir = Directory('${appDocDir.path}/malasnulis');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  /// Mendapatkan direktori untuk huruf digital: Documents/malasnulis/digital/
  Future<Directory> getDigitalDirectory() async {
    final appDir = await getAppDirectory();
    final dir = Directory('${appDir.path}/digital');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  /// Menyimpan PNG huruf digital ke folder digital/.
  /// [letter] adalah nama huruf (contoh: "A", "a", "B", "b").
  /// [pngBytes] adalah data PNG dalam bentuk Uint8List.
  Future<void> saveDigitalLetter(String letter, Uint8List pngBytes) async {
    try {
      final digitalDir = await getDigitalDirectory();
      final file = File('${digitalDir.path}/$letter.png');
      await file.writeAsBytes(pngBytes);
      debugPrint('Huruf $letter tersimpan di: ${file.path}');
    } catch (e) {
      debugPrint('Gagal menyimpan huruf $letter: $e');
      rethrow;
    }
  }

  /// Mengecek apakah suatu huruf sudah didaftarkan.
  /// Mengembalikan true jika file digital/[letter].png ada.
  Future<bool> isDigitalLetterRegistered(String letter) async {
    try {
      final digitalDir = await getDigitalDirectory();
      final file = File('${digitalDir.path}/$letter.png');
      return await file.exists();
    } catch (e) {
      return false;
    }
  }

  /// Mendapatkan daftar semua huruf yang sudah didaftarkan (A-Z dan a-z).
  /// Mengembalikan list nama file tanpa ekstensi, contoh: ["A", "B", ..., "z"].
  Future<List<String>> getRegisteredDigitalLetters() async {
    try {
      final digitalDir = await getDigitalDirectory();
      final List<FileSystemEntity> files = await digitalDir.list().toList();
      final List<String> letters = [];

      for (final entity in files) {
        if (entity is File && entity.path.endsWith('.png')) {
          // Ambil nama file tanpa ekstensi .png
          final String fileName = entity.uri.pathSegments.last
              .replaceAll('.png', '');
          letters.add(fileName);
        }
      }

      return letters;
    } catch (e) {
      debugPrint('Gagal membaca daftar huruf: $e');
      return [];
    }
  }

  /// Mendapatkan total huruf yang sudah didaftarkan.
  Future<int> getRegisteredCount() async {
    final letters = await getRegisteredDigitalLetters();
    return letters.length;
  }
}