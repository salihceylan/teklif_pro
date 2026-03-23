import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/app_theme.dart';
import '../../models/customer.dart';
import '../../providers/customer_provider.dart';
import '../widgets/action_menu_row.dart';
import '../widgets/app_shell.dart';

class CustomerDetailScreen extends StatefulWidget {
  final int customerId;

  const CustomerDetailScreen({super.key, required this.customerId});

  @override
  State<CustomerDetailScreen> createState() => _CustomerDetailScreenState();
}

class _CustomerDetailScreenState extends State<CustomerDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final provider = context.read<CustomerProvider>();
      if (provider.items.isEmpty) {
        await provider.load();
      }
    });
  }

  Customer? _customer(CustomerProvider provider) =>
      provider.items.where((item) => item.id == widget.customerId).firstOrNull;

  void _goBack() {
    if (Navigator.of(context).canPop()) {
      context.pop();
    } else {
      context.go('/customers');
    }
  }

  Future<void> _handleMenuAction(String value, Customer customer) async {
    if (value == 'edit') {
      context.push('/customers/${customer.id}/edit');
    } else if (value == 'delete') {
      await context.read<CustomerProvider>().delete(customer.id);
      if (mounted) {
        _goBack();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CustomerProvider>();
    final customer = _customer(provider);

    if (provider.loading && customer == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (customer == null) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            onPressed: _goBack,
            icon: const Icon(Icons.arrow_back_rounded),
          ),
          title: const Text('Firma Bulunamadi'),
        ),
        body: const Center(
          child: Text(
            'Firma kaydi bulunamadi',
            style: TextStyle(color: AppTheme.textMedium),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: _goBack,
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: Text(customer.companyName),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) => _handleMenuAction(value, customer),
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: 'edit',
                child: ActionMenuRow(
                  icon: Icons.edit_outlined,
                  label: 'Duzenle',
                ),
              ),
              PopupMenuItem(
                value: 'delete',
                child: ActionMenuRow(
                  icon: Icons.delete_outline,
                  label: 'Sil',
                  color: Color(0xFFEF4444),
                ),
              ),
            ],
          ),
        ],
      ),
      body: AppScrollableBody(
        maxWidth: 1080,
        children: [
          AppPageIntro(
            badge: customer.customerCode ?? 'Firma',
            icon: Icons.apartment_outlined,
            title: customer.companyName,
            subtitle: customer.contactName?.isNotEmpty == true
                ? '${customer.contactName} ile kayitli firma profili'
                : 'Sirket profili ve resmi bilgiler',
          ),
          const SizedBox(height: 20),
          AppSectionCard(
            icon: Icons.contact_phone_outlined,
            title: 'Iletisim Bilgileri',
            children: [
              _DetailLine('Yetkili Kisi', customer.contactName),
              _DetailLine('Telefon', customer.phone),
              _DetailLine('E-posta', customer.email),
              _DetailLine('Web Sitesi', customer.website),
              _DetailLine('Adres', customer.address),
              _DetailLine('Sehir', customer.city),
            ],
          ),
          const SizedBox(height: 20),
          AppSectionCard(
            icon: Icons.badge_outlined,
            title: 'Resmi Bilgiler',
            children: [
              AdaptiveFieldRow(
                maxColumns: 3,
                minItemWidth: 220,
                children: [
                  _InfoPanel(label: 'MERSIS', value: customer.mersisNo ?? '-'),
                  _InfoPanel(
                    label: 'Vergi No',
                    value: customer.taxNumber ?? '-',
                  ),
                  _InfoPanel(
                    label: 'Vergi Dairesi',
                    value: customer.taxOffice ?? '-',
                  ),
                  _InfoPanel(
                    label: 'Kurulus Tarihi',
                    value: customer.foundationDate == null
                        ? '-'
                        : DateFormat(
                            'dd.MM.yyyy',
                          ).format(customer.foundationDate!),
                  ),
                  _InfoPanel(
                    label: 'Personel',
                    value: customer.employeeCount?.toString() ?? '-',
                  ),
                  _InfoPanel(label: 'KEP', value: customer.kepAddress ?? '-'),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          AppSectionCard(
            icon: Icons.category_outlined,
            title: 'Sektor ve Finans',
            children: [
              AdaptiveFieldRow(
                maxColumns: 3,
                minItemWidth: 220,
                children: [
                  _InfoPanel(label: 'IBAN', value: customer.iban ?? '-'),
                  _InfoPanel(label: 'Marka', value: customer.brandName ?? '-'),
                  _InfoPanel(
                    label: 'Alt Sektor',
                    value: customer.subSector ?? '-',
                  ),
                  _InfoPanel(
                    label: 'NACE Kodu',
                    value: customer.naceCode ?? '-',
                  ),
                  _InfoPanel(
                    label: 'NACE Adi',
                    value: customer.naceName ?? '-',
                  ),
                  _InfoPanel(
                    label: 'Satis Kanali',
                    value: customer.salesChannel ?? '-',
                  ),
                ],
              ),
              _DetailLine('Sunulan Cozum', customer.offeredSolution),
              _DetailLine('Hedef Musteri Grubu', customer.targetCustomerGroup),
              _DetailLine('Ihracatci Birlikleri', customer.exporterUnions),
              _DetailLine('Notlar', customer.notes),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoPanel extends StatelessWidget {
  final String label;
  final String value;

  const _InfoPanel({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FBFD),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFD8E3EE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.textMedium,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              color: AppTheme.textDark,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailLine extends StatelessWidget {
  final String label;
  final String? value;

  const _DetailLine(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    final text = (value ?? '').trim();
    if (text.isEmpty) {
      return const SizedBox.shrink();
    }
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FBFD),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFD8E3EE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.textMedium,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            text,
            style: const TextStyle(
              fontSize: 14,
              color: AppTheme.textDark,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}
