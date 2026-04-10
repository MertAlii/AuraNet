import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';

class DnsTestScreen extends ConsumerStatefulWidget {
  const DnsTestScreen({super.key});

  @override
  ConsumerState<DnsTestScreen> createState() => _DnsTestScreenState();
}

class _DnsTestScreenState extends ConsumerState<DnsTestScreen> {
  // Aktif DNS State
  bool _isCheckingActive = false;
  List<String> _activeDnsServers = [];
  
  // Önerilen DNS State
  bool _isTestingRecommended = false;
  final Map<String, String> _recommendedDns = {
    'Cloudflare (Çok Hızlı, Gizlilik)': '1.1.1.1',
    'Google (Kararlı)': '8.8.8.8',
    'Quad9 (Kötü Amaçlı Yazılım Koruması)': '9.9.9.9',
    'OpenDNS (Aile Filtresi)': '208.67.222.222',
  };
  final Map<String, int> _dnsPings = {};

  // DNS Sorgusu State
  final _domainController = TextEditingController();
  bool _isQuerying = false;
  String _queryResult = '';

  @override
  void initState() {
    super.initState();
    _checkActiveDns();
  }

  @override
  void dispose() {
    _domainController.dispose();
    super.dispose();
  }

  Future<void> _checkActiveDns() async {
    setState(() {
      _isCheckingActive = true;
      _activeDnsServers.clear();
    });

    try {
      if (Platform.isAndroid) {
        final result1 = await Process.run('getprop', ['net.dns1']);
        if (result1.stdout.toString().trim().isNotEmpty) {
          _activeDnsServers.add(result1.stdout.toString().trim());
        }
        final result2 = await Process.run('getprop', ['net.dns2']);
        if (result2.stdout.toString().trim().isNotEmpty) {
          _activeDnsServers.add(result2.stdout.toString().trim());
        }
      }
      
      // Fallback
      if (_activeDnsServers.isEmpty) {
        _activeDnsServers = ['192.168.1.1 (Tahmini Yönlendirici IPv4)', 'Bilinmiyor (Sistem Yanıt Vermedi)'];
      }
    } catch (e) {
      _activeDnsServers = ['Hata: Tespit Edilemedi'];
    }

    setState(() {
      _isCheckingActive = false;
    });
  }

  Future<void> _testRecommendedDns() async {
    setState(() {
      _isTestingRecommended = true;
      _dnsPings.clear();
    });

    for (var ip in _recommendedDns.values) {
      int pingTime = -1; // -1 means timeout/error
      final stopwatch = Stopwatch()..start();
      try {
        // Port 53'e TCP bağlantısı atarak gecikmeyi ölç (ICMP engellenmiş olabilir)
        final socket = await Socket.connect(ip, 53, timeout: const Duration(seconds: 2));
        pingTime = stopwatch.elapsedMilliseconds;
        socket.destroy();
      } catch (_) {}
      
      if (mounted) {
        setState(() {
          _dnsPings[ip] = pingTime;
        });
      }
    }

    if (mounted) {
      setState(() {
        _isTestingRecommended = false;
      });
    }
  }

  Future<void> _lookupDomain() async {
    final target = _domainController.text.trim();
    if (target.isEmpty) return;

    FocusScope.of(context).unfocus();
    setState(() {
      _isQuerying = true;
      _queryResult = 'Sorgulanıyor...';
    });

    try {
      final lookup = await InternetAddress.lookup(target).timeout(const Duration(seconds: 5));
      if (lookup.isNotEmpty) {
        _queryResult = lookup.map((ip) => ip.address).join('\n');
      } else {
        _queryResult = 'IP bulunamadı.';
      }
    } catch (e) {
      _queryResult = 'Hata: Hedefe ulaşılamadı veya geçersiz format.';
    }

    setState(() {
      _isQuerying = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDeep,
      appBar: AppBar(title: const Text('Gelişmiş DNS Analizörü')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildActiveDnsCard(),
            const SizedBox(height: 24),
            _buildRecommendedDnsCard(),
            const SizedBox(height: 24),
            _buildQueryCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveDnsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primaryBlue.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.shield_outlined, color: AppColors.primaryBlueLight),
              const SizedBox(width: 12),
              const Text('Kullandığınız DNS', style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
              const Spacer(),
              if (_isCheckingActive)
                const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryBlue)),
            ],
          ),
          const SizedBox(height: 16),
          if (!_isCheckingActive && _activeDnsServers.isNotEmpty)
            ..._activeDnsServers.map((dns) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  const Icon(Icons.arrow_right_rounded, color: AppColors.safe),
                  const SizedBox(width: 8),
                  Expanded(child: Text(dns, style: const TextStyle(color: AppColors.textPrimary, fontSize: 15, fontFamily: 'JetBrains Mono'))),
                ],
              ),
            )),
          const SizedBox(height: 12),
          const Text('NOT: Eğer burada standart IP (örn: 192.168.1.1) görüyorsanız, sorgularınız İSS\'nize veya Google\'a şifrelenmeden gidiyor olabilir.', style: TextStyle(color: AppColors.textHint, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildRecommendedDnsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primaryBlue.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.speed_rounded, color: AppColors.warning),
              const SizedBox(width: 12),
              const Expanded(child: Text('Hızlı ve Güvenli DNS Önerileri', style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold))),
            ],
          ),
          const SizedBox(height: 16),
          const Text('Farklı DNS sunucularının size olan yanıt sürelerini (gecikme) test edin.', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          const SizedBox(height: 16),
          ..._recommendedDns.entries.map((req) {
            final ip = req.value;
            final ping = _dnsPings[ip];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(req.key, style: const TextStyle(color: AppColors.textPrimary, fontSize: 14)),
                        Text(ip, style: const TextStyle(color: AppColors.textHint, fontSize: 12, fontFamily: 'JetBrains Mono')),
                      ],
                    ),
                  ),
                  if (ping == null)
                    const Text('-- ms', style: TextStyle(color: AppColors.textSecondary))
                  else if (ping == -1)
                    const Text('Zaman Aşımı', style: TextStyle(color: AppColors.danger, fontSize: 12))
                  else
                    Text('$ping ms', style: TextStyle(color: ping < 50 ? AppColors.safe : AppColors.warning, fontWeight: FontWeight.bold)),
                ],
              ),
            );
          }),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isTestingRecommended ? null : _testRecommendedDns,
              icon: _isTestingRecommended ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.route_rounded),
              label: Text(_isTestingRecommended ? 'Test Ediliyor...' : 'Gecikme Testi Başlat'),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryBlue),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildQueryCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primaryBlue.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.search_rounded, color: AppColors.primaryBlueLight),
              const SizedBox(width: 12),
              const Text('DNS Sorgulayıcı', style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 16),
          const Text('Bir web sitesinin (örn: www.google.com) hangi IP adreslerine yönlendirildiğini sorgulayın.', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _domainController,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'www.turkiye.gov.tr',
                    hintStyle: const TextStyle(color: AppColors.textHint),
                    filled: true,
                    fillColor: AppColors.backgroundDeep,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: _isQuerying ? null : _lookupDomain,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.all(14),
                ),
                child: _isQuerying ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.arrow_forward_rounded, color: Colors.white),
              )
            ],
          ),
          if (_queryResult.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: AppColors.backgroundDeep.withOpacity(0.5), borderRadius: BorderRadius.circular(8)),
              child: Text(_queryResult, style: const TextStyle(color: AppColors.safe, fontFamily: 'JetBrains Mono', fontSize: 14)),
            ),
          ]
        ],
      ),
    );
  }
}
