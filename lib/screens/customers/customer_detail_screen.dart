import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/app_theme.dart';
import '../../models/customer.dart';
import '../../providers/customer_provider.dart';
import '../../services/customer_delete_service.dart';
import '../../services/customer_delete_verification_service.dart';
import '../widgets/action_menu_row.dart';
import '../widgets/app_shell.dart';
import '../widgets/destructive_confirm_dialog.dart';
import 'customer_delete_verification_dialog.dart';

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

  List<String> _dependencyParts(CustomerDeleteImpact impact) {
    return [
      if (impact.quoteCount > 0) '${impact.quoteCount} teklif',
      if (impact.invoiceCount > 0) '${impact.invoiceCount} fatura',
      if (impact.serviceRequestCount > 0)
        '${impact.serviceRequestCount} servis talebi',
      if (impact.visitCount > 0) '${impact.visitCount} servis formu',
    ];
  }

  String _buildDeleteMessage(Customer customer, CustomerDeleteImpact impact) {
    final deletionMessage = impact.hasDependencies
        ? '${customer.companyName} firmasını silerseniz bu firmaya bağlı ${_dependencyParts(impact).join(', ')} kayıtları da kalıcı olarak silinecek.'
        : '${customer.companyName} firma kaydını silmek istediğinizden emin misiniz?';

    return '$deletionMessage Bu işlem geri alınamaz.\n\nDevam ederseniz hesabınızın e-posta adresine 4 haneli doğrulama kodu gönderilecek.';
  }

  Future<void> _handleMenuAction(String value, Customer customer) async {
    if (value == 'edit') {
      context.push('/customers/${customer.id}/edit');
      return;
    }

    if (value != 'delete') {
      return;
    }

    final provider = context.read<CustomerProvider>();
    final impact = await provider.inspectDeleteImpact(customer.id);
    if (!mounted) {
      return;
    }

    final confirmed = await showDestructiveConfirmDialog(
      context,
      title: 'Firmayı Sil',
      message: _buildDeleteMessage(customer, impact),
      confirmLabel: 'Kodu Gönder',
    );
    if (!confirmed || !mounted) {
      return;
    }

    final result = await _requestVerification(customer);
    if (!mounted || result == null) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          result.hasDependencies
              ? 'Firma ve bağlı kayıtlar silindi'
              : 'Firma silindi',
        ),
      ),
    );
    _goBack();
  }

  Future<CustomerDeleteImpact?> _requestVerification(Customer customer) async {
    final provider = context.read<CustomerProvider>();
    try {
      return await showCustomerDeleteVerificationDialog(
        context,
        customerId: customer.id,
        companyName: customer.companyName,
        onVerified: (requestId, code) => provider.deleteWithVerification(
          id: customer.id,
          requestId: requestId,
          code: code,
        ),
      );
    } on CustomerDeleteVerificationException catch (error) {
      if (!mounted) {
        return null;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
      return null;
    } catch (_) {
      if (!mounted) {
        return null;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Doğrulama kodu gönderilemedi')),
      );
      return null;
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
          title: const Text('Firma Bulunamadı'),
        ),
        body: const Center(
          child: Text(
            'Firma kaydı bulunamadı',
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
            icon: const Icon(Icons.more_vert_rounded),
            tooltip: 'Firma işlemleri',
            onSelected: (value) => _handleMenuAction(value, customer),
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: 'edit',
                child: ActionMenuRow(
                  icon: Icons.edit_outlined,
                  label: 'Düzenle',
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
                ? '${customer.contactName} ile kayıtlı firma profili'
                : 'Şirket profili ve resmi bilgiler',
            trailing: Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                AppIntroActionButton(
                  icon: Icons.edit_outlined,
                  label: 'Düzenle',
                  onPressed: () => _handleMenuAction('edit', customer),
                  emphasized: true,
                ),
                AppIntroActionButton(
                  icon: Icons.delete_outline,
                  label: 'Sil',
                  onPressed: () => _handleMenuAction('delete', customer),
                  destructive: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          AppSectionCard(
            icon: Icons.contact_phone_outlined,
            title: 'İletişim Bilgileri',
            children: [
              _DetailLine('Yetkili Kişi', customer.contactName),
              _DetailLine('Telefon', customer.phone),
              _DetailLine('E-posta', customer.email),
              _DetailLine('Web Sitesi', customer.website),
              _DetailLine('Adres', customer.address),
              _DetailLine('Şehir', customer.city),
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
                  _InfoPanel(label: 'MERSİS', value: customer.mersisNo ?? '-'),
                  _InfoPanel(
                    label: 'Vergi No',
                    value: customer.taxNumber ?? '-',
                  ),
                  _InfoPanel(
                    label: 'Vergi Dairesi',
                    value: customer.taxOffice ?? '-',
                  ),
                  _InfoPanel(
                    label: 'Kuruluş Tarihi',
                    value: customer.foundationDate == null
                        ? '-'
                        : DateFormat(
                            'dd.MM.yyyy',
                            'tr_TR',
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
            title: 'Sektör ve Finans',
            children: [
              AdaptiveFieldRow(
                maxColumns: 3,
                minItemWidth: 220,
                children: [
                  _InfoPanel(label: 'IBAN', value: customer.iban ?? '-'),
                  _InfoPanel(label: 'Marka', value: customer.brandName ?? '-'),
                  _InfoPanel(
                    label: 'Alt Sektör',
                    value: customer.subSector ?? '-',
                  ),
                  _InfoPanel(
                    label: 'NACE Kodu',
                    value: customer.naceCode ?? '-',
                  ),
                  _InfoPanel(
                    label: 'NACE Adı',
                    value: customer.naceName ?? '-',
                  ),
                  _InfoPanel(
                    label: 'Satış Kanalı',
                    value: customer.salesChannel ?? '-',
                  ),
                ],
              ),
              _DetailLine('Sunulan Çözüm', customer.offeredSolution),
              _DetailLine('Hedef Müşteri Grubu', customer.targetCustomerGroup),
              _DetailLine('İhracatçı Birlikleri', customer.exporterUnions),
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
