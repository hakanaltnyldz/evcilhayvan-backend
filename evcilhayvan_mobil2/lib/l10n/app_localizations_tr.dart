// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Turkish (`tr`).
class AppLocalizationsTr extends AppLocalizations {
  AppLocalizationsTr([String locale = 'tr']) : super(locale);

  @override
  String get appName => 'Evcil Hayvan';

  @override
  String get login => 'Giriş Yap';

  @override
  String get logout => 'Çıkış Yap';

  @override
  String get register => 'Kayıt Ol';

  @override
  String get email => 'E-posta';

  @override
  String get password => 'Şifre';

  @override
  String get forgotPassword => 'Şifremi Unuttum';

  @override
  String get resetPassword => 'Şifreyi Sıfırla';

  @override
  String get name => 'Ad Soyad';

  @override
  String get save => 'Kaydet';

  @override
  String get cancel => 'Vazgeç';

  @override
  String get delete => 'Sil';

  @override
  String get edit => 'Düzenle';

  @override
  String get confirm => 'Onayla';

  @override
  String get back => 'Geri';

  @override
  String get close => 'Kapat';

  @override
  String get retry => 'Tekrar Dene';

  @override
  String get loading => 'Yükleniyor...';

  @override
  String get error => 'Hata';

  @override
  String get success => 'Başarılı';

  @override
  String get noData => 'Veri bulunamadı';

  @override
  String get send => 'Gönder';

  @override
  String get tabHome => 'Sahiplen';

  @override
  String get tabMessages => 'Sohbetler';

  @override
  String get tabVet => 'Veteriner';

  @override
  String get tabStore => 'Mağaza';

  @override
  String get tabProfile => 'Profil';

  @override
  String get homeTitle => 'İlanlar';

  @override
  String get homeSearchHint => 'Tür, ırk ara...';

  @override
  String get homeNearby => 'Yakınımdakiler';

  @override
  String get homeNoAds => 'Henüz ilan yok';

  @override
  String get homeNoAdsDesc => 'Yakınında ilan bulunamadı.';

  @override
  String get homeAdoptionTab => 'Sahiplendirme';

  @override
  String get homeMatingTab => 'Eşleştirme';

  @override
  String get petDetailTitle => 'İlan Detayı';

  @override
  String get petDetailAge => 'Yaş';

  @override
  String get petDetailBreed => 'Irk';

  @override
  String get petDetailGender => 'Cinsiyet';

  @override
  String get petDetailVaccinated => 'Aşılı';

  @override
  String get petDetailOwner => 'Sahip';

  @override
  String get petDetailContact => 'İletişime Geç';

  @override
  String get petDetailAdopt => 'Sahiplenmek İstiyorum';

  @override
  String get createPetTitle => 'İlan Oluştur';

  @override
  String get createPetName => 'Hayvan Adı';

  @override
  String get createPetSpecies => 'Tür';

  @override
  String get createPetBreed => 'Irk';

  @override
  String get createPetAge => 'Yaş (ay)';

  @override
  String get createPetGender => 'Cinsiyet';

  @override
  String get createPetBio => 'Hakkında';

  @override
  String get createPetPhotos => 'Fotoğraflar';

  @override
  String get createPetAddPhoto => 'Fotoğraf Ekle';

  @override
  String get createPetSubmit => 'İlanı Yayınla';

  @override
  String get matingTitle => 'Eşleştirme Bul';

  @override
  String get matingSubtitle => 'Evcil dostların için uygun eşleşmeleri keşfet.';

  @override
  String get matingSpecies => 'Tür';

  @override
  String get matingGender => 'Cinsiyet';

  @override
  String matingMaxDistance(int km) {
    return 'Maksimum mesafe: $km km';
  }

  @override
  String get matingRequests => 'Eşleştirme istekleri';

  @override
  String get matingEndTitle => 'Hepsi bu kadar!';

  @override
  String get matingEndDesc => 'Yakınında başka profil bulunamadı.';

  @override
  String get matingRefresh => 'Yenile';

  @override
  String get matingEmptyTitle => 'Filtreleri gevşetmeyi deneyin';

  @override
  String get matingEmptyDesc => 'Yakınında henüz uygun eşleşme bulunamadı.';

  @override
  String get matingAll => 'Tümü';

  @override
  String get matingMale => 'Erkek';

  @override
  String get matingFemale => 'Dişi';

  @override
  String get matingLikeStamp => 'LIKE';

  @override
  String get matingNopeStamp => 'NOPE';

  @override
  String get matingVaccinated => 'Aşılı';

  @override
  String get messagesTitle => 'Sohbetler';

  @override
  String get messagesEmpty => 'Henüz sohbet yok';

  @override
  String get messagesEmptyDesc => 'İlanlardan biriyle iletişime geç.';

  @override
  String get messagesTypeHint => 'Mesaj yaz...';

  @override
  String get messagesSend => 'Gönder';

  @override
  String get messagesImage => 'Resim gönder';

  @override
  String get messagesDeleted => '[silindi]';

  @override
  String get matchRequestsTitle => 'Eşleştirme İstekleri';

  @override
  String get matchRequestsInbox => 'Gelen';

  @override
  String get matchRequestsOutbox => 'Gönderilen';

  @override
  String get matchRequestsEmpty => 'İstek yok';

  @override
  String get matchRequestAccept => 'Kabul Et';

  @override
  String get matchRequestReject => 'Reddet';

  @override
  String get matchRequestCancel => 'İptal Et';

  @override
  String get profileTitle => 'Profil';

  @override
  String get profileEdit => 'Profili Düzenle';

  @override
  String get profileMyPets => 'İlanlarım';

  @override
  String get profileSettings => 'Ayarlar';

  @override
  String get profileLogout => 'Çıkış Yap';

  @override
  String get profileSeller => 'Satıcı';

  @override
  String get profileMember => 'Üye';

  @override
  String profileSince(String date) {
    return 'Katılım: $date';
  }

  @override
  String get settingsTitle => 'Ayarlar';

  @override
  String get settingsDarkMode => 'Karanlık Mod';

  @override
  String get settingsLanguage => 'Dil';

  @override
  String get settingsLanguageTr => 'Türkçe';

  @override
  String get settingsLanguageEn => 'English';

  @override
  String get settingsReview => 'Uygulamayı Değerlendir';

  @override
  String get settingsPrivacy => 'Gizlilik Politikası';

  @override
  String get settingsNotifications => 'Bildirimler';

  @override
  String get settingsLogout => 'Çıkış Yap';

  @override
  String get vetTitle => 'Veterinerler';

  @override
  String get vetSearch => 'Veteriner ara...';

  @override
  String get vetNoResults => 'Veteriner bulunamadı';

  @override
  String vetDistance(String km) {
    return '$km km uzakta';
  }

  @override
  String get vetAppointment => 'Randevu Al';

  @override
  String get vetVaccination => 'Aşı Takvimi';

  @override
  String get vetReminders => 'Hatırlatmalar';

  @override
  String get storeTitle => 'Mağaza';

  @override
  String get storeSearch => 'Ürün ara...';

  @override
  String get storeCart => 'Sepet';

  @override
  String get storeCheckout => 'Siparişi Tamamla';

  @override
  String get storeMyOrders => 'Siparişlerim';

  @override
  String get storeAddToCart => 'Sepete Ekle';

  @override
  String get storeOutOfStock => 'Stok Yok';

  @override
  String get storeOrderPlaced => 'Sipariş Oluşturuldu';

  @override
  String get lostFoundTitle => 'Kayıp & Bulunan';

  @override
  String get lostFoundReport => 'İlan Ekle';

  @override
  String get lostFoundLost => 'Kayıp';

  @override
  String get lostFoundFound => 'Bulunan';

  @override
  String get eventsTitle => 'Etkinlikler';

  @override
  String get eventsJoin => 'Katıl';

  @override
  String get eventsLeave => 'Ayrıl';

  @override
  String get sitterTitle => 'Evcil Hayvan Bakıcısı';

  @override
  String get sitterBecomeSitter => 'Bakıcı Ol';

  @override
  String get sitterBook => 'Rezervasyon Yap';

  @override
  String get sitterMyBookings => 'Rezervasyonlarım';

  @override
  String get adoptionApply => 'Başvur';

  @override
  String get adoptionMyApps => 'Başvurularım';

  @override
  String get notificationsTitle => 'Bildirimler';

  @override
  String get notificationsEmpty => 'Bildirim yok';

  @override
  String get notificationsClearAll => 'Tümünü Temizle';

  @override
  String get favoritesTitle => 'Favorilerim';

  @override
  String get favoritesEmpty => 'Favori ilanınız yok';

  @override
  String hello(String name) {
    return 'Merhaba, $name!';
  }

  @override
  String get genderMale => 'Erkek';

  @override
  String get genderFemale => 'Dişi';

  @override
  String get genderUnknown => 'Bilinmiyor';

  @override
  String get speciesDog => 'Köpek';

  @override
  String get speciesCat => 'Kedi';

  @override
  String get speciesBird => 'Kuş';

  @override
  String get speciesFish => 'Balık';

  @override
  String get speciesOther => 'Diğer';

  @override
  String get advertTypeAdoption => 'Sahiplendirme';

  @override
  String get advertTypeMating => 'Eşleştirme';

  @override
  String get privacyPolicyTitle => 'Gizlilik Politikası';

  @override
  String get reviewDialogTitle => 'Uygulamayı Puanla';

  @override
  String get reviewDialogDesc =>
      'Uygulamamızı beğendiniz mi? Puanlamanız bize çok yardımcı olur.';

  @override
  String get errorGeneric => 'Bir hata oluştu. Lütfen tekrar deneyin.';

  @override
  String get errorNetwork => 'İnternet bağlantısı yok.';

  @override
  String get errorUnauthorized =>
      'Oturum süresi doldu. Lütfen tekrar giriş yapın.';

  @override
  String get errorNotFound => 'Bulunamadı.';

  @override
  String get yes => 'Evet';

  @override
  String get no => 'Hayır';

  @override
  String get or => 'veya';

  @override
  String get km => 'km';

  @override
  String get month => 'ay';

  @override
  String get year => 'yıl';

  @override
  String months(int count) {
    return '$count aylık';
  }

  @override
  String years(int count) {
    return '$count yaş';
  }

  @override
  String get settingsSectionAccount => 'Hesabım';

  @override
  String get settingsSectionAccountSub =>
      'Profilini güncelle, güvenlik ayarlarını yönet.';

  @override
  String get settingsSectionStore => 'Mağaza Yönetimi';

  @override
  String get settingsSectionStoreSub => 'Mağazanı ve siparişlerini yönet.';

  @override
  String get settingsSectionNotif => 'Bildirimler';

  @override
  String get settingsSectionNotifSub =>
      'Topluluktan geri kalma, kontrol tamamen sende.';

  @override
  String get settingsSectionAppExp => 'Uygulama Deneyimi';

  @override
  String get settingsSectionAppExpSub =>
      'Görünüm ve kişisel tercihlerini özelleştir.';

  @override
  String get settingsSectionSupport => 'Destek';

  @override
  String get settingsSectionSupportSub =>
      'Yardıma mı ihtiyacın var? Sana yardımcı olalım.';

  @override
  String get settingsEditProfile => 'Profili Düzenle';

  @override
  String get settingsEditProfileSub =>
      'Kişisel bilgilerini ve biyografini güncelle';

  @override
  String get settingsChangePassword => 'Şifreyi Değiştir';

  @override
  String get settingsChangePasswordSub =>
      'E-posta üzerinden yeni bir şifre oluştur';

  @override
  String get settingsMyOrders => 'Siparişlerim';

  @override
  String get settingsMyOrdersSub => 'Sipariş geçmişini görüntüle ve takip et';

  @override
  String get settingsMyFavorites => 'Favorilerim';

  @override
  String get settingsMyFavoritesSub => 'Beğendiğin ürünleri görüntüle';

  @override
  String get settingsMyStore => 'Mağazam';

  @override
  String get settingsMyStoreSub => 'Mağaza bilgilerini görüntüle ve düzenle';

  @override
  String get settingsIncomingOrders => 'Gelen Siparişler';

  @override
  String get settingsIncomingOrdersSub => 'Mağazana gelen siparişleri yönet';

  @override
  String get settingsManageProducts => 'Ürünlerimi Yönet';

  @override
  String get settingsManageProductsSub =>
      'Ürün ekle, düzenle veya stok güncelle';

  @override
  String get settingsNotifChat => 'Sohbet bildirimleri';

  @override
  String get settingsNotifChatSub =>
      'Yeni mesaj ve sohbet isteklerinden haberdar ol';

  @override
  String get settingsNotifMatch => 'Eşleşme uyarıları';

  @override
  String get settingsNotifMatchSub => 'Yeni eşleşmelerde anında bildirim al';

  @override
  String get settingsAutoChat => 'Eşleşmelerde sohbeti otomatik hazırla';

  @override
  String get settingsAutoChatSub =>
      'Eşleşme oluştuğunda sohbet ekranını hızlıca aç';

  @override
  String get settingsCompactCards => 'Kartları kompakt göster';

  @override
  String get settingsCompactCardsSub =>
      'Liste görünümünde daha fazla içerik gör';

  @override
  String get settingsDarkModeSub => 'Gözlerin için daha konforlu koyu tema';

  @override
  String get settingsLanguageSub => 'Uygulama dilini değiştir';

  @override
  String get settingsExportData => 'Verilerimi dışa aktar';

  @override
  String get settingsExportDataSub =>
      'İlan ve sohbet geçmişini e-posta olarak iste';

  @override
  String get settingsHelp => 'SSS ve Yardım Merkezi';

  @override
  String get settingsContact => 'Destek ile iletişime geç';

  @override
  String get settingsShare => 'Uygulamayı Paylaş';

  @override
  String get settingsShareSub => 'Arkadaşlarına öner';

  @override
  String get profileTabMyAds => 'Sahiplendirme İlanlarım';

  @override
  String get profileTabMatingAds => 'Eşleştirme İlanlarım';

  @override
  String get profileAdoptionCount => 'Sahiplendirme';

  @override
  String get profileMatingCount => 'Eşleştirme';

  @override
  String get profileViewCount => 'Görüntülenme';

  @override
  String get profileNewAdoption => 'Sahiplendirme';

  @override
  String get profileNewMating => 'Eşleştirme';

  @override
  String get homeGreeting => 'Merhaba';

  @override
  String get homeShortcutMating => 'Eşleştir';

  @override
  String get homeShortcutLost => 'Kayıp';

  @override
  String get homeShortcutEvents => 'Etkinlik';

  @override
  String get homeShortcutSitter => 'Bakıcı';

  @override
  String get homeShortcutAi => 'Pati AI';

  @override
  String get homeShortcutFeed => 'Feed';

  @override
  String get homeShortcutSearch => 'Ara';

  @override
  String get homeUpcomingAppointments => 'Yaklaşan Randevular';

  @override
  String get homeNearbyAds => 'Yakınımdaki İlanlar';

  @override
  String get navMessages => 'Sohbetler';

  @override
  String get navAdopt => 'Sahiplen';

  @override
  String get navVet => 'Veteriner';

  @override
  String get navStore => 'Mağaza';

  @override
  String get navProfile => 'Profil';

  @override
  String get darkModeOn => 'Karanlık mod açık';

  @override
  String get darkModeOff => 'Karanlık mod kapalı';

  @override
  String get languageLabel => 'Dil / Language';

  @override
  String get selectLanguage => 'Dil Seçin';

  @override
  String get today => 'Bugün';

  @override
  String get tomorrow => 'Yarın';

  @override
  String get profileCompleteTitle => 'Profili tamamla';

  @override
  String get profileCompletePhoto => 'Fotoğraf';

  @override
  String get profileCompleteCity => 'Şehir';

  @override
  String get profileCompleteAbout => 'Hakkımda';

  @override
  String get searchMessages => 'Mesajlarda ara...';

  @override
  String noSearchResults(String query) {
    return '\"$query\" için sonuç bulunamadı';
  }
}
