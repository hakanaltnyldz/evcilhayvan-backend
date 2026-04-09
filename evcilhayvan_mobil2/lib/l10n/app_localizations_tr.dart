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
  String get msgConvDeleted => 'Sohbet silindi';

  @override
  String msgConvDeleteErr(String error) {
    return 'Sohbet silinemedi: $error';
  }

  @override
  String get msgConvStart => 'Sohbete başla';

  @override
  String get msgListingNotFound => 'İlan bilgisi bulunamadı';

  @override
  String get msgListingLoading => 'İlan yükleniyor...';

  @override
  String get msgListingLoadErr => 'İlan bilgisi alınamadı';

  @override
  String get msgMatingRequestsTitle => 'Eşleştirme İstekleri';

  @override
  String get msgNoMatingRequests => 'Henüz eşleştirme isteği yok.';

  @override
  String get msgAdoptionRequestsTitle => 'Sahiplendirme Başvuruları';

  @override
  String get msgNoAdoptionRequests => 'Henüz başvuru yok.';

  @override
  String get msgHeaderTitle => 'Sohbet kutunu renklendir';

  @override
  String get msgHeaderSubtitle =>
      'Sahiplendirme görüşmelerini, ilan sorularını ve yeni dostlukları burada yönet.';

  @override
  String get msgConvLoadErr => 'Sohbetler yüklenemedi';

  @override
  String msgSenderLabel(String name) {
    return 'Gönderen: $name';
  }

  @override
  String msgSelectedPet(String name) {
    return 'Seçilen pet: $name';
  }

  @override
  String get msgViewSenderListing => 'Gönderen ilanını gör';

  @override
  String msgApplicantLabel(String name) {
    return 'Başvuran: $name';
  }

  @override
  String get msgGoToChat => 'Sohbete git';

  @override
  String get msgStatusAccepted => 'Kabul edildi';

  @override
  String get msgStatusRejected => 'Reddedildi';

  @override
  String get msgStatusCancelled => 'İptal edildi';

  @override
  String get msgStatusPending => 'Beklemede';

  @override
  String get msgActionDone => 'İşlem tamamlandı';

  @override
  String get msgNoRecipient => 'Karşı taraf bilgisi bulunamadı.';

  @override
  String get msgLoginRequired => 'Sohbet için giriş yapın.';

  @override
  String get msgOpenFailed => 'Sohbet açılamadı.';

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
  String get speciesHamster => 'Hamster';

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
  String get homeDiscoverTitle => 'İlanları Keşfet';

  @override
  String get homeSearchTooltip => 'Ara';

  @override
  String get homeLostFoundTooltip => 'Kayıp & Bulunan';

  @override
  String get homeBreedSelect => 'Cins seç';

  @override
  String get homeClearFilter => 'Filtreyi temizle';

  @override
  String get homeWelcome => 'Hoş geldin!';

  @override
  String homeGreetingWith(String greeting, String name) {
    return '$greeting, $name!';
  }

  @override
  String get homeHeaderDesc => 'Sana en uygun pati dostunu keşfet.';

  @override
  String get homeGoodMorning => 'Günaydın';

  @override
  String get homeGoodDay => 'İyi günler';

  @override
  String get homeGoodEvening => 'İyi akşamlar';

  @override
  String get homeGoodNight => 'İyi geceler';

  @override
  String get homeShortcutSitterFull => 'Bakıcı\nBul';

  @override
  String get homeShortcutLostFull => 'Kayıp &\nBulunan';

  @override
  String get homeShortcutAiFull => 'Pati\nAsistan';

  @override
  String get homeShortcutMap => 'Harita';

  @override
  String get homeEmptyListings => 'Henüz ilan yok';

  @override
  String get homeEmptyListingsDesc =>
      'Bu kategoride henüz ilan yok. İlk sen ekle!';

  @override
  String get homeApptFallback => 'Veteriner Randevusu';

  @override
  String get homeNotifTooltip => 'Bildirimler';

  @override
  String get homeBreedSearch => 'Cins ara...';

  @override
  String get homeLocationPermErr => 'Konum izni gerekli';

  @override
  String homeLocationErr(String error) {
    return 'Konum alınamadı: $error';
  }

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

  @override
  String get vetVerified => 'Doğrulanmış';

  @override
  String get vetOnlineAppointment => 'Online Randevu';

  @override
  String get vetAbout => 'Hakkında';

  @override
  String get vetServices => 'Hizmetler';

  @override
  String get vetSpeciesServed => 'Hizmet Verilen Türler';

  @override
  String get vetWorkingHours => 'Çalışma Saatleri';

  @override
  String get vetClosed => 'Kapalı';

  @override
  String get vetOpenInMaps => 'Haritada Aç';

  @override
  String get vetSendMessage => 'Mesaj Gönder';

  @override
  String get vetClaimProfile => 'Bu Kliniği Sahiplen';

  @override
  String get vetClaimDialogTitle => 'Profili Sahiplen';

  @override
  String get vetClaimDialogContent =>
      'Bu klinik profilini hesabınıza bağlamak istediğinizden emin misiniz?\n\nSahiplendikten sonra müşteriler size doğrudan mesaj gönderebilir.';

  @override
  String get vetClaimAction => 'Sahiplen';

  @override
  String get vetClaimSuccess =>
      'Profil başarıyla sahiplenildi! Artık mesaj alabilirsiniz.';

  @override
  String get vetReviews => 'Değerlendirmeler';

  @override
  String get vetReviewsRate => 'Değerlendir';

  @override
  String get vetReviewsLoadError => 'Yorumlar yüklenemedi.';

  @override
  String get vetReviewsEmpty =>
      'Henüz değerlendirme yok. İlk yorumu siz yapın!';

  @override
  String vetReviewCount(int count) {
    return '$count değerlendirme';
  }

  @override
  String get vetReviewAdded => 'Değerlendirmeniz eklendi.';

  @override
  String vetReviewDeleteError(String error) {
    return 'Silinemedi: $error';
  }

  @override
  String get vetReviewDialogTitle => 'Veteriner Değerlendir';

  @override
  String get vetReviewCommentHint => 'Yorumunuz (isteğe bağlı)';

  @override
  String get vetSpeciesDog => 'Köpek';

  @override
  String get vetSpeciesCat => 'Kedi';

  @override
  String get vetSpeciesBird => 'Kuş';

  @override
  String get vetSpeciesFish => 'Balık';

  @override
  String get vetSpeciesRodent => 'Kemirgen';

  @override
  String get vetSpeciesOther => 'Diğer';

  @override
  String vetRating(String rating, int count) {
    return '$rating ($count değerlendirme)';
  }

  @override
  String get checkoutTitle => 'Ödeme';

  @override
  String get checkoutDeliveryAddress => 'Teslimat Adresi';

  @override
  String get checkoutPaymentMethod => 'Ödeme Yöntemi';

  @override
  String get checkoutCardInfo => 'Kart Bilgileri';

  @override
  String get checkoutCreditCard => 'Kredi Kartı';

  @override
  String get checkoutCashOnDelivery => 'Kapıda Ödeme';

  @override
  String get checkoutCardNumber => 'Kart Numarası';

  @override
  String get checkoutCardHolder => 'Kart Sahibi';

  @override
  String get checkoutCardHolderHint => 'AD SOYAD';

  @override
  String get checkoutExpiry => 'Son Kullanma';

  @override
  String get checkoutExpiryHint => 'AA/YY';

  @override
  String get checkoutCoupon => 'İndirim Kuponu';

  @override
  String get checkoutCouponHint => 'Kupon kodunuz';

  @override
  String get checkoutApply => 'Uygula';

  @override
  String get checkoutOrderNote => 'Sipariş Notu (Opsiyonel)';

  @override
  String get checkoutOrderNoteHint => 'Siparişinizle ilgili notunuz...';

  @override
  String get checkoutOrderSummary => 'Sipariş Özeti';

  @override
  String get checkoutSubtotal => 'Ara Toplam';

  @override
  String get checkoutShipping => 'Kargo';

  @override
  String get checkoutFreeShipping => 'Ücretsiz';

  @override
  String get checkoutDiscount => 'İndirim';

  @override
  String get checkoutTotal => 'Toplam';

  @override
  String get checkoutCompleteOrder => 'Siparişi Tamamla';

  @override
  String get checkoutDefaultAddress => 'Varsayılan';

  @override
  String get checkoutAddNewAddress => 'Yeni Adres Ekle';

  @override
  String checkoutAddressLoadError(String error) {
    return 'Adresler yüklenemedi: $error';
  }

  @override
  String checkoutCartLoadError(String error) {
    return 'Sepet yüklenemedi: $error';
  }

  @override
  String get checkoutErrNoAddress => 'Lütfen bir teslimat adresi seçin';

  @override
  String get checkoutErrCardNumber =>
      '16 haneli geçerli bir kart numarası girin';

  @override
  String get checkoutErrCardNumberInvalid => 'Kart numarası geçersiz';

  @override
  String get checkoutErrCardHolder => 'Kart sahibinin adını harflerle girin';

  @override
  String get checkoutErrExpiry =>
      'Son kullanma tarihini AA/YY formatında girin';

  @override
  String get checkoutErrExpiryPast => 'Kartın son kullanma tarihi geçmiş';

  @override
  String get checkoutErrCvv => '3 veya 4 haneli CVV girin';

  @override
  String get checkoutErrEmptyCart => 'Sepetiniz boş';

  @override
  String get checkoutErrCouponEmpty => 'Lütfen bir kupon kodu girin';

  @override
  String get checkoutErrCouponInvalid => 'Geçersiz kupon kodu';

  @override
  String get checkoutErrCouponNotApplicable =>
      'Kupon bu sipariş için geçerli değil';

  @override
  String get checkoutErrCouponFailed => 'Kupon uygulanamadı';

  @override
  String get checkoutErrCouponExpired => 'Bu kuponun süresi dolmuş';

  @override
  String get checkoutErrCouponUsageLimit => 'Kupon kullanım limitine ulaşıldı';

  @override
  String get couponsMyCouponsTitle => 'Kuponlarım';

  @override
  String get couponsAvailableTab => 'Kullanılabilir';

  @override
  String get couponsHistoryTab => 'Kullanım Geçmişi';

  @override
  String couponsCopied(String code) {
    return '$code kopyalandı';
  }

  @override
  String get couponsEmptyTitle => 'Şu an kullanılabilir kupon yok';

  @override
  String get couponsEmptySubtitle => 'Yakında kampanyaları takip edin!';

  @override
  String get couponsLoadError => 'Kuponlar yüklenemedi';

  @override
  String get couponsRetry => 'Tekrar Dene';

  @override
  String couponsValidUntil(String date) {
    return '$date\'e kadar';
  }

  @override
  String get sellerCouponManagementTitle => 'Kupon Yönetimi';

  @override
  String get sellerCouponNew => 'Yeni Kupon';

  @override
  String get sellerCouponShowExpired => 'Süresi Dolanları Göster';

  @override
  String get sellerCouponHideExpired => 'Süresi Dolanları Gizle';

  @override
  String get sellerCouponLoadError => 'Kuponlar yüklenemedi';

  @override
  String get sellerCouponEmptyTitle => 'Henüz kupon oluşturmadınız';

  @override
  String get sellerCouponEmptySubtitle =>
      'Aşağıdaki butona tıklayarak başlayın';

  @override
  String get sellerCouponCreateDialogTitle => 'Yeni Kupon Oluştur';

  @override
  String get sellerCouponCodeLabel => 'Kupon Kodu';

  @override
  String get sellerCouponRandom => 'Rastgele';

  @override
  String get sellerCouponDescLabel => 'Açıklama (opsiyonel)';

  @override
  String get sellerCouponTypeLabel => 'İndirim Türü';

  @override
  String get sellerCouponPercent => 'Yüzde (%)';

  @override
  String get sellerCouponFixed => 'Sabit (₺)';

  @override
  String get sellerCouponRateLabel => 'İndirim Oranı (%)';

  @override
  String get sellerCouponAmountLabel => 'İndirim Tutarı (₺)';

  @override
  String get sellerCouponMinPurchase => 'Min. Sepet Tutarı (₺)';

  @override
  String get sellerCouponMaxDiscount => 'Maks. İndirim Tutarı ₺ (opsiyonel)';

  @override
  String get sellerCouponPerUserLimit => 'Kişi Başı Kullanım Limiti';

  @override
  String get sellerCouponTotalLimit => 'Toplam Kullanım Limiti (opsiyonel)';

  @override
  String get sellerCouponStartDate => 'Başlangıç';

  @override
  String get sellerCouponEndDate => 'Bitiş';

  @override
  String get sellerCouponFirstOrderOnly => 'Yalnızca İlk Sipariş';

  @override
  String get sellerCouponCreate => 'Oluştur';

  @override
  String get sellerCouponValidationError => 'Kod ve indirim değeri gereklidir';

  @override
  String sellerCouponCreated(String code) {
    return '$code kuponu oluşturuldu';
  }

  @override
  String get sellerCouponCreateFailed => 'Kupon oluşturulamadı';

  @override
  String get sellerCouponToggleFailed => 'Durum değiştirilemedi';

  @override
  String get sellerCouponDeleteTitle => 'Kuponu Sil';

  @override
  String sellerCouponDeleteConfirm(String code) {
    return '$code kodlu kuponu silmek istediğinize emin misiniz?';
  }

  @override
  String sellerCouponDeleted(String code) {
    return '$code silindi';
  }

  @override
  String get sellerCouponDeleteFailed => 'Kupon silinemedi';

  @override
  String sellerCouponValidUntil(String date) {
    return '$date\'e kadar';
  }

  @override
  String sellerCouponUsageLimited(String count, String total) {
    return '$count / $total kullanım';
  }

  @override
  String sellerCouponUsage(String count) {
    return '$count kullanım';
  }

  @override
  String get sellerCouponFirstOrderLabel => 'İlk Sipariş';

  @override
  String get sellerCouponExpiredLabel => 'Süresi Doldu';

  @override
  String checkoutCouponApplied(String amount) {
    return 'Kupon uygulandı! ₺$amount indirim';
  }

  @override
  String checkoutCouponDiscount(String amount) {
    return '₺$amount indirim uygulandı';
  }

  @override
  String get checkoutOrderSuccess => 'Siparişiniz Alındı!';

  @override
  String get checkoutOrderSuccessDesc =>
      'Siparişiniz başarıyla oluşturuldu. Siparişlerim sayfasından takip edebilirsiniz.';

  @override
  String get checkoutGoToOrders => 'Siparişlerime Git';

  @override
  String checkoutOrderError(String error) {
    return 'Sipariş oluşturulamadı: $error';
  }

  @override
  String healthJournalTitle(String petName) {
    return '$petName Sağlık Günlüğü';
  }

  @override
  String get healthAddRecord => 'Kayıt Ekle';

  @override
  String get healthTypeAll => 'Tümü';

  @override
  String get healthTypeWeight => 'Kilo';

  @override
  String get healthTypeMedication => 'İlaç';

  @override
  String get healthTypeVetVisit => 'Veteriner';

  @override
  String get healthTypeNote => 'Not';

  @override
  String get healthRecordAdded => 'Kayıt eklendi.';

  @override
  String get healthRecordDeleteTitle => 'Kaydı Sil';

  @override
  String get healthRecordDeleteContent =>
      'Bu sağlık kaydını silmek istediğinize emin misiniz?';

  @override
  String get healthNoRecords => 'Henüz sağlık kaydı yok';

  @override
  String healthNoFilterRecords(String type) {
    return '$type kaydı yok';
  }

  @override
  String get healthAddHint => 'Sağ alttaki + butonuna basarak kayıt ekleyin';

  @override
  String get healthWeightChart => 'Kilo Takibi';

  @override
  String get healthWeightChartMin => 'Grafik için en az 2 kilo kaydı gerekli';

  @override
  String get healthWeightChartError => 'Kilo grafiği yüklenemedi';

  @override
  String get healthRefresh => 'Yenile';

  @override
  String healthLoadError(String error) {
    return 'Yüklenemedi: $error';
  }

  @override
  String healthDose(String dose) {
    return 'Doz: $dose';
  }

  @override
  String healthFrequency(String freq) {
    return 'Sıklık: $freq';
  }

  @override
  String healthVetName(String name) {
    return 'Veteriner: $name';
  }

  @override
  String healthDiagnosis(String diagnosis) {
    return 'Tanı: $diagnosis';
  }

  @override
  String get healthAddDialogTitle => 'Sağlık Kaydı Ekle';

  @override
  String get healthRecordType => 'Kayıt Tipi';

  @override
  String get healthRecordDate => 'Kayıt tarihi';

  @override
  String get healthWeightKg => 'Kilo (kg)';

  @override
  String get healthMedName => 'İlaç Adı *';

  @override
  String get healthMedDosage => 'Dozaj (ör. 5mg)';

  @override
  String get healthMedFreq => 'Sıklık (ör. Günde 2 kez)';

  @override
  String get healthVetNameLabel => 'Veteriner Adı';

  @override
  String get healthDiagnosisTreatment => 'Tanı / Tedavi';

  @override
  String get healthNotes => 'Notlar (isteğe bağlı)';

  @override
  String get healthErrWeight => 'Geçerli bir kilo girin.';

  @override
  String get healthErrMedName => 'İlaç adı zorunludur.';

  @override
  String get blockUserTitle => 'Kullanıcıyı Engelle';

  @override
  String blockUserContent(String name) {
    return '$name adlı kullanıcıyı engellemek istediğinize emin misiniz? Bu kullanıcının ilanlarını artık görmeyeceksiniz.';
  }

  @override
  String get blockUserAction => 'Engelle';

  @override
  String blockUserSuccess(String name) {
    return '$name engellendi.';
  }

  @override
  String blockUserError(String error) {
    return 'Engelleme başarısız: $error';
  }

  @override
  String get blockUserSubtitle =>
      'Bu kullanıcının ilanlarını görmek istemiyorum';

  @override
  String get reportUserTitle => 'Şikayet Et';

  @override
  String get reportUserSubtitle => 'Uygunsuz davranış veya içerik bildir';

  @override
  String reportDialogTitle(String name) {
    return '$name Şikayet Et';
  }

  @override
  String get reportReasonLabel => 'Şikayet nedeni:';

  @override
  String get reportReasonSpam => 'Spam';

  @override
  String get reportReasonHarassment => 'Taciz veya zorbalık';

  @override
  String get reportReasonInappropriate => 'Uygunsuz içerik';

  @override
  String get reportReasonFakeProfile => 'Sahte profil';

  @override
  String get reportReasonOther => 'Diğer';

  @override
  String get reportDescHint => 'Ek açıklama (isteğe bağlı)';

  @override
  String get reportAction => 'Şikayet Et';

  @override
  String get reportErrNoReason => 'Lütfen bir neden seçin.';

  @override
  String get reportSuccess => 'Şikayetiniz alındı, teşekkürler.';

  @override
  String get goBack => 'Geri Dön';

  @override
  String get petDetailLoadError => 'İlan yüklenemedi';

  @override
  String get petDetailGoBack => 'Geri Dön';

  @override
  String get petDetailShare => 'Paylaş';

  @override
  String get petDetailQrTooltip => 'QR Kimlik Kartı';

  @override
  String get petDetailQrCard => 'QR Kimlik Kartı';

  @override
  String get petDetailVaccine => 'Aşı';

  @override
  String get petDetailVaccineFull => 'Aşılı';

  @override
  String get petDetailVaccineMissing => 'Aşısız';

  @override
  String petDetailAgeYearsMonths(int years, int months) {
    return '$years yaş $months ay';
  }

  @override
  String petDetailShareText(String name) {
    return '$name - Pati Arkadaşı uygulamasında keşfet!';
  }

  @override
  String petDetailShareSubject(String name) {
    return '$name ilanı';
  }

  @override
  String get petDetailStatusActive => 'Yayında';

  @override
  String get petDetailStatusInactive => 'Pasif';

  @override
  String get petDetailBreedUnspecified => 'Cins belirtilmemiş';

  @override
  String get petDetailAbout => 'Hakkında';

  @override
  String get petDetailDetails => 'Detaylı Bilgiler';

  @override
  String get petDetailSpecies => 'Tür';

  @override
  String get petDetailBreedLabel => 'Cins';

  @override
  String get petDetailBreedUnset => 'Belirtilmemiş';

  @override
  String get petDetailGenderLabel => 'Cinsiyet';

  @override
  String get petDetailAgeLabel => 'Yaş';

  @override
  String petDetailAgeMonths(int months) {
    return '$months ay';
  }

  @override
  String get petDetailAdvertType => 'İlan Türü';

  @override
  String get petDetailHealth => 'Sağlık Bilgileri';

  @override
  String get petDetailVaccineStatus => 'Aşı Durumu';

  @override
  String get petDetailVaccineComplete => 'Aşıları Tam';

  @override
  String get petDetailVaccineNeeded => 'Aşı Gerekli';

  @override
  String get petDetailListingStatus => 'İlan Durumu';

  @override
  String get petDetailActive => 'Aktif';

  @override
  String get petDetailInactive => 'Pasif';

  @override
  String get petDetailLocation => 'Konum';

  @override
  String get petDetailLocationShared => 'Konum paylaşıldı';

  @override
  String get petDetailLocationNone => 'Konum bilgisi yok';

  @override
  String get petDetailOpenInMap => 'Haritada Aç';

  @override
  String get petDetailMapTapHint => 'Haritada görüntülemek için dokunun';

  @override
  String get petDetailMapOpenError => 'Harita uygulaması açılamadı';

  @override
  String get petDetailOwnerLabel => 'İlan Sahibi';

  @override
  String get petDetailOwnerUnknown => 'Sahip Bilgisi Yok';

  @override
  String get petDetailOwnerBannerTitle => 'Bu ilan size ait!';

  @override
  String get petDetailOwnerBannerDesc =>
      'İlanınızı güncel tutarak daha fazla ilgi çekebilirsiniz.';

  @override
  String get petDetailHealthJournal => 'Sağlık Günlüğü';

  @override
  String get petDetailMessage => 'Mesaj';

  @override
  String get petDetailAdoptBtn => 'Sahiplen';

  @override
  String get petDetailMatingRequest => 'Eşleştirme İsteği Gönder';

  @override
  String get petDetailQrAge => 'Yas';

  @override
  String get petDetailQrGender => 'Cinsiyet';

  @override
  String get petDetailQrVaccine => 'Asi';

  @override
  String get petDetailQrVaccineFull => 'Tam';

  @override
  String get petDetailQrVaccinePartial => 'Eksik';

  @override
  String get petDetailQrIdCopied => 'ID panoya kopyalandı';

  @override
  String get petDetailErrMsgLogin => 'Mesaj göndermek için giriş yapmalısınız.';

  @override
  String get petDetailErrOwnerNotFound => 'İlan sahibi bilgisi bulunamadı.';

  @override
  String get petDetailErrSelfMessage =>
      'Kendi ilanınıza mesaj gönderemezsiniz.';

  @override
  String get petDetailErrMatingLogin =>
      'Eşleştirme isteği göndermek için giriş yapmalısınız.';

  @override
  String get petDetailNoPetDialog => 'İlan Gerekli';

  @override
  String get petDetailNoPetContent =>
      'Eşleştirme isteği göndermek için önce bir eşleştirme ilanı oluşturmalısınız.';

  @override
  String get petDetailCreateListing => 'İlan Oluştur';

  @override
  String get petDetailSameSpeciesTitle => 'Aynı Tür Gerekli';

  @override
  String petDetailSameSpeciesContent(String species) {
    return 'Bu ilan \"$species\" türünde. Eşleştirme isteği gönderebilmek için aynı türden bir ilanınız olmalı.';
  }

  @override
  String petDetailMatingGenericError(String error) {
    return 'Eşleştirme isteği gönderilemedi: $error';
  }

  @override
  String get petDetailSuccessDialogTitle => 'İstek Gönderildi!';

  @override
  String get petDetailSuccessDialogMatch =>
      'Tebrikler! Karşılıklı eşleşme oluştu. Artık mesajlaşabilirsiniz.';

  @override
  String get petDetailSuccessDialogPending =>
      'Eşleştirme isteğiniz gönderildi. Karşı tarafın onayını bekliyorsunuz.';

  @override
  String get petDetailSuccessDialogStartChat => 'Mesajlaşmaya Başla';

  @override
  String get petDetailSelectPetTitle => 'Hayvanınızı Seçin';

  @override
  String petDetailSelectPetSubtitle(String species) {
    return 'Eşleştirme için $species türünden seçim yapın';
  }

  @override
  String get chatDeleteTitle => 'Sohbeti sil';

  @override
  String get chatDeleteContent =>
      'Bu sohbeti kalıcı olarak silmek istediğinizden emin misiniz? Bu işlem geri alınamaz.';

  @override
  String chatDeleteError(String error) {
    return 'Sohbet silinemedi: $error';
  }

  @override
  String get chatRefresh => 'Sohbeti yenile';

  @override
  String get chatNotifPrefs => 'Bildirim tercihleri';

  @override
  String get chatNotifPrefsSub =>
      'Ayarlar > Bildirimler bölümünden yönetebilirsin';

  @override
  String get chatNotifPrefsInfo =>
      'Bildirim tercihlerini ayarlar ekranından düzenleyebilirsin.';

  @override
  String get chatDeleteFromList => 'Sohbeti listeden sil';

  @override
  String get chatDeleteFromListSub => 'Sohbetler ekranından da silebilirsin.';

  @override
  String get chatBlockReport => 'Engelle / Şikayet Et';

  @override
  String get chatSelectFromGallery => 'Galeriden Seç';

  @override
  String get chatSelectFromGallerySub => 'Fotoğraf galerinizden seçin';

  @override
  String get chatCamera => 'Kamera';

  @override
  String get chatCameraSub => 'Yeni fotoğraf çekin';

  @override
  String get chatMsgHint => 'Mesajını yaz...';

  @override
  String get chatSearchHint => 'Mesajlarda ara...';

  @override
  String get chatErrMicPermission => 'Mikrofon izni gerekli.';

  @override
  String chatErrRecordStart(String error) {
    return 'Kayıt başlatılamadı: $error';
  }

  @override
  String chatErrAudioSend(String error) {
    return 'Ses gönderilemedi: $error';
  }

  @override
  String chatErrImagePick(String error) {
    return 'Resim seçilemedi: $error';
  }

  @override
  String chatErrImageSend(String error) {
    return 'Resim gönderilemedi: $error';
  }

  @override
  String get chatErrLoginRequired => 'Mesaj göndermek için giriş yapmalısınız.';

  @override
  String get chatErrLoginRequiredImage =>
      'Resim göndermek için giriş yapmalısınız.';

  @override
  String chatErrMsgSend(String error) {
    return 'Mesaj gönderilemedi: $error';
  }

  @override
  String chatErrMsgDelete(String error) {
    return 'Mesaj silinemedi: $error';
  }

  @override
  String chatErrReaction(String error) {
    return 'Reaksiyon gonderilemedi: $error';
  }

  @override
  String get chatMsgDeletedSelf => 'Bu mesajı sildiniz';

  @override
  String get chatDeleteMsgForMe => 'Bu mesajı kendimden sil';

  @override
  String get chatCopyMsg => 'Kopyala';

  @override
  String get chatAudioMsg => '[Ses Mesajı]';

  @override
  String chatSearchNoResults(String query) {
    return '\"$query\" için sonuç bulunamadı';
  }

  @override
  String get chatTooltipBack => 'Geri';

  @override
  String get chatTooltipSearch => 'Mesajlarda Ara';

  @override
  String get chatTooltipCloseSearch => 'Aramayı Kapat';

  @override
  String get chatTypeMatching => 'Eşleştirme sohbeti';

  @override
  String get chatTypeAdoption => 'Sahiplendirme sohbeti';

  @override
  String get chatTypeGeneral => 'Sohbet';

  @override
  String get ordersTitle => 'Siparişlerim';

  @override
  String get ordersEmpty => 'Henüz siparişiniz yok';

  @override
  String get ordersEmptyDesc => 'Mağazadan alışveriş yaparak başlayın';

  @override
  String get orderStatusPending => 'Onay Bekliyor';

  @override
  String get orderStatusProcessing => 'Hazırlanıyor';

  @override
  String get orderStatusShipped => 'Kargoya Verildi';

  @override
  String get orderStatusDelivered => 'Teslim Edildi';

  @override
  String get orderStatusCancelled => 'İptal Edildi';

  @override
  String get orderCancelTitle => 'Siparişi İptal Et';

  @override
  String get orderCancelContent =>
      'Bu siparişi iptal etmek istediğinize emin misiniz?';

  @override
  String get orderCancelAction => 'İptal Et';

  @override
  String get orderCancelSuccess => 'Sipariş iptal edildi';

  @override
  String orderCancelError(String error) {
    return 'İptal edilemedi: $error';
  }

  @override
  String orderNumber(String id) {
    return 'Sipariş #$id';
  }

  @override
  String orderItemCount(int count) {
    return '$count ürün';
  }

  @override
  String orderItemQty(int qty, String price) {
    return '$qty adet x ₺$price';
  }

  @override
  String get orderProducts => 'Ürünler';

  @override
  String get orderTrackingInfo => 'Kargo Takip Bilgisi';

  @override
  String orderTrackingCopied(String no) {
    return 'Takip no kopyalandı: $no';
  }

  @override
  String get orderMyOrdersTitle => 'Siparişlerim';

  @override
  String get orderNoOrders => 'Henüz siparişiniz yok';

  @override
  String get orderNoOrdersDesc => 'Mağazadan alışveriş yaparak başlayın';

  @override
  String orderLoadErr(String error) {
    return 'Hata: $error';
  }

  @override
  String get orderDeliveryAddress => 'Teslimat Adresi';

  @override
  String get orderReview => 'Değerlendir';

  @override
  String get copyTooltip => 'Kopyala';

  @override
  String orderMyRating(int rating) {
    return 'Puanınız: $rating';
  }

  @override
  String get nearbyTitle => 'Yakınımdaki İlanlar';

  @override
  String get nearbyLocating => 'Konum alınıyor...';

  @override
  String get nearbyNoResults => 'Bu bölgede ilan bulunamadı';

  @override
  String get nearbyExpandArea => 'Alanı genişlet (50 km)';

  @override
  String nearbyShown(int count) {
    return '$count ilan gösterildi';
  }

  @override
  String nearbyActiveFilters(int count) {
    return '$count filtre aktif';
  }

  @override
  String get nearbyClearFilters => 'Temizle';

  @override
  String get nearbyErrLocationService =>
      'Konum servisi kapalı. Lütfen ayarlardan açın.';

  @override
  String get nearbyErrPermDeniedForever =>
      'Konum izni kalıcı olarak reddedildi. Uygulama ayarlarından izin verin.';

  @override
  String get nearbyErrPermDenied =>
      'Konum izni gerekli. Lütfen tekrar deneyin.';

  @override
  String get nearbyErrTimeout =>
      'Konum alınamadı: zaman aşımı. Lütfen tekrar deneyin.';

  @override
  String get nearbyErrPermRequired =>
      'Konum izni gerekli. Lütfen ayarlardan izin verin.';

  @override
  String get nearbyErrGeneric => 'Konum alınamadı. Lütfen tekrar deneyin.';

  @override
  String get nearbyOpenLocationSettings => 'Konum Ayarlarını Aç';

  @override
  String get nearbyOpenAppSettings => 'Uygulama Ayarlarını Aç';

  @override
  String get filterTitle => 'Filtrele';

  @override
  String get filterReset => 'Sıfırla';

  @override
  String get filterAdvertType => 'İlan Türü';

  @override
  String get filterAnimalType => 'Hayvan Türü';

  @override
  String get filterBreed => 'Cins';

  @override
  String get filterVaccine => 'Aşı Durumu';

  @override
  String get filterVaccineAny => 'Fark Etmez';

  @override
  String get filterVaccinated => 'Aşılı';

  @override
  String get filterUnvaccinated => 'Aşısız';

  @override
  String get filterApply => 'Uygula';

  @override
  String get filterAll => 'Tümü';

  @override
  String get profileLoginRequired => 'Profili görmek için giriş yapmalısınız.';

  @override
  String get profileDeleteTitle => 'İlanı Sil';

  @override
  String get profileDeleteContent =>
      'Bu ilanı silmek istediğinizden emin misiniz? Bu işlem geri alınamaz.';

  @override
  String get profileDeleteSuccess => 'İlan başarıyla silindi.';

  @override
  String get profileLogoutTitle => 'Çıkış Yap';

  @override
  String get profileLogoutContent =>
      'Hesabınızdan çıkmak istediğinizden emin misiniz?';

  @override
  String get profileAdoptionApplications => 'Sahiplendirme Başvuruları';

  @override
  String get profileNewAdoptionBtn => 'Sahiplendirme';

  @override
  String get profileNewMatingBtn => 'Eşleştirme';

  @override
  String get profileLoginBtn => 'Giriş Yap';

  @override
  String get profileFavorites => 'Favoriler';

  @override
  String get profileOrders => 'Siparişler';

  @override
  String get profileSitterBtn => 'Sitter';

  @override
  String get profileNotifications => 'Bildirimler';

  @override
  String get profileMyStore => 'Mağazam';

  @override
  String get profileNoPetsTitle => 'Henüz ilan yok';

  @override
  String get profileNoPetsDesc =>
      'İlk ilanınızı oluşturarak topluluğa yeni bir dost kazandırabilirsiniz.';

  @override
  String get profileRoleSeller => 'Satıcı';

  @override
  String get profileRoleSitter => 'Sitter';

  @override
  String get profileRoleAdmin => 'Admin';

  @override
  String profileCompletePercent(int percent) {
    return 'Profili tamamla — $percent%';
  }

  @override
  String get profileAuthErr => 'Oturum doğrulanamadı. Tekrar deneyin.';

  @override
  String profileAdsLoadErr(String error) {
    return 'İlanlar yüklenemedi: $error';
  }

  @override
  String get cartTitle => 'Sepetim';

  @override
  String get cartClearAction => 'Boşalt';

  @override
  String get cartClearTitle => 'Sepeti Boşalt';

  @override
  String get cartClearContent =>
      'Sepetteki tüm ürünler silinecek. Emin misiniz?';

  @override
  String get cartItemRemoved => 'Ürün sepetten çıkarıldı';

  @override
  String cartItemRemoveError(String error) {
    return 'Ürün çıkarılamadı: $error';
  }

  @override
  String cartUpdateError(String error) {
    return 'Miktar güncellenemedi: $error';
  }

  @override
  String get cartCleared => 'Sepet boşaltıldı';

  @override
  String cartClearError(String error) {
    return 'Sepet boşaltılamadı: $error';
  }

  @override
  String get cartEmptyTitle => 'Sepetiniz Boş';

  @override
  String get cartEmptyDesc =>
      'Henüz sepetinize ürün eklemediniz.\nAlışverişe başlamak için mağazayı keşfedin!';

  @override
  String get cartShopNow => 'Alışverişe Başla';

  @override
  String get cartContinueShopping => 'Alışverişe Devam';

  @override
  String get cartCheckout => 'Ödemeye Geç';

  @override
  String get cartItemCount => 'Ürün Sayısı';

  @override
  String get cartTotalAmount => 'Toplam Tutar';

  @override
  String cartItemTotal(String total) {
    return 'Toplam: $total ₺';
  }

  @override
  String get cartLoadError => 'Sepet yüklenemedi';

  @override
  String get cartRetry => 'Yeniden Dene';

  @override
  String get sellerPanelTitle => 'Satıcı Paneli';

  @override
  String get sellerBecomeSeller => 'Satıcı Ol';

  @override
  String get sellerBecomeSellerDesc =>
      'Bu sayfayı görmek için satıcı olmanız gerekiyor';

  @override
  String get sellerStoreLoadErr => 'Mağaza bilgileri yüklenemedi';

  @override
  String get sellerOrderStatsLoadErr => 'Sipariş istatistikleri yüklenemedi';

  @override
  String get sellerProductStatsLoadErr => 'Ürün istatistikleri yüklenemedi';

  @override
  String get sellerRevenueChartLoadErr => 'Gelir grafiği yüklenemedi';

  @override
  String get sellerAttentionProducts => 'Dikkat Gerektiren Ürünler';

  @override
  String get sellerOutOfStock => 'Stokta Yok';

  @override
  String get sellerLowStock => 'Düşük Stok';

  @override
  String get sellerNoStore => 'Mağazanız Yok';

  @override
  String get sellerNoStoreDesc =>
      'Ürün satmaya başlamak için önce mağazanızı oluşturun';

  @override
  String get sellerCreateStore => 'Mağaza Oluştur';

  @override
  String get sellerActiveStore => 'Aktif Mağaza';

  @override
  String get sellerTotalRevenue => 'Toplam Gelir';

  @override
  String get sellerPendingOrders => 'Bekleyen';

  @override
  String sellerTotalOrdersCount(int count) {
    return '$count toplam';
  }

  @override
  String get sellerTotalProducts => 'Toplam Ürün';

  @override
  String get sellerQuickActions => 'Hızlı İşlemler';

  @override
  String get sellerAddProduct => 'Ürün Ekle';

  @override
  String get sellerManageProducts => 'Ürünlerimi Yönet';

  @override
  String get sellerViewStore => 'Mağazamı Gör';

  @override
  String get sellerMyOrders => 'Siparişlerim';

  @override
  String get sellerDemoProducts => 'Demo Ürünler Ekle';

  @override
  String get sellerDemoProductsLoading => 'Demo Ürünler Ekleniyor...';

  @override
  String get sellerDemoProductsTitle => 'Demo Ürünler Ekle';

  @override
  String get sellerDemoProductsContent =>
      'Bu işlem mağazanızdaki tüm ürünleri silip yerine demo ürünler ekleyecektir. Devam etmek istiyor musunuz?';

  @override
  String get sellerDemoProductsContinue => 'Devam Et';

  @override
  String sellerDemoProductsAdded(int count) {
    return '$count demo ürün başarıyla eklendi!';
  }

  @override
  String sellerErrGeneric(String error) {
    return 'Hata: $error';
  }

  @override
  String get sellerLast6Months => 'Son 6 Ay';

  @override
  String get sellerChartRevenue => 'Gelir';

  @override
  String get sellerChartOrders => 'Sipariş';

  @override
  String sellerStockLabel(int count) {
    return 'Stok: $count';
  }

  @override
  String sellerOrderCountTooltip(int count) {
    return '$count sipariş';
  }

  @override
  String get sellerRetry => 'Yenile';

  @override
  String get productMgmtTitle => 'Ürün Yönetimi';

  @override
  String get productMgmtAll => 'Tümü';

  @override
  String get productMgmtActive => 'Aktif';

  @override
  String get productMgmtInactive => 'Pasif';

  @override
  String get productMgmtLowStock => 'Düşük Stok';

  @override
  String get productMgmtOutOfStock => 'Stokta Yok';

  @override
  String get productMgmtNoProducts => 'Henüz ürün eklenmemiş';

  @override
  String get productMgmtNoCategoryProducts => 'Bu kategoride ürün yok';

  @override
  String get productMgmtAddFirst => 'İlk Ürünü Ekle';

  @override
  String get productMgmtAddProduct => 'Ürün Ekle';

  @override
  String get productMgmtLoadErr => 'Ürünler yüklenemedi';

  @override
  String get productMgmtStatusActive => 'Aktif';

  @override
  String get productMgmtStatusInactive => 'Pasif';

  @override
  String productMgmtStock(int count) {
    return 'Stok: $count';
  }

  @override
  String get productMgmtStockOutBadge => 'Stokta Yok';

  @override
  String get productMgmtStockLowBadge => 'Düşük';

  @override
  String get productMgmtDeactivate => 'Pasif Yap';

  @override
  String get productMgmtActivate => 'Aktif Yap';

  @override
  String get productMgmtStockAction => 'Stok';

  @override
  String get productMgmtEditAction => 'Düzenle';

  @override
  String get productMgmtDeleteAction => 'Sil';

  @override
  String get productMgmtToggleDeactivated => 'Ürün pasif yapıldı';

  @override
  String get productMgmtToggleActivated => 'Ürün aktif yapıldı';

  @override
  String get productMgmtStockUpdated => 'Stok güncellendi';

  @override
  String get productMgmtEditSoon => 'Ürün düzenleme yakında eklenecek';

  @override
  String get productMgmtDeleteTitle => 'Ürünü Sil';

  @override
  String productMgmtDeleteContent(String name) {
    return '\"$name\" ürününü silmek istediğinizden emin misiniz?';
  }

  @override
  String get productMgmtDeleteWarning => 'Bu işlem geri alınamaz!';

  @override
  String get productMgmtDeleted => 'Ürün silindi';

  @override
  String get productMgmtUpdateStockTitle => 'Stok Güncelle';

  @override
  String get productMgmtCurrentStock => 'Mevcut Stok';

  @override
  String get productMgmtStockUnit => 'adet';

  @override
  String get productMgmtStockChange => 'Değiştir';

  @override
  String get productMgmtStockIncrease => 'Arttır';

  @override
  String get productMgmtStockDecrease => 'Azalt';

  @override
  String get productMgmtNewStockAmt => 'Yeni Stok Miktarı';

  @override
  String get productMgmtAddAmt => 'Eklenecek Miktar';

  @override
  String get productMgmtSubtractAmt => 'Düşülecek Miktar';

  @override
  String get productMgmtEnterAmt => 'Miktar girin';

  @override
  String get productMgmtUpdate => 'Güncelle';

  @override
  String get matchReqNoRequests => 'Henüz istek yok.';

  @override
  String matchReqSenderLabel(String name) {
    return 'Gönderen: $name';
  }

  @override
  String matchReqReceiverLabel(String name) {
    return 'Alıcı: $name';
  }

  @override
  String matchReqSenderPet(String name) {
    return 'Gönderen peti: $name';
  }

  @override
  String matchReqSelectedPet(String name) {
    return 'Seçilen petin: $name';
  }

  @override
  String get matchReqViewListing => 'Gönderen ilanını gör';

  @override
  String matchReqActDone(String action) {
    return 'İşlem tamamlandı: $action';
  }

  @override
  String matchReqMatchSuccess(String name) {
    return 'Eşleşme başarılı! $name ile sohbete yönlendiriliyorsunuz...';
  }

  @override
  String get matchReqGoNow => 'Şimdi Git';

  @override
  String matchReqChatError(String error) {
    return 'Sohbet açılamadı: $error';
  }

  @override
  String get matchReqAccept => 'Kabul Et';

  @override
  String get matchReqReject => 'Reddet';

  @override
  String get matchReqGoToChat => 'Sohbete git';

  @override
  String get loginTitle => 'Giriş Yap';

  @override
  String get loginEmailError => 'Geçerli e-posta girin';

  @override
  String get loginPasswordError => 'En az 6 karakter';

  @override
  String get loginNoAccount => 'Hesabın yok mu?';

  @override
  String get registerTitle => 'Hesap Oluştur';

  @override
  String get registerNameError => 'Ad gerekli';

  @override
  String get registerPasswordConfirmHint => 'Şifre Tekrar';

  @override
  String get registerPasswordMismatch => 'Şifreler eşleşmiyor';

  @override
  String get registerHasAccount => 'Zaten hesabın var mı?';

  @override
  String get forgotTitle => 'Şifremi Unuttum';

  @override
  String get forgotDesc =>
      'Şifrenizi sıfırlamak için e-posta adresinizi girin.';

  @override
  String get forgotSubmit => 'Kod Gönder';

  @override
  String get forgotSuccessTitle => 'E-posta Gönderildi!';

  @override
  String forgotSuccessDesc(String email) {
    return '$email adresine şifre sıfırlama kodu gönderdik.';
  }

  @override
  String get forgotEnterCode => 'Kodu Gir';

  @override
  String get resetTitle => 'Şifre Sıfırla';

  @override
  String resetDesc(String email) {
    return '$email adresine gönderilen kodu girin.';
  }

  @override
  String get resetCodeHint => 'Doğrulama Kodu';

  @override
  String get resetCodeError => 'Kod gerekli';

  @override
  String get resetNewPasswordHint => 'Yeni Şifre';

  @override
  String get resetPasswordError => 'En az 6 karakter';

  @override
  String get resetSubmit => 'Şifreyi Sıfırla';

  @override
  String get resetSuccess => 'Şifreniz başarıyla sıfırlandı!';

  @override
  String get createPetEditTitle => 'İlanı Düzenle';

  @override
  String get createPetNewTitle => 'Yeni İlan';

  @override
  String get createPetUpdateDesc => 'İlan bilgilerini güncelle';

  @override
  String get createPetNewDesc => 'Yeni ilan oluştur';

  @override
  String get createPetHeroDesc =>
      'İlan tipini seç, fotoğraf/video ekle ve patili dostuna uygun evi bul.';

  @override
  String get createPetAdoptionChip => 'Sahiplendirme ilanı';

  @override
  String get createPetMatingChip => 'Eşleştirme ilanı';

  @override
  String get createPetBasicInfo => 'Temel Bilgiler';

  @override
  String get createPetNameLabel => 'İsim';

  @override
  String get createPetNameError => 'İsim zorunludur';

  @override
  String get createPetSpeciesLabel => 'Tür';

  @override
  String get createPetGenderLabel => 'Cinsiyet';

  @override
  String get createPetVaccinatedTitle => 'Aşıları tam';

  @override
  String get createPetVaccinatedSubtitle =>
      'Aşı bilgileri ilanda rozet olarak gösterilir.';

  @override
  String get createPetDetailsSection => 'Detaylar';

  @override
  String get createPetAgeLabel => 'Yaş (Ay)';

  @override
  String get createPetAgeError => 'Yaş zorunlu';

  @override
  String get createPetAgeInvalidError => 'Geçerli bir sayı girin';

  @override
  String get createPetBreedLabel => 'Cins';

  @override
  String get createPetBreedSelect => 'Seçiniz';

  @override
  String get createPetBreedSearch => 'Cins ara...';

  @override
  String get createPetDescLabel => 'Açıklama';

  @override
  String get createPetDescHint => 'Karakteri, sağlık durumu ve ihtiyaçları';

  @override
  String get createPetLocationSelected => 'Konum seçildi';

  @override
  String get createPetLocationAdd => 'Konum ekle';

  @override
  String get createPetLocationHint => 'İl/ilçe seçimi için haritayı aç';

  @override
  String get createPetMedia => 'Fotoğraf & Video';

  @override
  String get createPetAddPhotoBtn => 'Fotoğraf ekle';

  @override
  String get createPetAddVideoBtn => 'Video ekle';

  @override
  String get createPetSave => 'Kaydet';

  @override
  String get createPetPublish => 'Yayınla';

  @override
  String get shellOfflineBanner => 'İnternet bağlantısı yok';

  @override
  String get shellReconnected => 'İnternet bağlantısı yeniden kuruldu';

  @override
  String get shellApptSnackView => 'Görüntüle';

  @override
  String get shellAdvertsNav => 'İlanlarım';

  @override
  String get shellGuideFab => 'Rehber Pati';

  @override
  String get addressEditTitle => 'Adresi Düzenle';

  @override
  String get addressNewTitle => 'Yeni Adres';

  @override
  String get addressUpdated => 'Adres güncellendi';

  @override
  String get addressAdded => 'Adres eklendi';

  @override
  String addressSaveErr(String error) {
    return 'Hata: $error';
  }

  @override
  String get addressInfoCard => 'Adres Bilgileri';

  @override
  String get addressTitleLabel => 'Adres Başlığı';

  @override
  String get addressTitleHint => 'Ev, İş, vb.';

  @override
  String get addressRecipientCard => 'Alıcı Bilgileri';

  @override
  String get addressFullName => 'Ad Soyad';

  @override
  String get addressFullNameHint => 'Teslimat alacak kişi';

  @override
  String get addressPhone => 'Telefon';

  @override
  String get addressDetailsCard => 'Adres Detayları';

  @override
  String get addressCity => 'İl';

  @override
  String get addressCityHint => 'İstanbul';

  @override
  String get addressDistrict => 'İlçe';

  @override
  String get addressDistrictHint => 'Kadıköy';

  @override
  String get addressNeighborhood => 'Mahalle';

  @override
  String get addressNeighborhoodHint => 'Mahalle adı';

  @override
  String get addressStreet => 'Sokak/Cadde';

  @override
  String get addressStreetHint => 'Sokak veya cadde adı';

  @override
  String get addressBuildingNo => 'Bina No';

  @override
  String get addressFloor => 'Kat';

  @override
  String get addressApartmentNo => 'Daire';

  @override
  String get addressPostalCode => 'Posta Kodu';

  @override
  String get addressPreferencesCard => 'Tercihler';

  @override
  String get addressSetDefault => 'Varsayılan adres olarak ayarla';

  @override
  String get addressSetDefaultSub => 'Siparişlerde bu adres otomatik seçilir';

  @override
  String get addressUpdate => 'Güncelle';

  @override
  String addressRequired(String field) {
    return '$field zorunludur';
  }

  @override
  String get verifyTitle => 'E-posta Doğrula';

  @override
  String verifyDesc(String email) {
    return '$email adresine bir doğrulama kodu gönderdik.';
  }

  @override
  String get verifyCodeLabel => 'Doğrulama Kodu';

  @override
  String get verifySubmit => 'Doğrula';

  @override
  String get verifySuccess => 'E-posta doğrulandı! Giriş yapabilirsiniz.';

  @override
  String get verifyBackToLogin => 'Giriş sayfasına dön';

  @override
  String get userProfileLoadErr => 'Profil yüklenemedi';

  @override
  String get userProfileAbout => 'Hakkında';

  @override
  String userProfileListings(int count) {
    return 'İlanlar ($count)';
  }

  @override
  String get userProfileNoListings => 'Henüz ilan yok';

  @override
  String get userProfileMessageTooltip => 'Mesaj gönder';

  @override
  String userProfileChatErr(String error) {
    return 'Sohbet başlatılamadı: $error';
  }

  @override
  String userProfileMemberSince(int year) {
    return '$year\'den beri üye';
  }

  @override
  String get userProfileDefaultName => 'Kullanıcı';

  @override
  String get userProfileTypeAdopt => 'Sahiplendir';

  @override
  String get userProfileTypeMating => 'Çiftleştir';

  @override
  String get userProfileTypeLost => 'Kayıp';

  @override
  String get shellBirthdayDefault => 'Dostunuzun doğum günü bugün!';

  @override
  String get shellApptReminderDefault => 'Evcil hayvanınız';

  @override
  String get shellAdvertExpiryDefault => 'İlanınızın süresi doluyor.';

  @override
  String get vacCalendarTitle => 'Aşı Takvimi';

  @override
  String vacCalendarLoadErr(String error) {
    return 'Hata: $error';
  }

  @override
  String get vacCalendarEmpty => 'Aşı takvimi bulunamadı';

  @override
  String get vacCalendarAddRecord => 'Aşı Kaydı Ekle';

  @override
  String get vacCalendarNoRecord => 'Bu gün için kayıt yok';

  @override
  String get vacCalendarClickDay => 'Bir güne tıklayın';

  @override
  String get vacCalendarAdd => 'Ekle';

  @override
  String vacCalendarFirstDose(int months) {
    return 'İlk Doz: $months ay';
  }

  @override
  String vacCalendarRepeat(int months) {
    return 'Tekrar: $months ay';
  }

  @override
  String get vacCalendarRequired => 'Zorunlu';

  @override
  String vacCalendarNext(String date) {
    return 'Sonraki: $date';
  }

  @override
  String get vetSearchTitle => 'Veteriner Ara';

  @override
  String get vetSearchGoogleTitle => 'Google ile Ara';

  @override
  String get vetSearchSortTooltip => 'Sırala';

  @override
  String get vetSearchSortByDistance => 'Mesafeye Göre';

  @override
  String get vetSearchSortByRating => 'Puana Göre';

  @override
  String get vetSearchHint => 'Klinik adı veya adres...';

  @override
  String get vetSearchUseLocation => 'Konumumu kullan';

  @override
  String get vetSearchErrPermission => 'Konum izni gerekli';

  @override
  String vetSearchErrLocation(String error) {
    return 'Konum alınamadı: $error';
  }

  @override
  String get vetSearchPrompt =>
      'Aramak için yukarıya yazın veya konumunuzu paylaşın';

  @override
  String get vetSearchNoResults => 'Sonuç bulunamadı';

  @override
  String get vetHomeTabSearch => 'Ara';

  @override
  String get vetHomeTabAppointments => 'Randevular';

  @override
  String get vetHomeTabVaccine => 'Aşı Takvimi';

  @override
  String get vetHomeSearchHint => 'Veteriner kliniği ara...';

  @override
  String get vetHomeNearMe => 'Yakınımda';

  @override
  String get vetHomeSaveClinic => 'Klinik Kaydet';

  @override
  String get vetHomeGoogleSearch => 'Google ile Ara';

  @override
  String get vetHomeReminders => 'Hatırlatmalar';

  @override
  String get vetHomeNearbyTitle => 'Yakınındaki Veterinerler';

  @override
  String get vetHomeNearbyPermRequired =>
      'Yakın veterinerleri görmek için konum izni verin';

  @override
  String get vetHomeNearbyEmpty => 'Yakında veteriner bulunamadı';

  @override
  String get vetHomeApptsEmpty => 'Henüz randevunuz yok';

  @override
  String get vetHomeApptsEmptyDesc => 'Veteriner arayın ve randevu alın';

  @override
  String get vetHomeVaccineTitle => 'Aşı Hatırlatmaları';

  @override
  String get vetHomeVaccineEmpty => 'Yaklaşan aşı hatırlatması yok';

  @override
  String get vetHomeVaccineEmptyDesc =>
      'Evcil hayvanınızın profil sayfasından aşı takvimini görüntüleyin';

  @override
  String get vetHomeVaccineOverdue => 'Gecikti';

  @override
  String get vetHomeVaccineUpcoming => 'Yaklaşıyor';

  @override
  String vetHomeLoadError(String error) {
    return 'Hata: $error';
  }

  @override
  String get storeHomeLive => 'Canlı Mağaza';

  @override
  String get storeHomeLiveDesc => 'Gerçek mağazalar ve gerçek ürünler burada.';

  @override
  String get storeHomeQuickExplore => 'Hızlı keşfet';

  @override
  String get storeHomeAll => 'Tümü';

  @override
  String get storeHomeFeatured => 'Öne çıkan mağazalar';

  @override
  String get storeHomeNoDesc => 'Açıklama yok.';

  @override
  String get storeHomeGoToStore => 'Mağazaya git';

  @override
  String get storeHomeProducts => 'Ürünler';

  @override
  String get storeHomeLatest => 'En Yeni';

  @override
  String get storeNoDescAdded => 'Açıklama eklenmemiş.';

  @override
  String get storeHomeCategoryLoadErr => 'Kategoriler yüklenemedi.';

  @override
  String get storeHomeFeaturedEmpty => 'Şimdilik öne çıkan mağaza yok.';

  @override
  String get storeHomeStoresLoadErr => 'Mağazalar yüklenemedi.';

  @override
  String get storeHomeProductsEmpty => 'Ürün bulunamadı';

  @override
  String get storeHomeProductsNotFound =>
      'Arama kriterlerinize uygun ürün yok.';

  @override
  String get storeHomeProductsNone => 'Henüz ürün eklenmemiş.';

  @override
  String get storeHomeProductsLoadErr => 'Ürünler yüklenemedi.';

  @override
  String get storeHomeFiltersClear => 'Filtreleri temizle';

  @override
  String storeHomeMyStoreLoadErr(String error) {
    return 'Mağazanız alınamadı: $error';
  }

  @override
  String get storeHomeCategoryNotFound => 'Kategori bulunamadı.';

  @override
  String get storeHomeSearchHint => 'Ürün veya mağaza ara';

  @override
  String get storeHomeSearchBtn => 'Ara';

  @override
  String get storeHomeOpenStore => 'Mağaza aç, ürünlerini vitrine çıkar!';

  @override
  String get storeHomeOpenStoreDesc =>
      'Dakikalar içinde başvur, petseverlere ulaş.';

  @override
  String get storeHomeOpenStoreBtn => 'Mağaza Aç';

  @override
  String get storeHomeRetry => 'Yeniden dene';

  @override
  String get storeMyCouponsLabel => 'Kuponlarım & Fırsatlar';

  @override
  String get productDetailSelectAllVariants =>
      'Lütfen tüm seçenekleri belirleyin';

  @override
  String get productVariantsTitle => 'Varyantlar';

  @override
  String get productVariantsDesc => 'Beden, renk, boyut gibi seçenekler';

  @override
  String get productVariantAdd => 'Ekle';

  @override
  String get productVariantNameHint => 'Varyant adı (ör: Boyut, Renk)';

  @override
  String get productVariantLabelHint => 'Etiket (ör: S, Kırmızı)';

  @override
  String get storeHomeSoldOut => 'Tükendi';

  @override
  String storeHomeLastStock(int count) {
    return 'Son $count';
  }

  @override
  String get storePriceAsc => 'Fiyat ↑';

  @override
  String get storePriceDesc => 'Fiyat ↓';

  @override
  String get storeNameAz => 'A–Z';

  @override
  String get storesListTitle => 'Mağazalar';

  @override
  String get storesListSearchHint => 'Mağaza ara...';

  @override
  String get storesListEmpty => 'Henüz mağaza yok';

  @override
  String get storesListSearchEmpty => 'Arama sonucu bulunamadı';

  @override
  String get storesListLoadErr => 'Mağazalar yüklenemedi';

  @override
  String get storesListRetry => 'Yeniden Dene';

  @override
  String get storeDetailTitle => 'Mağaza';

  @override
  String get storeDetailLoadErr => 'Mağaza yüklenemedi';

  @override
  String get storeDetailProductsLoadErr => 'Ürünler yüklenemedi';

  @override
  String get storeDetailNoProducts => 'Bu mağazada henüz ürün yok.';

  @override
  String get storeDetailTotalProducts => 'Toplam ürün';

  @override
  String get storeDetailAddProduct => 'Urun ekle';

  @override
  String get storeDetailFavorited => 'Favorilerde';

  @override
  String get storeDetailAddToFavorites => 'Favorilere ekle';

  @override
  String get storeDetailRemovedFav => 'Favorilerden kaldırıldı';

  @override
  String get storeDetailAddedFav => 'Favorilere eklendi';

  @override
  String storeDetailFavError(String error) {
    return 'Hata: $error';
  }

  @override
  String get storeDetailShare => 'Paylaş';

  @override
  String get storeDetailProductActive => 'Aktif';

  @override
  String get storeDetailProductInactive => 'Pasif';

  @override
  String get storeDetailProductSoldOut => 'Tukendi';

  @override
  String storeDetailProductStock(int count) {
    return 'Stok: $count';
  }

  @override
  String get storeDetailMenuEdit => 'Duzenle';

  @override
  String get storeDetailMenuToggle => 'Aktif/Pasif';

  @override
  String get storeDetailMenuDelete => 'Sil';

  @override
  String get storeDetailDeleteTitle => 'Urunu sil';

  @override
  String get storeDetailDeleteContent =>
      'Bu urunu silmek istediginize emin misiniz?';

  @override
  String get storeDetailDeleteCancel => 'Vazgec';

  @override
  String get storeDetailProductActivated => 'Urun aktif edildi.';

  @override
  String get storeDetailProductDeactivated => 'Urun pasif edildi.';

  @override
  String storeDetailProductUpdateErr(String error) {
    return 'Urun guncellenemedi: $error';
  }

  @override
  String get storeDetailProductDeleted => 'Urun silindi.';

  @override
  String storeDetailProductDeleteErr(String error) {
    return 'Urun silinemedi: $error';
  }

  @override
  String get storeDetailRetry => 'Yeniden Dene';

  @override
  String get applySellerTitle => 'Mağaza Aç';

  @override
  String get applySellerLogoTitle => 'Mağaza Logosu Seç';

  @override
  String get applySellerPickGallery => 'Galeriden Seç';

  @override
  String get applySellerPickCamera => 'Kamerayı Aç';

  @override
  String get applySellerLogoSection => 'Mağaza Logosu';

  @override
  String get applySellerLogoAdd => 'Logo Ekle';

  @override
  String get applySellerLogoHint =>
      'Kare formatta, minimum 200x200 piksel önerilir';

  @override
  String get applySellerInfoSection => 'Mağaza Bilgileri';

  @override
  String get applySellerNameLabel => 'Mağaza Adı *';

  @override
  String get applySellerNameHint => 'Örn: Happy Pets Store';

  @override
  String get applySellerNameRequired => 'Mağaza adı gerekli';

  @override
  String get applySellerNameTooShort => 'En az 3 karakter olmalı';

  @override
  String get applySellerDescLabel => 'Mağaza Açıklaması';

  @override
  String get applySellerDescHint => 'Mağazanızı tanıtın...';

  @override
  String get applySellerTermsTitle => 'Satıcı Sözleşmesi';

  @override
  String get applySellerTermsAccepted => 'Kabul Edildi';

  @override
  String get applySellerTermsRead =>
      'Satıcı sözleşmesini okudum ve kabul ediyorum';

  @override
  String get applySellerTermsDialogTitle => 'Satıcı Sözleşmesi';

  @override
  String get applySellerTermsAcceptBtn => 'Okudum ve Kabul Ediyorum';

  @override
  String get applySellerStepLogo => 'Logo';

  @override
  String get applySellerStepInfo => 'Bilgiler';

  @override
  String get applySellerStepContract => 'Sözleşme';

  @override
  String get applySellerOpenBtn => 'Mağazamı Aç';

  @override
  String get applySellerApprovalNote =>
      'Mağazanız onaylandıktan sonra ürün eklemeye başlayabilirsiniz.';

  @override
  String get applySellerSuccessTitle => 'Tebrikler!';

  @override
  String applySellerSuccessDesc(String storeName) {
    return '\"$storeName\" mağazanız başarıyla oluşturuldu!';
  }

  @override
  String get applySellerGoToStore => 'Mağazama Git';

  @override
  String get applySellerGenericError =>
      'Bir hata oluştu, lütfen tekrar deneyin.';

  @override
  String get addProductTitle => 'Ürün Ekle';

  @override
  String get addProductEditTitle => 'Ürün Düzenle';

  @override
  String get addProductPhotosSection => 'Ürün Fotoğrafları';

  @override
  String get addProductPickGallery => 'Galeriden Seç';

  @override
  String get addProductPickGallerySub => 'Mevcut fotoğraflarınızdan seçin';

  @override
  String get addProductPickCamera => 'Kamerayı Aç';

  @override
  String get addProductPickCameraSub => 'Yeni fotoğraf çekin';

  @override
  String get addProductPickDialogTitle => 'Fotoğraf Ekle';

  @override
  String get addProductAddBtn => 'Ekle';

  @override
  String addProductMaxWarning(int max) {
    return 'En fazla $max fotoğraf ekleyebilirsiniz';
  }

  @override
  String addProductPhotosHint(int max) {
    return 'Ürününüzün fotoğraflarını ekleyin (max $max)';
  }

  @override
  String get addProductTitleField => 'Ürün Başlığı';

  @override
  String get addProductTitleHint => 'Örn: Renkli kedi oyuncağı';

  @override
  String get addProductTitleRequired => 'Başlık gerekli';

  @override
  String get addProductCategoryLabel => 'Kategori';

  @override
  String get addProductCategoryRequired => 'Kategori seçin';

  @override
  String get addProductDescLabel => 'Açıklama';

  @override
  String get addProductDescHint => 'Ürün özellikleri, boyut, malzeme...';

  @override
  String get addProductPriceLabel => 'Fiyat (₺)';

  @override
  String get addProductPriceRequired => 'Gerekli';

  @override
  String get addProductPriceInvalid => 'Geçersiz';

  @override
  String get addProductStockLabel => 'Stok';

  @override
  String get addProductActiveLabel => 'Ürün Aktif';

  @override
  String get addProductInactiveLabel => 'Ürün Pasif';

  @override
  String get addProductSaving => 'Kaydediliyor...';

  @override
  String get addProductSaveBtn => 'Kaydet';

  @override
  String get addProductUpdated => 'Ürün güncellendi!';

  @override
  String get addProductAdded => 'Ürün eklendi!';

  @override
  String get addProductCategoryLoadErr => 'Kategoriler yüklenemedi.';

  @override
  String get addProductCategoryNotFound => 'Kategori bulunamadı.';

  @override
  String get addProductRetry => 'Yeniden dene';

  @override
  String addProductCategoryLoading(String label) {
    return '$label yükleniyor...';
  }

  @override
  String get sellerOrdersTitle => 'Siparişlerim';

  @override
  String get sellerOrdersTabAll => 'Tümü';

  @override
  String get sellerOrdersTabPending => 'Bekleyen';

  @override
  String get sellerOrdersTabProcessing => 'Hazırlanan';

  @override
  String get sellerOrdersTabShipped => 'Kargoda';

  @override
  String get sellerOrdersTabCompleted => 'Tamamlanan';

  @override
  String get sellerOrdersEmpty => 'Henüz sipariş yok';

  @override
  String get sellerOrdersEmptyDesc =>
      'Ürünlerinize sipariş geldiğinde burada görünecek';

  @override
  String sellerOrdersLoadErr(String error) {
    return 'Siparişler yüklenemedi: $error';
  }

  @override
  String get sellerOrdersCategoryEmpty => 'Bu kategoride sipariş yok';

  @override
  String get sellerOrdersStatusUpdated => 'Sipariş durumu güncellendi';

  @override
  String sellerOrdersStatusError(String error) {
    return 'Hata: $error';
  }

  @override
  String get sellerOrdersStatTotal => 'Toplam';

  @override
  String get sellerOrdersStatPending => 'Bekleyen';

  @override
  String get sellerOrdersStatSales => 'Satış';

  @override
  String get sellerOrdersStatRevenue => 'Gelir';

  @override
  String get sellerOrdersPrepare => 'Hazırla';

  @override
  String get sellerOrdersShip => 'Kargola';

  @override
  String get sellerOrdersDelivered => 'Teslim Edildi';

  @override
  String sellerOrdersItemCount(int count) {
    return '$count ürün';
  }

  @override
  String sellerOrdersItemQty(int qty, String price) {
    return '$qty adet x ₺$price';
  }

  @override
  String get petCardMating => 'Eşleştirme';

  @override
  String get petCardAdoption => 'Sahiplendirme';

  @override
  String get petCardVaccinated => 'Aşılı';

  @override
  String get petCardOwnerUnknown => 'Bilinmiyor';

  @override
  String get apptCreateTitle => 'Randevu Oluştur';

  @override
  String get apptCreateSelectPet => 'Evcil Hayvan Seçin';

  @override
  String get apptCreateDate => 'Tarih';

  @override
  String get apptCreateTime => 'Saat';

  @override
  String get apptCreateReason => 'Randevu Nedeni';

  @override
  String get apptCreateNotes => 'Notlar (opsiyonel)';

  @override
  String get apptCreateBtn => 'Randevu Oluştur';

  @override
  String get apptCreateSuccess => 'Randevu oluşturuldu!';

  @override
  String get apptCreateSelectDateBtn => 'Tarih seçin';

  @override
  String get apptCreateNoPets => 'Henüz evcil hayvan eklememişsiniz';

  @override
  String get apptCreateNoSlots => 'Bu tarihte uygun slot bulunamadı';

  @override
  String get apptCreateValidation => 'Lütfen pet, tarih ve saat seçin';

  @override
  String apptCreateSlotsError(String error) {
    return 'Slotlar alınamadı: $error';
  }

  @override
  String apptCreatePetsError(String error) {
    return 'Petler yüklenemedi: $error';
  }

  @override
  String apptCreateError(String error) {
    return 'Hata: $error';
  }

  @override
  String get apptDetailTitle => 'Randevu Detay';

  @override
  String get apptDetailDate => 'Tarih ve Saat';

  @override
  String get apptDetailVet => 'Veteriner';

  @override
  String get apptDetailPet => 'Evcil Hayvan';

  @override
  String get apptDetailReason => 'Randevu Nedeni';

  @override
  String get apptDetailNotes => 'Notlar';

  @override
  String get apptDetailVetNotes => 'Veteriner Notları';

  @override
  String get apptDetailCancelBtn => 'Randevuyu İptal Et';

  @override
  String get apptDetailCancelTitle => 'Randevuyu İptal Et';

  @override
  String get apptDetailCancelContent =>
      'Randevuyu iptal etmek istediğinize emin misiniz?';

  @override
  String get apptDetailCancelConfirm => 'İptal Et';

  @override
  String get apptDetailCancelBack => 'Vazgeç';

  @override
  String get apptDetailCancelSuccess => 'Randevu iptal edildi';

  @override
  String apptDetailError(String error) {
    return 'Hata: $error';
  }

  @override
  String get vetRegisterTitle => 'Klinik Kaydet';

  @override
  String get vetRegisterClinicName => 'Klinik Adı *';

  @override
  String get vetRegisterAddress => 'Adres *';

  @override
  String get vetRegisterPhone => 'Telefon';

  @override
  String get vetRegisterEmail => 'E-posta';

  @override
  String get vetRegisterDesc => 'Açıklama';

  @override
  String vetRegisterLocationLabel(String lat, String lng) {
    return 'Konum: $lat, $lng';
  }

  @override
  String get vetRegisterLocationNone => 'Konum eklenmedi';

  @override
  String get vetRegisterGetLocation => 'Konum Al';

  @override
  String get vetRegisterGettingLocation => 'Alınıyor...';

  @override
  String get vetRegisterSpecies => 'Hizmet Verilen Türler';

  @override
  String get vetRegisterSaveBtn => 'Kaydet';

  @override
  String get vetRegisterSuccess => 'Klinik kaydedildi ve hesabınıza bağlandı!';

  @override
  String get vetRegisterClinicNameRequired => 'Klinik adı gerekli';

  @override
  String get vetRegisterAddressRequired => 'Adres gerekli';

  @override
  String vetRegisterLocationError(String error) {
    return 'Konum alınamadı: $error';
  }

  @override
  String get vetRegisterLocationDenied =>
      'Konum izni reddedildi. Ayarlardan izin verin.';

  @override
  String vetRegisterError(String error) {
    return 'Hata: $error';
  }

  @override
  String get searchHint => 'İlan, mağaza veya veteriner ara...';

  @override
  String get searchTypeHint => 'Aramak istediğinizi yazın';

  @override
  String get searchTypeHintSub => 'İlan, mağaza veya veteriner arayabilirsiniz';

  @override
  String get searchHistory => 'Son Aramalar';

  @override
  String get searchClearHistory => 'Tümünü Temizle';

  @override
  String searchError(String error) {
    return 'Arama hatası: $error';
  }

  @override
  String searchNoResults(String query) {
    return '\"$query\" için sonuç bulunamadı';
  }

  @override
  String get searchSectionListings => 'İlanlar';

  @override
  String get searchSectionStores => 'Mağazalar';

  @override
  String get searchSectionVets => 'Veterinerler';

  @override
  String get searchStoreSubtitle => 'Mağaza';

  @override
  String get searchVetSubtitle => 'Veteriner';

  @override
  String get aiAssistantTitle => 'Pati Asistan';

  @override
  String get aiModeReset => 'Sıfırla';

  @override
  String get aiModeDiagnosis => 'Teşhis';

  @override
  String get aiModeGeneral => 'Genel';

  @override
  String get aiSymptomLabel => 'Semptom seç (çoklu):';

  @override
  String get aiDiagnoseBtn => 'Teşhis Et →';

  @override
  String aiSymptomSelected(String symptoms) {
    return 'Seçili: $symptoms';
  }

  @override
  String get aiWelcomeDiagnosis => 'Semptom seç veya yaz → Teşhis al';

  @override
  String get aiWelcomeGeneral =>
      'Evcil hayvanın hakkında ne sormak istiyorsun?';

  @override
  String get aiWelcomeDiagnosisSub =>
      'Yukarıdan türü ve belirtileri seç,\nyoksa metin kutusuna yaz.';

  @override
  String get aiWelcomeGeneralSub =>
      'Bakım, beslenme, eğitim hakkında\nkısa ve pratik yanıtlar alırsın.';

  @override
  String get aiExampleLabel => 'Örnek sorular:';

  @override
  String get aiInputDiagnosisHint => 'Ek bilgi ekle veya direkt yaz...';

  @override
  String get aiInputGeneralHint => 'Sorunuzu yazın...';

  @override
  String get aiErrorResponse =>
      'Üzgünüm, şu an yanıt veremiyorum. Lütfen tekrar deneyin.';

  @override
  String get aiNoReply => 'Yanıt alınamadı.';

  @override
  String get guideTitle => 'Rehber Pati';

  @override
  String get guideNewChat => 'Yeni sohbet';

  @override
  String get guideWelcome => 'Merhaba! 👋';

  @override
  String get guideWelcomeSub =>
      'Ne yapmak istiyorsun?\nSana en kısa yoldan yardım edeyim.';

  @override
  String get guideQuickOptions => 'Hızlı seçenekler:';

  @override
  String get guideNavigateBtn => 'Götür beni →';

  @override
  String get guideInputHint => 'Ne yapmak istiyorsun?';

  @override
  String get guideConnError => 'Bağlantı hatası, lütfen tekrar dene.';

  @override
  String get guideUnknown => 'Anlayamadım.';

  @override
  String get monthJan => 'Oca';

  @override
  String get monthFeb => 'Şub';

  @override
  String get monthMar => 'Mar';

  @override
  String get monthApr => 'Nis';

  @override
  String get monthMay => 'May';

  @override
  String get monthJun => 'Haz';

  @override
  String get monthJul => 'Tem';

  @override
  String get monthAug => 'Ağu';

  @override
  String get monthSep => 'Eyl';

  @override
  String get monthOct => 'Eki';

  @override
  String get monthNov => 'Kas';

  @override
  String get monthDec => 'Ara';

  @override
  String get sitterFindTitle => 'Bakıcı Bul';

  @override
  String get sitterMyBookingsTooltip => 'Rezervasyonlarım';

  @override
  String get sitterServiceAll => 'Tümü';

  @override
  String get sitterServiceWalking => 'Gezdirme';

  @override
  String get sitterServiceHomeSitting => 'Ev Bakımı';

  @override
  String get sitterServiceBoarding => 'Pansiyon';

  @override
  String get sitterServiceDaycare => 'Gündüz Bakımı';

  @override
  String get sitterServiceGrooming => 'Tımar';

  @override
  String get sitterEmptyTitle => 'Yakında bakıcı bulunamadı';

  @override
  String get sitterEmptySubtitle =>
      'İlk bakıcı profilini oluştur ve diğer kullanıcılara hizmet ver!';

  @override
  String get sitterBecomeSitterBtn => 'Bakıcı Ol';

  @override
  String get sitterEditProfile => 'Profili Düzenle';

  @override
  String get sitterBasicInfo => 'Temel Bilgiler';

  @override
  String get sitterDisplayName => 'Görüntülenen İsim *';

  @override
  String get sitterDisplayNameRequired => 'İsim gerekli';

  @override
  String get sitterBio => 'Hakkında / Tanıtım';

  @override
  String get sitterExperience => 'Deneyim';

  @override
  String get sitterLocation => 'Konum';

  @override
  String get sitterUseLocation => 'Konumumu Kullan';

  @override
  String get sitterLocationObtained => 'Konum Alındı ✓';

  @override
  String get sitterAddress => 'Adres / Semt';

  @override
  String get sitterSpeciesTitle => 'Hangi Hayvanlarla Çalışıyorsunuz?';

  @override
  String get sitterSpeciesDog => 'Köpek';

  @override
  String get sitterSpeciesCat => 'Kedi';

  @override
  String get sitterSpeciesBird => 'Kuş';

  @override
  String get sitterSpeciesRabbit => 'Tavşan';

  @override
  String get sitterSpeciesOther => 'Diğer';

  @override
  String get sitterServicesTitle => 'Sunduğunuz Hizmetler';

  @override
  String get sitterServicesAdd => 'Ekle';

  @override
  String get sitterServicesAllAdded => 'Tüm hizmetler eklendi';

  @override
  String get sitterServiceType => 'Hizmet Türü';

  @override
  String get sitterServiceWalkingLabel => 'Gezdirme';

  @override
  String get sitterServiceHomeSittingLabel => 'Ev Bakımı';

  @override
  String get sitterServiceBoardingLabel => 'Pansiyonda Bakım';

  @override
  String get sitterServiceDaycareLabel => 'Gündüz Bakımı';

  @override
  String get sitterServiceGroomingLabel => 'Tımar/Bakım';

  @override
  String get sitterHourlyPrice => 'Saat Fiyatı (TL)';

  @override
  String get sitterDailyPrice => 'Gün Fiyatı (TL)';

  @override
  String get sitterSpeciesRequired => 'En az bir hayvan türü seçin';

  @override
  String get sitterLocationPermRequired => 'Konum izni gerekli';

  @override
  String sitterLocationErr(String error) {
    return 'Konum alınamadı: $error';
  }

  @override
  String get sitterAvailableNow => 'Şimdi Müsait';

  @override
  String get sitterCurrentlyBusy => 'Şimdilik Dolu';

  @override
  String get sitterVerifiedLabel => 'Doğrulanmış';

  @override
  String get sitterAboutSection => 'Hakkında';

  @override
  String get sitterServicesAndPrices => 'Hizmetler ve Fiyatlar';

  @override
  String get sitterPhotosSection => 'Fotoğraflar';

  @override
  String get sitterReviewsSection => 'Değerlendirmeler';

  @override
  String sitterHourlyRate(int price) {
    return '$price TL/saat';
  }

  @override
  String sitterDailyRate(int price) {
    return '$price TL/gün';
  }

  @override
  String get sitterErrorPrefix => 'Hata: ';

  @override
  String get sitterProfileUpdated => 'Profil güncellendi!';

  @override
  String get sitterProfileCreated => 'Bakıcı profili oluşturuldu!';

  @override
  String sitterSubmitErr(String error) {
    return 'Hata: $error';
  }

  @override
  String get sitterCreateBtn => 'Bakıcı Profili Oluştur';

  @override
  String get sitterUpdateBtn => 'Profili Güncelle';

  @override
  String get bookingsTitle => 'Rezervasyonlar';

  @override
  String get bookingsTabMine => 'Rezervasyonlarım';

  @override
  String get bookingsTabIncoming => 'Gelen Talepler';

  @override
  String get bookingsEmptyTitle => 'Henüz rezervasyon yok';

  @override
  String get bookingsEmptySubtitle =>
      'Onaylanan rezervasyonlarınız burada görünecek.';

  @override
  String get bookingsOwnerLabel => 'Sahip';

  @override
  String get bookingsSitterLabel => 'Bakıcı';

  @override
  String get bookingsAccept => 'Kabul Et';

  @override
  String get bookingsReject => 'Reddet';

  @override
  String get bookingsMarkCompleted => 'Tamamlandı Olarak İşaretle';

  @override
  String get bookingsReview => 'Değerlendir';

  @override
  String get bookingsReviewDialogTitle => 'Bakıcıyı Değerlendir';

  @override
  String get bookingsReviewHint => 'Yorum (opsiyonel)';

  @override
  String get bookingsReviewCancel => 'İptal';

  @override
  String get bookingsReviewSend => 'Gönder';

  @override
  String bookingsActionErr(String error) {
    return 'Hata: $error';
  }

  @override
  String get adoptionAppsTitle => 'Sahiplendirme Başvuruları';

  @override
  String get adoptionAppsTabInbox => 'Gelen Başvurular';

  @override
  String get adoptionAppsTabSent => 'Gönderdiklerim';

  @override
  String get adoptionAppsInboxEmpty => 'Gelen başvuru yok';

  @override
  String get adoptionAppsInboxEmptyDesc =>
      'Sahiplendirme ilanlarınıza gelen başvurular burada görünecek.';

  @override
  String get adoptionAppsSentEmpty => 'Gönderilen başvuru yok';

  @override
  String get adoptionAppsSentEmptyDesc =>
      'Sahiplendirme ilanlarına yaptığınız başvurular burada görünecek.';

  @override
  String adoptionAppsErrGeneric(String error) {
    return 'Hata: $error';
  }

  @override
  String get adoptionAppsAcceptTitle => 'Başvuruyu Kabul Et';

  @override
  String get adoptionAppsRejectTitle => 'Başvuruyu Reddet';

  @override
  String get adoptionAppsAcceptContent =>
      'Bu başvuruyu kabul etmek istediğinize emin misiniz? Mesajlaşma başlatılacaktır.';

  @override
  String get adoptionAppsRejectContent =>
      'Bu başvuruyu reddetmek istediğinize emin misiniz?';

  @override
  String get adoptionAppsCancel => 'Vazgeç';

  @override
  String get adoptionAppsAcceptBtn => 'Kabul Et';

  @override
  String get adoptionAppsRejectBtn => 'Reddet';

  @override
  String get adoptionAppsAcceptedStarted =>
      'Başvuru kabul edildi! Mesajlaşma başlatıldı.';

  @override
  String get adoptionAppsAccepted => 'Başvuru kabul edildi';

  @override
  String get adoptionAppsRejected => 'Başvuru reddedildi';

  @override
  String get adoptionAppsGoToChat => 'Mesajlaşma';

  @override
  String adoptionAppsApplicant(String name) {
    return 'Başvuran: $name';
  }

  @override
  String get adoptionAppsListing => 'İlan';

  @override
  String get adoptionAppsStatusAccepted => 'Kabul Edildi';

  @override
  String get adoptionAppsStatusRejected => 'Reddedildi';

  @override
  String get adoptionAppsStatusCancelled => 'İptal Edildi';

  @override
  String get adoptionAppsStatusPending => 'Beklemede';

  @override
  String get adoptionAppsTimelineApplication => 'Başvuru';

  @override
  String get adoptionAppsTimelineReview => 'İnceleme';

  @override
  String get adoptionAppsTimelineApproval => 'Onay';

  @override
  String get adoptionAppsTimelineCompleted => 'Tamamlandı';

  @override
  String get adoptionAppsTimelineRejected => 'Reddedildi';

  @override
  String get adoptionAppsTimelineCancelled => 'İptal';

  @override
  String get adoptionAppsTimelineDecision => 'Karar';

  @override
  String get adoptionApplyTitle => 'Sahiplendirme Başvurusu';

  @override
  String get adoptionApplyInfoText =>
      'Başvurunuz ilan sahibine iletilecektir. İlan sahibi başvurunuzu kabul ederse mesajlaşma başlatılacaktır.';

  @override
  String get adoptionApplyNoteLabel => 'Başvuru Notu (opsiyonel)';

  @override
  String get adoptionApplyNoteHint =>
      'Kendinizi tanıtın, neden bu hayvanı sahiplenmek istediğinizi açıklayın...';

  @override
  String adoptionApplyErrGeneric(String error) {
    return 'Hata: $error';
  }

  @override
  String get adoptionApplySuccessTitle => 'Başvuru Gönderildi!';

  @override
  String get adoptionApplySuccessContent =>
      'Sahiplendirme başvurunuz ilan sahibine iletildi. Sonucu başvurularım sayfasından takip edebilirsiniz.';

  @override
  String get adoptionApplySuccessOk => 'Tamam';

  @override
  String get adoptionApplySending => 'Gönderiliyor...';

  @override
  String get adoptionApplySendBtn => 'Başvuru Gönder';

  @override
  String get lostFoundTitle2 => 'Kayıp & Bulunan';

  @override
  String get lostFoundListView => 'Liste Görünümü';

  @override
  String get lostFoundMapView => 'Harita Görünümü';

  @override
  String get lostFoundLostTab => 'Kayıp';

  @override
  String get lostFoundFoundTab => 'Bulunan';

  @override
  String get lostFoundEmptyTitle => 'Yakında ilan yok';

  @override
  String get lostFoundEmptySubtitle =>
      'Yakınınızdaki kayıp veya bulunan hayvan ilanları burada görünecek.';

  @override
  String get lostFoundCreateBtn => 'İlan Oluştur';

  @override
  String get eventsTitle2 => 'Etkinlikler';

  @override
  String get eventsMyEventsTooltip => 'Katıldıklarım';

  @override
  String get eventsCreateBtn => 'Etkinlik Oluştur';

  @override
  String get eventsCatAll => 'Tümü';

  @override
  String get eventsCatPark => 'Park';

  @override
  String get eventsCatAdoption => 'Sahiplen';

  @override
  String get eventsCatTraining => 'Eğitim';

  @override
  String get eventsCatCompetition => 'Yarış';

  @override
  String get eventsCatGrooming => 'Bakım';

  @override
  String get eventsCatHealth => 'Sağlık';

  @override
  String get eventsEmptyTitle => 'Etkinlik Bulunamadı';

  @override
  String get eventsEmptySubtitle =>
      'Bu bölge veya kategoride henüz etkinlik yok.';

  @override
  String get eventsLocationBannerText => 'Yakın etkinlikler için konum gerekli';

  @override
  String get eventsLocationBannerBtn => 'İzin Ver';

  @override
  String get myEventsTitle => 'Etkinliklerim';

  @override
  String get myEventsTabAttending => 'Katılacaklarım';

  @override
  String get myEventsTabOrganized => 'Organize Ettiklerim';

  @override
  String get myEventsEmptyTitle => 'Etkinlik Yok';

  @override
  String get myEventsEmptySubtitle => 'Henüz bu kategoride etkinliğiniz yok.';

  @override
  String get createPostTitle => 'Gönderi Oluştur';

  @override
  String get createPostShareBtn => 'Paylaş';

  @override
  String get createPostPhotosLabel => 'Fotoğraflar';

  @override
  String get createPostAddBtn => 'Ekle';

  @override
  String get createPostEmptyHint => 'Fotoğraf eklemek için dokunun';

  @override
  String get createPostHint =>
      'Ne paylaşıyorsun? Sevimli hayvanınızı anlatın...';

  @override
  String get createPostMaxImages => 'En fazla 4 fotoğraf ekleyebilirsiniz';

  @override
  String get createPostValidation =>
      'Lütfen bir şey yazın veya fotoğraf ekleyin';

  @override
  String createPostErr(String error) {
    return 'Hata: $error';
  }

  @override
  String get connectTitle => 'Keşfet';

  @override
  String get connectSocialFeed => 'Sosyal Akış';

  @override
  String get connectSocialFeedSub => 'Evcil hayvan sahiplerini takip et';

  @override
  String get connectSearch => 'Ara';

  @override
  String get connectSearchSub => 'Evcil hayvan, mağaza ve veteriner bul';

  @override
  String get connectMapDiscover => 'Haritada Keşfet';

  @override
  String get connectMapDiscoverSub => 'Yakınındaki ilanları haritada gör';

  @override
  String get connectFavorites => 'Favoriler';

  @override
  String get connectFavoritesSub => 'Kaydettiğin ilanlar';

  @override
  String get reviewAddTitle => 'Yorum Yap';

  @override
  String get reviewEditTitle => 'Yorumu Düzenle';

  @override
  String get reviewProductLabel => 'Ürün';

  @override
  String get reviewRatingLabel => 'Puanınız *';

  @override
  String get reviewCommentLabel => 'Yorumunuz (Opsiyonel)';

  @override
  String get reviewCommentHint => 'Ürün hakkındaki düşüncelerinizi paylaşın...';

  @override
  String get reviewSubmitBtn => 'Gönder';

  @override
  String get reviewUpdateBtn => 'Güncelle';

  @override
  String get reviewRating1 => 'Çok Kötü';

  @override
  String get reviewRating2 => 'Kötü';

  @override
  String get reviewRating3 => 'Orta';

  @override
  String get reviewRating4 => 'İyi';

  @override
  String get reviewRating5 => 'Mükemmel';

  @override
  String get reviewNoRatingErr => 'Lütfen bir puan seçin';

  @override
  String get reviewUpdated => 'Yorum güncellendi';

  @override
  String get reviewAdded => 'Yorum eklendi';

  @override
  String reviewErr(String error) {
    return 'Hata: $error';
  }

  @override
  String get reviewsSectionTitle => 'Değerlendirmeler';

  @override
  String get reviewsSectionEdit => 'Düzenle';

  @override
  String get reviewsSectionAdd => 'Yorum Yap';

  @override
  String reviewsCount(int count) {
    return '$count değerlendirme';
  }

  @override
  String get reviewsVerifiedBuyer => 'Alıcı';

  @override
  String reviewsLoadErr(String error) {
    return 'Yorumlar yüklenemedi: $error';
  }

  @override
  String get reviewsEmptyTitle => 'Henüz değerlendirme yok';

  @override
  String get reviewsEmptySubtitle => 'İlk yorumu siz yapın!';

  @override
  String get editProfileTitle => 'Profili Düzenle';

  @override
  String get editProfilePhotoUpdated => 'Profil fotoğrafı güncellendi!';

  @override
  String get editProfileNameLabel => 'İsim Soyisim';

  @override
  String get editProfileCityLabel => 'Şehir';

  @override
  String get editProfileAboutLabel => 'Hakkımda';

  @override
  String get editProfileNameRequired => 'İsim boş olamaz';

  @override
  String get editProfileSaveBtn => 'Değişiklikleri Kaydet';

  @override
  String get onboardingSkip => 'Atla';

  @override
  String get onboardingNext => 'Devam Et';

  @override
  String get onboardingStart => 'Hadi Başlayalım!';

  @override
  String get onboardingPage1Title => 'Evcil Dostunuzu Keşfedin';

  @override
  String get onboardingPage1Subtitle =>
      'Binlerce evcil hayvan ilanına göz atın. Sahiplendirme veya eşleştirme için doğru dostu bulun.';

  @override
  String get onboardingPage2Title => 'Eşleştirme & Sahiplendirme';

  @override
  String get onboardingPage2Subtitle =>
      'Doğum tarihleri, ırk ve konum filtrelerine göre evcil hayvanları eşleştirin veya sahiplendirin.';

  @override
  String get onboardingPage3Title => 'Sağlık Takibi';

  @override
  String get onboardingPage3Subtitle =>
      'Aşı takvimi, veteriner randevuları ve sağlık günlüğü ile dostunuzun sağlığını kontrol altında tutun.';

  @override
  String get onboardingPage4Title => 'Mağaza & Topluluk';

  @override
  String get onboardingPage4Subtitle =>
      'Evcil hayvan ürünleri alın, bakıcı tutun, etkinliklere katılın ve sosyal topluluğun parçası olun.';

  @override
  String get adminAppsTitle => 'Satıcı Başvuruları';

  @override
  String adminAppsStatus(String status) {
    return 'Durum: $status';
  }

  @override
  String get adminAppsLoadErr => 'Başvurular yüklenemedi.';

  @override
  String get productDetailOwnProduct => 'Bu sizin ürününüz';

  @override
  String get productDetailOwnProductErr =>
      'Kendi ürünlerinizi sepete ekleyemezsiniz';

  @override
  String get productDetailOutOfStock => 'Bu ürün stokta yok';

  @override
  String productDetailMaxStock(int stock) {
    return 'Maksimum $stock adet ekleyebilirsiniz';
  }

  @override
  String productDetailAddedToCart(int count) {
    return '$count adet sepete eklendi';
  }

  @override
  String get productDetailGoToCart => 'Sepete Git';

  @override
  String productDetailAddErr(String error) {
    return 'Sepete eklenemedi: $error';
  }

  @override
  String get productDetailShareSoon => 'Paylaşma özelliği yakında eklenecek';

  @override
  String get productDetailAddingToCart => 'Ekleniyor...';

  @override
  String get productDetailAddToCartBtn => 'Sepete Ekle';

  @override
  String get productDetailNoTitle => 'Ürün adı yok';

  @override
  String get productDetailNoDesc => 'Açıklama yok';

  @override
  String productDetailStock(int count) {
    return 'Stok: $count';
  }

  @override
  String get productDetailNotFound => 'Ürün bulunamadı.';

  @override
  String get sellerApplyTitle => 'Satıcı Ol';

  @override
  String get sellerApplyCompanyName => 'Firma adı';

  @override
  String get sellerApplyCompanyTitle => 'Firma unvanı';

  @override
  String get sellerApplyTaxNumber => 'Vergi numarası';

  @override
  String get sellerApplyTaxOffice => 'Vergi dairesi';

  @override
  String get sellerApplyAddress => 'Adres';

  @override
  String get sellerApplyContact => 'İletişim';

  @override
  String get sellerApplyIban => 'IBAN';

  @override
  String get sellerApplyRequired => 'Zorunlu';

  @override
  String get sellerApplyKvkk => 'KVKK metnini onaylıyorum';

  @override
  String get sellerApplyContract => 'Satıcı sözleşmesini onaylıyorum';

  @override
  String get sellerApplyApprovalsRequired => 'Onaylar zorunlu';

  @override
  String get sellerApplySending => 'Gönderiliyor...';

  @override
  String get sellerApplySendBtn => 'Başvuru gönder';

  @override
  String get sellerApplyFailed => 'Başvuru gönderilemedi.';

  @override
  String get sellerApplyPending => 'Başvurunuz inceleniyor';

  @override
  String get productsPageTitle => 'Ürünlerim';

  @override
  String get productsActive => 'Aktif';

  @override
  String get productsPassive => 'Pasif';

  @override
  String get productsLoadErr => 'Ürünler yüklenemedi.';

  @override
  String productsStockStatus(int stock, String status) {
    return 'Stok: $stock • $status';
  }

  @override
  String get productAddTitle => 'Ürün Ekle';

  @override
  String get productAddName => 'Ürün adı';

  @override
  String get productAddRequired => 'Zorunlu';

  @override
  String get productAddCategory => 'Kategori';

  @override
  String get productAddNoCategoryFound => 'Kategori bulunamadı.';

  @override
  String get productAddCategoryLoading => 'Kategoriler yükleniyor...';

  @override
  String productAddCategoryLoadErr(String error) {
    return 'Kategoriler yüklenemedi: $error';
  }

  @override
  String get productAddCategorySelect => 'Kategori seçin';

  @override
  String get productAddDescription => 'Açıklama';

  @override
  String get productAddPrice => 'Fiyat';

  @override
  String get productAddStock => 'Stok';

  @override
  String get productAddSaving => 'Kaydediliyor...';

  @override
  String get productAddSaveBtn => 'Kaydet';

  @override
  String get productEditTitle => 'Ürün Düzenle';

  @override
  String get productEditUpdating => 'Güncelleniyor...';

  @override
  String get productEditUpdateBtn => 'Güncelle';

  @override
  String get productEditFailed => 'Güncelleme başarısız.';

  @override
  String get productEditActive => 'Aktif';

  @override
  String get storeCategoryAll => 'Tümü';

  @override
  String productCardAddedToCart(String title) {
    return '$title sepete eklendi';
  }

  @override
  String productCardAddErr(String error) {
    return 'Sepete eklenemedi: $error';
  }

  @override
  String get productCardNoTitle => 'Ürün adı yok';

  @override
  String get aiSpeciesDog => 'Köpek';

  @override
  String get aiSpeciesCat => 'Kedi';

  @override
  String get aiSpeciesBird => 'Kuş';

  @override
  String get aiSpeciesOther => 'Diğer';

  @override
  String get aiSymptomLossOfAppetite => 'İştahsızlık';

  @override
  String get aiSymptomFever => 'Ateş';

  @override
  String get aiSymptomDiarrhea => 'İshal';

  @override
  String get aiSymptomVomiting => 'Kusma';

  @override
  String get aiSymptomCough => 'Öksürük';

  @override
  String get aiSymptomShortnessOfBreath => 'Nefes darlığı';

  @override
  String get aiSymptomLethargy => 'Uyuşukluk';

  @override
  String get aiSymptomBloodyStool => 'Kanlı dışkı';

  @override
  String get aiSymptomExcessiveItching => 'Aşırı kaşınma';

  @override
  String get aiSymptomHairLoss => 'Tüy dökülmesi';

  @override
  String get aiSymptomLimping => 'Topallama';

  @override
  String get aiSymptomExcessiveThirst => 'Aşırı su içme';

  @override
  String get aiSymptomUnableToUrinate => 'İdrar yapmama';

  @override
  String get aiSymptomBloatedBelly => 'Şişmiş karın';

  @override
  String get aiSymptomLossOfConsciousness => 'Bilinç kaybı';

  @override
  String get aiSymptomRunnyNose => 'Burun akıntısı';

  @override
  String get aiSymptomEyeDischarge => 'Göz akıntısı';

  @override
  String get aiSymptomBreathingDifficulty => 'Nefes güçlüğü';

  @override
  String get aiSymptomWeightLoss => 'Kilo kaybı';

  @override
  String get aiSymptomFeatherPlucking => 'Tüy yolma';

  @override
  String get aiSymptomBloodyUrine => 'Kanlı idrar';

  @override
  String get aiSymptomJaundice => 'Sarılık';

  @override
  String get aiSymptomSeizures => 'Nöbet/Titreme';

  @override
  String get aiSymptomFeatherLoss => 'Tüy döküyor';

  @override
  String get aiSymptomNotEating => 'Yemiyor';

  @override
  String get aiSymptomPuffed => 'Şişmiş/Kabarık';

  @override
  String get aiSymptomUnableToStand => 'Ayakta duramıyor';

  @override
  String get aiSymptomHavingSeizure => 'Nöbet geçiriyor';

  @override
  String get aiSymptomBleeding => 'Kanıyor';

  @override
  String get aiSymptomScratch => 'Kaşınma';

  @override
  String aiSymptomPrefix(String species) {
    return '$species, belirtiler: ';
  }

  @override
  String get aiGenSug1 => 'Köpeğime ne kadar su vermeli?';

  @override
  String get aiGenSug2 => 'Kedi kumu ne sıklıkla değiştirilmeli?';

  @override
  String get aiGenSug3 => 'Yavru köpek eğitimi nasıl yapılır?';

  @override
  String get aiGenSug4 => 'Kedim neden gece bağırıyor?';

  @override
  String get aiGenSug5 => 'Köpek ısırması ne yapmalı?';

  @override
  String get guideSug1 => 'Sahiplendirme ilanlarına bak';

  @override
  String get guideSug2 => 'Veteriner bul';

  @override
  String get guideSug3 => 'Eşleştirme yap';

  @override
  String get guideSug4 => 'Sepetimi göster';

  @override
  String get guideSug5 => 'Kayıp ilan oluştur';

  @override
  String get guideSug6 => 'Etkinliklere katıl';

  @override
  String get eventLocationObtained => 'Konum Alındı ✓';

  @override
  String get eventUseMyLocation => 'Konumumu Kullan';

  @override
  String get eventCreateTitle => 'Etkinlik Oluştur';

  @override
  String get eventCatParkMeetup => 'Park Buluşması';

  @override
  String get eventCatAdoptionDay => 'Sahiplendirme Günü';

  @override
  String get eventCatTraining => 'Eğitim Semineri';

  @override
  String get eventCatCompetition => 'Yarış / Gösterim';

  @override
  String get eventCatGrooming => 'Bakım Günü';

  @override
  String get eventCatHealth => 'Sağlık / Aşı';

  @override
  String get eventCatOther => 'Diğer';

  @override
  String get eventSpeciesAll => 'Tümü';

  @override
  String get eventSpeciesDog => 'Köpek';

  @override
  String get eventSpeciesCat => 'Kedi';

  @override
  String get eventSpeciesBird => 'Kuş';

  @override
  String get eventSpeciesRabbit => 'Tavşan';

  @override
  String get eventSpeciesOther => 'Diğer';

  @override
  String get eventErrLocationPerm => 'Konum izni gerekli';

  @override
  String get eventErrMaxPhotos => 'En fazla 5 fotoğraf eklenebilir';

  @override
  String get eventErrEndBeforeStart =>
      'Bitiş tarihi başlangıç tarihinden önce olamaz';

  @override
  String get eventCreated => 'Etkinlik oluşturuldu!';

  @override
  String get eventPhotosLabel => 'Fotoğraflar (max 5)';

  @override
  String get eventDateTimeLabel => 'Tarih ve Saat';

  @override
  String get eventStartLabel => 'Başlangıç *';

  @override
  String get eventEndLabel => 'Bitiş *';

  @override
  String get eventLocationLabel => 'Konum';

  @override
  String get eventCapacityLabel => 'Kapasite ve Ücret';

  @override
  String get eventFreeLabel => 'Ücretsiz Etkinlik';

  @override
  String get eventAnimalsLabel => 'Katılabilecek Hayvanlar';

  @override
  String get eventCreateBtn => 'Etkinliği Oluştur';

  @override
  String eventErrLocationFail(String error) {
    return 'Konum alınamadı: $error';
  }

  @override
  String eventCreateErr(String error) {
    return 'Hata: $error';
  }

  @override
  String get themeSelectTitle => 'Temanı Seç';

  @override
  String get themeSelectSub => 'Sana en uygun görünümü seç';

  @override
  String get themeSelectLight => 'Açık';

  @override
  String get themeSelectDark => 'Koyu';

  @override
  String get themeSelectConfirm => 'Devam Et';

  @override
  String get themeSelectChangeHint =>
      'Bunu istediğin zaman Ayarlar\'dan değiştirebilirsin';
}
