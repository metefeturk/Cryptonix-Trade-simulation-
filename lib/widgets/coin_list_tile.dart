import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import '../models/coin_model.dart';
import '../core/constants/app_colors.dart';
import '../providers/app_providers.dart';

class CoinListTile extends ConsumerWidget {
  final Coin coin;
  final VoidCallback onTap;

  const CoinListTile({super.key, required this.coin, required this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currency = ref.watch(currencyProvider);
    final symbol = CurrencyHelper.getSymbol(currency);
    final rate = CurrencyHelper.getRate(currency);
    final displayPrice = coin.price * rate;
    final currencyFormat = NumberFormat.currency(symbol: symbol, decimalDigits: 2);
    final isPositive = coin.change24h >= 0;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: Colors.transparent,
          child: CachedNetworkImage(
            imageUrl: coin.iconUrl,
            placeholder: (context, url) => const CircleAvatar(backgroundColor: Colors.grey),
            errorWidget: (context, url, error) => const Icon(Icons.monetization_on, color: AppColors.primary),
          ),
        ),
        title: Text(coin.name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(coin.symbol, style: const TextStyle(color: AppColors.textGrey)),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(currencyFormat.format(displayPrice), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            Text(
              "${isPositive ? '+' : ''}${coin.change24h.toStringAsFixed(2)}%",
              style: TextStyle(
                color: isPositive ? AppColors.success : AppColors.error,
                fontWeight: FontWeight.w500,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
