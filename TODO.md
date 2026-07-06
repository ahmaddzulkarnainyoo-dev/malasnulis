# TODO - Fix GitHub Actions Android build

## Plan yang akan dijalankan
- [ ] Update dependency `google_mobile_ads` di `pubspec.yaml` ke versi terbaru yang kompatibel (menghindari error `Namespace not specified`).
- [ ] Jalankan `flutter pub get` untuk meng-update `pubspec.lock`.
- [ ] Jalankan build lokal: `flutter build apk --release --split-per-abi`.
- [ ] Pastikan workflow `.github/workflows/build-android.yml` masih benar (artifact path ok).
- [ ] Commit perubahan dan push ke GitHub.

