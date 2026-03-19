import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_tr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('tr'),
  ];

  /// Uygulama adı
  ///
  /// In tr, this message translates to:
  /// **'Evcil Hayvan'**
  String get appName;

  /// No description provided for @login.
  ///
  /// In tr, this message translates to:
  /// **'Giriş Yap'**
  String get login;

  /// No description provided for @logout.
  ///
  /// In tr, this message translates to:
  /// **'Çıkış Yap'**
  String get logout;

  /// No description provided for @register.
  ///
  /// In tr, this message translates to:
  /// **'Kayıt Ol'**
  String get register;

  /// No description provided for @email.
  ///
  /// In tr, this message translates to:
  /// **'E-posta'**
  String get email;

  /// No description provided for @password.
  ///
  /// In tr, this message translates to:
  /// **'Şifre'**
  String get password;

  /// No description provided for @forgotPassword.
  ///
  /// In tr, this message translates to:
  /// **'Şifremi Unuttum'**
  String get forgotPassword;

  /// No description provided for @resetPassword.
  ///
  /// In tr, this message translates to:
  /// **'Şifreyi Sıfırla'**
  String get resetPassword;

  /// No description provided for @name.
  ///
  /// In tr, this message translates to:
  /// **'Ad Soyad'**
  String get name;

  /// No description provided for @save.
  ///
  /// In tr, this message translates to:
  /// **'Kaydet'**
  String get save;

  /// No description provided for @cancel.
  ///
  /// In tr, this message translates to:
  /// **'Vazgeç'**
  String get cancel;

  /// No description provided for @delete.
  ///
  /// In tr, this message translates to:
  /// **'Sil'**
  String get delete;

  /// No description provided for @edit.
  ///
  /// In tr, this message translates to:
  /// **'Düzenle'**
  String get edit;

  /// No description provided for @confirm.
  ///
  /// In tr, this message translates to:
  /// **'Onayla'**
  String get confirm;

  /// No description provided for @back.
  ///
  /// In tr, this message translates to:
  /// **'Geri'**
  String get back;

  /// No description provided for @close.
  ///
  /// In tr, this message translates to:
  /// **'Kapat'**
  String get close;

  /// No description provided for @retry.
  ///
  /// In tr, this message translates to:
  /// **'Tekrar Dene'**
  String get retry;

  /// No description provided for @loading.
  ///
  /// In tr, this message translates to:
  /// **'Yükleniyor...'**
  String get loading;

  /// No description provided for @error.
  ///
  /// In tr, this message translates to:
  /// **'Hata'**
  String get error;

  /// No description provided for @success.
  ///
  /// In tr, this message translates to:
  /// **'Başarılı'**
  String get success;

  /// No description provided for @noData.
  ///
  /// In tr, this message translates to:
  /// **'Veri bulunamadı'**
  String get noData;

  /// No description provided for @send.
  ///
  /// In tr, this message translates to:
  /// **'Gönder'**
  String get send;

  /// No description provided for @tabHome.
  ///
  /// In tr, this message translates to:
  /// **'Sahiplen'**
  String get tabHome;

  /// No description provided for @tabMessages.
  ///
  /// In tr, this message translates to:
  /// **'Sohbetler'**
  String get tabMessages;

  /// No description provided for @tabVet.
  ///
  /// In tr, this message translates to:
  /// **'Veteriner'**
  String get tabVet;

  /// No description provided for @tabStore.
  ///
  /// In tr, this message translates to:
  /// **'Mağaza'**
  String get tabStore;

  /// No description provided for @tabProfile.
  ///
  /// In tr, this message translates to:
  /// **'Profil'**
  String get tabProfile;

  /// No description provided for @homeTitle.
  ///
  /// In tr, this message translates to:
  /// **'İlanlar'**
  String get homeTitle;

  /// No description provided for @homeSearchHint.
  ///
  /// In tr, this message translates to:
  /// **'Tür, ırk ara...'**
  String get homeSearchHint;

  /// No description provided for @homeNearby.
  ///
  /// In tr, this message translates to:
  /// **'Yakınımdakiler'**
  String get homeNearby;

  /// No description provided for @homeNoAds.
  ///
  /// In tr, this message translates to:
  /// **'Henüz ilan yok'**
  String get homeNoAds;

  /// No description provided for @homeNoAdsDesc.
  ///
  /// In tr, this message translates to:
  /// **'Yakınında ilan bulunamadı.'**
  String get homeNoAdsDesc;

  /// No description provided for @homeAdoptionTab.
  ///
  /// In tr, this message translates to:
  /// **'Sahiplendirme'**
  String get homeAdoptionTab;

  /// No description provided for @homeMatingTab.
  ///
  /// In tr, this message translates to:
  /// **'Eşleştirme'**
  String get homeMatingTab;

  /// No description provided for @petDetailTitle.
  ///
  /// In tr, this message translates to:
  /// **'İlan Detayı'**
  String get petDetailTitle;

  /// No description provided for @petDetailAge.
  ///
  /// In tr, this message translates to:
  /// **'Yaş'**
  String get petDetailAge;

  /// No description provided for @petDetailBreed.
  ///
  /// In tr, this message translates to:
  /// **'Irk'**
  String get petDetailBreed;

  /// No description provided for @petDetailGender.
  ///
  /// In tr, this message translates to:
  /// **'Cinsiyet'**
  String get petDetailGender;

  /// No description provided for @petDetailVaccinated.
  ///
  /// In tr, this message translates to:
  /// **'Aşılı'**
  String get petDetailVaccinated;

  /// No description provided for @petDetailOwner.
  ///
  /// In tr, this message translates to:
  /// **'Sahip'**
  String get petDetailOwner;

  /// No description provided for @petDetailContact.
  ///
  /// In tr, this message translates to:
  /// **'İletişime Geç'**
  String get petDetailContact;

  /// No description provided for @petDetailAdopt.
  ///
  /// In tr, this message translates to:
  /// **'Sahiplenmek İstiyorum'**
  String get petDetailAdopt;

  /// No description provided for @createPetTitle.
  ///
  /// In tr, this message translates to:
  /// **'İlan Oluştur'**
  String get createPetTitle;

  /// No description provided for @createPetName.
  ///
  /// In tr, this message translates to:
  /// **'Hayvan Adı'**
  String get createPetName;

  /// No description provided for @createPetSpecies.
  ///
  /// In tr, this message translates to:
  /// **'Tür'**
  String get createPetSpecies;

  /// No description provided for @createPetBreed.
  ///
  /// In tr, this message translates to:
  /// **'Irk'**
  String get createPetBreed;

  /// No description provided for @createPetAge.
  ///
  /// In tr, this message translates to:
  /// **'Yaş (ay)'**
  String get createPetAge;

  /// No description provided for @createPetGender.
  ///
  /// In tr, this message translates to:
  /// **'Cinsiyet'**
  String get createPetGender;

  /// No description provided for @createPetBio.
  ///
  /// In tr, this message translates to:
  /// **'Hakkında'**
  String get createPetBio;

  /// No description provided for @createPetPhotos.
  ///
  /// In tr, this message translates to:
  /// **'Fotoğraflar'**
  String get createPetPhotos;

  /// No description provided for @createPetAddPhoto.
  ///
  /// In tr, this message translates to:
  /// **'Fotoğraf Ekle'**
  String get createPetAddPhoto;

  /// No description provided for @createPetSubmit.
  ///
  /// In tr, this message translates to:
  /// **'İlanı Yayınla'**
  String get createPetSubmit;

  /// No description provided for @matingTitle.
  ///
  /// In tr, this message translates to:
  /// **'Eşleştirme Bul'**
  String get matingTitle;

  /// No description provided for @matingSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Evcil dostların için uygun eşleşmeleri keşfet.'**
  String get matingSubtitle;

  /// No description provided for @matingSpecies.
  ///
  /// In tr, this message translates to:
  /// **'Tür'**
  String get matingSpecies;

  /// No description provided for @matingGender.
  ///
  /// In tr, this message translates to:
  /// **'Cinsiyet'**
  String get matingGender;

  /// No description provided for @matingMaxDistance.
  ///
  /// In tr, this message translates to:
  /// **'Maksimum mesafe: {km} km'**
  String matingMaxDistance(int km);

  /// No description provided for @matingRequests.
  ///
  /// In tr, this message translates to:
  /// **'Eşleştirme istekleri'**
  String get matingRequests;

  /// No description provided for @matingEndTitle.
  ///
  /// In tr, this message translates to:
  /// **'Hepsi bu kadar!'**
  String get matingEndTitle;

  /// No description provided for @matingEndDesc.
  ///
  /// In tr, this message translates to:
  /// **'Yakınında başka profil bulunamadı.'**
  String get matingEndDesc;

  /// No description provided for @matingRefresh.
  ///
  /// In tr, this message translates to:
  /// **'Yenile'**
  String get matingRefresh;

  /// No description provided for @matingEmptyTitle.
  ///
  /// In tr, this message translates to:
  /// **'Filtreleri gevşetmeyi deneyin'**
  String get matingEmptyTitle;

  /// No description provided for @matingEmptyDesc.
  ///
  /// In tr, this message translates to:
  /// **'Yakınında henüz uygun eşleşme bulunamadı.'**
  String get matingEmptyDesc;

  /// No description provided for @matingAll.
  ///
  /// In tr, this message translates to:
  /// **'Tümü'**
  String get matingAll;

  /// No description provided for @matingMale.
  ///
  /// In tr, this message translates to:
  /// **'Erkek'**
  String get matingMale;

  /// No description provided for @matingFemale.
  ///
  /// In tr, this message translates to:
  /// **'Dişi'**
  String get matingFemale;

  /// No description provided for @matingLikeStamp.
  ///
  /// In tr, this message translates to:
  /// **'LIKE'**
  String get matingLikeStamp;

  /// No description provided for @matingNopeStamp.
  ///
  /// In tr, this message translates to:
  /// **'NOPE'**
  String get matingNopeStamp;

  /// No description provided for @matingVaccinated.
  ///
  /// In tr, this message translates to:
  /// **'Aşılı'**
  String get matingVaccinated;

  /// No description provided for @messagesTitle.
  ///
  /// In tr, this message translates to:
  /// **'Sohbetler'**
  String get messagesTitle;

  /// No description provided for @messagesEmpty.
  ///
  /// In tr, this message translates to:
  /// **'Henüz sohbet yok'**
  String get messagesEmpty;

  /// No description provided for @messagesEmptyDesc.
  ///
  /// In tr, this message translates to:
  /// **'İlanlardan biriyle iletişime geç.'**
  String get messagesEmptyDesc;

  /// No description provided for @messagesTypeHint.
  ///
  /// In tr, this message translates to:
  /// **'Mesaj yaz...'**
  String get messagesTypeHint;

  /// No description provided for @messagesSend.
  ///
  /// In tr, this message translates to:
  /// **'Gönder'**
  String get messagesSend;

  /// No description provided for @messagesImage.
  ///
  /// In tr, this message translates to:
  /// **'Resim gönder'**
  String get messagesImage;

  /// No description provided for @messagesDeleted.
  ///
  /// In tr, this message translates to:
  /// **'[silindi]'**
  String get messagesDeleted;

  /// No description provided for @matchRequestsTitle.
  ///
  /// In tr, this message translates to:
  /// **'Eşleştirme İstekleri'**
  String get matchRequestsTitle;

  /// No description provided for @matchRequestsInbox.
  ///
  /// In tr, this message translates to:
  /// **'Gelen'**
  String get matchRequestsInbox;

  /// No description provided for @matchRequestsOutbox.
  ///
  /// In tr, this message translates to:
  /// **'Gönderilen'**
  String get matchRequestsOutbox;

  /// No description provided for @matchRequestsEmpty.
  ///
  /// In tr, this message translates to:
  /// **'İstek yok'**
  String get matchRequestsEmpty;

  /// No description provided for @matchRequestAccept.
  ///
  /// In tr, this message translates to:
  /// **'Kabul Et'**
  String get matchRequestAccept;

  /// No description provided for @matchRequestReject.
  ///
  /// In tr, this message translates to:
  /// **'Reddet'**
  String get matchRequestReject;

  /// No description provided for @matchRequestCancel.
  ///
  /// In tr, this message translates to:
  /// **'İptal Et'**
  String get matchRequestCancel;

  /// No description provided for @profileTitle.
  ///
  /// In tr, this message translates to:
  /// **'Profil'**
  String get profileTitle;

  /// No description provided for @profileEdit.
  ///
  /// In tr, this message translates to:
  /// **'Profili Düzenle'**
  String get profileEdit;

  /// No description provided for @profileMyPets.
  ///
  /// In tr, this message translates to:
  /// **'İlanlarım'**
  String get profileMyPets;

  /// No description provided for @profileSettings.
  ///
  /// In tr, this message translates to:
  /// **'Ayarlar'**
  String get profileSettings;

  /// No description provided for @profileLogout.
  ///
  /// In tr, this message translates to:
  /// **'Çıkış Yap'**
  String get profileLogout;

  /// No description provided for @profileSeller.
  ///
  /// In tr, this message translates to:
  /// **'Satıcı'**
  String get profileSeller;

  /// No description provided for @profileMember.
  ///
  /// In tr, this message translates to:
  /// **'Üye'**
  String get profileMember;

  /// No description provided for @profileSince.
  ///
  /// In tr, this message translates to:
  /// **'Katılım: {date}'**
  String profileSince(String date);

  /// No description provided for @settingsTitle.
  ///
  /// In tr, this message translates to:
  /// **'Ayarlar'**
  String get settingsTitle;

  /// No description provided for @settingsDarkMode.
  ///
  /// In tr, this message translates to:
  /// **'Karanlık Mod'**
  String get settingsDarkMode;

  /// No description provided for @settingsLanguage.
  ///
  /// In tr, this message translates to:
  /// **'Dil'**
  String get settingsLanguage;

  /// No description provided for @settingsLanguageTr.
  ///
  /// In tr, this message translates to:
  /// **'Türkçe'**
  String get settingsLanguageTr;

  /// No description provided for @settingsLanguageEn.
  ///
  /// In tr, this message translates to:
  /// **'English'**
  String get settingsLanguageEn;

  /// No description provided for @settingsReview.
  ///
  /// In tr, this message translates to:
  /// **'Uygulamayı Değerlendir'**
  String get settingsReview;

  /// No description provided for @settingsPrivacy.
  ///
  /// In tr, this message translates to:
  /// **'Gizlilik Politikası'**
  String get settingsPrivacy;

  /// No description provided for @settingsNotifications.
  ///
  /// In tr, this message translates to:
  /// **'Bildirimler'**
  String get settingsNotifications;

  /// No description provided for @settingsLogout.
  ///
  /// In tr, this message translates to:
  /// **'Çıkış Yap'**
  String get settingsLogout;

  /// No description provided for @vetTitle.
  ///
  /// In tr, this message translates to:
  /// **'Veterinerler'**
  String get vetTitle;

  /// No description provided for @vetSearch.
  ///
  /// In tr, this message translates to:
  /// **'Veteriner ara...'**
  String get vetSearch;

  /// No description provided for @vetNoResults.
  ///
  /// In tr, this message translates to:
  /// **'Veteriner bulunamadı'**
  String get vetNoResults;

  /// No description provided for @vetDistance.
  ///
  /// In tr, this message translates to:
  /// **'{km} km uzakta'**
  String vetDistance(String km);

  /// No description provided for @vetAppointment.
  ///
  /// In tr, this message translates to:
  /// **'Randevu Al'**
  String get vetAppointment;

  /// No description provided for @vetVaccination.
  ///
  /// In tr, this message translates to:
  /// **'Aşı Takvimi'**
  String get vetVaccination;

  /// No description provided for @vetReminders.
  ///
  /// In tr, this message translates to:
  /// **'Hatırlatmalar'**
  String get vetReminders;

  /// No description provided for @storeTitle.
  ///
  /// In tr, this message translates to:
  /// **'Mağaza'**
  String get storeTitle;

  /// No description provided for @storeSearch.
  ///
  /// In tr, this message translates to:
  /// **'Ürün ara...'**
  String get storeSearch;

  /// No description provided for @storeCart.
  ///
  /// In tr, this message translates to:
  /// **'Sepet'**
  String get storeCart;

  /// No description provided for @storeCheckout.
  ///
  /// In tr, this message translates to:
  /// **'Siparişi Tamamla'**
  String get storeCheckout;

  /// No description provided for @storeMyOrders.
  ///
  /// In tr, this message translates to:
  /// **'Siparişlerim'**
  String get storeMyOrders;

  /// No description provided for @storeAddToCart.
  ///
  /// In tr, this message translates to:
  /// **'Sepete Ekle'**
  String get storeAddToCart;

  /// No description provided for @storeOutOfStock.
  ///
  /// In tr, this message translates to:
  /// **'Stok Yok'**
  String get storeOutOfStock;

  /// No description provided for @storeOrderPlaced.
  ///
  /// In tr, this message translates to:
  /// **'Sipariş Oluşturuldu'**
  String get storeOrderPlaced;

  /// No description provided for @lostFoundTitle.
  ///
  /// In tr, this message translates to:
  /// **'Kayıp & Bulunan'**
  String get lostFoundTitle;

  /// No description provided for @lostFoundReport.
  ///
  /// In tr, this message translates to:
  /// **'İlan Ekle'**
  String get lostFoundReport;

  /// No description provided for @lostFoundLost.
  ///
  /// In tr, this message translates to:
  /// **'Kayıp'**
  String get lostFoundLost;

  /// No description provided for @lostFoundFound.
  ///
  /// In tr, this message translates to:
  /// **'Bulunan'**
  String get lostFoundFound;

  /// No description provided for @eventsTitle.
  ///
  /// In tr, this message translates to:
  /// **'Etkinlikler'**
  String get eventsTitle;

  /// No description provided for @eventsJoin.
  ///
  /// In tr, this message translates to:
  /// **'Katıl'**
  String get eventsJoin;

  /// No description provided for @eventsLeave.
  ///
  /// In tr, this message translates to:
  /// **'Ayrıl'**
  String get eventsLeave;

  /// No description provided for @sitterTitle.
  ///
  /// In tr, this message translates to:
  /// **'Evcil Hayvan Bakıcısı'**
  String get sitterTitle;

  /// No description provided for @sitterBecomeSitter.
  ///
  /// In tr, this message translates to:
  /// **'Bakıcı Ol'**
  String get sitterBecomeSitter;

  /// No description provided for @sitterBook.
  ///
  /// In tr, this message translates to:
  /// **'Rezervasyon Yap'**
  String get sitterBook;

  /// No description provided for @sitterMyBookings.
  ///
  /// In tr, this message translates to:
  /// **'Rezervasyonlarım'**
  String get sitterMyBookings;

  /// No description provided for @adoptionApply.
  ///
  /// In tr, this message translates to:
  /// **'Başvur'**
  String get adoptionApply;

  /// No description provided for @adoptionMyApps.
  ///
  /// In tr, this message translates to:
  /// **'Başvurularım'**
  String get adoptionMyApps;

  /// No description provided for @notificationsTitle.
  ///
  /// In tr, this message translates to:
  /// **'Bildirimler'**
  String get notificationsTitle;

  /// No description provided for @notificationsEmpty.
  ///
  /// In tr, this message translates to:
  /// **'Bildirim yok'**
  String get notificationsEmpty;

  /// No description provided for @notificationsClearAll.
  ///
  /// In tr, this message translates to:
  /// **'Tümünü Temizle'**
  String get notificationsClearAll;

  /// No description provided for @favoritesTitle.
  ///
  /// In tr, this message translates to:
  /// **'Favorilerim'**
  String get favoritesTitle;

  /// No description provided for @favoritesEmpty.
  ///
  /// In tr, this message translates to:
  /// **'Favori ilanınız yok'**
  String get favoritesEmpty;

  /// No description provided for @hello.
  ///
  /// In tr, this message translates to:
  /// **'Merhaba, {name}!'**
  String hello(String name);

  /// No description provided for @genderMale.
  ///
  /// In tr, this message translates to:
  /// **'Erkek'**
  String get genderMale;

  /// No description provided for @genderFemale.
  ///
  /// In tr, this message translates to:
  /// **'Dişi'**
  String get genderFemale;

  /// No description provided for @genderUnknown.
  ///
  /// In tr, this message translates to:
  /// **'Bilinmiyor'**
  String get genderUnknown;

  /// No description provided for @speciesDog.
  ///
  /// In tr, this message translates to:
  /// **'Köpek'**
  String get speciesDog;

  /// No description provided for @speciesCat.
  ///
  /// In tr, this message translates to:
  /// **'Kedi'**
  String get speciesCat;

  /// No description provided for @speciesBird.
  ///
  /// In tr, this message translates to:
  /// **'Kuş'**
  String get speciesBird;

  /// No description provided for @speciesFish.
  ///
  /// In tr, this message translates to:
  /// **'Balık'**
  String get speciesFish;

  /// No description provided for @speciesOther.
  ///
  /// In tr, this message translates to:
  /// **'Diğer'**
  String get speciesOther;

  /// No description provided for @advertTypeAdoption.
  ///
  /// In tr, this message translates to:
  /// **'Sahiplendirme'**
  String get advertTypeAdoption;

  /// No description provided for @advertTypeMating.
  ///
  /// In tr, this message translates to:
  /// **'Eşleştirme'**
  String get advertTypeMating;

  /// No description provided for @privacyPolicyTitle.
  ///
  /// In tr, this message translates to:
  /// **'Gizlilik Politikası'**
  String get privacyPolicyTitle;

  /// No description provided for @reviewDialogTitle.
  ///
  /// In tr, this message translates to:
  /// **'Uygulamayı Puanla'**
  String get reviewDialogTitle;

  /// No description provided for @reviewDialogDesc.
  ///
  /// In tr, this message translates to:
  /// **'Uygulamamızı beğendiniz mi? Puanlamanız bize çok yardımcı olur.'**
  String get reviewDialogDesc;

  /// No description provided for @errorGeneric.
  ///
  /// In tr, this message translates to:
  /// **'Bir hata oluştu. Lütfen tekrar deneyin.'**
  String get errorGeneric;

  /// No description provided for @errorNetwork.
  ///
  /// In tr, this message translates to:
  /// **'İnternet bağlantısı yok.'**
  String get errorNetwork;

  /// No description provided for @errorUnauthorized.
  ///
  /// In tr, this message translates to:
  /// **'Oturum süresi doldu. Lütfen tekrar giriş yapın.'**
  String get errorUnauthorized;

  /// No description provided for @errorNotFound.
  ///
  /// In tr, this message translates to:
  /// **'Bulunamadı.'**
  String get errorNotFound;

  /// No description provided for @yes.
  ///
  /// In tr, this message translates to:
  /// **'Evet'**
  String get yes;

  /// No description provided for @no.
  ///
  /// In tr, this message translates to:
  /// **'Hayır'**
  String get no;

  /// No description provided for @or.
  ///
  /// In tr, this message translates to:
  /// **'veya'**
  String get or;

  /// No description provided for @km.
  ///
  /// In tr, this message translates to:
  /// **'km'**
  String get km;

  /// No description provided for @month.
  ///
  /// In tr, this message translates to:
  /// **'ay'**
  String get month;

  /// No description provided for @year.
  ///
  /// In tr, this message translates to:
  /// **'yıl'**
  String get year;

  /// No description provided for @months.
  ///
  /// In tr, this message translates to:
  /// **'{count} aylık'**
  String months(int count);

  /// No description provided for @years.
  ///
  /// In tr, this message translates to:
  /// **'{count} yaş'**
  String years(int count);

  /// No description provided for @settingsSectionAccount.
  ///
  /// In tr, this message translates to:
  /// **'Hesabım'**
  String get settingsSectionAccount;

  /// No description provided for @settingsSectionAccountSub.
  ///
  /// In tr, this message translates to:
  /// **'Profilini güncelle, güvenlik ayarlarını yönet.'**
  String get settingsSectionAccountSub;

  /// No description provided for @settingsSectionStore.
  ///
  /// In tr, this message translates to:
  /// **'Mağaza Yönetimi'**
  String get settingsSectionStore;

  /// No description provided for @settingsSectionStoreSub.
  ///
  /// In tr, this message translates to:
  /// **'Mağazanı ve siparişlerini yönet.'**
  String get settingsSectionStoreSub;

  /// No description provided for @settingsSectionNotif.
  ///
  /// In tr, this message translates to:
  /// **'Bildirimler'**
  String get settingsSectionNotif;

  /// No description provided for @settingsSectionNotifSub.
  ///
  /// In tr, this message translates to:
  /// **'Topluluktan geri kalma, kontrol tamamen sende.'**
  String get settingsSectionNotifSub;

  /// No description provided for @settingsSectionAppExp.
  ///
  /// In tr, this message translates to:
  /// **'Uygulama Deneyimi'**
  String get settingsSectionAppExp;

  /// No description provided for @settingsSectionAppExpSub.
  ///
  /// In tr, this message translates to:
  /// **'Görünüm ve kişisel tercihlerini özelleştir.'**
  String get settingsSectionAppExpSub;

  /// No description provided for @settingsSectionSupport.
  ///
  /// In tr, this message translates to:
  /// **'Destek'**
  String get settingsSectionSupport;

  /// No description provided for @settingsSectionSupportSub.
  ///
  /// In tr, this message translates to:
  /// **'Yardıma mı ihtiyacın var? Sana yardımcı olalım.'**
  String get settingsSectionSupportSub;

  /// No description provided for @settingsEditProfile.
  ///
  /// In tr, this message translates to:
  /// **'Profili Düzenle'**
  String get settingsEditProfile;

  /// No description provided for @settingsEditProfileSub.
  ///
  /// In tr, this message translates to:
  /// **'Kişisel bilgilerini ve biyografini güncelle'**
  String get settingsEditProfileSub;

  /// No description provided for @settingsChangePassword.
  ///
  /// In tr, this message translates to:
  /// **'Şifreyi Değiştir'**
  String get settingsChangePassword;

  /// No description provided for @settingsChangePasswordSub.
  ///
  /// In tr, this message translates to:
  /// **'E-posta üzerinden yeni bir şifre oluştur'**
  String get settingsChangePasswordSub;

  /// No description provided for @settingsMyOrders.
  ///
  /// In tr, this message translates to:
  /// **'Siparişlerim'**
  String get settingsMyOrders;

  /// No description provided for @settingsMyOrdersSub.
  ///
  /// In tr, this message translates to:
  /// **'Sipariş geçmişini görüntüle ve takip et'**
  String get settingsMyOrdersSub;

  /// No description provided for @settingsMyFavorites.
  ///
  /// In tr, this message translates to:
  /// **'Favorilerim'**
  String get settingsMyFavorites;

  /// No description provided for @settingsMyFavoritesSub.
  ///
  /// In tr, this message translates to:
  /// **'Beğendiğin ürünleri görüntüle'**
  String get settingsMyFavoritesSub;

  /// No description provided for @settingsMyStore.
  ///
  /// In tr, this message translates to:
  /// **'Mağazam'**
  String get settingsMyStore;

  /// No description provided for @settingsMyStoreSub.
  ///
  /// In tr, this message translates to:
  /// **'Mağaza bilgilerini görüntüle ve düzenle'**
  String get settingsMyStoreSub;

  /// No description provided for @settingsIncomingOrders.
  ///
  /// In tr, this message translates to:
  /// **'Gelen Siparişler'**
  String get settingsIncomingOrders;

  /// No description provided for @settingsIncomingOrdersSub.
  ///
  /// In tr, this message translates to:
  /// **'Mağazana gelen siparişleri yönet'**
  String get settingsIncomingOrdersSub;

  /// No description provided for @settingsManageProducts.
  ///
  /// In tr, this message translates to:
  /// **'Ürünlerimi Yönet'**
  String get settingsManageProducts;

  /// No description provided for @settingsManageProductsSub.
  ///
  /// In tr, this message translates to:
  /// **'Ürün ekle, düzenle veya stok güncelle'**
  String get settingsManageProductsSub;

  /// No description provided for @settingsNotifChat.
  ///
  /// In tr, this message translates to:
  /// **'Sohbet bildirimleri'**
  String get settingsNotifChat;

  /// No description provided for @settingsNotifChatSub.
  ///
  /// In tr, this message translates to:
  /// **'Yeni mesaj ve sohbet isteklerinden haberdar ol'**
  String get settingsNotifChatSub;

  /// No description provided for @settingsNotifMatch.
  ///
  /// In tr, this message translates to:
  /// **'Eşleşme uyarıları'**
  String get settingsNotifMatch;

  /// No description provided for @settingsNotifMatchSub.
  ///
  /// In tr, this message translates to:
  /// **'Yeni eşleşmelerde anında bildirim al'**
  String get settingsNotifMatchSub;

  /// No description provided for @settingsAutoChat.
  ///
  /// In tr, this message translates to:
  /// **'Eşleşmelerde sohbeti otomatik hazırla'**
  String get settingsAutoChat;

  /// No description provided for @settingsAutoChatSub.
  ///
  /// In tr, this message translates to:
  /// **'Eşleşme oluştuğunda sohbet ekranını hızlıca aç'**
  String get settingsAutoChatSub;

  /// No description provided for @settingsCompactCards.
  ///
  /// In tr, this message translates to:
  /// **'Kartları kompakt göster'**
  String get settingsCompactCards;

  /// No description provided for @settingsCompactCardsSub.
  ///
  /// In tr, this message translates to:
  /// **'Liste görünümünde daha fazla içerik gör'**
  String get settingsCompactCardsSub;

  /// No description provided for @settingsDarkModeSub.
  ///
  /// In tr, this message translates to:
  /// **'Gözlerin için daha konforlu koyu tema'**
  String get settingsDarkModeSub;

  /// No description provided for @settingsLanguageSub.
  ///
  /// In tr, this message translates to:
  /// **'Uygulama dilini değiştir'**
  String get settingsLanguageSub;

  /// No description provided for @settingsExportData.
  ///
  /// In tr, this message translates to:
  /// **'Verilerimi dışa aktar'**
  String get settingsExportData;

  /// No description provided for @settingsExportDataSub.
  ///
  /// In tr, this message translates to:
  /// **'İlan ve sohbet geçmişini e-posta olarak iste'**
  String get settingsExportDataSub;

  /// No description provided for @settingsHelp.
  ///
  /// In tr, this message translates to:
  /// **'SSS ve Yardım Merkezi'**
  String get settingsHelp;

  /// No description provided for @settingsContact.
  ///
  /// In tr, this message translates to:
  /// **'Destek ile iletişime geç'**
  String get settingsContact;

  /// No description provided for @settingsShare.
  ///
  /// In tr, this message translates to:
  /// **'Uygulamayı Paylaş'**
  String get settingsShare;

  /// No description provided for @settingsShareSub.
  ///
  /// In tr, this message translates to:
  /// **'Arkadaşlarına öner'**
  String get settingsShareSub;

  /// No description provided for @profileTabMyAds.
  ///
  /// In tr, this message translates to:
  /// **'Sahiplendirme İlanlarım'**
  String get profileTabMyAds;

  /// No description provided for @profileTabMatingAds.
  ///
  /// In tr, this message translates to:
  /// **'Eşleştirme İlanlarım'**
  String get profileTabMatingAds;

  /// No description provided for @profileAdoptionCount.
  ///
  /// In tr, this message translates to:
  /// **'Sahiplendirme'**
  String get profileAdoptionCount;

  /// No description provided for @profileMatingCount.
  ///
  /// In tr, this message translates to:
  /// **'Eşleştirme'**
  String get profileMatingCount;

  /// No description provided for @profileViewCount.
  ///
  /// In tr, this message translates to:
  /// **'Görüntülenme'**
  String get profileViewCount;

  /// No description provided for @profileNewAdoption.
  ///
  /// In tr, this message translates to:
  /// **'Sahiplendirme'**
  String get profileNewAdoption;

  /// No description provided for @profileNewMating.
  ///
  /// In tr, this message translates to:
  /// **'Eşleştirme'**
  String get profileNewMating;

  /// No description provided for @homeGreeting.
  ///
  /// In tr, this message translates to:
  /// **'Merhaba'**
  String get homeGreeting;

  /// No description provided for @homeShortcutMating.
  ///
  /// In tr, this message translates to:
  /// **'Eşleştir'**
  String get homeShortcutMating;

  /// No description provided for @homeShortcutLost.
  ///
  /// In tr, this message translates to:
  /// **'Kayıp'**
  String get homeShortcutLost;

  /// No description provided for @homeShortcutEvents.
  ///
  /// In tr, this message translates to:
  /// **'Etkinlik'**
  String get homeShortcutEvents;

  /// No description provided for @homeShortcutSitter.
  ///
  /// In tr, this message translates to:
  /// **'Bakıcı'**
  String get homeShortcutSitter;

  /// No description provided for @homeShortcutAi.
  ///
  /// In tr, this message translates to:
  /// **'Pati AI'**
  String get homeShortcutAi;

  /// No description provided for @homeShortcutFeed.
  ///
  /// In tr, this message translates to:
  /// **'Feed'**
  String get homeShortcutFeed;

  /// No description provided for @homeShortcutSearch.
  ///
  /// In tr, this message translates to:
  /// **'Ara'**
  String get homeShortcutSearch;

  /// No description provided for @homeUpcomingAppointments.
  ///
  /// In tr, this message translates to:
  /// **'Yaklaşan Randevular'**
  String get homeUpcomingAppointments;

  /// No description provided for @homeNearbyAds.
  ///
  /// In tr, this message translates to:
  /// **'Yakınımdaki İlanlar'**
  String get homeNearbyAds;

  /// No description provided for @navMessages.
  ///
  /// In tr, this message translates to:
  /// **'Sohbetler'**
  String get navMessages;

  /// No description provided for @navAdopt.
  ///
  /// In tr, this message translates to:
  /// **'Sahiplen'**
  String get navAdopt;

  /// No description provided for @navVet.
  ///
  /// In tr, this message translates to:
  /// **'Veteriner'**
  String get navVet;

  /// No description provided for @navStore.
  ///
  /// In tr, this message translates to:
  /// **'Mağaza'**
  String get navStore;

  /// No description provided for @navProfile.
  ///
  /// In tr, this message translates to:
  /// **'Profil'**
  String get navProfile;

  /// No description provided for @darkModeOn.
  ///
  /// In tr, this message translates to:
  /// **'Karanlık mod açık'**
  String get darkModeOn;

  /// No description provided for @darkModeOff.
  ///
  /// In tr, this message translates to:
  /// **'Karanlık mod kapalı'**
  String get darkModeOff;

  /// No description provided for @languageLabel.
  ///
  /// In tr, this message translates to:
  /// **'Dil / Language'**
  String get languageLabel;

  /// No description provided for @selectLanguage.
  ///
  /// In tr, this message translates to:
  /// **'Dil Seçin'**
  String get selectLanguage;

  /// No description provided for @today.
  ///
  /// In tr, this message translates to:
  /// **'Bugün'**
  String get today;

  /// No description provided for @tomorrow.
  ///
  /// In tr, this message translates to:
  /// **'Yarın'**
  String get tomorrow;

  /// No description provided for @profileCompleteTitle.
  ///
  /// In tr, this message translates to:
  /// **'Profili tamamla'**
  String get profileCompleteTitle;

  /// No description provided for @profileCompletePhoto.
  ///
  /// In tr, this message translates to:
  /// **'Fotoğraf'**
  String get profileCompletePhoto;

  /// No description provided for @profileCompleteCity.
  ///
  /// In tr, this message translates to:
  /// **'Şehir'**
  String get profileCompleteCity;

  /// No description provided for @profileCompleteAbout.
  ///
  /// In tr, this message translates to:
  /// **'Hakkımda'**
  String get profileCompleteAbout;

  /// No description provided for @searchMessages.
  ///
  /// In tr, this message translates to:
  /// **'Mesajlarda ara...'**
  String get searchMessages;

  /// No description provided for @noSearchResults.
  ///
  /// In tr, this message translates to:
  /// **'\"{query}\" için sonuç bulunamadı'**
  String noSearchResults(String query);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'tr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'tr':
      return AppLocalizationsTr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
