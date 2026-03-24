import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/customer.dart';
import '../../models/visit.dart';
import '../../providers/auth_provider.dart';
import '../../providers/visit_provider.dart';
import 'visit_pdf_preview_screen.dart';

class VisitUiActions {
  static Future<void> previewVisit(
    BuildContext context, {
    required ServiceVisit visit,
    required Customer? customer,
  }) async {
    try {
      final user = context.read<AuthProvider>().user;
      if (!context.mounted) {
        return;
      }
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => VisitPdfPreviewScreen(
            visit: visit,
            customer: customer,
            user: user,
          ),
        ),
      );
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Servis cikti onizlemesi acilamadi')),
        );
      }
    }
  }

  static Future<void> showSendEmailDialog(
    BuildContext context, {
    required ServiceVisit visit,
    required Customer? customer,
  }) async {
    final emailCtrl = TextEditingController(text: customer?.email ?? '');
    final subjectCtrl = TextEditingController(
      text:
          'Servis Formu ${visit.serviceCode ?? visit.id} - ${visit.customerCompanyName ?? customer?.companyName ?? 'Firma'}',
    );
    final messageCtrl = TextEditingController(
      text:
          'Merhaba,\n\nServis formunuzu ekte PDF olarak iletiyoruz. Inceleyip geri donus saglayabilirsiniz.',
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
              title: const Text('Servis Formunu Mail Gonder'),
              content: SizedBox(
                width: 460,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Firma e-posta adresi otomatik doldurulur. Gerekirse alici adresini manuel olarak degistirebilirsiniz.',
                        style: TextStyle(fontSize: 13, height: 1.45),
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: emailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'Alici E-posta',
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
                  child: const Text('Iptal'),
                ),
                FilledButton.icon(
                  onPressed: sending
                      ? null
                      : () async {
                          final email = emailCtrl.text.trim();
                          if (!email.contains('@')) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Gecerli bir e-posta girin'),
                              ),
                            );
                            return;
                          }
                          setState(() => sending = true);
                          try {
                            await context.read<VisitProvider>().sendEmail(
                              visit.id,
                              email: email,
                              subject: subjectCtrl.text.trim(),
                              message: messageCtrl.text.trim(),
                            );
                            if (context.mounted) {
                              Navigator.pop(dialogContext);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Servis formu $email adresine gonderildi',
                                  ),
                                ),
                              );
                            }
                          } catch (_) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Mail gonderimi basarisiz oldu',
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
                  label: const Text('Gonder'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
