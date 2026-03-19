// lib/features/auth/presentation/screens/privacy_policy_screen.dart

import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gizlilik Politikası'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
        children: [
          Text(
            'Gizlilik Politikası',
            style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            'Son güncelleme: Mart 2025',
            style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
          ),
          const SizedBox(height: 20),
          _Section(
            title: '1. Toplanan Veriler',
            content:
                'Pati Arkadaşı uygulaması, hizmetlerimizi sunabilmek için aşağıdaki verileri toplar:\n\n'
                '• Ad, e-posta adresi ve şifre (kayıt sırasında)\n'
                '• Profil fotoğrafı (isteğe bağlı)\n'
                '• Evcil hayvan bilgileri (ad, tür, ırk, fotoğraflar)\n'
                '• Yaklaşık konum bilgisi (yakın eşleşme/bakıcı bulmak için)\n'
                '• Mesajlaşma içerikleri\n'
                '• Uygulama kullanım istatistikleri',
          ),
          _Section(
            title: '2. Verilerin Kullanımı',
            content:
                'Topladığımız veriler şu amaçlarla kullanılır:\n\n'
                '• Hesap oluşturma ve yönetimi\n'
                '• İlan oluşturma ve eşleşme önerileri\n'
                '• Kullanıcılar arası mesajlaşma\n'
                '• Bakıcı ve veteriner arama\n'
                '• Uygulama güvenliği ve doğrulama\n'
                '• Hizmet kalitesinin iyileştirilmesi',
          ),
          _Section(
            title: '3. Veri Paylaşımı',
            content:
                'Kişisel verileriniz üçüncü taraflarla satılmaz veya kiralanmaz. '
                'Verileriniz yalnızca yasal zorunluluklar kapsamında yetkili mercilerle paylaşılabilir.',
          ),
          _Section(
            title: '4. Konum Bilgisi',
            content:
                'Konum bilgisi yalnızca yakındaki evcil hayvan ilanlarını, '
                'bakıcıları ve veterinerleri göstermek için kullanılır. '
                'Hassas konum bilgisi sunucularımızda saklanmaz; yalnızca yaklaşık şehir/bölge bilgisi tutulur.',
          ),
          _Section(
            title: '5. Veri Güvenliği',
            content:
                'Tüm veriler şifreli bağlantılar (HTTPS/TLS) üzerinden iletilir. '
                'Şifreler bcrypt algoritmasıyla hashlenerek saklanır. '
                'Güvenlik açıklarını bize bildirmek için support@evcildostum.app adresine yazabilirsiniz.',
          ),
          _Section(
            title: '6. Kullanıcı Hakları',
            content:
                'KVKK kapsamında aşağıdaki haklara sahipsiniz:\n\n'
                '• Verilerinize erişme ve kopyasını talep etme\n'
                '• Yanlış verilerin düzeltilmesini isteme\n'
                '• Verilerinizin silinmesini talep etme\n'
                '• Veri işlemeye itiraz etme\n\n'
                'Bu haklarınızı kullanmak için support@evcildostum.app adresine e-posta gönderebilirsiniz.',
          ),
          _Section(
            title: '7. Çerezler ve Analitik',
            content:
                'Uygulama performansını ölçmek için anonim kullanım istatistikleri toplanabilir. '
                'Bu veriler kişisel bilgilerle ilişkilendirilmez.',
          ),
          _Section(
            title: '8. İletişim',
            content:
                'Gizlilik politikamız hakkında sorularınız için:\n\n'
                'E-posta: support@evcildostum.app\n'
                'Adres: Türkiye',
          ),
          const SizedBox(height: 16),
          Text(
            'Bu politikayı uygulamayı kullanmaya devam ederek kabul etmiş sayılırsınız.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: Colors.grey,
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
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
            style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(content, style: theme.textTheme.bodyMedium),
        ],
      ),
    );
  }
}
