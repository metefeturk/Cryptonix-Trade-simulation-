import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/app_providers.dart';

class TransferScreen extends ConsumerStatefulWidget {
  const TransferScreen({super.key});

  @override
  ConsumerState<TransferScreen> createState() => _TransferScreenState();
}

class _TransferScreenState extends ConsumerState<TransferScreen> {
  final _amountController = TextEditingController();
  final _ibanController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Transfer Yap")),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              "Başka Bir Hesaba Gönder",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _ibanController,
              decoration: const InputDecoration(
                labelText: "Alıcı Cüzdan / IBAN",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.account_balance),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _amountController,
              decoration: const InputDecoration(
                labelText: "Gönderilecek Tutar (USD)",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.attach_money),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () async {
                final amount = double.tryParse(_amountController.text);
                if (amount != null && amount > 0) {
                  final success = await ref.read(portfolioProvider.notifier).withdraw(amount);
                  if (success && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("\$$amount başarıyla transfer edildi!")));
                    context.pop();
                  } else if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Yetersiz bakiye!"), backgroundColor: AppColors.error));
                  }
                }
              },
              style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(16), backgroundColor: AppColors.primary, foregroundColor: Colors.white),
              child: const Text("GÖNDER"),
            ),
          ],
        ),
      ),
    );
  }
}
