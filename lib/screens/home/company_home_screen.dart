import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/app_theme.dart';
import '../../core/branding.dart';
import '../widgets/app_shell.dart';
import 'widgets/contact_map_embed.dart';

class CompanyHomeScreen extends StatefulWidget {
  const CompanyHomeScreen({super.key});

  @override
  State<CompanyHomeScreen> createState() => _CompanyHomeScreenState();
}

class _CompanyHomeScreenState extends State<CompanyHomeScreen> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _aboutKey = GlobalKey();
  final _solutionsKey = GlobalKey();
  final _processKey = GlobalKey();
  final _referencesKey = GlobalKey();
  final _contactKey = GlobalKey();

  late final List<_NavItemData> _navItems = [
    _NavItemData('Hakkımızda', _aboutKey),
    _NavItemData('Çözümler', _solutionsKey),
    _NavItemData('Süreç', _processKey),
    _NavItemData('Referanslar', _referencesKey),
    _NavItemData('İletişim', _contactKey),
  ];

  Future<void> _scrollTo(GlobalKey key) async {
    final context = key.currentContext;
    if (context == null) return;
    await Scrollable.ensureVisible(
      context,
      duration: const Duration(milliseconds: 550),
      curve: Curves.easeInOutCubic,
      alignment: 0.02,
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final compact = width < 980;

    return Scaffold(
      key: _scaffoldKey,
      endDrawer: compact
          ? Drawer(
              child: SafeArea(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    const _CompanyMark(large: true),
                    const SizedBox(height: 20),
                    for (final item in _navItems)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          item.label,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textDark,
                          ),
                        ),
                        trailing: const Icon(
                          Icons.chevron_right,
                          color: AppTheme.textLight,
                        ),
                        onTap: () {
                          Navigator.of(context).pop();
                          Future<void>.delayed(
                            const Duration(milliseconds: 220),
                            () => _scrollTo(item.key),
                          );
                        },
                      ),
                    const Divider(height: 28),
                    FilledButton.icon(
                      onPressed: () => context.go('/login'),
                      icon: const Icon(Icons.lock_open_rounded),
                      label: const Text('Teklif Pro Giriş'),
                    ),
                  ],
                ),
              ),
            )
          : null,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF6F8FB), Color(0xFFEAF1F8)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          children: [
            _LandingHeader(
              compact: compact,
              navItems: _navItems,
              onNavTap: _scrollTo,
              onLoginTap: () => context.go('/login'),
              onMenuTap: () => _scaffoldKey.currentState?.openEndDrawer(),
            ),
            Expanded(
              child: SingleChildScrollView(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1240),
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        compact ? 16 : 24,
                        16,
                        compact ? 16 : 24,
                        40,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _HeroSection(
                            compact: width < 900,
                            onLoginTap: () => context.go('/login'),
                            onSolutionsTap: () => _scrollTo(_solutionsKey),
                            onContactTap: () => _scrollTo(_contactKey),
                          ),
                          const SizedBox(height: 24),
                          _SectionAnchor(
                            key: _aboutKey,
                            child: _AboutSection(compact: width < 900),
                          ),
                          const SizedBox(height: 24),
                          _SectionAnchor(
                            key: _solutionsKey,
                            child: _SolutionsSection(
                              compact: width < 900,
                              onLoginTap: () => context.go('/login'),
                            ),
                          ),
                          const SizedBox(height: 24),
                          _SectionAnchor(
                            key: _processKey,
                            child: const _ProcessSection(),
                          ),
                          const SizedBox(height: 24),
                          _SectionAnchor(
                            key: _referencesKey,
                            child: const _ReferencesSection(),
                          ),
                          const SizedBox(height: 24),
                          _SectionAnchor(
                            key: _contactKey,
                            child: _ContactSection(
                              onLoginTap: () => context.go('/login'),
                              onAboutTap: () => _scrollTo(_aboutKey),
                            ),
                          ),
                          const SizedBox(height: 24),
                          _Footer(
                            navItems: _navItems,
                            onNavTap: _scrollTo,
                            onLoginTap: () => context.go('/login'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItemData {
  final String label;
  final GlobalKey key;

  _NavItemData(this.label, this.key);
}

class _LandingHeader extends StatelessWidget {
  final bool compact;
  final List<_NavItemData> navItems;
  final ValueChanged<GlobalKey> onNavTap;
  final VoidCallback onLoginTap;
  final VoidCallback onMenuTap;

  const _LandingHeader({
    required this.compact,
    required this.navItems,
    required this.onNavTap,
    required this.onLoginTap,
    required this.onMenuTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 4,
      shadowColor: AppTheme.primaryDark.withValues(alpha: 0.08),
      color: Colors.white.withValues(alpha: 0.96),
      child: SafeArea(
        bottom: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1240),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  const _CompanyMark(),
                  const Spacer(),
                  if (!compact) ...[
                    for (final item in navItems)
                      Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: TextButton(
                          onPressed: () => onNavTap(item.key),
                          child: Text(item.label),
                        ),
                      ),
                    const SizedBox(width: 16),
                  ],
                  if (!compact)
                    OutlinedButton(
                      onPressed: onLoginTap,
                      child: const Text('Teklif Pro Giriş'),
                    )
                  else ...[
                    Flexible(
                      child: FilledButton.tonal(
                        onPressed: onLoginTap,
                        style: FilledButton.styleFrom(
                          foregroundColor: AppTheme.primary,
                          backgroundColor: AppTheme.primary.withValues(
                            alpha: 0.08,
                          ),
                          minimumSize: const Size(0, 44),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          textStyle: const TextStyle(
                            fontFamily: AppTheme.fontFamily,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            height: 1.15,
                          ),
                        ),
                        child: const FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text('Teklif Pro Giriş'),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: onMenuTap,
                      icon: const Icon(Icons.menu_rounded),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HeroSection extends StatelessWidget {
  final bool compact;
  final VoidCallback onLoginTap;
  final VoidCallback onSolutionsTap;
  final VoidCallback onContactTap;

  const _HeroSection({
    required this.compact,
    required this.onLoginTap,
    required this.onSolutionsTap,
    required this.onContactTap,
  });

  @override
  Widget build(BuildContext context) {
    final textContent = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
          ),
          child: const Text(
            'Kurumsal yazılım, mobil ürünler ve operasyon panelleri',
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(height: 18),
        Text(
          'Güde Teknoloji ile iş süreçlerinizi sadeleştirin, dijitalleşmeyi hızlandırın.',
          style: TextStyle(
            fontSize: compact ? 32 : 48,
            height: 1.08,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            letterSpacing: -1.1,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Güde Teknoloji; saha operasyonları, teklif ve servis takibi, mobil uygulama geliştirme ve özel yazılım çözümleriyle işletmelerin daha kontrollü büyümesini hedefler.',
          style: TextStyle(
            fontSize: compact ? 14 : 16,
            height: 1.65,
            color: Colors.white.withValues(alpha: 0.82),
          ),
        ),
        const SizedBox(height: 24),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            FilledButton.icon(
              onPressed: onLoginTap,
              style: FilledButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppTheme.primaryDark,
                minimumSize: const Size(0, 54),
                textStyle: const TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  height: 1.15,
                ),
              ),
              icon: const Icon(Icons.lock_open_rounded),
              label: const Text('Teklif Pro Giriş'),
            ),
            OutlinedButton.icon(
              onPressed: onSolutionsTap,
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: Colors.white54),
                minimumSize: const Size(0, 54),
                textStyle: const TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  height: 1.15,
                ),
              ),
              icon: const Icon(Icons.widgets_outlined),
              label: const Text('Çözümleri İncele'),
            ),
            TextButton.icon(
              onPressed: onContactTap,
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                textStyle: const TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  height: 1.15,
                ),
              ),
              icon: const Icon(Icons.arrow_outward_rounded),
              label: const Text('Proje görüşmesi planla'),
            ),
          ],
        ),
        const SizedBox(height: 24),
        AdaptiveFieldRow(
          maxColumns: 3,
          minItemWidth: compact ? 180 : 150,
          children: const [
            _HeroStat(value: '12+', label: 'Kurumsal çözüm başlığı'),
            _HeroStat(value: '7/24', label: 'Operasyon görünürlüğü'),
            _HeroStat(value: 'Tek Panel', label: 'Teklif Pro merkez yapısı'),
          ],
        ),
      ],
    );
    const visualContent = _HeroVisual();

    return Container(
      padding: EdgeInsets.all(compact ? 20 : 30),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.primaryDark, AppTheme.primary, AppTheme.secondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryDark.withValues(alpha: 0.15),
            blurRadius: 36,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: compact
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                textContent,
                const SizedBox(height: 20),
                visualContent,
              ],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(flex: 12, child: textContent),
                const SizedBox(width: 24),
                const Expanded(flex: 11, child: _HeroVisual()),
              ],
            ),
    );
  }
}

class _AboutSection extends StatelessWidget {
  final bool compact;

  const _AboutSection({required this.compact});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _SectionHeading(
            eyebrow: 'Güde Teknoloji',
            title: 'Şirket yapısı, ürün yaklaşımı ve çalışma biçimi',
            description:
                'Teknoloji yatırımlarını parça parça değil, operasyonel bütüne hizmet eden bir sistem olarak ele alıyoruz. Kurumsal web yapıları, saha uygulamaları ve özel iş panelleri bu yaklaşımın parçasıdır.',
          ),
          const SizedBox(height: 20),
          AdaptiveFieldRow(
            maxColumns: 4,
            minItemWidth: compact ? 180 : 220,
            children: const [
              _InfoCard(
                icon: Icons.apartment_outlined,
                title: 'Kurumsal Duruş',
                description:
                    'Profesyonel, sade ve güven veren dijital yüzeyler oluşturur.',
              ),
              _InfoCard(
                icon: Icons.phone_android_outlined,
                title: 'Mobil Öncelik',
                description:
                    'Ekranlar dar alanda bozulmadan, her cihazda okunur kalır.',
              ),
              _InfoCard(
                icon: Icons.settings_suggest_outlined,
                title: 'Operasyon Odağı',
                description:
                    'Teklif, servis ve ekip süreçleri aynı yapı içinde kurgulanır.',
              ),
              _InfoCard(
                icon: Icons.support_agent_outlined,
                title: 'Sürdürülebilir Destek',
                description:
                    'Yayın sonrası da geliştirme ve bakım devam edecek şekilde tasarlanır.',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SolutionsSection extends StatelessWidget {
  final bool compact;
  final VoidCallback onLoginTap;

  const _SolutionsSection({required this.compact, required this.onLoginTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _SectionHeading(
            eyebrow: 'Çözümler',
            title: 'Şirket içinde bulunması gereken temel dijital katmanlar',
            description:
                'Kurumsal web sitesi, teklif sistemleri, mobil uygulamalar ve yönetim panelleri tek markaya uygun şekilde birlikte tasarlanır.',
          ),
          const SizedBox(height: 20),
          const AdaptiveFieldRow(
            maxColumns: 4,
            minItemWidth: 220,
            children: [
              _SolutionCard(
                icon: Icons.language_rounded,
                title: 'Kurumsal Web Yapıları',
                description:
                    'Marka duruşunu güçlendiren, hızlı açılan ve mobil uyumlu anasayfalar.',
              ),
              _SolutionCard(
                icon: Icons.inventory_2_outlined,
                title: 'Operasyon Panelleri',
                description:
                    'Teklif, müşteri, servis, tahsilat ve ekip takibini tek ekranda toplar.',
              ),
              _SolutionCard(
                icon: Icons.developer_board_outlined,
                title: 'Özel Yazılım Geliştirme',
                description:
                    'İşletmenin akışına göre şekillenen, gereksiz karmaşıklık içermeyen çözümler.',
              ),
              _SolutionCard(
                icon: Icons.mobile_friendly_outlined,
                title: 'Mobil Dostu Deneyim',
                description:
                    'Saha personeli ve karar vericiler için hızlı kullanılabilir ekranlar.',
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFF6FAFF), Color(0xFFEFF7F4)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppTheme.border),
            ),
            child: AdaptiveFieldRow(
              maxColumns: 2,
              minItemWidth: 280,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: const Text(
                        'Öne çıkan ürün',
                        style: TextStyle(
                          color: AppTheme.primary,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Teklif Pro ile satıştan saha operasyonuna kadar tek akış.',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textDark,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Teklif Pro; müşteri kayıtları, servis talepleri, ziyaretler, teklifler ve faturalar için merkez panel sunar. Güde Teknoloji ürün yapısının vitrindeki örneklerinden biridir.',
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.6,
                        color: AppTheme.textMedium,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const _BulletLine(
                      text: 'Müşteri, talep ve teklif geçmişi tek yerde',
                    ),
                    const _BulletLine(
                      text: 'Mobil uyumlu panel ve operasyon form akışı',
                    ),
                    const _BulletLine(
                      text: 'Kurumsal web ile ürün girişi ayrılmış yapı',
                    ),
                    const SizedBox(height: 18),
                    FilledButton.icon(
                      onPressed: onLoginTap,
                      icon: const Icon(Icons.lock_open_rounded),
                      label: const Text('Teklif Pro Giriş'),
                    ),
                  ],
                ),
                const _ProductShowcase(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProcessSection extends StatelessWidget {
  const _ProcessSection();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: AppTheme.border),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SectionHeading(
            eyebrow: 'Süreç',
            title: 'Projeleri dört net adımda yönetiyoruz',
            description:
                'İlk görüşmeden yayına kadar karar ve tasarım katmanlarını kontrollü biçimde ilerletiyoruz.',
          ),
          SizedBox(height: 20),
          AdaptiveFieldRow(
            maxColumns: 4,
            minItemWidth: 220,
            children: [
              _ProcessCard(
                step: '01',
                title: 'İhtiyaç Analizi',
                description:
                    'İş modelini, kullanıcı tiplerini ve kritik ekranları çıkarırız.',
              ),
              _ProcessCard(
                step: '02',
                title: 'Arayüz ve Mimari',
                description:
                    'Kurumsal görünümü ve veri akışını birlikte planlarız.',
              ),
              _ProcessCard(
                step: '03',
                title: 'Geliştirme',
                description:
                    'Mobil dostu, hızlı ve sürdürülebilir kod yapısı kurarız.',
              ),
              _ProcessCard(
                step: '04',
                title: 'Yayın ve İyileştirme',
                description:
                    'Yayına alır, geri bildirimle sistemi kademeli güçlendiririz.',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ReferencesSection extends StatelessWidget {
  const _ReferencesSection();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: AppTheme.border),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SectionHeading(
            eyebrow: 'Referans Yapısı',
            title: 'Kurumsal ana sayfada bulunması gereken güven alanları',
            description:
                'Gerçek içerikler daha sonra yerleştirilebilir; şu aşamada yer tutucu görseller ve güven kartları ile kurumsal çerçeve hazırlandı.',
          ),
          SizedBox(height: 20),
          AdaptiveFieldRow(
            maxColumns: 3,
            minItemWidth: 250,
            children: [
              _ImagePlaceholderCard(
                icon: Icons.apartment_rounded,
                title: 'Kurumsal Proje Görseli',
                subtitle: 'Web, ürün ve operasyon akışı için yer tutucu alan',
              ),
              _ImagePlaceholderCard(
                icon: Icons.devices_other_rounded,
                title: 'Mobil Ekran Sunumu',
                subtitle: 'Uygulama ve panel uyumluluğu için örnek vitrin',
              ),
              _ImagePlaceholderCard(
                icon: Icons.groups_rounded,
                title: 'Ekip ve Süreç Alanı',
                subtitle: 'Şirket sunumu için geçici kurumsal görsel alanı',
              ),
            ],
          ),
          SizedBox(height: 20),
          AdaptiveFieldRow(
            maxColumns: 3,
            minItemWidth: 240,
            children: [
              _TrustCard(
                title: 'Profesyonel Arayüz Standardı',
                detail:
                    'Her ekran, marka algısını bozmayacak şekilde görsel hiyerarşiyle kurulur.',
              ),
              _TrustCard(
                title: 'Mobil Öncelikli Tasarım',
                detail:
                    'Dar ekranlarda satır kırılımları, kart düzeni ve CTA alanları korunur.',
              ),
              _TrustCard(
                title: 'Ürün ve Şirket Ayrımı',
                detail:
                    'Kurumsal anasayfa ile ürün giriş alanı birbirinden net biçimde ayrılır.',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ContactSection extends StatelessWidget {
  final VoidCallback onLoginTap;
  final VoidCallback onAboutTap;

  const _ContactSection({required this.onLoginTap, required this.onAboutTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.primaryDark, AppTheme.primary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'İletişim ve konum bilgileri',
            style: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              height: 1.15,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Ziyaretçiler Güde Teknoloji ile hızlıca iletişime geçebilsin diye adres, telefon ve Google konum görünümünü aynı bölümde topladık.',
            style: TextStyle(
              fontSize: 14,
              height: 1.6,
              color: Colors.white.withValues(alpha: 0.84),
            ),
          ),
          const SizedBox(height: 20),
          LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 920;
              final infoColumn = Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: const [
                  _ContactCard(
                    icon: Icons.location_on_outlined,
                    title: 'Adres',
                    detail: Branding.companyAddress,
                  ),
                  SizedBox(height: 12),
                  _ContactCard(
                    icon: Icons.phone_in_talk_outlined,
                    title: 'Telefon',
                    detail: Branding.companyPhoneDisplay,
                  ),
                  SizedBox(height: 12),
                  _ContactCard(
                    icon: Icons.language_outlined,
                    title: 'Web',
                    detail: Branding.website,
                  ),
                ],
              );

              final mapPanel = Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.16),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(
                            Icons.map_outlined,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Google Konumu',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                Branding.companyDistrict,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.white.withValues(alpha: 0.78),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: const ContactMapEmbed(height: 320),
                    ),
                    const SizedBox(height: 14),
                    const _ContactMetaLine(
                      icon: Icons.place_outlined,
                      text: Branding.companyAddress,
                    ),
                    const SizedBox(height: 8),
                    const _ContactMetaLine(
                      icon: Icons.call_outlined,
                      text: Branding.companyPhoneDisplay,
                    ),
                  ],
                ),
              );

              if (compact) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [infoColumn, const SizedBox(height: 18), mapPanel],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 9, child: infoColumn),
                  const SizedBox(width: 18),
                  Expanded(flex: 13, child: mapPanel),
                ],
              );
            },
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              FilledButton.icon(
                onPressed: onLoginTap,
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppTheme.primaryDark,
                  minimumSize: const Size(0, 54),
                  textStyle: const TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    height: 1.15,
                  ),
                ),
                icon: const Icon(Icons.lock_open_rounded),
                label: const Text('Teklif Pro Giriş'),
              ),
              OutlinedButton.icon(
                onPressed: onAboutTap,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white54),
                  textStyle: const TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    height: 1.15,
                  ),
                ),
                icon: const Icon(Icons.arrow_upward_rounded),
                label: const Text('Şirketi İncele'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  final List<_NavItemData> navItems;
  final ValueChanged<GlobalKey> onNavTap;
  final VoidCallback onLoginTap;

  const _Footer({
    required this.navItems,
    required this.onNavTap,
    required this.onLoginTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.border),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 760;
          final links = Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final item in navItems)
                TextButton(
                  onPressed: () => onNavTap(item.key),
                  child: Text(item.label),
                ),
            ],
          );

          final right = Wrap(
            spacing: 12,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Text(
                    Branding.companyName,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textDark,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    Branding.companyPhoneDisplay,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textMedium,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    Branding.companyDistrict,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textLight,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              OutlinedButton(
                onPressed: onLoginTap,
                child: const Text('Teklif Pro Giriş'),
              ),
            ],
          );

          return compact
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _CompanyMark(),
                    const SizedBox(height: 12),
                    links,
                    const SizedBox(height: 12),
                    right,
                  ],
                )
              : Row(
                  children: [
                    const _CompanyMark(),
                    const SizedBox(width: 16),
                    Expanded(child: links),
                    right,
                  ],
                );
        },
      ),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  final String eyebrow;
  final String title;
  final String description;

  const _SectionHeading({
    required this.eyebrow,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          eyebrow,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppTheme.primary,
            letterSpacing: 0.4,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          title,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: AppTheme.textDark,
            height: 1.15,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          description,
          style: const TextStyle(
            fontSize: 14,
            height: 1.65,
            color: AppTheme.textMedium,
          ),
        ),
      ],
    );
  }
}

class _CompanyMark extends StatelessWidget {
  final bool large;

  const _CompanyMark({this.large = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.max,
      children: [
        Container(
          width: large ? 56 : 46,
          height: large ? 56 : 46,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.border),
          ),
          padding: const EdgeInsets.all(3),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.asset(Branding.logoAsset, fit: BoxFit.cover),
          ),
        ),
        const SizedBox(width: 12),
        const Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                Branding.companyName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textDark,
                  letterSpacing: -0.2,
                ),
              ),
              Text(
                Branding.companyTagline,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.textMedium,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _HeroVisual extends StatelessWidget {
  const _HeroVisual();

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1.08,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
            ),
          ),
          Positioned(
            left: 24,
            right: 24,
            top: 24,
            bottom: 86,
            child: Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFDFEFF), Color(0xFFE7F0FB)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Row(
                      children: [
                        _MiniDot(color: Color(0xFFE45858)),
                        SizedBox(width: 6),
                        _MiniDot(color: Color(0xFFF59E0B)),
                        SizedBox(width: 6),
                        _MiniDot(color: Color(0xFF10B981)),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Container(
                      height: 14,
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      height: 14,
                      margin: const EdgeInsets.only(right: 70),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryDark.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Expanded(
                      child: Row(
                        children: [
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Padding(
                                padding: EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _PanelLabel(text: 'Kurumsal görünüm'),
                                    SizedBox(height: 12),
                                    Expanded(
                                      child: _BigVisualCard(
                                        icon: Icons.language_rounded,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              children: const [
                                Expanded(
                                  child: _SmallVisualCard(
                                    backgroundColor: Color(0xFFEDF6F4),
                                    color: AppTheme.secondary,
                                    icon: Icons.dashboard_customize_outlined,
                                  ),
                                ),
                                SizedBox(height: 14),
                                Expanded(
                                  child: _SmallVisualCard(
                                    backgroundColor: Color(0xFFF8F3EA),
                                    color: Color(0xFFF59E0B),
                                    icon: Icons.mobile_friendly_outlined,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const Positioned(
            left: 18,
            bottom: 22,
            child: _FloatingNote(
              icon: Icons.shield_outlined,
              title: 'Kurumsal kimlik',
              subtitle: 'Güven veren anasayfa akışı',
            ),
          ),
          const Positioned(
            right: 18,
            bottom: 18,
            child: _FloatingNote(
              icon: Icons.lock_open_outlined,
              title: 'Teklif Pro',
              subtitle: 'Ayrı ürün giriş butonu',
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroStat extends StatelessWidget {
  final String value;
  final String label;

  const _HeroStat({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              height: 1.4,
              color: Colors.white.withValues(alpha: 0.76),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _InfoCard({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FBFD),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: AppTheme.primary),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: const TextStyle(
              fontSize: 13,
              height: 1.55,
              color: AppTheme.textMedium,
            ),
          ),
        ],
      ),
    );
  }
}

class _SolutionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _SolutionCard({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFDFEFF), Color(0xFFF2F7FC)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppTheme.primary, AppTheme.secondary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(icon, color: Colors.white),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: const TextStyle(
              fontSize: 13,
              height: 1.55,
              color: AppTheme.textMedium,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductShowcase extends StatelessWidget {
  const _ProductShowcase();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 380;
        final height = compact ? 500.0 : 360.0;
        const metricMinWidth = 96.0;

        return SizedBox(
          height: height,
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(26),
              border: Border.all(color: AppTheme.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Row(
                  children: [
                    _MiniDot(color: Color(0xFFE45858)),
                    SizedBox(width: 6),
                    _MiniDot(color: Color(0xFFF59E0B)),
                    SizedBox(width: 6),
                    _MiniDot(color: Color(0xFF10B981)),
                  ],
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF102B46), Color(0xFF1B4D8C)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Row(
                            children: [
                              Icon(
                                Icons.dashboard_customize_rounded,
                                color: Colors.white,
                              ),
                              SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Teklif Pro Paneli',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),
                          AdaptiveFieldRow(
                            maxColumns: 4,
                            minItemWidth: metricMinWidth,
                            children: const [
                              _ProductMetric(title: 'Müşteri', value: '128'),
                              _ProductMetric(title: 'Teklif', value: '46'),
                              _ProductMetric(title: 'Ziyaret', value: '21'),
                              _ProductMetric(title: 'Fatura', value: '18'),
                            ],
                          ),
                          const Spacer(),
                          const _DarkInfoCard(
                            text:
                                'Yer tutucu ürün vitrin alanı. Gerçek ekran görüntüleri daha sonra eklenebilir.',
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ProductMetric extends StatelessWidget {
  final String title;
  final String value;

  const _ProductMetric({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.white70,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProcessCard extends StatelessWidget {
  final String step;
  final String title;
  final String description;

  const _ProcessCard({
    required this.step,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FBFD),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              step,
              style: const TextStyle(
                color: AppTheme.primary,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: const TextStyle(
              fontSize: 13,
              height: 1.55,
              color: AppTheme.textMedium,
            ),
          ),
        ],
      ),
    );
  }
}

class _ImagePlaceholderCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _ImagePlaceholderCard({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 300,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: AppTheme.border),
          gradient: const LinearGradient(
            colors: [Color(0xFFFDFEFF), Color(0xFFEFF4FB)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1B4D8C), Color(0xFF2F87D1)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Center(
                    child: Icon(icon, color: Colors.white, size: 52),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textDark,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 13,
                  height: 1.5,
                  color: AppTheme.textMedium,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TrustCard extends StatelessWidget {
  final String title;
  final String detail;

  const _TrustCard({required this.title, required this.detail});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FBFD),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.verified_outlined, color: AppTheme.primary),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            detail,
            style: const TextStyle(
              fontSize: 13,
              height: 1.55,
              color: AppTheme.textMedium,
            ),
          ),
        ],
      ),
    );
  }
}

class _ContactCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String detail;

  const _ContactCard({
    required this.icon,
    required this.title,
    required this.detail,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.white, size: 24),
          const SizedBox(height: 14),
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            detail,
            style: TextStyle(
              fontSize: 13,
              height: 1.55,
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }
}

class _ContactMetaLine extends StatelessWidget {
  final IconData icon;
  final String text;

  const _ContactMetaLine({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Colors.white, size: 18),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 13,
              height: 1.5,
              color: Colors.white.withValues(alpha: 0.84),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _BulletLine extends StatelessWidget {
  final String text;

  const _BulletLine({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.only(top: 6),
            decoration: const BoxDecoration(
              color: AppTheme.secondary,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 14,
                height: 1.5,
                color: AppTheme.textMedium,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FloatingNote extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _FloatingNote({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryDark.withValues(alpha: 0.1),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppTheme.primary, size: 20),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textDark,
                ),
              ),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppTheme.textMedium,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PanelLabel extends StatelessWidget {
  final String text;

  const _PanelLabel({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        softWrap: false,
        style: const TextStyle(
          color: AppTheme.primary,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _BigVisualCard extends StatelessWidget {
  final IconData icon;

  const _BigVisualCard({required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1B4D8C), Color(0xFF2A7EC7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Center(child: Icon(icon, size: 54, color: Colors.white)),
    );
  }
}

class _SmallVisualCard extends StatelessWidget {
  final Color backgroundColor;
  final Color color;
  final IconData icon;

  const _SmallVisualCard({
    required this.backgroundColor,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Center(child: Icon(icon, size: 44, color: color)),
    );
  }
}

class _DarkInfoCard extends StatelessWidget {
  final String text;

  const _DarkInfoCard({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Text(
        text,
        style: const TextStyle(color: Colors.white70, height: 1.45),
      ),
    );
  }
}

class _MiniDot extends StatelessWidget {
  final Color color;

  const _MiniDot({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

class _SectionAnchor extends StatelessWidget {
  final Widget child;

  const _SectionAnchor({super.key, required this.child});

  @override
  Widget build(BuildContext context) => child;
}
