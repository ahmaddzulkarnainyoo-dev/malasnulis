import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'screens/register_digital_screen.dart';
import 'screens/register_scan_screen.dart';
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

/// Layar untuk menampilkan status registrasi huruf (Digital & Scan).
/// User bisa melihat status dan tombol untuk registrasi/tambah/edit.
class DataHurufScreen extends StatefulWidget {
  const DataHurufScreen({super.key});

  @override
  State<DataHurufScreen> createState() => _DataHurufScreenState();
}

class _DataHurufScreenState extends State<DataHurufScreen> {
  final StorageService _storageService = StorageService();

  // Status digital
  int _digitalCount = 0;
  // Status scan
  int _scanCount = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    setState(() => _isLoading = true);
    try {
      final digital = await _storageService.getRegisteredCount(folder: 'digital');
      final scan = await _storageService.getRegisteredCount(folder: 'scan');
      if (mounted) {
        setState(() {
          _digitalCount = digital;
          _scanCount = scan;
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
        title: const Text('Data Huruf'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadAllData,
              child: ListView(
                padding: const EdgeInsets.all(16.0),
                children: [
                  // Card 1: Digital
                  _buildMethodCard(
                    icon: Icons.touch_app,
                    title: 'Digital (Tulis di HP)',
                    count: _digitalCount,
                    color: Colors.indigo,
                    onEdit: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const RegisterDigitalScreen(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),

                  // Card 2: Scan Kertas
                  _buildMethodCard(
                    icon: Icons.camera_alt,
                    title: 'Scan Kertas (4×13)',
                    count: _scanCount,
                    color: Colors.teal,
                    onEdit: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const RegisterScanScreen(),
                        ),
                      );
                    },
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
                            'Info',
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const Divider(),
                          const Text('• 52 huruf (A-Z + a-z) per metode.'),
                          const SizedBox(height: 4),
                          const Text('• Digital: tulis langsung di layar.'),
                          const SizedBox(height: 4),
                          const Text('• Scan: foto kertas yang sudah ditulisi.'),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  /// Membangun satu card untuk satu metode registrasi.
  Widget _buildMethodCard({
    required IconData icon,
    required String title,
    required int count,
    required Color color,
    required VoidCallback onEdit,
  }) {
    final bool isComplete = count >= 52;

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Icon(
              isComplete ? Icons.check_circle : icon,
              size: 48,
              color: isComplete ? Colors.green : color,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              isComplete
                  ? 'Lengkap ($count/52)'
                  : '$count / 52 huruf terdaftar',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: isComplete ? Colors.green : Colors.orange.shade700,
              ),
            ),
            if (!isComplete)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: LinearProgressIndicator(
                  value: count / 52.0,
                  minHeight: 6,
                  borderRadius: BorderRadius.circular(3),
                  backgroundColor: Colors.grey.shade200,
                ),
              ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onEdit,
              icon: Icon(isComplete ? Icons.edit : Icons.add),
              label: Text(
                isComplete ? 'Edit' : 'Daftar',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
