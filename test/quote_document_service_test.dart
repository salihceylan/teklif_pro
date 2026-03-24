import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:teklif_pro/models/customer.dart';
import 'package:teklif_pro/models/quote.dart';
import 'package:teklif_pro/models/user.dart';
import 'package:teklif_pro/services/quote_document_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await initializeDateFormatting('tr_TR');
  });

  test('buildQuotePdf returns a valid pdf document', () async {
    final quote = Quote(
      id: 1,
      customerId: 1,
      quoteCode: 'TEST-001',
      title: 'Smoke Test Quote',
      customerCompanyName: 'Acme Ltd',
      customerContactName: 'Jane Doe',
      customerPhone: '+90 555 000 00 00',
      customerAddress: 'Istanbul',
      subtotalUsd: 100,
      subtotal: 3800,
      vatTotalUsd: 20,
      vatTotal: 760,
      totalAmountUsd: 120,
      totalAmount: 4560,
      exchangeRate: 38,
      exchangeRateDate: DateTime(2026, 3, 24),
      exchangeRateSource: 'TCMB',
      status: 'draft',
      issuedAt: DateTime(2026, 3, 24),
      validUntil: DateTime(2026, 4, 24),
      deliveryTime: '7 days',
      paymentTerms: 'Cash',
      termsAndConditions: 'Standard terms apply.',
      pricesIncludeVat: false,
      notes: 'Generated in test.',
      createdAt: DateTime(2026, 3, 24),
      items: const [
        QuoteItem(
          productCode: 'PRD-001',
          description: 'Test Product',
          quantity: 1,
          unit: 'Adet',
          unitPriceUsd: 100,
          unitPrice: 3800,
          vatRate: 20,
          totalPriceUsd: 120,
          totalPrice: 4560,
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

    final bytes = await QuoteDocumentService.buildQuotePdf(
      quote: quote,
      customer: customer,
      user: user,
    );

    expect(bytes, isNotEmpty);
    expect(String.fromCharCodes(bytes.take(4)), '%PDF');
  });
}
