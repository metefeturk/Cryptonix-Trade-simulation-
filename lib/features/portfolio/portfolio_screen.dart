import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:go_router/go_router.dart';
import '../../providers/app_providers.dart';
import '../../core/constants/app_colors.dart';
import '../../widgets/trade_success_dialog.dart';

class PortfolioScreen extends ConsumerWidget {
  const PortfolioScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final portfolio = ref.watch(portfolioProvider);
    final marketData = ref.watch(marketDataProvider);
    final currency = ref.watch(currencyProvider);
    final rate = CurrencyHelper.getRate(currency);
    final symbol = CurrencyHelper.getSymbol(currency);
    final currencyFormat = NumberFormat.currency(symbol: symbol, decimalDigits: 2);

    // Calculate Total Value
    double totalValue = 0;
    double holdingsValue = 0;
    double weightedChange = 0; // Ağırlıklı ortalama değişim
    double totalCost = 0;

    // Map current prices to holdings
    Map<String, dynamic> coinMap = {}; // Coin objelerini tutmak için
    marketData.whenData((coins) {
      for (var coin in coins) {
        coinMap[coin.symbol] = coin;
      }
    });

    for (var item in portfolio.holdings) {
      final coin = coinMap[item.symbol];
      double price = (coin?.price ?? item.averageBuyPrice) * rate;
      double change = coin?.change24h ?? 0.0;
      
      holdingsValue += item.amount * price;
      weightedChange += (item.amount * price) * change;
      totalCost += item.amount * item.averageBuyPrice * rate;
    }
    totalValue = (portfolio.balance * rate) + holdingsValue;
    
    // Kâr Zarar Hesaplamaları
    double totalProfit = holdingsValue - totalCost;
    double profitPercent = totalCost > 0 ? (totalProfit / totalCost * 100) : 0;
    bool isPortfolioUp = portfolio.holdings.isEmpty ? true : totalProfit >= 0;
    double chartEffect = portfolio.holdings.isEmpty ? 0 : profitPercent.clamp(-50.0, 50.0);

    return Scaffold(
      appBar: AppBar(title: const Text("Portföyüm")),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Grafik Alanı
            if (portfolio.holdings.isNotEmpty)
              SizedBox(
                height: 200,
                child: Row(
                  children: [
                    // Pasta Grafik (Varlık Dağılımı)
                    Expanded(
                      child: PieChart(
                        PieChartData(
                          sectionsSpace: 2,
                          centerSpaceRadius: 30,
                          sections: portfolio.holdings.map((item) {
                            final coin = coinMap[item.symbol];
                            final price = coin?.price ?? item.averageBuyPrice;
                            final value = item.amount * price;
                            final percent = (value / (totalValue - portfolio.balance)) * 100;
                            return PieChartSectionData(
                              color: Colors.primaries[portfolio.holdings.indexOf(item) % Colors.primaries.length],
                              value: value,
                              title: '${item.symbol}\n%${percent.toStringAsFixed(0)}',
                              radius: 40,
                              titleStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                    // Çizgi Grafik (Simüle Edilmiş Yükseliş)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: LineChart(
                          LineChartData(
                            gridData: const FlGridData(show: false),
                            titlesData: const FlTitlesData(show: false),
                            borderData: FlBorderData(show: false),
                            lineBarsData: [
                              LineChartBarData(
                                spots: [
                                  // Dinamik Grafik: Portföy değişimine göre eğri çiz
                                FlSpot(0, totalValue * (1 - (chartEffect / 100))),
                                FlSpot(1, totalValue * (1 - (chartEffect / 200))),
                                FlSpot(2, totalValue * (1 + (chartEffect / 400))),
                                FlSpot(3, totalValue * (1 + (chartEffect / 100) * 0.5)),
                                  FlSpot(4, totalValue),
                                ],
                                isCurved: true,
                                color: isPortfolioUp ? AppColors.success : AppColors.error,
                                barWidth: 3,
                                dotData: const FlDotData(show: false),
                                belowBarData: BarAreaData(
                                  show: true,
                                  color: (isPortfolioUp ? AppColors.success : AppColors.error).withOpacity(0.2),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // Balance Card
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isPortfolioUp 
                      ? [AppColors.success, Colors.green.shade800]
                      : [AppColors.error, Colors.red.shade800],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: (isPortfolioUp ? AppColors.success : AppColors.error).withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Toplam Bakiye",
                    style: TextStyle(
                        color: Colors.white70,
                        fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    currencyFormat.format(totalValue),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (portfolio.holdings.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Row(
                        children: [
                          Icon(
                            isPortfolioUp ? Icons.arrow_upward : Icons.arrow_downward,
                            color: Colors.white,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            "${isPortfolioUp ? '+' : ''}${currencyFormat.format(totalProfit)} (${isPortfolioUp ? '+' : ''}${profitPercent.toStringAsFixed(2)}%)",
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment:
                        MainAxisAlignment.spaceBetween,
                    children: [
                      _buildStat(
                        "Nakit",
                        currencyFormat.format(portfolio.balance * rate),
                      ),
                      _buildStat(
                        "Varlıklar",
                        currencyFormat
                            .format(holdingsValue),
                      ),
                    ],
                  )
                ],
              ),
            ),

            const Padding(
              padding: EdgeInsets.symmetric(
                  horizontal: 16, vertical: 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Varlıkların",
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ),

            // Holdings List
            if (portfolio.holdings.isEmpty)
              const Padding(
                padding: EdgeInsets.all(32.0),
                child: Text(
                  "Henüz varlık yok. Alım yapmak için Anasayfaya git!",
                  style: TextStyle(color: Colors.grey),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics:
                    const NeverScrollableScrollPhysics(),
                itemCount: portfolio.holdings.length,
                itemBuilder: (context, index) {
                  final item =
                      portfolio.holdings[index];
                  final coin = coinMap[item.symbol];
                  final currentPriceUSD = coin?.price ?? item.averageBuyPrice;
                  final currentPrice = currentPriceUSD * rate;
                  final currentValue = item.amount * currentPrice;
                  final profit = currentValue - (item.amount * item.averageBuyPrice * rate);
                  final isProfit = profit >= 0;

                  return Card(
                    margin:
                        const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 6),
                    child: ListTile(
                      onTap: () {
                        // Detay sayfasına git
                        if (coin != null) {
                          context.push('/coin-detail', extra: coin);
                        }
                      },
                      title: Text(
                        item.symbol,
                        style: const TextStyle(
                            fontWeight:
                                FontWeight.bold),
                      ),
                      subtitle: Text(
                        "${item.amount.toStringAsFixed(4)} adet",
                      ),
                      trailing: Column(
                        mainAxisAlignment:
                            MainAxisAlignment
                                .center,
                        crossAxisAlignment:
                            CrossAxisAlignment.end,
                        children: [
                          Text(
                            currencyFormat
                                .format(currentValue),
                            style:
                                const TextStyle(
                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),
                          Text(
                            "${isProfit ? '+' : ''}${currencyFormat.format(profit)}",
                            style: TextStyle(
                              color: isProfit
                                  ? AppColors.success
                                  : AppColors.error,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStat(String label, String value) {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
              color: Colors.white70,
              fontSize: 12),
        ),
        Text(
          value,
          style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}