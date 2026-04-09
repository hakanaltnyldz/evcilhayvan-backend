// lib/features/auth/presentation/screens/privacy_policy_screen.dart

import 'package:flutter/material.dart';
import 'package:evcilhayvan_mobil2/core/theme/app_palette.dart';
import 'package:evcilhayvan_mobil2/l10n/app_localizations.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final isEn = Localizations.localeOf(context).languageCode == 'en';

    final sections = isEn ? [
      _SectionData('1. Data Collected',
          'Pati App collects the following data to provide our services:\n\n'
          '• Name, email address and password (on registration)\n'
          '• Profile photo (optional)\n'
          '• Pet information (name, species, breed, photos)\n'
          '• Approximate location (to find nearby matches/sitters)\n'
          '• Messaging content\n'
          '• App usage statistics'),
      _SectionData('2. Use of Data',
          'The data we collect is used for:\n\n'
          '• Account creation and management\n'
          '• Listing creation and match suggestions\n'
          '• Messaging between users\n'
          '• Sitter and vet search\n'
          '• App security and verification\n'
          '• Service quality improvement'),
      _SectionData('3. Data Sharing',
          'Your personal data is not sold or rented to third parties. '
          'Data may only be shared with authorized authorities as required by law.'),
      _SectionData('4. Location Information',
          'Location data is only used to show nearby pet listings, sitters and vets. '
          'Precise location is not stored on our servers; only approximate city/district info is kept.'),
      _SectionData('5. Data Security',
          'All data is transmitted over encrypted connections (HTTPS/TLS). '
          'Passwords are hashed using bcrypt. '
          'To report security vulnerabilities, email support@evcildostum.app.'),
      _SectionData('6. User Rights',
          'Under GDPR/KVKK you have the following rights:\n\n'
          '• Access your data and request a copy\n'
          '• Request correction of incorrect data\n'
          '• Request deletion of your data\n'
          '• Object to data processing\n\n'
          'To exercise these rights, email support@evcildostum.app.'),
      _SectionData('7. Cookies & Analytics',
          'Anonymous usage statistics may be collected to measure app performance. '
          'This data is not linked to personal information.'),
      _SectionData('8. Contact',
          'For questions about our privacy policy:\n\n'
          'Email: support@evcildostum.app\nAddress: Turkey'),
    ] : [
      _SectionData('1. Toplanan Veriler',
          'Pati Arkadaşı uygulaması, hizmetlerimizi sunabilmek için aşağıdaki verileri toplar:\n\n'
          '• Ad, e-posta adresi ve şifre (kayıt sırasında)\n'
          '• Profil fotoğrafı (isteğe bağlı)\n'
          '• Evcil hayvan bilgileri (ad, tür, ırk, fotoğraflar)\n'
          '• Yaklaşık konum bilgisi (yakın eşleşme/bakıcı bulmak için)\n'
          '• Mesajlaşma içerikleri\n'
          '• Uygulama kullanım istatistikleri'),
      _SectionData('2. Verilerin Kullanımı',
          'Topladığımız veriler şu amaçlarla kullanılır:\n\n'
          '• Hesap oluşturma ve yönetimi\n'
          '• İlan oluşturma ve eşleşme önerileri\n'
          '• Kullanıcılar arası mesajlaşma\n'
          '• Bakıcı ve veteriner arama\n'
          '• Uygulama güvenliği ve doğrulama\n'
          '• Hizmet kalitesinin iyileştirilmesi'),
      _SectionData('3. Veri Paylaşımı',
          'Kişisel verileriniz üçüncü taraflarla satılmaz veya kiralanmaz. '
          'Verileriniz yalnızca yasal zorunluluklar kapsamında yetkili mercilerle paylaşılabilir.'),
      _SectionData('4. Konum Bilgisi',
          'Konum bilgisi yalnızca yakındaki evcil hayvan ilanlarını, bakıcıları ve veterinerleri göstermek için kullanılır. '
          'Hassas konum bilgisi sunucularımızda saklanmaz; yalnızca yaklaşık şehir/bölge bilgisi tutulur.'),
      _SectionData('5. Veri Güvenliği',
          'Tüm veriler şifreli bağlantılar (HTTPS/TLS) üzerinden iletilir. '
          'Şifreler bcrypt algoritmasıyla hashlenerek saklanır. '
          'Güvenlik açıklarını bize bildirmek için support@evcildostum.app adresine yazabilirsiniz.'),
      _SectionData('6. Kullanıcı Hakları',
          'KVKK kapsamında aşağıdaki haklara sahipsiniz:\n\n'
          '• Verilerinize erişme ve kopyasını talep etme\n'
          '• Yanlış verilerin düzeltilmesini isteme\n'
          '• Verilerinizin silinmesini talep etme\n'
          '• Veri işlemeye itiraz etme\n\n'
          'Bu haklarınızı kullanmak için support@evcildostum.app adresine e-posta gönderebilirsiniz.'),
      _SectionData('7. Çerezler ve Analitik',
          'Uygulama performansını ölçmek için anonim kullanım istatistikleri toplanabilir. '
          'Bu veriler kişisel bilgilerle ilişkilendirilmez.'),
      _SectionData('8. İletişim',
          'Gizlilik politikamız hakkında sorularınız için:\n\n'
          'E-posta: support@evcildostum.app\nAdres: Türkiye'),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.privacyPolicyTitle),
        backgroundColor: AppPalette.appBarDark,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
        children: [
          Text(
            l10n.privacyPolicyTitle,
            style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            isEn ? 'Last updated: March 2025' : 'Son güncelleme: Mart 2025',
            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 20),
          ...sections.map((s) => _Section(title: s.title, content: s.content)),
          const SizedBox(height: 16),
          Text(
            isEn
                ? 'By continuing to use the app, you are deemed to have accepted this policy.'
                : 'Bu politikayı uygulamayı kullanmaya devam ederek kabul etmiş sayılırsınız.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _SectionData {
  final String title;
  final String content;
  const _SectionData(this.title, this.content);
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.content});
  final String title;
  final String content;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: const Color(0xFF2D6A4F),
            ),
          ),
          const SizedBox(height: 8),
          Text(content, style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey.shade700)),
        ],
      ),
    );
  }
}
