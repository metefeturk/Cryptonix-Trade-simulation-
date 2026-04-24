import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/coin_model.dart';
import '../../providers/app_providers.dart';
import '../../core/constants/app_colors.dart';
import '../../widgets/trade_success_dialog.dart';

class TradeScreen extends ConsumerStatefulWidget {
  final Coin coin;
  final bool isBuy;

  const TradeScreen({super.key, required this.coin, required this.isBuy});

  @override
  ConsumerState<TradeScreen> createState() => _TradeScreenState();
}

class _TradeScreenState extends ConsumerState<TradeScreen> {
  final _controller = TextEditingController();
  late bool _isFiatInput;

  @override
  void initState() {
    super.initState();
    _isFiatInput = widget.isBuy; // Alışta varsayılan "Tutar", Satışta "Miktar"
  }

  @override
  Widget build(BuildContext context) {
    final currency = ref.watch(currencyProvider);
    final rate = CurrencyHelper.getRate(currency);
    final symbol = CurrencyHelper.getSymbol(currency);
    final displayPrice = widget.coin.price * rate;
    final portfolio = ref.watch(portfolioProvider);

    double inputAmount = double.tryParse(_controller.text) ?? 0.0;
    
    double maxSellAmount = 0.0;
    if (!widget.isBuy) {
      final itemIndex = portfolio.holdings.indexWhere((h) => h.symbol == widget.coin.symbol);
      if (itemIndex != -1) {
        maxSellAmount = portfolio.holdings[itemIndex].amount;
      }
    }

    // Anlık Hesaplamalar
    double estimatedCoins = 0.0;
    double estimatedFiat = 0.0;
    if (_isFiatInput) {
      estimatedFiat = inputAmount;
      estimatedCoins = inputAmount > 0 ? inputAmount / displayPrice : 0.0;
    } else {
      estimatedCoins = inputAmount;
      estimatedFiat = inputAmount * displayPrice;
    }

    return Scaffold(
      appBar: AppBar(title: Text("${widget.coin.name} ${widget.isBuy ? 'Satın Al' : 'Sat'}")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CachedNetworkImage(imageUrl: widget.coin.iconUrl, height: 48, width: 48),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("1 ${widget.coin.symbol} = $symbol${displayPrice.toStringAsFixed(2)}", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    Text(widget.isBuy ? "Kullanılabilir Bakiye: $symbol${(portfolio.balance * rate).toStringAsFixed(2)}" : "Mevcut Varlık: ${maxSellAmount.toStringAsFixed(6)} ${widget.coin.symbol}", style: const TextStyle(color: AppColors.textGrey)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 30),
            Center(
              child: ToggleButtons(
                isSelected: [_isFiatInput, !_isFiatInput],
                onPressed: (index) {
                  setState(() {
                    _isFiatInput = index == 0;
                    _controller.clear();
                  });
                },
                borderRadius: BorderRadius.circular(12),
                selectedColor: Colors.white,
                fillColor: widget.isBuy ? AppColors.success : AppColors.error,
                color: AppColors.textGrey,
                constraints: const BoxConstraints(minHeight: 40, minWidth: 120),
                children: [
                  Text(" Tutar ($symbol) ", style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text(" Miktar (${widget.coin.symbol}) ", style: const TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _controller,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              onChanged: (val) => setState(() {}),
              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                labelText: _isFiatInput ? "Tutar Girin ($symbol)" : "Miktar Girin (${widget.coin.symbol})",
                labelStyle: const TextStyle(fontSize: 16),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                prefixText: _isFiatInput ? "$symbol " : "",
                suffixText: _isFiatInput ? "" : " ${widget.coin.symbol}",
                filled: true,
                fillColor: Theme.of(context).cardColor,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [0.25, 0.50, 0.75, 1.0].map((percent) {
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        foregroundColor: widget.isBuy ? AppColors.success : AppColors.error,
                        side: BorderSide(color: (widget.isBuy ? AppColors.success : AppColors.error).withOpacity(0.4)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () {
                        double maxVal = 0.0;
                        if (widget.isBuy) {
                          double balance = portfolio.balance * rate;
                          maxVal = _isFiatInput ? (balance * percent) : ((balance / displayPrice) * percent);
                        } else {
                          maxVal = _isFiatInput ? (maxSellAmount * displayPrice * percent) : (maxSellAmount * percent);
                        }
                        setState(() {
                          _controller.text = _isFiatInput ? maxVal.toStringAsFixed(2) : maxVal.toStringAsFixed(6);
                        });
                      },
                      child: Text("%${(percent * 100).toInt()}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: (widget.isBuy ? AppColors.success : AppColors.error).withOpacity(0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: (widget.isBuy ? AppColors.success : AppColors.error).withOpacity(0.2)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _isFiatInput 
                        ? (widget.isBuy ? "Alınacak Miktar:" : "Satılacak Miktar:") 
                        : (widget.isBuy ? "Ödenecek Tutar:" : "Elde Edilecek Tutar:"), 
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                  Text(
                    _isFiatInput 
                        ? "${estimatedCoins.toStringAsFixed(6)} ${widget.coin.symbol}" 
                        : "$symbol${estimatedFiat.toStringAsFixed(2)}", 
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: widget.isBuy ? AppColors.success : AppColors.error)
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget.isBuy ? AppColors.success : AppColors.error,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                onPressed: () {
                  if (estimatedCoins > 0) {
                    if (widget.isBuy) {
                      if (estimatedFiat > portfolio.balance * rate) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Yetersiz bakiye!"), backgroundColor: AppColors.error));
                        return;
                      }
                      final amountUSD = estimatedFiat / rate;
                      ref.read(portfolioProvider.notifier).buyCoin(widget.coin.symbol, widget.coin.price, amountUSD);
                    } else {
                      if (estimatedCoins > maxSellAmount) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Yetersiz varlık!"), backgroundColor: AppColors.error));
                        return;
                      }
                      ref.read(portfolioProvider.notifier).sellCoin(widget.coin.symbol, widget.coin.price, estimatedCoins);
                    }
                    Navigator.pop(context); // Trade ekranını kapat
                    showTradeSuccessDialog(context, widget.isBuy ? "Alım" : "Satış", widget.coin.symbol, estimatedCoins, estimatedFiat, symbol);
                  }
                },
                child: Text(widget.isBuy ? "SATIN AL" : "SATIŞ YAP", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}