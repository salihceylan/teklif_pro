import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:teklif_pro/models/customer.dart';
import 'package:teklif_pro/models/user.dart';
import 'package:teklif_pro/models/visit.dart';
import 'package:teklif_pro/services/visit_document_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await initializeDateFormatting('tr_TR');
  });

  test('buildVisitPdf returns a valid pdf document', () async {
    final visit = ServiceVisit(
      id: 1,
      customerId: 1,
      serviceCode: 'SRVTEST000001',
      scheduledDate: DateTime(2026, 3, 24, 10, 30),
      actualDate: DateTime(2026, 3, 24, 11, 15),
      status: 'completed',
      customerCompanyName: 'Acme Ltd',
      customerContactName: 'Jane Doe',
      customerPhone: '+90 555 000 00 00',
      customerAddress: 'Istanbul',
      complaint: 'Kombi periyodik bakimi',
      technicianName: 'Teknisyen 1',
      laborAmountUsd: 30,
      laborAmount: 1140,
      vatRate: 20,
      materialTotalUsd: 100,
      materialTotal: 3800,
      vatTotalUsd: 26,
      vatTotal: 988,
      grandTotalUsd: 156,
      grandTotal: 5928,
      exchangeRate: 38,
      exchangeRateDate: DateTime(2026, 3, 24),
      exchangeRateSource: 'TCMB',
      notes: 'Yerinde test tamamlandi.',
      technicianNotes: 'Filtre temizlendi.',
      createdAt: DateTime(2026, 3, 24),
      items: const [
        ServiceVisitItem(
          productCode: 'PRD-001',
          materialName: 'Filtre temizleme',
          quantity: 1,
          unitPriceUsd: 50,
          unitPrice: 1900,
          totalPriceUsd: 50,
          totalPrice: 1900,
        ),
        ServiceVisitItem(
          productCode: 'PRD-002',
          materialName: 'Gaz kontrolu',
          quantity: 1,
          unitPriceUsd: 50,
          unitPrice: 1900,
          totalPriceUsd: 50,
          totalPrice: 1900,
        ),
      ],
    );

    final customer = Customer(
      id: 1,
      fullName: 'Acme Ltd',
      contactName: 'Jane Doe',
      email: 'jane@example.com',
      phone: '+90 555 000 00 00',
      address: 'Istanbul',
    );

    final user = User(
      id: 1,
      email: 'info@example.com',
      fullName: 'John Doe',
      phone: '+90 555 111 11 11',
      companyName: 'Gude Teknoloji',
    );

    final bytes = await VisitDocumentService.buildVisitPdf(
      visit: visit,
      customer: customer,
      user: user,
    );

    expect(bytes, isNotEmpty);
    expect(String.fromCharCodes(bytes.take(4)), '%PDF');
  });
}
