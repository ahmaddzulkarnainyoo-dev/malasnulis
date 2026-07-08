import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'screens/register_digital_screen.dart';
import 'screens/home_screen.dart';
import 'screens/premium_screen.dart';
import 'services/storage_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inisialisasi AdMob
  await MobileAds.instance.initialize();

  runApp(const MalasNulisApp());
}

class MalasNulisApp extends StatelessWidget {
  const MalasNulisApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Malas Nulis',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.indigo,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      // Layar pertama: RegisterDigitalScreen (wajib registrasi dulu)
      home: const RegisterDigitalScreen(),
      routes: {
        '/home': (context) => const MainScreen(),
        '/premium': (context) => const PremiumScreen(),
      },
    );
  }
}

/// Layar utama dengan BottomNavigationBar (3 tab).
/// Tab: Beranda, Data Huruf, Premium.
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  // Halaman untuk setiap tab
  final List<Widget> _pages = const [
    HomeScreen(),
    DataHurufScreen(),
    PremiumScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() => _currentIndex = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Beranda',
          ),
          NavigationDestination(
            icon: Icon(Icons.font_download_outlined),
            selectedIcon: Icon(Icons.font_download),
            label: 'Data Huruf',
          ),
          NavigationDestination(
            icon: Icon(Icons.star_outline),
            selectedIcon: Icon(Icons.star),
            label: 'Premium',
          ),
        ],
      ),
    );
  }
}

/// Layar untuk menampilkan status registrasi huruf digital.
/// User bisa melihat huruf apa saja yang sudah didaftarkan,
/// dan tombol untuk menambah/edit huruf digital.
class DataHurufScreen extends StatefulWidget {
  const DataHurufScreen({super.key});

  @override
  State<DataHurufScreen> createState() => _DataHurufScreenState();
}

class _DataHurufScreenState extends State<DataHurufScreen> {
  final StorageService _storageService = StorageService();
  int _registeredCount = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final count = await _storageService.getRegisteredCount();
      if (mounted) {
        setState(() {
          _registeredCount = count;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Data Huruf Digital'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: ListView(
                padding: const EdgeInsets.all(16.0),
                children: [
                  // Kartu status registrasi
                  Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        children: [
                          Icon(
                            _registeredCount >= 52
                                ? Icons.check_circle
                                : Icons.font_download,
                            size: 64,
                            color: _registeredCount >= 52
                                ? Colors.green
                                : Colors.orange,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _registeredCount >= 52
                                ? 'Lengkap!'
                                : 'Belum Lengkap',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '$_registeredCount / 52 huruf terdaftar',
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                          const SizedBox(height: 8),
                          // Progress bar
                          LinearProgressIndicator(
                            value: _registeredCount / 52.0,
                            minHeight: 8,
                            borderRadius: BorderRadius.circular(4),
                            backgroundColor: Colors.grey.shade200,
                          ),
                          const SizedBox(height: 16),
                          // Tombol tambah/edit
                          FilledButton.icon(
                            onPressed: () {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const RegisterDigitalScreen(),
                                ),
                              );
                            },
                            icon: Icon(
                              _registeredCount >= 52
                                  ? Icons.edit
                                  : Icons.add,
                            ),
                            label: Text(
                              _registeredCount >= 52
                                  ? 'Edit Huruf Digital'
                                  : 'Tambah Huruf Digital',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Informasi
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Informasi',
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const Divider(),
                          const Text(
                            '• Daftarkan 52 huruf (A-Z dan a-z) '
                            'untuk hasil generate maksimal.',
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            '• Tulis setiap huruf satu per satu '
                            'di kanvas dengan jari.',
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            '• Hasil akan disimpan sebagai PNG '
                            'transparan di penyimpanan lokal.',
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}