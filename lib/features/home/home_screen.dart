import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../providers/app_providers.dart';
import '../../widgets/coin_list_tile.dart';
import '../../core/constants/app_colors.dart';
import '../../widgets/trade_success_dialog.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final marketData = ref.watch(marketDataProvider);
    final filter = ref.watch(filterProvider);
    final currentCurrency = ref.watch(currencyProvider);
    final searchQuery = ref.watch(searchQueryProvider);
    final notifications = ref.watch(notificationProvider).notifications;
    final unreadCount = notifications.where((n) => !n.isRead).length;
    final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();

    return Scaffold(
      key: scaffoldKey,
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(color: AppColors.primary),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  const Icon(Icons.currency_bitcoin, size: 48, color: Colors.white),
                  const SizedBox(height: 10),
                  const Text("Cryptonix", style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.monetization_on),
              title: const Text('Para Birimi'),
              trailing: DropdownButton<AppCurrency>(
                value: currentCurrency,
                underline: const SizedBox(),
                items: AppCurrency.values.map((c) {
                  return DropdownMenuItem(
                    value: c,
                    child: Text(c.name),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) ref.read(currencyProvider.notifier).setCurrency(val);
                },
              ),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.account_balance_wallet),
              title: const Text('Para Yatır'),
              onTap: () {
                Navigator.pop(context);
                context.push('/deposit');
              },
            ),
            ListTile(
              leading: const Icon(Icons.send),
              title: const Text('Transfer Yap'),
              onTap: () {
                Navigator.pop(context);
                context.push('/transfer');
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Ayarlar'),
              onTap: () {
                Navigator.pop(context);
                context.go('/profile');
              },
            ),
          ],
        ),
      ),
      appBar: AppBar(
        title: const Text("Kripto Piyasası"),
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => scaffoldKey.currentState?.openDrawer(),
        ),
        actions: [
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_none),
                onPressed: () => context.push('/notifications'),
              ),
              if (unreadCount > 0)
                Positioned(
                  right: 12,
                  top: 12,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: AppColors.error,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      unreadCount.toString(),
                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
            ],
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              onChanged: (value) => ref.read(searchQueryProvider.notifier).state = value,
              decoration: InputDecoration(
                hintText: "Coin Ara...",
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Theme.of(context).cardColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
        ),
      ),
      body: marketData.when(
        data: (coins) {
          // Filtreleme Mantığı
          var displayCoins = [...coins];
          switch (filter) {
            case SortOption.priceDesc:
              displayCoins.sort((a, b) => b.price.compareTo(a.price));
              break;
            case SortOption.priceAsc:
              displayCoins.sort((a, b) => a.price.compareTo(b.price));
              break;
            case SortOption.gainers:
              displayCoins = displayCoins.where((c) => c.change24h > 0).toList();
              displayCoins.sort((a, b) => b.change24h.compareTo(a.change24h));
              break;
            case SortOption.losers:
              displayCoins = displayCoins.where((c) => c.change24h < 0).toList();
              displayCoins.sort((a, b) => a.change24h.compareTo(b.change24h));
              break;
            default:
              // Rank (Varsayılan API sırası)
              break;
          }

          return RefreshIndicator(
            onRefresh: () => ref.refresh(marketDataProvider.future),
            child: Column(
              children: [
                // Filtre Butonları
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      _buildFilterChip(context, ref, "Sıralama", SortOption.rank, filter),
                      const SizedBox(width: 8),
                      _buildFilterChip(context, ref, "Fiyat (Azalan)", SortOption.priceDesc, filter),
                      const SizedBox(width: 8),
                      _buildFilterChip(context, ref, "Fiyat (Artan)", SortOption.priceAsc, filter),
                      const SizedBox(width: 8),
                      _buildFilterChip(context, ref, "Kazananlar", SortOption.gainers, filter),
                      const SizedBox(width: 8),
                      _buildFilterChip(context, ref, "Kaybedenler", SortOption.losers, filter),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: displayCoins.length,
                    itemBuilder: (context, index) {
                      final coin = displayCoins[index];
                      return CoinListTile(
                        coin: coin,
                        onTap: () {
                          context.push('/coin-detail', extra: coin);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => _buildLoadingSkeleton(),
        error: (err, stack) => Center(child: Text("Error: $err")),
      ),
    );
  }

  Widget _buildFilterChip(BuildContext context, WidgetRef ref, String label, SortOption option, SortOption current) {
    final isSelected = option == current;
    return FilterChip(
      label: Text(
        label,
        style: TextStyle(
          color: isSelected ? AppColors.primary : Theme.of(context).textTheme.bodyLarge?.color,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      selected: isSelected,
      showCheckmark: false, // Daha sade bir görünüm için tiki kaldırdık
      onSelected: (bool selected) {
        ref.read(filterProvider.notifier).setFilter(option);
      },
      backgroundColor: Theme.of(context).cardColor,
      selectedColor: AppColors.primary.withOpacity(0.15),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected ? AppColors.primary : Colors.grey.withOpacity(0.3),
        ),
      ),
    );
  }

  Widget _buildLoadingSkeleton() {
    return ListView.builder(
      itemCount: 10,
      itemBuilder: (_, __) => Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          height: 80,
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
        ),
      ),
    );
  }
}
