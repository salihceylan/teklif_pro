import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../core/branding.dart';
import '../models/customer.dart';
import '../models/quote.dart';
import '../models/user.dart';

class QuoteDocumentService {
  static final DateFormat _dateFormat = DateFormat('dd.MM.yyyy', 'tr_TR');
  static final NumberFormat _currency = NumberFormat('#,##0.00', 'tr_TR');
  static Future<pw.ThemeData>? _themeFuture;

  static Future<void> printQuote({
    required Quote quote,
    required Customer? customer,
    required User? user,
  }) async {
    final document = pw.Document();
    final logoBytes = await rootBundle.load(Branding.logoAsset);
    final logoImage = pw.MemoryImage(logoBytes.buffer.asUint8List());
    final theme = await _loadTheme();

    final companyName = (user?.companyName?.trim().isNotEmpty ?? false)
        ? user!.companyName!.trim()
        : Branding.companyName;
    final companyContact = user?.fullName ?? 'Firma Yetkilisi';
    final companyPhone = user?.phone ?? '';
    final companyEmail = user?.email ?? '';

    final customerCompany =
        quote.customerCompanyName ?? customer?.companyName ?? '-';
    final customerContact =
        quote.customerContactName ?? customer?.contactName ?? '-';
    final customerPhone = quote.customerPhone ?? customer?.phone ?? '-';
    final customerAddress = quote.customerAddress ?? customer?.address ?? '-';

    document.addPage(
      pw.MultiPage(
        margin: const pw.EdgeInsets.all(28),
        pageTheme: pw.PageTheme(theme: theme),
        build: (context) => [
          pw.Container(
            padding: const pw.EdgeInsets.all(18),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey600),
            ),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Expanded(
                  flex: 3,
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Row(
                        crossAxisAlignment: pw.CrossAxisAlignment.center,
                        children: [
                          pw.Container(
                            width: 58,
                            height: 58,
                            decoration: pw.BoxDecoration(
                              borderRadius: pw.BorderRadius.circular(10),
                            ),
                            child: pw.ClipRRect(
                              horizontalRadius: 10,
                              verticalRadius: 10,
                              child: pw.Image(logoImage, fit: pw.BoxFit.cover),
                            ),
                          ),
                          pw.SizedBox(width: 12),
                          pw.Expanded(
                            child: pw.Column(
                              crossAxisAlignment: pw.CrossAxisAlignment.start,
                              children: [
                                pw.Text(
                                  companyName,
                                  style: pw.TextStyle(
                                    fontSize: 18,
                                    fontWeight: pw.FontWeight.bold,
                                  ),
                                ),
                                pw.SizedBox(height: 4),
                                pw.Text(
                                  companyContact,
                                  style: pw.TextStyle(fontSize: 10),
                                ),
                                if (companyPhone.isNotEmpty)
                                  pw.Text(
                                    'Tel: $companyPhone',
                                    style: pw.TextStyle(fontSize: 10),
                                  ),
                                if (companyEmail.isNotEmpty)
                                  pw.Text(
                                    'E-posta: $companyEmail',
                                    style: pw.TextStyle(fontSize: 10),
                                  ),
                                pw.Text(
                                  'Web: ${Branding.website}',
                                  style: pw.TextStyle(fontSize: 10),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(width: 16),
                pw.Expanded(
                  flex: 2,
                  child: pw.Container(
                    padding: const pw.EdgeInsets.all(12),
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: PdfColors.grey500),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        _infoRow(
                          'Tarih',
                          _formatDate(quote.issuedAt ?? quote.createdAt),
                        ),
                        _infoRow('Teklif No', quote.quoteCode ?? '-'),
                        _infoRow(
                          'TCMB USD/TRY',
                          quote.hasExchangeRate
                              ? _currency.format(quote.exchangeRate!)
                              : '-',
                        ),
                        _infoRow(
                          'Kur Tarihi',
                          quote.exchangeRateDate == null
                              ? '-'
                              : _formatDate(quote.exchangeRateDate!),
                        ),
                        _infoRow(
                          'Geçerlilik',
                          quote.validUntil == null
                              ? '-'
                              : _formatDate(quote.validUntil!),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 14),
          _sectionTitle('Müşteri Bilgileri'),
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey600),
            columnWidths: {0: const pw.FixedColumnWidth(100)},
            children: [
              _tableTextRow('Firma Adı', customerCompany),
              _tableTextRow('Yetkili', customerContact),
              _tableTextRow('Telefon', customerPhone),
              _tableTextRow('Adres', customerAddress),
            ],
          ),
          pw.SizedBox(height: 14),
          _buildItemsTable(quote.items),
          pw.SizedBox(height: 14),
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                flex: 3,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    _sectionTitle('Açıklamalar ve Koşullar'),
                    pw.Container(
                      width: double.infinity,
                      padding: const pw.EdgeInsets.all(12),
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(color: PdfColors.grey600),
                      ),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          _conditionLine(
                            'Kalem fiyatları USD ve KDV hariç girilir. TL karşılıklar TCMB USD/TRY kuru ile hesaplanır.',
                          ),
                          _conditionLine(
                            quote.pricesIncludeVat
                                ? 'Fiyatlara KDV dahildir.'
                                : 'Fiyatlara KDV dahil değildir.',
                          ),
                          if ((quote.exchangeRateSource ?? '')
                              .trim()
                              .isNotEmpty)
                            _conditionLine(
                              'Uygulanan kur kaynagi: ${quote.exchangeRateSource}.',
                            ),
                          if ((quote.deliveryTime ?? '').trim().isNotEmpty)
                            _conditionLine(
                              'Teslimat süresi: ${quote.deliveryTime}.',
                            ),
                          if ((quote.paymentTerms ?? '').trim().isNotEmpty)
                            _conditionLine('Ödeme: ${quote.paymentTerms}.'),
                          if (quote.validUntil != null)
                            _conditionLine(
                              'Teklif geçerlilik süresi: ${_formatDate(quote.validUntil!)}.',
                            ),
                          if ((quote.termsAndConditions ?? '')
                              .trim()
                              .isNotEmpty)
                            _conditionLine(quote.termsAndConditions!.trim()),
                          if ((quote.notes ?? '').trim().isNotEmpty)
                            _conditionLine(quote.notes!.trim()),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(width: 16),
              pw.Expanded(
                flex: 2,
                child: pw.Table(
                  border: pw.TableBorder.all(color: PdfColors.grey600),
                  children: [
                    _summaryRow(
                      'Ara Toplam (USD)',
                      quote.subtotalUsd,
                      currency: 'USD',
                    ),
                    _summaryRow('Ara Toplam (TL)', quote.subtotal),
                    _summaryRow(
                      'Toplam KDV (USD)',
                      quote.vatTotalUsd,
                      currency: 'USD',
                    ),
                    _summaryRow('Toplam KDV (TL)', quote.vatTotal),
                    _summaryRow(
                      'Genel Toplam (USD)',
                      quote.totalAmountUsd,
                      currency: 'USD',
                    ),
                    _summaryRow(
                      'Genel Toplam (TL)',
                      quote.totalAmount,
                      highlighted: true,
                    ),
                  ],
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 30),
          pw.Row(
            children: [
              pw.Expanded(child: _signatureBlock('Firma Yetkilisi')),
              pw.SizedBox(width: 36),
              pw.Expanded(child: _signatureBlock('Müşteri Onayı')),
            ],
          ),
        ],
      ),
    );

    await Printing.layoutPdf(onLayout: (_) async => document.save());
  }

  static Future<pw.ThemeData> _loadTheme() {
    return _themeFuture ??= () async {
      final baseFont = pw.Font.ttf(
        await rootBundle.load('assets/fonts/noto/NotoSans-Regular.ttf'),
      );
      final boldFont = pw.Font.ttf(
        await rootBundle.load('assets/fonts/noto/NotoSans-Bold.ttf'),
      );
      return pw.ThemeData.withFont(base: baseFont, bold: boldFont);
    }();
  }

  static pw.Widget _buildItemsTable(List<QuoteItem> items) {
    final rows = <pw.TableRow>[
      pw.TableRow(
        decoration: pw.BoxDecoration(color: const PdfColor.fromInt(0xFF1F5EA8)),
        children: [
          _headerCell('No'),
          _headerCell('Kod'),
          _headerCell('Ürün / Hizmet Adı'),
          _headerCell('Miktar'),
          _headerCell('Birim'),
          _headerCell('Birim USD'),
          _headerCell('Birim TL'),
          _headerCell('KDV'),
          _headerCell('Toplam TL'),
        ],
      ),
    ];

    for (var i = 0; i < items.length; i++) {
      final item = items[i];
      rows.add(
        pw.TableRow(
          children: [
            _cell('${i + 1}', align: pw.TextAlign.center),
            _cell(item.productCode ?? '-', align: pw.TextAlign.center),
            _cell(item.description),
            _cell(_currency.format(item.quantity), align: pw.TextAlign.center),
            _cell(item.unit, align: pw.TextAlign.center),
            _cell(
              '${_currency.format(item.unitPriceUsd)} USD',
              align: pw.TextAlign.right,
            ),
            _cell(
              '${_currency.format(item.unitPrice)} ₺',
              align: pw.TextAlign.right,
            ),
            _cell(
              '%${item.vatRate.toStringAsFixed(0)}',
              align: pw.TextAlign.center,
            ),
            _cell(
              '${_currency.format(item.totalPrice)} ₺',
              align: pw.TextAlign.right,
            ),
          ],
        ),
      );
    }

    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey600),
      columnWidths: {
        0: const pw.FixedColumnWidth(24),
        1: const pw.FixedColumnWidth(54),
        3: const pw.FixedColumnWidth(48),
        4: const pw.FixedColumnWidth(46),
        5: const pw.FixedColumnWidth(58),
        6: const pw.FixedColumnWidth(40),
        7: const pw.FixedColumnWidth(40),
        8: const pw.FixedColumnWidth(72),
      },
      children: rows,
    );
  }

  static pw.Widget _sectionTitle(String text) => pw.Container(
    width: double.infinity,
    padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: pw.BoxDecoration(color: const PdfColor.fromInt(0xFFECECEC)),
    child: pw.Text(
      text,
      style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
    ),
  );

  static pw.TableRow _tableTextRow(String label, String value) =>
      pw.TableRow(children: [_cell(label, bold: true), _cell(value)]);

  static pw.TableRow _summaryRow(
    String label,
    double value, {
    bool highlighted = false,
    String currency = 'TRY',
  }) => pw.TableRow(
    decoration: highlighted
        ? pw.BoxDecoration(color: const PdfColor.fromInt(0xFF1F5EA8))
        : null,
    children: [
      _cell(
        label,
        bold: true,
        textColor: highlighted ? PdfColors.white : PdfColors.black,
      ),
      _cell(
        '${_currency.format(value)} ${currency == 'USD' ? 'USD' : '₺'}',
        align: pw.TextAlign.right,
        bold: true,
        textColor: highlighted ? PdfColors.white : PdfColors.black,
      ),
    ],
  );

  static pw.Widget _signatureBlock(String title) => pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.center,
    children: [
      pw.Text(
        title,
        style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
      ),
      pw.SizedBox(height: 26),
      pw.Container(
        height: 1,
        decoration: pw.BoxDecoration(color: PdfColors.grey600),
      ),
      pw.SizedBox(height: 4),
      pw.Text('İmza / Kaşe', style: pw.TextStyle(fontSize: 9)),
    ],
  );

  static pw.Widget _conditionLine(String value) => pw.Padding(
    padding: const pw.EdgeInsets.only(bottom: 6),
    child: pw.Text(value, style: pw.TextStyle(fontSize: 10)),
  );

  static pw.Widget _infoRow(String label, String value) => pw.Padding(
    padding: const pw.EdgeInsets.only(bottom: 6),
    child: pw.Row(
      children: [
        pw.SizedBox(
          width: 52,
          child: pw.Text(
            '$label:',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
          ),
        ),
        pw.Expanded(child: pw.Text(value, style: pw.TextStyle(fontSize: 10))),
      ],
    ),
  );

  static pw.Widget _headerCell(String text) => pw.Padding(
    padding: const pw.EdgeInsets.all(6),
    child: pw.Text(
      text,
      style: pw.TextStyle(
        color: PdfColors.white,
        fontSize: 9,
        fontWeight: pw.FontWeight.bold,
      ),
      textAlign: pw.TextAlign.center,
    ),
  );

  static pw.Widget _cell(
    String text, {
    pw.TextAlign align = pw.TextAlign.left,
    bool bold = false,
    PdfColor textColor = PdfColors.black,
  }) => pw.Padding(
    padding: const pw.EdgeInsets.all(6),
    child: pw.Text(
      text,
      textAlign: align,
      style: pw.TextStyle(
        fontSize: 9,
        fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
        color: textColor,
      ),
    ),
  );

  static String _formatDate(DateTime value) => _dateFormat.format(value);
}
