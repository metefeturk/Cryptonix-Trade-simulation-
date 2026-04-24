import 'package:appwrite/models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'core/theme/app_theme.dart';
import 'providers/app_providers.dart';
import 'features/main_wrapper.dart';
import 'features/home/home_screen.dart';
import 'features/portfolio/portfolio_screen.dart';
import 'features/news/news_screen.dart';
import 'features/profile/profile_screen.dart';
import 'features/auth/login_screen.dart';
import 'features/auth/register_screen.dart';
import 'features/profile/transaction_history_screen.dart';
import 'features/profile/profile_setup_screen.dart';
import 'features/wallet/deposit_screen.dart';
import 'features/wallet/transfer_screen.dart';
import 'features/market/trade_screen.dart';
import 'features/market/coin_detail_screen.dart';
import 'features/news/news_detail_screen.dart';
import 'features/forum/forum_screen.dart';
import 'features/forum/create_topic_screen.dart';
import 'features/forum/topic_detail_screen.dart';
import 'features/notifications/notifications_screen.dart';
import 'models/coin_model.dart';

void main() {
  runApp(const ProviderScope(child: CryptoApp()));
}

// Router Configuration
final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  final isAuthenticated = ref.watch(authProvider);

  return GoRouter(
  navigatorKey: _rootNavigatorKey,
    initialLocation: '/home',
    redirect: (context, state) {
      final isLoggingIn = state.uri.toString() == '/login';
      final isRegistering = state.uri.toString() == '/register';

      if (!isAuthenticated && !isLoggingIn && !isRegistering) return '/login';
      if (isAuthenticated && (isLoggingIn || isRegistering)) return '/home';

      return null;
    },
  routes: [
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(path: '/register', builder: (context, state) => const RegisterScreen()),
      GoRoute(path: '/deposit', builder: (context, state) => const DepositScreen()),
      GoRoute(path: '/transfer', builder: (context, state) => const TransferScreen()),
      GoRoute(
        path: '/profile-setup',
        builder: (context, state) => const ProfileSetupScreen(),
      ),
      GoRoute(
        path: '/transaction-history',
        builder: (context, state) => const TransactionHistoryScreen(),
      ),
      GoRoute(
        path: '/notifications',
        builder: (context, state) => const NotificationsScreen(),
      ),
      GoRoute(
        path: '/coin-detail',
        builder: (context, state) => CoinDetailScreen(coin: state.extra as Coin),
      ),
      GoRoute(
        path: '/trade',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>;
          return TradeScreen(coin: extra['coin'] as Coin, isBuy: extra['isBuy'] as bool);
        },
      ),
      GoRoute(
        path: '/news-detail',
        builder: (context, state) => NewsDetailScreen(news: state.extra as Map<String, String>),
      ),
      GoRoute(
        path: '/create-topic',
        builder: (context, state) => const CreateTopicScreen(),
      ),
      GoRoute(
        path: '/forum-detail',
        builder: (context, state) => TopicDetailScreen(topic: state.extra as Document),
      ),
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return MainWrapper(navigationShell: navigationShell);
      },
      branches: [
        StatefulShellBranch(
          routes: [GoRoute(path: '/home', builder: (context, state) => const HomeScreen())],
        ),
        StatefulShellBranch(
          routes: [GoRoute(path: '/portfolio', builder: (context, state) => const PortfolioScreen())],
        ),
        StatefulShellBranch(
          routes: [GoRoute(path: '/news', builder: (context, state) => const NewsScreen())],
        ),
        StatefulShellBranch(
          routes: [GoRoute(path: '/forum', builder: (context, state) => const ForumScreen())],
        ),
        StatefulShellBranch(
          routes: [GoRoute(path: '/profile', builder: (context, state) => const ProfileScreen())],
        ),
      ],
    ),
  ],
  );
});

class CryptoApp extends ConsumerWidget {
  const CryptoApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = ref.watch(themeProvider);
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Cryptonix',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
      routerConfig: router,
    );
  }
}
