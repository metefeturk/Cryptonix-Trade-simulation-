import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:shimmer/shimmer.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../models/coin_model.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/app_providers.dart';

class CoinDetailScreen extends ConsumerWidget {
  final Coin coin;

  const CoinDetailScreen({super.key, required this.coin});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currency = ref.watch(currencyProvider);
    final rate = CurrencyHelper.getRate(currency);
    final symbol = CurrencyHelper.getSymbol(currency);
    final displayPrice = coin.price * rate;
    final currencyFormat = NumberFormat.currency(symbol: symbol, decimalDigits: 2);
    final isPositive = coin.change24h >= 0;
    
    final portfolio = ref.watch(portfolioProvider);
    final hasCoin = portfolio.holdings.any((h) => h.symbol == coin.symbol);
    final newsAsync = ref.watch(newsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CachedNetworkImage(imageUrl: coin.iconUrl, height: 28, width: 28),
            const SizedBox(width: 8),
            Text("${coin.name} (${coin.symbol})"),
          ],
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),
            Text(currencyFormat.format(displayPrice), style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: (isPositive ? AppColors.success : AppColors.error).withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                  child: Text(
                    "${isPositive ? '+' : ''}${coin.change24h.toStringAsFixed(2)}%",
                    style: TextStyle(color: isPositive ? AppColors.success : AppColors.error, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 8),
                const Text("Son 24 Saat", style: TextStyle(color: Colors.grey)),
              ],
            ),
            const SizedBox(height: 40),
            const SizedBox(height: 10),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(show: false),
                  titlesData: const FlTitlesData(show: false),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: [
                        FlSpot(0, displayPrice * (1 - (coin.change24h / 100))),
                        FlSpot(1, displayPrice * (1 - (coin.change24h / 200))),
                        FlSpot(2, displayPrice * (1 + (coin.change24h / 400))),
                        FlSpot(3, displayPrice),
                      ],
                      isCurved: true,
                      color: isPositive ? AppColors.success : AppColors.error,
                      barWidth: 3,
                      belowBarData: BarAreaData(show: true, color: (isPositive ? AppColors.success : AppColors.error).withOpacity(0.1)),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),
            const Text("İstatistikler", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(16)),
              child: Column(
                children: [
                  _buildStatRow("Hacim (24s)", currencyFormat.format(coin.volume * rate)),
                  const Divider(height: 24),
                  _buildStatRow("Piyasa Hakimiyeti", "#${1 + (coin.volume % 10).toInt()} (Tahmini)"),
                  const Divider(height: 24),
                  _buildStatRow("Tedarik Edilen Miktar", "Bilinmiyor"),
                ],
              ),
            ),
            
            const SizedBox(height: 30),
            const Text("İlgili Haberler", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            newsAsync.when(
              data: (newsList) {
                // Haberleri coin ismi veya sembolüne göre filtrele
                var relatedNews = newsList.where((n) {
                  final title = n['title']!.toLowerCase();
                  final desc = n['description']!.toLowerCase();
                  final symbol = coin.symbol.toLowerCase();
                  final name = coin.name.toLowerCase();
                  return title.contains(symbol) || title.contains(name) || desc.contains(symbol) || desc.contains(name);
                }).toList();

                // Eğer haber bulunamazsa, genel haberlerin ilk 2 tanesini göster
                if (relatedNews.isEmpty) {
                  relatedNews = newsList.take(2).toList();
                } else {
                  relatedNews = relatedNews.take(2).toList();
                }

                return Column(
                  children: relatedNews.map((news) => Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => context.push('/news-detail', extra: news),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(8),
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: CachedNetworkImage(imageUrl: news['image']!, width: 80, height: 80, fit: BoxFit.cover),
                        ),
                        title: Text(news['title']!, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                        subtitle: Text(news['source']!, style: const TextStyle(fontSize: 12, color: AppColors.primary)),
                      ),
                    ),
                  )).toList(),
                );
              },
              loading: () => Column(
                children: List.generate(2, (index) => Shimmer.fromColors(
                  baseColor: Colors.grey[300]!,
                  highlightColor: Colors.grey[100]!,
                  child: Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(8),
                      leading: Container(width: 80, height: 80, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8))),
                      title: Container(height: 14, width: double.infinity, color: Colors.white, margin: const EdgeInsets.only(bottom: 8)),
                      subtitle: Container(height: 12, width: 100, color: Colors.white),
                    ),
                  ),
                )),
              ),
              error: (_, __) => const Text("Haberler yüklenemedi"),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, -5))],
          ),
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Mevcut Fiyat", style: TextStyle(color: Colors.grey, fontSize: 12)),
                    Text(currencyFormat.format(displayPrice), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              if (hasCoin) ...[
                Expanded(
                  flex: 1,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(foregroundColor: AppColors.error, side: const BorderSide(color: AppColors.error), padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    onPressed: () => context.push('/trade', extra: {'coin': coin, 'isBuy': false}),
                    child: const Text("SAT", style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.success, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  onPressed: () => context.push('/trade', extra: {'coin': coin, 'isBuy': true}),
                  child: const Text("SATIN AL", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
