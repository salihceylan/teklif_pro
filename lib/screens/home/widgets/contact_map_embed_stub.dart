import 'package:flutter/material.dart';

import '../../../core/app_theme.dart';
import '../../../core/branding.dart';

class ContactMapEmbed extends StatelessWidget {
  final double height;

  const ContactMapEmbed({super.key, this.height = 320});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFFF7FAFD),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.border),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(
                Icons.location_on_outlined,
                color: AppTheme.primary,
                size: 26,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Google Konumu',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppTheme.textDark,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Harita görünümü web sürümünde etkileşimli olarak açılır. Diğer platformlarda adres bilgisi aşağıda yer alır.',
              style: TextStyle(
                fontSize: 14,
                height: 1.55,
                color: AppTheme.textMedium,
              ),
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppTheme.border),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.place_outlined, color: AppTheme.primary, size: 20),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      Branding.companyAddress,
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.5,
                        color: AppTheme.textDark,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
