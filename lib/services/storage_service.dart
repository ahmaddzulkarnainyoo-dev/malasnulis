import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

/// Service untuk menyimpan dan memuat file PNG huruf digital/scan.
/// Semua huruf disimpan di folder: Documents/malasnulis/{folder}/
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

  /// Mendapatkan direktori untuk folder tertentu (digital/ scan/ dll).
  /// Jika [folder] tidak disediakan, default ke 'digital'.
  Future<Directory> getFolderDirectory({String folder = 'digital'}) async {
    final appDir = await getAppDirectory();
    final dir = Directory('${appDir.path}/$folder');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  /// Menyimpan PNG huruf ke folder tertentu.
  /// [letter] adalah nama huruf (contoh: "A", "a", "B", "b").
  /// [pngBytes] adalah data PNG dalam bentuk Uint8List.
  /// [folder] adalah subfolder tujuan (default: 'digital').
  Future<void> saveDigitalLetter(String letter, Uint8List pngBytes, {String folder = 'digital'}) async {
    try {
      final dir = await getFolderDirectory(folder: folder);
      final file = File('${dir.path}/$letter.png');
      await file.writeAsBytes(pngBytes);
      debugPrint('Huruf $letter tersimpan di: ${file.path}');
    } catch (e) {
      debugPrint('Gagal menyimpan huruf $letter: $e');
      rethrow;
    }
  }

  /// Mengecek apakah suatu huruf sudah didaftarkan di folder tertentu.
  /// Mengembalikan true jika file {folder}/[letter].png ada.
  Future<bool> isDigitalLetterRegistered(String letter, {String folder = 'digital'}) async {
    try {
      final dir = await getFolderDirectory(folder: folder);
      final file = File('${dir.path}/$letter.png');
      return await file.exists();
    } catch (e) {
      return false;
    }
  }

  /// Mendapatkan daftar semua huruf yang sudah didaftarkan di folder tertentu.
  /// Mengembalikan list nama file tanpa ekstensi.
  Future<List<String>> getRegisteredDigitalLetters({String folder = 'digital'}) async {
    try {
      final dir = await getFolderDirectory(folder: folder);
      final List<FileSystemEntity> files = await dir.list().toList();
      final List<String> letters = [];

      for (final entity in files) {
        if (entity is File && entity.path.endsWith('.png')) {
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

  /// Mendapatkan total huruf yang sudah didaftarkan di folder tertentu.
  Future<int> getRegisteredCount({String folder = 'digital'}) async {
    final letters = await getRegisteredDigitalLetters(folder: folder);
    return letters.length;
  }

  /// Memuat bytes PNG huruf dari folder tertentu.
  /// Mengembalikan null jika file tidak ditemukan.
  Future<Uint8List?> loadLetterBytes(String letter, {String folder = 'digital'}) async {
    try {
      final dir = await getFolderDirectory(folder: folder);
      final file = File('${dir.path}/$letter.png');
      if (await file.exists()) {
        return await file.readAsBytes();
      }
      return null;
    } catch (e) {
      debugPrint('Gagal load huruf $letter: $e');
      return null;
    }
  }
}