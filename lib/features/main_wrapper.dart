import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/constants/app_colors.dart';
import '../providers/app_providers.dart';

class MainWrapper extends ConsumerStatefulWidget {
  final StatefulNavigationShell navigationShell;
  const MainWrapper({super.key, required this.navigationShell});

  @override
  ConsumerState<MainWrapper> createState() => _MainWrapperState();
}

class _MainWrapperState extends ConsumerState<MainWrapper> {
  bool _hasCheckedProfile = false;

  @override
  Widget build(BuildContext context) {
    // Profil tamamlama yönlendirmesi (Uygulama arka planında gizlice kontrol edilir)
    ref.listen(
      currentUserProvider,
      (previous, next) {
        if (!_hasCheckedProfile && next is AsyncData && next.value != null) {
          final isSetupComplete = next.value!.prefs.data['setup_complete'] == true;
          if (!isSetupComplete) {
            _hasCheckedProfile = true; // Loop'a girmemek için sadece bir kez yönlendiriyoruz
            Future.microtask(() {
              if (mounted) context.push('/profile-setup');
            });
          }
        }
      },
    );

    // Eğer uygulama açıldığında state zaten AsyncData olarak hazırsa (listen tetiklenmezse), 
    // anlık kontrolü manuel olarak yapıyoruz.
    if (!_hasCheckedProfile) {
      final currentUser = ref.read(currentUserProvider);
      if (currentUser is AsyncData && currentUser.value != null) {
        final isSetupComplete = currentUser.value!.prefs.data['setup_complete'] == true;
        if (!isSetupComplete) {
          _hasCheckedProfile = true;
          Future.microtask(() {
            if (mounted) context.push('/profile-setup');
          });
        }
      }
    }

    return Scaffold(
      body: widget.navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: widget.navigationShell.currentIndex,
        onDestinationSelected: (index) {
          widget.navigationShell.goBranch(
            index,
            initialLocation:
                index == widget.navigationShell.currentIndex,
          );
        },
        indicatorColor: AppColors.primary.withOpacity(0.2),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Anasayfa',
          ),
          NavigationDestination(
            icon: Icon(Icons.pie_chart_outline),
            selectedIcon: Icon(Icons.pie_chart),
            label: 'Portföy',
          ),
          NavigationDestination(
            icon: Icon(Icons.article_outlined),
            selectedIcon: Icon(Icons.article),
            label: 'Haberler',
          ),
          NavigationDestination(
            icon: Icon(Icons.forum_outlined),
            selectedIcon: Icon(Icons.forum),
            label: 'Forum',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}