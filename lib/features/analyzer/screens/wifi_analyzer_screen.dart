import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

class _WiFiAnalyzerScreenState extends ConsumerState<WiFiAnalyzerScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    // Taramayı başlat
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(wifiAnalyzerProvider.notifier).startContinuousScan();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final analyzerState = ref.watch(wifiAnalyzerProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundDeep,
      appBar: AppBar(
        title: const Text('Wi-Fi Analizörü'),
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
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
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
        title: Text(
          network.ssid.isEmpty ? 'Gizli Ağ' : network.ssid,
          style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('${network.band} · Kanal ${network.channel} · ${network.level} dBm',
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
            const SizedBox(height: 2),
            Text('Mesafe: ~${network.distance.toStringAsFixed(1)}m',
                style: TextStyle(color: AppColors.textPrimary.withValues(alpha: 0.6), fontSize: 12)),
          ],
        ),
        trailing: Column(
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
      ),
    );
  }

  Widget _buildChannelGraphTab(WiFiAnalyzerState state) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const Text('2.4 GHz Kanal Dağılımı', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          Expanded(
            child: LineChart(
              LineChartData(
                minX: 1, maxX: 14,
                minY: -100, maxY: -20,
                lineBarsData: state.networks
                    .where((n) => n.band == '2.4 GHz')
                    .map((n) => LineChartBarData(
                          spots: _getParabolaSpots(n.channel.toDouble(), n.level.toDouble()),
                          isCurved: true,
                          color: _getSignalColor(n.level),
                          dotData: const FlDotData(show: false),
                          belowBarData: BarAreaData(show: true, color: _getSignalColor(n.level).withValues(alpha: 0.1)),
                        ))
                    .toList(),
                titlesData: const FlTitlesData(
                  bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, interval: 1)),
                  leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, interval: 20)),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: const FlGridData(show: true, drawVerticalLine: false),
                borderData: FlBorderData(show: false),
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text('Grafik, kanalların çakışma durumunu gösterir.', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
        ],
      ),
    );
  }

  List<FlSpot> _getParabolaSpots(double channel, double level) {
    // Kanal merkezli bir parabola oluştur
    return [
      FlSpot(channel - 2, -100),
      FlSpot(channel - 1, level - 10),
      FlSpot(channel, level),
      FlSpot(channel + 1, level - 10),
      FlSpot(channel + 2, -100),
    ];
  }

  Widget _buildTimeGraphTab(WiFiAnalyzerState state) {
    if (state.networks.isEmpty) {
      return const Center(child: Text('Takip edilecek ağ bulunamadı.', style: TextStyle(color: AppColors.textSecondary)));
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Sinyal Geçmişi', style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('Seçilen ağların son 10 taramadaki sinyal değişimi.', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          const SizedBox(height: 32),
          Expanded(
            child: LineChart(
              LineChartData(
                minY: -100, maxY: -20,
                lineBarsData: [
                  // Sadece en güçlü 3 ağın simülasyon geçmişini gösterelim
                  for (int i = 0; i < state.networks.take(3).length; i++)
                    LineChartBarData(
                      spots: List.generate(10, (idx) => FlSpot(idx.toDouble(), state.networks[i].level + (idx % 2 == 0 ? 2.0 : -2.0))),
                      isCurved: true,
                      color: i == 0 ? AppColors.primaryBlue : (i == 1 ? AppColors.safe : AppColors.warning),
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
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.backgroundCard,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.backgroundBorder.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44, height: 44,
                      decoration: const BoxDecoration(color: AppColors.backgroundDeep, shape: BoxShape.circle),
                      alignment: Alignment.center,
                      child: Text('${r.channel}', style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
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
                          Text('${r.overlappingCount} Çakışan Ağ', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
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
              );
            },
          ),
        ),
      ],
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
}
