import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/app_theme.dart';
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
          // ── Header ──────────────────────────────────────────────
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
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Text(
                      (user?.fullName ?? 'T')[0].toUpperCase(),
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  user?.companyName ?? user?.fullName ?? 'Teklif Pro',
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

          // ── Menu ────────────────────────────────────────────────
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                _DrawerItem(
                  icon: Icons.grid_view_rounded,
                  label: 'Ana Sayfa',
                  route: '/',
                  currentRoute: currentRoute,
                ),
                const _DrawerDivider(label: 'İŞ YÖNETİMİ'),
                _DrawerItem(
                  icon: Icons.people_alt_outlined,
                  label: 'Müşteriler',
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
                  label: 'Servis Ziyaretleri',
                  route: '/visits',
                  currentRoute: currentRoute,
                ),
                _DrawerItem(
                  icon: Icons.receipt_long_outlined,
                  label: 'Faturalar',
                  route: '/invoices',
                  currentRoute: currentRoute,
                ),
              ],
            ),
          ),

          // ── Footer ──────────────────────────────────────────────
          const Divider(height: 1),
          ListTile(
            leading: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFFFFEEEE),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.logout_rounded,
                  color: Color(0xFFEF4444), size: 18),
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

  bool get _isActive => currentRoute == route;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
      child: ListTile(
        leading: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: _isActive
                ? AppTheme.primary.withValues(alpha: 0.12)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 20,
            color: _isActive ? AppTheme.primary : AppTheme.textMedium,
          ),
        ),
        title: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: _isActive ? FontWeight.w700 : FontWeight.w500,
            color: _isActive ? AppTheme.primary : AppTheme.textDark,
          ),
        ),
        tileColor: _isActive
            ? AppTheme.primary.withValues(alpha: 0.07)
            : Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        dense: true,
        onTap: () {
          Navigator.pop(context);
          if (!_isActive) context.go(route);
        },
      ),
    );
  }
}
