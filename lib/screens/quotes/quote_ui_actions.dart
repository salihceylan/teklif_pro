import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/customer.dart';
import '../../models/quote.dart';
import '../../providers/auth_provider.dart';
import '../../providers/quote_provider.dart';
import 'quote_pdf_preview_screen.dart';

class QuoteUiActions {
  static Future<void> printQuote(
    BuildContext context, {
    required Quote quote,
    required Customer? customer,
  }) async {
    try {
      final user = context.read<AuthProvider>().user;
      if (!context.mounted) {
        return;
      }
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => QuotePdfPreviewScreen(
            quote: quote,
            customer: customer,
            user: user,
          ),
        ),
      );
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Teklif çıktısı oluşturulamadı')),
        );
      }
    }
  }

  static Future<void> showSendEmailDialog(
    BuildContext context, {
    required Quote quote,
    required Customer? customer,
  }) async {
    final emailCtrl = TextEditingController(text: customer?.email ?? '');
    final subjectCtrl = TextEditingController(
      text: 'Teklif ${quote.quoteCode ?? quote.id} - ${quote.title}',
    );
    final messageCtrl = TextEditingController(
      text:
          'Merhaba,\n\nTeklifinizi ekte PDF olarak iletiyoruz. İnceleyip geri dönüş sağlayabilirsiniz.',
    );
    var sending = false;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: const Text('Teklifi Mail Gönder'),
              content: SizedBox(
                width: 460,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: emailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'Alıcı E-posta',
                          prefixIcon: Icon(Icons.alternate_email_outlined),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: subjectCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Konu',
                          prefixIcon: Icon(Icons.subject_outlined),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: messageCtrl,
                        maxLines: 5,
                        decoration: const InputDecoration(
                          labelText: 'Mesaj',
                          alignLabelWithHint: true,
                          prefixIcon: Icon(Icons.mail_outline),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: sending
                      ? null
                      : () => Navigator.pop(dialogContext),
                  child: const Text('İptal'),
                ),
                FilledButton.icon(
                  onPressed: sending
                      ? null
                      : () async {
                          final email = emailCtrl.text.trim();
                          if (!email.contains('@')) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Geçerli bir e-posta girin'),
                              ),
                            );
                            return;
                          }
                          setState(() => sending = true);
                          try {
                            await context.read<QuoteProvider>().sendEmail(
                              quote.id,
                              email: email,
                              subject: subjectCtrl.text.trim(),
                              message: messageCtrl.text.trim(),
                            );
                            if (context.mounted) {
                              Navigator.pop(dialogContext);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Teklif $email adresine gönderildi',
                                  ),
                                ),
                              );
                            }
                          } catch (_) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Mail gönderimi başarısız oldu',
                                  ),
                                ),
                              );
                            }
                            setState(() => sending = false);
                          }
                        },
                  icon: sending
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.send_outlined),
                  label: const Text('Gönder'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
