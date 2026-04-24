import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../providers/app_providers.dart';
import '../../core/constants/app_colors.dart';

class TransactionHistoryScreen extends ConsumerWidget {
  const TransactionHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final portfolio = ref.watch(portfolioProvider);
    final currency = ref.watch(currencyProvider);
    final rate = CurrencyHelper.getRate(currency);
    final symbol = CurrencyHelper.getSymbol(currency);
    final currencyFormat = NumberFormat.currency(symbol: symbol, decimalDigits: 2);

    return Scaffold(
      appBar: AppBar(title: const Text("Geçmiş İşlemler")),
      body: portfolio.transactions.isEmpty
          ? const Center(child: Text("Henüz bir işlem yapmadınız.", style: TextStyle(color: Colors.grey)))
          : ListView.builder(
              itemCount: portfolio.transactions.length,
              itemBuilder: (context, index) {
                final tx = portfolio.transactions[index];
                final isBuy = tx.type == 'buy';
                final txPrice = tx.price * rate;
                final total = tx.amount * txPrice;
                final formattedDate = DateFormat('dd MMM yyyy HH:mm').format(tx.date);

                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: (isBuy ? AppColors.success : AppColors.error).withOpacity(0.1),
                      child: Icon(
                        isBuy ? Icons.arrow_downward : Icons.arrow_upward,
                        color: isBuy ? AppColors.success : AppColors.error,
                      ),
                    ),
                    title: Text("${isBuy ? 'Alım' : 'Satış'} - ${tx.symbol}", style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text("$formattedDate\nBirim Fiyat: ${currencyFormat.format(txPrice)}"),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text("${isBuy ? '+' : '-'}${tx.amount.toStringAsFixed(4)} ${tx.symbol}", style: TextStyle(color: isBuy ? AppColors.success : AppColors.error, fontWeight: FontWeight.bold)),
                        Text("Tutar: ${currencyFormat.format(total)}", style: const TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                    isThreeLine: true,
                  ),
                );
              },
            ),
    );
  }
}