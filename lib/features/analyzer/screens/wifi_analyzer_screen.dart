import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/channel_rating_utils.dart';
import '../providers/wifi_analyzer_provider.dart';
import '../models/wifi_network_model.dart';
import 'package:fl_chart/fl_chart.dart';

class WiFiAnalyzerScreen extends ConsumerStatefulWidget {
  const WiFiAnalyzerScreen({super.key});

  @override
  ConsumerState<WiFiAnalyzerScreen> createState() => _WiFiAnalyzerScreenState();
}

class _WiFiAnalyzerScreenState extends ConsumerState<WiFiAnalyzerScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _radarController;
  String _selectedBand = '2.4 GHz'; // 2.4 GHz veya 5 GHz
  
  final List<Color> _chartColors = const [
    AppColors.primaryBlue, AppColors.safe, AppColors.warning, 
    Colors.purple, Colors.pinkAccent, Colors.teal, Colors.orange
  ];

  Color _getColorForNetwork(int index) => _chartColors[index % _chartColors.length];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _radarController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    
    // Taramayı başlat
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(wifiAnalyzerProvider.notifier).startContinuousScan();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _radarController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final analyzerState = ref.watch(wifiAnalyzerProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundDeep,
      appBar: AppBar(
        title: Row(
          children: [
            if (analyzerState.isScanning)
              RotationTransition(
                turns: _radarController,
                child: const Icon(Icons.radar_rounded, color: AppColors.primaryBlueLight, size: 20),
              ),
            if (analyzerState.isScanning) const SizedBox(width: 8),
            const Text('Wi-Fi Analizörü'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline_rounded),
            onPressed: () => _showGraphInfo(context),
          ),
          const SizedBox(width: 8),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: AppColors.primaryBlue,
          labelColor: AppColors.primaryBlue,
          unselectedLabelColor: AppColors.textSecondary,
          tabs: const [
            Tab(text: 'Erişim Noktaları'),
            Tab(text: 'Kanal Grafiği'),
            Tab(text: 'Zaman Grafiği'),
            Tab(text: 'Derecelendirme'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildAPListTab(analyzerState),
          _buildChannelGraphTab(analyzerState),
          _buildTimeGraphTab(analyzerState),
          _buildRatingTab(analyzerState),
        ],
      ),
    );
  }

  void _showNetworkDetails(WiFiNetworkModel network) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: AppColors.backgroundCard,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(color: AppColors.textHint, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Icon(network.isSecure ? Icons.lock_rounded : Icons.lock_open_rounded, color: AppColors.primaryBlue),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    network.ssid.isEmpty ? 'Gizli Ağ' : network.ssid,
                    style: const TextStyle(color: AppColors.textPrimary, fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _detailRow(Icons.fingerprint_rounded, 'BSSID (MAC)', network.bssid),
            _detailRow(Icons.wifi_tethering_rounded, 'Frekans', '${network.frequency} MHz'),
            _detailRow(Icons.speed_rounded, 'Sinyal Gücü', '${network.level} dBm (%${network.signalLevel})'),
            _detailRow(Icons.straighten_rounded, 'Mesafe Tahmini', '${network.distance.toStringAsFixed(1)} metre'),
            _detailRow(Icons.security_rounded, 'Güvenlik', network.capabilities),
            _detailRow(Icons.router_rounded, 'Kanal', 'Kanal ${network.channel} (${network.band})'),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.qr_code_2_rounded),
                label: const Text('QR ile Paylaş'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue.withOpacity(0.1),
                  foregroundColor: AppColors.primaryBlueLight,
                  side: const BorderSide(color: AppColors.primaryBlue),
                ),
                onPressed: () {
                  Navigator.pop(context);
                  context.push('/qrShare', extra: network.ssid);
                },
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.backgroundBorder.withOpacity(0.2),
                  foregroundColor: AppColors.textPrimary,
                ),
                child: const Text('Kapat'),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Icon(icon, color: AppColors.textSecondary, size: 20),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: AppColors.textHint, fontSize: 12)),
              Text(value, style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAPListTab(WiFiAnalyzerState state) {
    if (state.networks.isEmpty && state.isScanning) {
      return const Center(child: CircularProgressIndicator());
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: state.networks.length,
      itemBuilder: (context, index) {
        final network = state.networks[index];
        return _buildNetworkCard(network);
      },
    );
  }

  Widget _buildNetworkCard(WiFiNetworkModel network) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.backgroundBorder.withValues(alpha: 0.3)),
      ),
      child: InkWell(
        onTap: () => _showNetworkDetails(network),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48, height: 48,
                decoration: BoxDecoration(
                  color: network.isSecure ? AppColors.primaryBlue.withValues(alpha: 0.1) : AppColors.danger.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  network.isSecure ? Icons.lock_outline_rounded : Icons.lock_open_rounded,
                  color: network.isSecure ? AppColors.primaryBlue : AppColors.danger,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      network.ssid.isEmpty ? 'Gizli Ağ' : network.ssid,
                      style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text('${network.band} · Kanal ${network.channel} · ${network.level} dBm',
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                  ],
                ),
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _getSignalIcon(network.level),
                    color: _getSignalColor(network.level),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${network.signalLevel}%',
                    style: TextStyle(color: _getSignalColor(network.level), fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBandFilter() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ChoiceChip(
          label: const Text('2.4 GHz'),
          selected: _selectedBand == '2.4 GHz',
          onSelected: (val) { if (val) setState(() => _selectedBand = '2.4 GHz'); },
          selectedColor: AppColors.primaryBlue.withOpacity(0.2),
          labelStyle: TextStyle(color: _selectedBand == '2.4 GHz' ? AppColors.primaryBlueLight : AppColors.textSecondary),
        ),
        const SizedBox(width: 12),
        ChoiceChip(
          label: const Text('5/6 GHz'),
          selected: _selectedBand == '5 GHz',
          onSelected: (val) { if (val) setState(() => _selectedBand = '5 GHz'); },
          selectedColor: Colors.purple.withOpacity(0.2),
          labelStyle: TextStyle(color: _selectedBand == '5 GHz' ? Colors.purple[200] : AppColors.textSecondary),
        ),
      ],
    );
  }

  Widget _buildChannelGraphTab(WiFiAnalyzerState state) {
    final filteredNetworks = state.networks.where((n) {
      if (_selectedBand == '5 GHz') return n.band == '5 GHz' || n.band == '6 GHz';
      return n.band == '2.4 GHz';
    }).toList();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildBandFilter(),
          const SizedBox(height: 16),
          Expanded(
            child: LineChart(
              LineChartData(
                minX: _selectedBand == '2.4 GHz' ? 1 : 36, 
                maxX: _selectedBand == '2.4 GHz' ? 14 : 165,
                minY: -100, maxY: -20,
                lineBarsData: filteredNetworks.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final n = entry.value;
                  return LineChartBarData(
                    spots: _getParabolaSpots(n.channel.toDouble(), n.level.toDouble(), _selectedBand == '2.4 GHz'),
                    isCurved: true,
                    color: _getColorForNetwork(idx),
                    barWidth: 2,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          _getColorForNetwork(idx).withOpacity(0.3),
                          _getColorForNetwork(idx).withOpacity(0.0),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  );
                }).toList(),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: true, interval: _selectedBand == '2.4 GHz' ? 1 : 16, reservedSize: 22),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: true, interval: 20, reservedSize: 32),
                  ),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: true,
                  horizontalInterval: 20,
                  verticalInterval: _selectedBand == '2.4 GHz' ? 1 : 16,
                  getDrawingHorizontalLine: (value) => FlLine(color: AppColors.backgroundBorder.withOpacity(0.1), strokeWidth: 1),
                  getDrawingVerticalLine: (value) => FlLine(color: AppColors.backgroundBorder.withOpacity(0.1), strokeWidth: 1),
                ),
                borderData: FlBorderData(show: false),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Legend
          SizedBox(
            height: 60,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: filteredNetworks.asMap().entries.map((e) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: Row(
                      children: [
                        Container(width: 12, height: 12, decoration: BoxDecoration(color: _getColorForNetwork(e.key), shape: BoxShape.circle)),
                        const SizedBox(width: 4),
                        Text(e.value.ssid.isEmpty ? 'Gizli' : e.value.ssid, style: const TextStyle(color: AppColors.textPrimary, fontSize: 12)),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          )
        ],
      ),
    );
  }

  List<FlSpot> _getParabolaSpots(double channel, double level, bool is24) {
    double spread = is24 ? 2.0 : 4.0;
    return [
      FlSpot(channel - spread, -100),
      FlSpot(channel - (spread/2), level - 10),
      FlSpot(channel, level),
      FlSpot(channel + (spread/2), level - 10),
      FlSpot(channel + spread, -100),
    ];
  }

  Widget _buildTimeGraphTab(WiFiAnalyzerState state) {
    final filteredNetworks = state.networks.where((n) {
      if (_selectedBand == '5 GHz') return n.band == '5 GHz' || n.band == '6 GHz';
      return n.band == '2.4 GHz';
    }).toList();

    if (filteredNetworks.isEmpty) {
      return Center(child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildBandFilter(),
          const SizedBox(height: 24),
          const Text('Bu frekansta ağ bulunamadı.', style: TextStyle(color: AppColors.textSecondary)),
        ],
      ));
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildBandFilter(),
          const SizedBox(height: 16),
          const Text('Sinyal Geçmişi', style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('Bulunan ağların sinyal dalgalanmaları (simüle).', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          const SizedBox(height: 32),
          Expanded(
            child: LineChart(
              LineChartData(
                minY: -100, maxY: -20,
                lineBarsData: [
                  for (int i = 0; i < filteredNetworks.length; i++)
                    LineChartBarData(
                      spots: List.generate(10, (idx) => FlSpot(idx.toDouble(), filteredNetworks[i].level + (idx % 2 == 0 ? 2.0 : -2.0))),
                      isCurved: true,
                      color: _getColorForNetwork(i),
                      barWidth: 3,
                      dotData: const FlDotData(show: false),
                    ),
                ],
                titlesData: const FlTitlesData(
                  bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, interval: 20)),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: const FlGridData(show: true, drawVerticalLine: false),
                borderData: FlBorderData(show: false),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Legend
          SizedBox(
            height: 60,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: filteredNetworks.asMap().entries.map((e) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: Row(
                      children: [
                        Container(width: 12, height: 12, decoration: BoxDecoration(color: _getColorForNetwork(e.key), shape: BoxShape.circle)),
                        const SizedBox(width: 4),
                        Text(e.value.ssid.isEmpty ? 'Gizli' : e.value.ssid, style: const TextStyle(color: AppColors.textPrimary, fontSize: 12)),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildRatingTab(WiFiAnalyzerState state) {
    final ratings = ChannelRatingUtils.rateChannels(state.networks);
    final bestChannels = ratings.take(3).toList();

    return Column(
      children: [
        // En iyi kanal başlığı
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(24),
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primaryBlue.withValues(alpha: 0.2), AppColors.backgroundCard],
              begin: Alignment.topLeft, end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.primaryBlue.withValues(alpha: 0.3)),
          ),
          child: Column(
            children: [
              const Text('Tavsiye Edilen En İyi Kanal', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
              const SizedBox(height: 12),
              Text(
                bestChannels.isEmpty ? '-' : '${bestChannels.first.channel}',
                style: const TextStyle(color: AppColors.primaryBlueLight, fontSize: 56, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) => Icon(
                  index < (bestChannels.isEmpty ? 0 : bestChannels.first.score / 2) ? Icons.star_rounded : Icons.star_outline_rounded,
                  color: AppColors.warning, size: 28,
                )),
              ),
            ],
          ),
        ),

        // Tüm liste
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: ratings.length,
            itemBuilder: (context, index) {
              final r = ratings[index];
              return InkWell(
                onTap: r.overlappingNetworks.isEmpty ? null : () => _showOverlappingNetworks(context, r.channel, r.overlappingNetworks),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.backgroundCard,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.backgroundBorder.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44, height: 44,
                        decoration: BoxDecoration(
                          color: r.band == '5 GHz' ? Colors.purple.withOpacity(0.1) : AppColors.backgroundDeep, 
                          shape: BoxShape.circle
                        ),
                        alignment: Alignment.center,
                        child: Text('${r.channel}', style: TextStyle(color: r.band == '5 GHz' ? Colors.purple[200] : AppColors.textPrimary, fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: List.generate(5, (idx) => Icon(
                                Icons.star_rounded, 
                                size: 14, 
                                color: idx < r.score / 2 ? AppColors.warning : AppColors.textHint
                              )),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              r.overlappingCount > 0 ? '${r.overlappingCount} Çakışan Ağ (Tıkla)' : 'Temiz Kanal', 
                              style: TextStyle(color: r.overlappingCount > 0 ? AppColors.primaryBlueLight : AppColors.safe, fontSize: 12)
                            ),
                          ],
                        ),
                      ),
                      Text(
                        r.score.toStringAsFixed(1),
                        style: TextStyle(
                          color: r.score > 7 ? AppColors.safe : (r.score > 4 ? AppColors.warning : AppColors.danger),
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _showOverlappingNetworks(BuildContext context, int channel, List<String> networks) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: AppColors.backgroundCard,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.textHint, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 24),
            Text('Kanal $channel Çakışan Ağlar', style: const TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ...networks.map((n) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  const Icon(Icons.wifi, color: AppColors.warning, size: 18),
                  const SizedBox(width: 12),
                  Text(n, style: const TextStyle(color: AppColors.textSecondary, fontSize: 14)),
                ],
              ),
            )),
            const SizedBox(height: 32),
          ],
        ),
      )
    );
  }

  IconData _getSignalIcon(int dbm) {
    if (dbm > -50) return Icons.wifi_rounded;
    if (dbm > -70) return Icons.wifi_2_bar_rounded;
    return Icons.wifi_1_bar_rounded;
  }

  Color _getSignalColor(int dbm) {
    if (dbm > -50) return AppColors.safe;
    if (dbm > -70) return AppColors.warning;
    return AppColors.danger;
  }

  void _showGraphInfo(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: AppColors.backgroundCard,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(color: AppColors.textHint, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 24),
            const Text('Grafikler Nasıl Yorumlanır?', style: TextStyle(color: AppColors.textPrimary, fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            _buildInfoItem(
              Icons.signal_wifi_4_bar_rounded,
              'Sinyal Gücü (dBm)',
              'Sinyal seviyesi negatif değerlerle ölçülür. -30 dBm mükemmel, -70 dBm kararlı, -90 dBm ise çok zayıf bir bağlantıyı temsil eder. Değer 0\'a ne kadar yakınsa sinyal o kadar güçlüdür.',
            ),
            const SizedBox(height: 16),
            _buildInfoItem(
              Icons.grid_4x4_rounded,
              'Kanal Çakışması',
              'Wi-Fi kanalları birbirine çok yakın olduğunda "çakışma" yaşanır. Özellikle 2.4 GHz bandında 1, 6 ve 11. kanallar birbiriyle çakışmadığı için en ideal seçimlerdir.',
            ),
            const SizedBox(height: 16),
            _buildInfoItem(
              Icons.show_chart_rounded,
              'Zaman Grafiği',
              'Sinyalin zaman içindeki değişimini gösterir. Eğer çizgiler çok dalgalıysa çevrede sinyal kirliliği (mikrodalga fırın, bluetooth vb.) olabilir.',
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Anladım'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String title, String desc) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: AppColors.primaryBlue.withValues(alpha: 0.1), shape: BoxShape.circle),
          child: Icon(icon, color: AppColors.primaryBlue, size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 4),
              Text(desc, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
            ],
          ),
        ),
      ],
    );
  }
}
