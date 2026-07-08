import 'package:flutter/material.dart';
import '../services/quota_service.dart';

/// Layar untuk menampilkan status kuota harian dan status premium.
///
/// Fitur:
/// - Menampilkan sisa kuota generate hari ini
/// - Menampilkan status premium (aktif/tidak aktif)
/// - Informasi tentang batasan kuota
class PremiumScreen extends StatefulWidget {
  const PremiumScreen({super.key});

  @override
  State<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends State<PremiumScreen> {
  final QuotaService _quotaService = QuotaService();

  int _remainingQuota = 0;
  int _todayCount = 0;
  bool _isPremium = false;
  int _remainingDays = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadQuotaInfo();
  }

  /// Memuat informasi kuota dan premium dari QuotaService.
  Future<void> _loadQuotaInfo() async {
    setState(() => _isLoading = true);

    try {
      final remaining = await _quotaService.getRemainingQuota();
      final todayCount = await _quotaService.getTodayCount();
      final premiumStatus = await _quotaService.getPremiumStatus();

      if (mounted) {
        setState(() {
          _remainingQuota = remaining;
          _todayCount = todayCount;
          _isPremium = premiumStatus['isPremium'] as bool;
          _remainingDays = premiumStatus['remainingDays'] as int;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading quota: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Premium & Kuota'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadQuotaInfo,
              child: ListView(
                padding: const EdgeInsets.all(16.0),
                children: [
                  // Kartu status premium
                  _buildPremiumCard(),
                  const SizedBox(height: 16),

                  // Kartu kuota harian
                  _buildQuotaCard(),
                  const SizedBox(height: 16),

                  // Informasi tambahan
                  _buildInfoCard(),
                ],
              ),
            ),
    );
  }

  /// Kartu yang menampilkan status premium.
  Widget _buildPremiumCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Icon(
              _isPremium ? Icons.verified : Icons.star_border,
              size: 64,
              color: _isPremium ? Colors.amber : Colors.grey,
            ),
            const SizedBox(height: 12),
            Text(
              _isPremium ? 'Premium Aktif' : 'Belum Premium',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: _isPremium ? Colors.amber.shade800 : Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 8),
            if (_isPremium)
              Text(
                'Sisa $_remainingDays hari',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.green.shade700,
                ),
              )
            else
              Text(
                'Aktifkan premium untuk generate unlimited',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey.shade600,
                ),
                textAlign: TextAlign.center,
              ),
            const SizedBox(height: 16),
            if (!_isPremium)
              FilledButton.icon(
                onPressed: () {
                  _showInfoDialog(
                    'Premium',
                    'Fitur premium akan tersedia di update selanjutnya. '
                    'Dengan premium, Anda bisa generate tulisan tanpa batas!',
                  );
                },
                icon: const Icon(Icons.lock_open),
                label: const Text('Aktifkan Premium'),
              ),
          ],
        ),
      ),
    );
  }

  /// Kartu yang menampilkan sisa kuota harian.
  Widget _buildQuotaCard() {
    final bool isUnlimited = _isPremium && _remainingQuota == 999;
    final String quotaText = isUnlimited
        ? 'Unlimited'
        : '$_remainingQuota tersisa';
    final Color quotaColor = isUnlimited
        ? Colors.green
        : _remainingQuota > 0
            ? Colors.blue
            : Colors.red;

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.auto_awesome, color: quotaColor, size: 28),
                const SizedBox(width: 8),
                Text(
                  'Kuota Generate',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              quotaText,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: quotaColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Hari ini: $_todayCount / 2',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 12),
            // Progress bar kuota
            if (!isUnlimited)
              LinearProgressIndicator(
                value: _todayCount / 2.0,
                minHeight: 8,
                borderRadius: BorderRadius.circular(4),
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation<Color>(
                  _remainingQuota > 0 ? Colors.blue : Colors.red,
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Kartu informasi tentang kuota.
  Widget _buildInfoCard() {
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, size: 20, color: Colors.blue.shade700),
                const SizedBox(width: 8),
                Text(
                  'Informasi',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(),
            _buildInfoRow(
              Icons.refresh,
              'Kuota direset setiap hari',
            ),
            const SizedBox(height: 8),
            _buildInfoRow(
              Icons.star,
              'Premium = generate tanpa batas',
            ),
            const SizedBox(height: 8),
            _buildInfoRow(
              Icons.cloud_off,
              'Semua data tersimpan offline',
            ),
          ],
        ),
      ),
    );
  }

  /// Satu baris informasi dengan ikon.
  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey.shade600),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      ],
    );
  }

  /// Tampilkan dialog informasi.
  void _showInfoDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}