import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

import '../../core/app_theme.dart';
import '../../core/browser_file_download.dart';
import '../../models/customer.dart';
import '../../models/quote.dart';
import '../../models/user.dart';
import '../../services/quote_document_service.dart';
import 'quote_ui_actions.dart';
import 'widgets/quote_pdf_web_viewer.dart';

class QuotePdfPreviewScreen extends StatefulWidget {
  final Quote quote;
  final Customer? customer;
  final User? user;

  const QuotePdfPreviewScreen({
    super.key,
    required this.quote,
    required this.customer,
    required this.user,
  });

  @override
  State<QuotePdfPreviewScreen> createState() => _QuotePdfPreviewScreenState();
}

class _QuotePdfPreviewScreenState extends State<QuotePdfPreviewScreen> {
  late final Future<Uint8List> _pdfFuture;

  bool _printing = false;
  bool _downloading = false;

  @override
  void initState() {
    super.initState();
    _pdfFuture = QuoteDocumentService.buildQuotePdf(
      quote: widget.quote,
      customer: widget.customer,
      user: widget.user,
    );
  }

  String get _fileName {
    final code = (widget.quote.quoteCode ?? 'teklif-${widget.quote.id}').trim();
    final safeCode = code.replaceAll(RegExp(r'[^A-Za-z0-9_-]+'), '-');
    return '$safeCode.pdf';
  }

  Future<void> _printPdf() async {
    if (_printing) {
      return;
    }

    setState(() => _printing = true);
    try {
      final bytes = await _pdfFuture;
      await Printing.layoutPdf(name: _fileName, onLayout: (_) async => bytes);
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Teklif PDF yazdirilamadi')),
      );
    } finally {
      if (mounted) {
        setState(() => _printing = false);
      }
    }
  }

  Future<void> _downloadPdf() async {
    if (_downloading) {
      return;
    }

    setState(() => _downloading = true);
    try {
      final bytes = await _pdfFuture;
      final downloaded = await downloadPdfFile(bytes, _fileName);
      if (!downloaded) {
        await Printing.sharePdf(bytes: bytes, filename: _fileName);
      }
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Teklif PDF indirilemedi')),
      );
    } finally {
      if (mounted) {
        setState(() => _downloading = false);
      }
    }
  }

  Future<void> _sendByEmail() async {
    await QuoteUiActions.showSendEmailDialog(
      context,
      quote: widget.quote,
      customer: widget.customer,
    );
  }

  Widget _buildErrorState(Object error) {
    return Center(
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
              'Teklif PDF onizlemesi acilamadi',
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
    );
  }

  Widget _buildActionBar() {
    final actionStyle = FilledButton.styleFrom(
      minimumSize: const Size(0, 46),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
    );

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      color: Colors.white,
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          FilledButton.tonalIcon(
            onPressed: _printing || _downloading ? null : _printPdf,
            icon: _printing
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.print_outlined),
            label: const Text('Yazdir'),
            style: actionStyle,
          ),
          FilledButton.tonalIcon(
            onPressed: _printing || _downloading ? null : _downloadPdf,
            icon: _downloading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.download_rounded),
            label: const Text('Indir'),
            style: actionStyle,
          ),
          FilledButton.icon(
            onPressed: _printing || _downloading ? null : _sendByEmail,
            icon: const Icon(Icons.email_outlined),
            label: const Text('Firmaya Mail Gonder'),
            style: actionStyle,
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewBody() {
    if (supportsQuotePdfWebViewer) {
      return FutureBuilder<Uint8List>(
        future: _pdfFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return _buildErrorState(snapshot.error!);
          }
          final bytes = snapshot.data;
          if (bytes == null || bytes.isEmpty) {
            return _buildErrorState('PDF verisi olusturulamadi');
          }
          return QuotePdfWebViewer(bytes: bytes, fileName: _fileName);
        },
      );
    }

    return PdfPreview(
      build: (_) => _pdfFuture,
      pdfFileName: _fileName,
      allowPrinting: false,
      allowSharing: false,
      useActions: false,
      canChangeOrientation: false,
      canChangePageFormat: false,
      canDebug: false,
      maxPageWidth: 900,
      loadingWidget: const Center(child: CircularProgressIndicator()),
      onError: (context, error) => _buildErrorState(error),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.quote.quoteCode ?? 'Teklif PDF')),
      body: Column(
        children: [
          _buildActionBar(),
          const Divider(height: 1),
          Expanded(child: _buildPreviewBody()),
        ],
      ),
    );
  }
}
