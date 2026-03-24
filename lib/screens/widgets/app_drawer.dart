import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/app_theme.dart';
import '../../core/branding.dart';
import '../../providers/auth_provider.dart';

class AppDrawer extends StatelessWidget {
  final String currentRoute;

  const AppDrawer({super.key, required this.currentRoute});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;

    return Drawer(
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 52, 20, 24),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppTheme.primaryDark, AppTheme.primary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 52,
                  height: 52,
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(11),
                    child: Image.asset(Branding.logoAsset, fit: BoxFit.cover),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  user?.companyName ?? Branding.companyName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  user?.email ?? '',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.75),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                _DrawerItem(
                  icon: Icons.grid_view_rounded,
                  label: 'Panel',
                  route: '/panel',
                  currentRoute: currentRoute,
                ),
                _DrawerItem(
                  icon: Icons.public_outlined,
                  label: 'Kurumsal Site',
                  route: '/',
                  currentRoute: currentRoute,
                ),
                const _DrawerDivider(label: 'İŞ YÖNETİMİ'),
                _DrawerItem(
                  icon: Icons.inventory_2_outlined,
                  label: 'Ürünler',
                  route: '/products',
                  currentRoute: currentRoute,
                ),
                _DrawerItem(
                  icon: Icons.people_alt_outlined,
                  label: 'Firmalar',
                  route: '/customers',
                  currentRoute: currentRoute,
                ),
                _DrawerItem(
                  icon: Icons.build_circle_outlined,
                  label: 'Servis Talepleri',
                  route: '/service-requests',
                  currentRoute: currentRoute,
                ),
                _DrawerItem(
                  icon: Icons.request_quote_outlined,
                  label: 'Teklifler',
                  route: '/quotes',
                  currentRoute: currentRoute,
                ),
                _DrawerItem(
                  icon: Icons.calendar_month_outlined,
                  label: 'Servis Formları',
                  route: '/visits',
                  currentRoute: currentRoute,
                ),
                _DrawerItem(
                  icon: Icons.receipt_long_outlined,
                  label: 'Faturalar',
                  route: '/invoices',
                  currentRoute: currentRoute,
                ),
                const _DrawerDivider(label: 'TERCİHLER'),
                _DrawerItem(
                  icon: Icons.notifications_outlined,
                  label: 'Bildirimler',
                  route: '/notifications',
                  currentRoute: currentRoute,
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          ListTile(
            leading: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFFFFEEEE),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.logout_rounded,
                color: Color(0xFFEF4444),
                size: 18,
              ),
            ),
            title: const Text(
              'Çıkış Yap',
              style: TextStyle(
                color: Color(0xFFEF4444),
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
            onTap: () {
              Navigator.pop(context);
              context.read<AuthProvider>().logout();
              context.go('/');
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _DrawerDivider extends StatelessWidget {
  final String label;

  const _DrawerDivider({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: AppTheme.textLight,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String route;
  final String currentRoute;

  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.route,
    required this.currentRoute,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = currentRoute == route;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
      child: ListTile(
        leading: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: isActive
                ? AppTheme.primary.withValues(alpha: 0.12)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 20,
            color: isActive ? AppTheme.primary : AppTheme.textMedium,
          ),
        ),
        title: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
            color: isActive ? AppTheme.primary : AppTheme.textDark,
          ),
        ),
        tileColor: isActive
            ? AppTheme.primary.withValues(alpha: 0.07)
            : Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        dense: true,
        onTap: () {
          Navigator.pop(context);
          if (!isActive) context.go(route);
        },
      ),
    );
  }
}
