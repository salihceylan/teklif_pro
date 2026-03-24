import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../core/branding.dart';
import '../models/customer.dart';
import '../models/user.dart';
import '../models/visit.dart';

class VisitDocumentService {
  static final DateFormat _dateFormat = DateFormat('dd.MM.yyyy', 'tr_TR');
  static final DateFormat _dateTimeFormat = DateFormat(
    'dd.MM.yyyy HH:mm',
    'tr_TR',
  );
  static final NumberFormat _currency = NumberFormat('#,##0.00', 'tr_TR');
  static Future<pw.ThemeData>? _themeFuture;

  static Future<Uint8List> buildVisitPdf({
    required ServiceVisit visit,
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
    final companyPhone = user?.phone ?? Branding.companyPhoneDisplay;
    final companyEmail = user?.email ?? '';

    final customerCompany =
        visit.customerCompanyName ?? customer?.companyName ?? '-';
    final customerContact =
        visit.customerContactName ?? customer?.contactName ?? '-';
    final customerPhone = visit.customerPhone ?? customer?.phone ?? '-';
    final customerAddress = visit.customerAddress ?? customer?.address ?? '-';

    document.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          theme: theme,
          margin: const pw.EdgeInsets.all(28),
        ),
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
                  child: pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
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
                              style: const pw.TextStyle(fontSize: 10),
                            ),
                            if (companyPhone.isNotEmpty)
                              pw.Text(
                                'Tel: $companyPhone',
                                style: const pw.TextStyle(fontSize: 10),
                              ),
                            if (companyEmail.isNotEmpty)
                              pw.Text(
                                'E-posta: $companyEmail',
                                style: const pw.TextStyle(fontSize: 10),
                              ),
                            pw.Text(
                              'Web: ${Branding.website}',
                              style: const pw.TextStyle(fontSize: 10),
                            ),
                          ],
                        ),
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
                          'Form Tarihi',
                          _formatDateTime(visit.scheduledDate),
                        ),
                        _infoRow('Servis No', visit.serviceCode ?? '-'),
                        _infoRow(
                          'Durum',
                          visit.statusLabel.isEmpty ? '-' : visit.statusLabel,
                        ),
                        _infoRow(
                          'TCMB USD/TRY',
                          visit.hasExchangeRate
                              ? _currency.format(visit.exchangeRate!)
                              : '-',
                        ),
                        _infoRow(
                          'Kur Tarihi',
                          visit.exchangeRateDate == null
                              ? '-'
                              : _formatDate(visit.exchangeRateDate!),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 14),
          _sectionTitle('Firma Bilgileri'),
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey600),
            columnWidths: {0: const pw.FixedColumnWidth(100)},
            children: [
              _tableTextRow('Firma Adi', customerCompany),
              _tableTextRow('Yetkili', customerContact),
              _tableTextRow('Telefon', customerPhone),
              _tableTextRow('Adres', customerAddress),
            ],
          ),
          pw.SizedBox(height: 14),
          _sectionTitle('Servis Bilgileri'),
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey600),
            columnWidths: {0: const pw.FixedColumnWidth(100)},
            children: [
              _tableTextRow(
                'Teknisyen',
                (visit.technicianName ?? '').trim().isEmpty
                    ? '-'
                    : visit.technicianName!.trim(),
              ),
              _tableTextRow(
                'Gerceklesen',
                visit.actualDate == null ? '-' : _formatDateTime(visit.actualDate!),
              ),
              _tableTextRow(
                'Sikayet / Talep',
                (visit.complaint ?? '').trim().isEmpty
                    ? '-'
                    : visit.complaint!.trim(),
              ),
            ],
          ),
          pw.SizedBox(height: 14),
          _buildItemsTable(visit.items),
          pw.SizedBox(height: 14),
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                flex: 3,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    _sectionTitle('Aciklamalar ve Notlar'),
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
                            'Malzeme ve iscilik fiyatlari USD ve KDV haric tutulur.',
                          ),
                          _conditionLine(
                            'TL karsiliklari belgeye uygulanan TCMB USD/TRY kuru ile snapshot olarak yazilir.',
                          ),
                          if ((visit.exchangeRateSource ?? '').trim().isNotEmpty)
                            _conditionLine(
                              'Uygulanan kur kaynagi: ${visit.exchangeRateSource}.',
                            ),
                          if ((visit.notes ?? '').trim().isNotEmpty)
                            _conditionLine(visit.notes!.trim()),
                          if ((visit.technicianNotes ?? '').trim().isNotEmpty)
                            _conditionLine(
                              'Teknisyen notu: ${visit.technicianNotes!.trim()}',
                            ),
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
                      'Malzeme (USD)',
                      visit.materialTotalUsd,
                      currency: 'USD',
                    ),
                    _summaryRow('Malzeme (TL)', visit.materialTotal),
                    _summaryRow(
                      'Iscilik (USD)',
                      visit.laborAmountUsd,
                      currency: 'USD',
                    ),
                    _summaryRow('Iscilik (TL)', visit.laborAmount),
                    _summaryRow(
                      'KDV (USD)',
                      visit.vatTotalUsd,
                      currency: 'USD',
                    ),
                    _summaryRow('KDV (TL)', visit.vatTotal),
                    _summaryRow(
                      'Genel Toplam (USD)',
                      visit.grandTotalUsd,
                      currency: 'USD',
                    ),
                    _summaryRow(
                      'Genel Toplam (TL)',
                      visit.grandTotal,
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
              pw.Expanded(child: _signatureBlock('Servis Personeli')),
              pw.SizedBox(width: 36),
              pw.Expanded(child: _signatureBlock('Musteri Onayi')),
            ],
          ),
        ],
      ),
    );

    return document.save();
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

  static pw.Widget _buildItemsTable(List<ServiceVisitItem> items) {
    final rows = <pw.TableRow>[
      pw.TableRow(
        decoration: pw.BoxDecoration(color: const PdfColor.fromInt(0xFF1F5EA8)),
        children: [
          _headerCell('No'),
          _headerCell('Kod'),
          _headerCell('Malzeme / Hizmet'),
          _headerCell('Miktar'),
          _headerCell('Birim USD'),
          _headerCell('Birim TL'),
          _headerCell('Toplam USD'),
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
            _cell(item.materialName),
            _cell(_currency.format(item.quantity), align: pw.TextAlign.center),
            _cell(
              '${_currency.format(item.unitPriceUsd)} USD',
              align: pw.TextAlign.right,
            ),
            _cell(
              '${_currency.format(item.unitPrice)} TL',
              align: pw.TextAlign.right,
            ),
            _cell(
              '${_currency.format(item.totalPriceUsd)} USD',
              align: pw.TextAlign.right,
            ),
            _cell(
              '${_currency.format(item.totalPrice)} TL',
              align: pw.TextAlign.right,
            ),
          ],
        ),
      );
    }

    if (items.isEmpty) {
      rows.add(
        pw.TableRow(
          children: [
            _cell('-', align: pw.TextAlign.center),
            _cell('-', align: pw.TextAlign.center),
            _cell('Malzeme kalemi bulunmuyor'),
            _cell('-', align: pw.TextAlign.center),
            _cell('-', align: pw.TextAlign.right),
            _cell('-', align: pw.TextAlign.right),
            _cell('-', align: pw.TextAlign.right),
            _cell('-', align: pw.TextAlign.right),
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
        4: const pw.FixedColumnWidth(58),
        5: const pw.FixedColumnWidth(58),
        6: const pw.FixedColumnWidth(62),
        7: const pw.FixedColumnWidth(62),
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
        '${_currency.format(value)} ${currency == 'USD' ? 'USD' : 'TL'}',
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
        decoration: const pw.BoxDecoration(color: PdfColors.grey600),
      ),
      pw.SizedBox(height: 4),
      pw.Text('Imza / Kase', style: const pw.TextStyle(fontSize: 9)),
    ],
  );

  static pw.Widget _conditionLine(String value) => pw.Padding(
    padding: const pw.EdgeInsets.only(bottom: 6),
    child: pw.Text(value, style: const pw.TextStyle(fontSize: 10)),
  );

  static pw.Widget _infoRow(String label, String value) => pw.Padding(
    padding: const pw.EdgeInsets.only(bottom: 6),
    child: pw.Row(
      children: [
        pw.SizedBox(
          width: 60,
          child: pw.Text(
            '$label:',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
          ),
        ),
        pw.Expanded(child: pw.Text(value, style: const pw.TextStyle(fontSize: 10))),
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

  static String _formatDateTime(DateTime value) => _dateTimeFormat.format(value);
}
