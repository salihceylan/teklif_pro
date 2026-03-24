import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

import '../../core/app_theme.dart';
import '../../models/customer.dart';
import '../../models/quote.dart';
import '../../models/user.dart';
import '../../services/quote_document_service.dart';

class QuotePdfPreviewScreen extends StatelessWidget {
  final Quote quote;
  final Customer? customer;
  final User? user;

  const QuotePdfPreviewScreen({
    super.key,
    required this.quote,
    required this.customer,
    required this.user,
  });

  String get _fileName {
    final code = (quote.quoteCode ?? 'teklif-${quote.id}').trim();
    final safeCode = code.replaceAll(RegExp(r'[^A-Za-z0-9_-]+'), '-');
    return '$safeCode.pdf';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(quote.quoteCode ?? 'Teklif PDF')),
      body: PdfPreview(
        build: (_) => QuoteDocumentService.buildQuotePdf(
          quote: quote,
          customer: customer,
          user: user,
        ),
        pdfFileName: _fileName,
        allowPrinting: true,
        allowSharing: true,
        canChangeOrientation: false,
        canChangePageFormat: false,
        canDebug: false,
        maxPageWidth: 900,
        loadingWidget: const Center(child: CircularProgressIndicator()),
        onError: (context, error) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: AppTheme.danger.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.picture_as_pdf_outlined,
                    color: AppTheme.danger,
                    size: 34,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Teklif PDF önizlemesi açılamadı',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textDark,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                Text(
                  error.toString(),
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.5,
                    color: AppTheme.textMedium,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
