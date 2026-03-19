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

  /// No description provided for @msgConvDeleted.
  ///
  /// In tr, this message translates to:
  /// **'Sohbet silindi'**
  String get msgConvDeleted;

  /// No description provided for @msgConvDeleteErr.
  ///
  /// In tr, this message translates to:
  /// **'Sohbet silinemedi: {error}'**
  String msgConvDeleteErr(String error);

  /// No description provided for @msgConvStart.
  ///
  /// In tr, this message translates to:
  /// **'Sohbete başla'**
  String get msgConvStart;

  /// No description provided for @msgListingNotFound.
  ///
  /// In tr, this message translates to:
  /// **'İlan bilgisi bulunamadı'**
  String get msgListingNotFound;

  /// No description provided for @msgListingLoading.
  ///
  /// In tr, this message translates to:
  /// **'İlan yükleniyor...'**
  String get msgListingLoading;

  /// No description provided for @msgListingLoadErr.
  ///
  /// In tr, this message translates to:
  /// **'İlan bilgisi alınamadı'**
  String get msgListingLoadErr;

  /// No description provided for @msgMatingRequestsTitle.
  ///
  /// In tr, this message translates to:
  /// **'Eşleştirme İstekleri'**
  String get msgMatingRequestsTitle;

  /// No description provided for @msgNoMatingRequests.
  ///
  /// In tr, this message translates to:
  /// **'Henüz eşleştirme isteği yok.'**
  String get msgNoMatingRequests;

  /// No description provided for @msgAdoptionRequestsTitle.
  ///
  /// In tr, this message translates to:
  /// **'Sahiplendirme Başvuruları'**
  String get msgAdoptionRequestsTitle;

  /// No description provided for @msgNoAdoptionRequests.
  ///
  /// In tr, this message translates to:
  /// **'Henüz başvuru yok.'**
  String get msgNoAdoptionRequests;

  /// No description provided for @msgHeaderTitle.
  ///
  /// In tr, this message translates to:
  /// **'Sohbet kutunu renklendir'**
  String get msgHeaderTitle;

  /// No description provided for @msgHeaderSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Sahiplendirme görüşmelerini, ilan sorularını ve yeni dostlukları burada yönet.'**
  String get msgHeaderSubtitle;

  /// No description provided for @msgConvLoadErr.
  ///
  /// In tr, this message translates to:
  /// **'Sohbetler yüklenemedi'**
  String get msgConvLoadErr;

  /// No description provided for @msgSenderLabel.
  ///
  /// In tr, this message translates to:
  /// **'Gönderen: {name}'**
  String msgSenderLabel(String name);

  /// No description provided for @msgSelectedPet.
  ///
  /// In tr, this message translates to:
  /// **'Seçilen pet: {name}'**
  String msgSelectedPet(String name);

  /// No description provided for @msgViewSenderListing.
  ///
  /// In tr, this message translates to:
  /// **'Gönderen ilanını gör'**
  String get msgViewSenderListing;

  /// No description provided for @msgApplicantLabel.
  ///
  /// In tr, this message translates to:
  /// **'Başvuran: {name}'**
  String msgApplicantLabel(String name);

  /// No description provided for @msgGoToChat.
  ///
  /// In tr, this message translates to:
  /// **'Sohbete git'**
  String get msgGoToChat;

  /// No description provided for @msgStatusAccepted.
  ///
  /// In tr, this message translates to:
  /// **'Kabul edildi'**
  String get msgStatusAccepted;

  /// No description provided for @msgStatusRejected.
  ///
  /// In tr, this message translates to:
  /// **'Reddedildi'**
  String get msgStatusRejected;

  /// No description provided for @msgStatusCancelled.
  ///
  /// In tr, this message translates to:
  /// **'İptal edildi'**
  String get msgStatusCancelled;

  /// No description provided for @msgStatusPending.
  ///
  /// In tr, this message translates to:
  /// **'Beklemede'**
  String get msgStatusPending;

  /// No description provided for @msgActionDone.
  ///
  /// In tr, this message translates to:
  /// **'İşlem tamamlandı'**
  String get msgActionDone;

  /// No description provided for @msgNoRecipient.
  ///
  /// In tr, this message translates to:
  /// **'Karşı taraf bilgisi bulunamadı.'**
  String get msgNoRecipient;

  /// No description provided for @msgLoginRequired.
  ///
  /// In tr, this message translates to:
  /// **'Sohbet için giriş yapın.'**
  String get msgLoginRequired;

  /// No description provided for @msgOpenFailed.
  ///
  /// In tr, this message translates to:
  /// **'Sohbet açılamadı.'**
  String get msgOpenFailed;

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

  /// No description provided for @speciesHamster.
  ///
  /// In tr, this message translates to:
  /// **'Hamster'**
  String get speciesHamster;

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

  /// No description provided for @homeDiscoverTitle.
  ///
  /// In tr, this message translates to:
  /// **'İlanları Keşfet'**
  String get homeDiscoverTitle;

  /// No description provided for @homeSearchTooltip.
  ///
  /// In tr, this message translates to:
  /// **'Ara'**
  String get homeSearchTooltip;

  /// No description provided for @homeLostFoundTooltip.
  ///
  /// In tr, this message translates to:
  /// **'Kayıp & Bulunan'**
  String get homeLostFoundTooltip;

  /// No description provided for @homeBreedSelect.
  ///
  /// In tr, this message translates to:
  /// **'Cins seç'**
  String get homeBreedSelect;

  /// No description provided for @homeClearFilter.
  ///
  /// In tr, this message translates to:
  /// **'Filtreyi temizle'**
  String get homeClearFilter;

  /// No description provided for @homeWelcome.
  ///
  /// In tr, this message translates to:
  /// **'Hoş geldin!'**
  String get homeWelcome;

  /// No description provided for @homeGreetingWith.
  ///
  /// In tr, this message translates to:
  /// **'{greeting}, {name}!'**
  String homeGreetingWith(String greeting, String name);

  /// No description provided for @homeHeaderDesc.
  ///
  /// In tr, this message translates to:
  /// **'Sana en uygun pati dostunu keşfet.'**
  String get homeHeaderDesc;

  /// No description provided for @homeGoodMorning.
  ///
  /// In tr, this message translates to:
  /// **'Günaydın'**
  String get homeGoodMorning;

  /// No description provided for @homeGoodDay.
  ///
  /// In tr, this message translates to:
  /// **'İyi günler'**
  String get homeGoodDay;

  /// No description provided for @homeGoodEvening.
  ///
  /// In tr, this message translates to:
  /// **'İyi akşamlar'**
  String get homeGoodEvening;

  /// No description provided for @homeGoodNight.
  ///
  /// In tr, this message translates to:
  /// **'İyi geceler'**
  String get homeGoodNight;

  /// No description provided for @homeShortcutSitterFull.
  ///
  /// In tr, this message translates to:
  /// **'Bakıcı\nBul'**
  String get homeShortcutSitterFull;

  /// No description provided for @homeShortcutLostFull.
  ///
  /// In tr, this message translates to:
  /// **'Kayıp &\nBulunan'**
  String get homeShortcutLostFull;

  /// No description provided for @homeShortcutAiFull.
  ///
  /// In tr, this message translates to:
  /// **'Pati\nAsistan'**
  String get homeShortcutAiFull;

  /// No description provided for @homeShortcutMap.
  ///
  /// In tr, this message translates to:
  /// **'Harita'**
  String get homeShortcutMap;

  /// No description provided for @homeEmptyListings.
  ///
  /// In tr, this message translates to:
  /// **'Henüz ilan yok'**
  String get homeEmptyListings;

  /// No description provided for @homeEmptyListingsDesc.
  ///
  /// In tr, this message translates to:
  /// **'Bu kategoride henüz ilan yok. İlk sen ekle!'**
  String get homeEmptyListingsDesc;

  /// No description provided for @homeApptFallback.
  ///
  /// In tr, this message translates to:
  /// **'Veteriner Randevusu'**
  String get homeApptFallback;

  /// No description provided for @homeNotifTooltip.
  ///
  /// In tr, this message translates to:
  /// **'Bildirimler'**
  String get homeNotifTooltip;

  /// No description provided for @homeBreedSearch.
  ///
  /// In tr, this message translates to:
  /// **'Cins ara...'**
  String get homeBreedSearch;

  /// No description provided for @homeLocationPermErr.
  ///
  /// In tr, this message translates to:
  /// **'Konum izni gerekli'**
  String get homeLocationPermErr;

  /// No description provided for @homeLocationErr.
  ///
  /// In tr, this message translates to:
  /// **'Konum alınamadı: {error}'**
  String homeLocationErr(String error);

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

  /// No description provided for @vetVerified.
  ///
  /// In tr, this message translates to:
  /// **'Doğrulanmış'**
  String get vetVerified;

  /// No description provided for @vetOnlineAppointment.
  ///
  /// In tr, this message translates to:
  /// **'Online Randevu'**
  String get vetOnlineAppointment;

  /// No description provided for @vetAbout.
  ///
  /// In tr, this message translates to:
  /// **'Hakkında'**
  String get vetAbout;

  /// No description provided for @vetServices.
  ///
  /// In tr, this message translates to:
  /// **'Hizmetler'**
  String get vetServices;

  /// No description provided for @vetSpeciesServed.
  ///
  /// In tr, this message translates to:
  /// **'Hizmet Verilen Türler'**
  String get vetSpeciesServed;

  /// No description provided for @vetWorkingHours.
  ///
  /// In tr, this message translates to:
  /// **'Çalışma Saatleri'**
  String get vetWorkingHours;

  /// No description provided for @vetClosed.
  ///
  /// In tr, this message translates to:
  /// **'Kapalı'**
  String get vetClosed;

  /// No description provided for @vetOpenInMaps.
  ///
  /// In tr, this message translates to:
  /// **'Haritada Aç'**
  String get vetOpenInMaps;

  /// No description provided for @vetSendMessage.
  ///
  /// In tr, this message translates to:
  /// **'Mesaj Gönder'**
  String get vetSendMessage;

  /// No description provided for @vetClaimProfile.
  ///
  /// In tr, this message translates to:
  /// **'Bu Kliniği Sahiplen'**
  String get vetClaimProfile;

  /// No description provided for @vetClaimDialogTitle.
  ///
  /// In tr, this message translates to:
  /// **'Profili Sahiplen'**
  String get vetClaimDialogTitle;

  /// No description provided for @vetClaimDialogContent.
  ///
  /// In tr, this message translates to:
  /// **'Bu klinik profilini hesabınıza bağlamak istediğinizden emin misiniz?\n\nSahiplendikten sonra müşteriler size doğrudan mesaj gönderebilir.'**
  String get vetClaimDialogContent;

  /// No description provided for @vetClaimAction.
  ///
  /// In tr, this message translates to:
  /// **'Sahiplen'**
  String get vetClaimAction;

  /// No description provided for @vetClaimSuccess.
  ///
  /// In tr, this message translates to:
  /// **'Profil başarıyla sahiplenildi! Artık mesaj alabilirsiniz.'**
  String get vetClaimSuccess;

  /// No description provided for @vetReviews.
  ///
  /// In tr, this message translates to:
  /// **'Değerlendirmeler'**
  String get vetReviews;

  /// No description provided for @vetReviewsRate.
  ///
  /// In tr, this message translates to:
  /// **'Değerlendir'**
  String get vetReviewsRate;

  /// No description provided for @vetReviewsLoadError.
  ///
  /// In tr, this message translates to:
  /// **'Yorumlar yüklenemedi.'**
  String get vetReviewsLoadError;

  /// No description provided for @vetReviewsEmpty.
  ///
  /// In tr, this message translates to:
  /// **'Henüz değerlendirme yok. İlk yorumu siz yapın!'**
  String get vetReviewsEmpty;

  /// No description provided for @vetReviewCount.
  ///
  /// In tr, this message translates to:
  /// **'{count} değerlendirme'**
  String vetReviewCount(int count);

  /// No description provided for @vetReviewAdded.
  ///
  /// In tr, this message translates to:
  /// **'Değerlendirmeniz eklendi.'**
  String get vetReviewAdded;

  /// No description provided for @vetReviewDeleteError.
  ///
  /// In tr, this message translates to:
  /// **'Silinemedi: {error}'**
  String vetReviewDeleteError(String error);

  /// No description provided for @vetReviewDialogTitle.
  ///
  /// In tr, this message translates to:
  /// **'Veteriner Değerlendir'**
  String get vetReviewDialogTitle;

  /// No description provided for @vetReviewCommentHint.
  ///
  /// In tr, this message translates to:
  /// **'Yorumunuz (isteğe bağlı)'**
  String get vetReviewCommentHint;

  /// No description provided for @vetSpeciesDog.
  ///
  /// In tr, this message translates to:
  /// **'Köpek'**
  String get vetSpeciesDog;

  /// No description provided for @vetSpeciesCat.
  ///
  /// In tr, this message translates to:
  /// **'Kedi'**
  String get vetSpeciesCat;

  /// No description provided for @vetSpeciesBird.
  ///
  /// In tr, this message translates to:
  /// **'Kuş'**
  String get vetSpeciesBird;

  /// No description provided for @vetSpeciesFish.
  ///
  /// In tr, this message translates to:
  /// **'Balık'**
  String get vetSpeciesFish;

  /// No description provided for @vetSpeciesRodent.
  ///
  /// In tr, this message translates to:
  /// **'Kemirgen'**
  String get vetSpeciesRodent;

  /// No description provided for @vetSpeciesOther.
  ///
  /// In tr, this message translates to:
  /// **'Diğer'**
  String get vetSpeciesOther;

  /// No description provided for @vetRating.
  ///
  /// In tr, this message translates to:
  /// **'{rating} ({count} değerlendirme)'**
  String vetRating(String rating, int count);

  /// No description provided for @checkoutTitle.
  ///
  /// In tr, this message translates to:
  /// **'Ödeme'**
  String get checkoutTitle;

  /// No description provided for @checkoutDeliveryAddress.
  ///
  /// In tr, this message translates to:
  /// **'Teslimat Adresi'**
  String get checkoutDeliveryAddress;

  /// No description provided for @checkoutPaymentMethod.
  ///
  /// In tr, this message translates to:
  /// **'Ödeme Yöntemi'**
  String get checkoutPaymentMethod;

  /// No description provided for @checkoutCardInfo.
  ///
  /// In tr, this message translates to:
  /// **'Kart Bilgileri'**
  String get checkoutCardInfo;

  /// No description provided for @checkoutCreditCard.
  ///
  /// In tr, this message translates to:
  /// **'Kredi Kartı'**
  String get checkoutCreditCard;

  /// No description provided for @checkoutCashOnDelivery.
  ///
  /// In tr, this message translates to:
  /// **'Kapıda Ödeme'**
  String get checkoutCashOnDelivery;

  /// No description provided for @checkoutCardNumber.
  ///
  /// In tr, this message translates to:
  /// **'Kart Numarası'**
  String get checkoutCardNumber;

  /// No description provided for @checkoutCardHolder.
  ///
  /// In tr, this message translates to:
  /// **'Kart Sahibi'**
  String get checkoutCardHolder;

  /// No description provided for @checkoutCardHolderHint.
  ///
  /// In tr, this message translates to:
  /// **'AD SOYAD'**
  String get checkoutCardHolderHint;

  /// No description provided for @checkoutExpiry.
  ///
  /// In tr, this message translates to:
  /// **'Son Kullanma'**
  String get checkoutExpiry;

  /// No description provided for @checkoutExpiryHint.
  ///
  /// In tr, this message translates to:
  /// **'AA/YY'**
  String get checkoutExpiryHint;

  /// No description provided for @checkoutCoupon.
  ///
  /// In tr, this message translates to:
  /// **'İndirim Kuponu'**
  String get checkoutCoupon;

  /// No description provided for @checkoutCouponHint.
  ///
  /// In tr, this message translates to:
  /// **'Kupon kodunuz'**
  String get checkoutCouponHint;

  /// No description provided for @checkoutApply.
  ///
  /// In tr, this message translates to:
  /// **'Uygula'**
  String get checkoutApply;

  /// No description provided for @checkoutOrderNote.
  ///
  /// In tr, this message translates to:
  /// **'Sipariş Notu (Opsiyonel)'**
  String get checkoutOrderNote;

  /// No description provided for @checkoutOrderNoteHint.
  ///
  /// In tr, this message translates to:
  /// **'Siparişinizle ilgili notunuz...'**
  String get checkoutOrderNoteHint;

  /// No description provided for @checkoutOrderSummary.
  ///
  /// In tr, this message translates to:
  /// **'Sipariş Özeti'**
  String get checkoutOrderSummary;

  /// No description provided for @checkoutSubtotal.
  ///
  /// In tr, this message translates to:
  /// **'Ara Toplam'**
  String get checkoutSubtotal;

  /// No description provided for @checkoutShipping.
  ///
  /// In tr, this message translates to:
  /// **'Kargo'**
  String get checkoutShipping;

  /// No description provided for @checkoutFreeShipping.
  ///
  /// In tr, this message translates to:
  /// **'Ücretsiz'**
  String get checkoutFreeShipping;

  /// No description provided for @checkoutDiscount.
  ///
  /// In tr, this message translates to:
  /// **'İndirim'**
  String get checkoutDiscount;

  /// No description provided for @checkoutTotal.
  ///
  /// In tr, this message translates to:
  /// **'Toplam'**
  String get checkoutTotal;

  /// No description provided for @checkoutCompleteOrder.
  ///
  /// In tr, this message translates to:
  /// **'Siparişi Tamamla'**
  String get checkoutCompleteOrder;

  /// No description provided for @checkoutDefaultAddress.
  ///
  /// In tr, this message translates to:
  /// **'Varsayılan'**
  String get checkoutDefaultAddress;

  /// No description provided for @checkoutAddNewAddress.
  ///
  /// In tr, this message translates to:
  /// **'Yeni Adres Ekle'**
  String get checkoutAddNewAddress;

  /// No description provided for @checkoutAddressLoadError.
  ///
  /// In tr, this message translates to:
  /// **'Adresler yüklenemedi: {error}'**
  String checkoutAddressLoadError(String error);

  /// No description provided for @checkoutCartLoadError.
  ///
  /// In tr, this message translates to:
  /// **'Sepet yüklenemedi: {error}'**
  String checkoutCartLoadError(String error);

  /// No description provided for @checkoutErrNoAddress.
  ///
  /// In tr, this message translates to:
  /// **'Lütfen bir teslimat adresi seçin'**
  String get checkoutErrNoAddress;

  /// No description provided for @checkoutErrCardNumber.
  ///
  /// In tr, this message translates to:
  /// **'Geçerli bir kart numarası girin'**
  String get checkoutErrCardNumber;

  /// No description provided for @checkoutErrCardHolder.
  ///
  /// In tr, this message translates to:
  /// **'Kart sahibi adını girin'**
  String get checkoutErrCardHolder;

  /// No description provided for @checkoutErrExpiry.
  ///
  /// In tr, this message translates to:
  /// **'Geçerli bir son kullanma tarihi girin'**
  String get checkoutErrExpiry;

  /// No description provided for @checkoutErrCvv.
  ///
  /// In tr, this message translates to:
  /// **'Geçerli bir CVV girin'**
  String get checkoutErrCvv;

  /// No description provided for @checkoutErrEmptyCart.
  ///
  /// In tr, this message translates to:
  /// **'Sepetiniz boş'**
  String get checkoutErrEmptyCart;

  /// No description provided for @checkoutErrCouponEmpty.
  ///
  /// In tr, this message translates to:
  /// **'Lütfen bir kupon kodu girin'**
  String get checkoutErrCouponEmpty;

  /// No description provided for @checkoutErrCouponInvalid.
  ///
  /// In tr, this message translates to:
  /// **'Geçersiz kupon kodu'**
  String get checkoutErrCouponInvalid;

  /// No description provided for @checkoutErrCouponNotApplicable.
  ///
  /// In tr, this message translates to:
  /// **'Kupon bu sipariş için geçerli değil'**
  String get checkoutErrCouponNotApplicable;

  /// No description provided for @checkoutErrCouponFailed.
  ///
  /// In tr, this message translates to:
  /// **'Kupon uygulanamadı'**
  String get checkoutErrCouponFailed;

  /// No description provided for @checkoutCouponApplied.
  ///
  /// In tr, this message translates to:
  /// **'Kupon uygulandı! ₺{amount} indirim'**
  String checkoutCouponApplied(String amount);

  /// No description provided for @checkoutCouponDiscount.
  ///
  /// In tr, this message translates to:
  /// **'₺{amount} indirim uygulandı'**
  String checkoutCouponDiscount(String amount);

  /// No description provided for @checkoutOrderSuccess.
  ///
  /// In tr, this message translates to:
  /// **'Siparişiniz Alındı!'**
  String get checkoutOrderSuccess;

  /// No description provided for @checkoutOrderSuccessDesc.
  ///
  /// In tr, this message translates to:
  /// **'Siparişiniz başarıyla oluşturuldu. Siparişlerim sayfasından takip edebilirsiniz.'**
  String get checkoutOrderSuccessDesc;

  /// No description provided for @checkoutGoToOrders.
  ///
  /// In tr, this message translates to:
  /// **'Siparişlerime Git'**
  String get checkoutGoToOrders;

  /// No description provided for @checkoutOrderError.
  ///
  /// In tr, this message translates to:
  /// **'Sipariş oluşturulamadı: {error}'**
  String checkoutOrderError(String error);

  /// No description provided for @healthJournalTitle.
  ///
  /// In tr, this message translates to:
  /// **'{petName} Sağlık Günlüğü'**
  String healthJournalTitle(String petName);

  /// No description provided for @healthAddRecord.
  ///
  /// In tr, this message translates to:
  /// **'Kayıt Ekle'**
  String get healthAddRecord;

  /// No description provided for @healthTypeAll.
  ///
  /// In tr, this message translates to:
  /// **'Tümü'**
  String get healthTypeAll;

  /// No description provided for @healthTypeWeight.
  ///
  /// In tr, this message translates to:
  /// **'Kilo'**
  String get healthTypeWeight;

  /// No description provided for @healthTypeMedication.
  ///
  /// In tr, this message translates to:
  /// **'İlaç'**
  String get healthTypeMedication;

  /// No description provided for @healthTypeVetVisit.
  ///
  /// In tr, this message translates to:
  /// **'Veteriner'**
  String get healthTypeVetVisit;

  /// No description provided for @healthTypeNote.
  ///
  /// In tr, this message translates to:
  /// **'Not'**
  String get healthTypeNote;

  /// No description provided for @healthRecordAdded.
  ///
  /// In tr, this message translates to:
  /// **'Kayıt eklendi.'**
  String get healthRecordAdded;

  /// No description provided for @healthRecordDeleteTitle.
  ///
  /// In tr, this message translates to:
  /// **'Kaydı Sil'**
  String get healthRecordDeleteTitle;

  /// No description provided for @healthRecordDeleteContent.
  ///
  /// In tr, this message translates to:
  /// **'Bu sağlık kaydını silmek istediğinize emin misiniz?'**
  String get healthRecordDeleteContent;

  /// No description provided for @healthNoRecords.
  ///
  /// In tr, this message translates to:
  /// **'Henüz sağlık kaydı yok'**
  String get healthNoRecords;

  /// No description provided for @healthNoFilterRecords.
  ///
  /// In tr, this message translates to:
  /// **'{type} kaydı yok'**
  String healthNoFilterRecords(String type);

  /// No description provided for @healthAddHint.
  ///
  /// In tr, this message translates to:
  /// **'Sağ alttaki + butonuna basarak kayıt ekleyin'**
  String get healthAddHint;

  /// No description provided for @healthWeightChart.
  ///
  /// In tr, this message translates to:
  /// **'Kilo Takibi'**
  String get healthWeightChart;

  /// No description provided for @healthWeightChartMin.
  ///
  /// In tr, this message translates to:
  /// **'Grafik için en az 2 kilo kaydı gerekli'**
  String get healthWeightChartMin;

  /// No description provided for @healthWeightChartError.
  ///
  /// In tr, this message translates to:
  /// **'Kilo grafiği yüklenemedi'**
  String get healthWeightChartError;

  /// No description provided for @healthRefresh.
  ///
  /// In tr, this message translates to:
  /// **'Yenile'**
  String get healthRefresh;

  /// No description provided for @healthLoadError.
  ///
  /// In tr, this message translates to:
  /// **'Yüklenemedi: {error}'**
  String healthLoadError(String error);

  /// No description provided for @healthDose.
  ///
  /// In tr, this message translates to:
  /// **'Doz: {dose}'**
  String healthDose(String dose);

  /// No description provided for @healthFrequency.
  ///
  /// In tr, this message translates to:
  /// **'Sıklık: {freq}'**
  String healthFrequency(String freq);

  /// No description provided for @healthVetName.
  ///
  /// In tr, this message translates to:
  /// **'Veteriner: {name}'**
  String healthVetName(String name);

  /// No description provided for @healthDiagnosis.
  ///
  /// In tr, this message translates to:
  /// **'Tanı: {diagnosis}'**
  String healthDiagnosis(String diagnosis);

  /// No description provided for @healthAddDialogTitle.
  ///
  /// In tr, this message translates to:
  /// **'Sağlık Kaydı Ekle'**
  String get healthAddDialogTitle;

  /// No description provided for @healthRecordType.
  ///
  /// In tr, this message translates to:
  /// **'Kayıt Tipi'**
  String get healthRecordType;

  /// No description provided for @healthRecordDate.
  ///
  /// In tr, this message translates to:
  /// **'Kayıt tarihi'**
  String get healthRecordDate;

  /// No description provided for @healthWeightKg.
  ///
  /// In tr, this message translates to:
  /// **'Kilo (kg)'**
  String get healthWeightKg;

  /// No description provided for @healthMedName.
  ///
  /// In tr, this message translates to:
  /// **'İlaç Adı *'**
  String get healthMedName;

  /// No description provided for @healthMedDosage.
  ///
  /// In tr, this message translates to:
  /// **'Dozaj (ör. 5mg)'**
  String get healthMedDosage;

  /// No description provided for @healthMedFreq.
  ///
  /// In tr, this message translates to:
  /// **'Sıklık (ör. Günde 2 kez)'**
  String get healthMedFreq;

  /// No description provided for @healthVetNameLabel.
  ///
  /// In tr, this message translates to:
  /// **'Veteriner Adı'**
  String get healthVetNameLabel;

  /// No description provided for @healthDiagnosisTreatment.
  ///
  /// In tr, this message translates to:
  /// **'Tanı / Tedavi'**
  String get healthDiagnosisTreatment;

  /// No description provided for @healthNotes.
  ///
  /// In tr, this message translates to:
  /// **'Notlar (isteğe bağlı)'**
  String get healthNotes;

  /// No description provided for @healthErrWeight.
  ///
  /// In tr, this message translates to:
  /// **'Geçerli bir kilo girin.'**
  String get healthErrWeight;

  /// No description provided for @healthErrMedName.
  ///
  /// In tr, this message translates to:
  /// **'İlaç adı zorunludur.'**
  String get healthErrMedName;

  /// No description provided for @blockUserTitle.
  ///
  /// In tr, this message translates to:
  /// **'Kullanıcıyı Engelle'**
  String get blockUserTitle;

  /// No description provided for @blockUserContent.
  ///
  /// In tr, this message translates to:
  /// **'{name} adlı kullanıcıyı engellemek istediğinize emin misiniz? Bu kullanıcının ilanlarını artık görmeyeceksiniz.'**
  String blockUserContent(String name);

  /// No description provided for @blockUserAction.
  ///
  /// In tr, this message translates to:
  /// **'Engelle'**
  String get blockUserAction;

  /// No description provided for @blockUserSuccess.
  ///
  /// In tr, this message translates to:
  /// **'{name} engellendi.'**
  String blockUserSuccess(String name);

  /// No description provided for @blockUserError.
  ///
  /// In tr, this message translates to:
  /// **'Engelleme başarısız: {error}'**
  String blockUserError(String error);

  /// No description provided for @blockUserSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Bu kullanıcının ilanlarını görmek istemiyorum'**
  String get blockUserSubtitle;

  /// No description provided for @reportUserTitle.
  ///
  /// In tr, this message translates to:
  /// **'Şikayet Et'**
  String get reportUserTitle;

  /// No description provided for @reportUserSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Uygunsuz davranış veya içerik bildir'**
  String get reportUserSubtitle;

  /// No description provided for @reportDialogTitle.
  ///
  /// In tr, this message translates to:
  /// **'{name} Şikayet Et'**
  String reportDialogTitle(String name);

  /// No description provided for @reportReasonLabel.
  ///
  /// In tr, this message translates to:
  /// **'Şikayet nedeni:'**
  String get reportReasonLabel;

  /// No description provided for @reportReasonSpam.
  ///
  /// In tr, this message translates to:
  /// **'Spam'**
  String get reportReasonSpam;

  /// No description provided for @reportReasonHarassment.
  ///
  /// In tr, this message translates to:
  /// **'Taciz veya zorbalık'**
  String get reportReasonHarassment;

  /// No description provided for @reportReasonInappropriate.
  ///
  /// In tr, this message translates to:
  /// **'Uygunsuz içerik'**
  String get reportReasonInappropriate;

  /// No description provided for @reportReasonFakeProfile.
  ///
  /// In tr, this message translates to:
  /// **'Sahte profil'**
  String get reportReasonFakeProfile;

  /// No description provided for @reportReasonOther.
  ///
  /// In tr, this message translates to:
  /// **'Diğer'**
  String get reportReasonOther;

  /// No description provided for @reportDescHint.
  ///
  /// In tr, this message translates to:
  /// **'Ek açıklama (isteğe bağlı)'**
  String get reportDescHint;

  /// No description provided for @reportAction.
  ///
  /// In tr, this message translates to:
  /// **'Şikayet Et'**
  String get reportAction;

  /// No description provided for @reportErrNoReason.
  ///
  /// In tr, this message translates to:
  /// **'Lütfen bir neden seçin.'**
  String get reportErrNoReason;

  /// No description provided for @reportSuccess.
  ///
  /// In tr, this message translates to:
  /// **'Şikayetiniz alındı, teşekkürler.'**
  String get reportSuccess;

  /// No description provided for @goBack.
  ///
  /// In tr, this message translates to:
  /// **'Geri Dön'**
  String get goBack;

  /// No description provided for @petDetailLoadError.
  ///
  /// In tr, this message translates to:
  /// **'İlan yüklenemedi'**
  String get petDetailLoadError;

  /// No description provided for @petDetailGoBack.
  ///
  /// In tr, this message translates to:
  /// **'Geri Dön'**
  String get petDetailGoBack;

  /// No description provided for @petDetailShare.
  ///
  /// In tr, this message translates to:
  /// **'Paylaş'**
  String get petDetailShare;

  /// No description provided for @petDetailQrTooltip.
  ///
  /// In tr, this message translates to:
  /// **'QR Kimlik Kartı'**
  String get petDetailQrTooltip;

  /// No description provided for @petDetailQrCard.
  ///
  /// In tr, this message translates to:
  /// **'QR Kimlik Kartı'**
  String get petDetailQrCard;

  /// No description provided for @petDetailVaccine.
  ///
  /// In tr, this message translates to:
  /// **'Aşı'**
  String get petDetailVaccine;

  /// No description provided for @petDetailVaccineFull.
  ///
  /// In tr, this message translates to:
  /// **'Aşılı'**
  String get petDetailVaccineFull;

  /// No description provided for @petDetailVaccineMissing.
  ///
  /// In tr, this message translates to:
  /// **'Aşısız'**
  String get petDetailVaccineMissing;

  /// No description provided for @petDetailAgeYearsMonths.
  ///
  /// In tr, this message translates to:
  /// **'{years} yaş {months} ay'**
  String petDetailAgeYearsMonths(int years, int months);

  /// No description provided for @petDetailShareText.
  ///
  /// In tr, this message translates to:
  /// **'{name} - Pati Arkadaşı uygulamasında keşfet!'**
  String petDetailShareText(String name);

  /// No description provided for @petDetailShareSubject.
  ///
  /// In tr, this message translates to:
  /// **'{name} ilanı'**
  String petDetailShareSubject(String name);

  /// No description provided for @petDetailStatusActive.
  ///
  /// In tr, this message translates to:
  /// **'Yayında'**
  String get petDetailStatusActive;

  /// No description provided for @petDetailStatusInactive.
  ///
  /// In tr, this message translates to:
  /// **'Pasif'**
  String get petDetailStatusInactive;

  /// No description provided for @petDetailBreedUnspecified.
  ///
  /// In tr, this message translates to:
  /// **'Cins belirtilmemiş'**
  String get petDetailBreedUnspecified;

  /// No description provided for @petDetailAbout.
  ///
  /// In tr, this message translates to:
  /// **'Hakkında'**
  String get petDetailAbout;

  /// No description provided for @petDetailDetails.
  ///
  /// In tr, this message translates to:
  /// **'Detaylı Bilgiler'**
  String get petDetailDetails;

  /// No description provided for @petDetailSpecies.
  ///
  /// In tr, this message translates to:
  /// **'Tür'**
  String get petDetailSpecies;

  /// No description provided for @petDetailBreedLabel.
  ///
  /// In tr, this message translates to:
  /// **'Cins'**
  String get petDetailBreedLabel;

  /// No description provided for @petDetailBreedUnset.
  ///
  /// In tr, this message translates to:
  /// **'Belirtilmemiş'**
  String get petDetailBreedUnset;

  /// No description provided for @petDetailGenderLabel.
  ///
  /// In tr, this message translates to:
  /// **'Cinsiyet'**
  String get petDetailGenderLabel;

  /// No description provided for @petDetailAgeLabel.
  ///
  /// In tr, this message translates to:
  /// **'Yaş'**
  String get petDetailAgeLabel;

  /// No description provided for @petDetailAgeMonths.
  ///
  /// In tr, this message translates to:
  /// **'{months} ay'**
  String petDetailAgeMonths(int months);

  /// No description provided for @petDetailAdvertType.
  ///
  /// In tr, this message translates to:
  /// **'İlan Türü'**
  String get petDetailAdvertType;

  /// No description provided for @petDetailHealth.
  ///
  /// In tr, this message translates to:
  /// **'Sağlık Bilgileri'**
  String get petDetailHealth;

  /// No description provided for @petDetailVaccineStatus.
  ///
  /// In tr, this message translates to:
  /// **'Aşı Durumu'**
  String get petDetailVaccineStatus;

  /// No description provided for @petDetailVaccineComplete.
  ///
  /// In tr, this message translates to:
  /// **'Aşıları Tam'**
  String get petDetailVaccineComplete;

  /// No description provided for @petDetailVaccineNeeded.
  ///
  /// In tr, this message translates to:
  /// **'Aşı Gerekli'**
  String get petDetailVaccineNeeded;

  /// No description provided for @petDetailListingStatus.
  ///
  /// In tr, this message translates to:
  /// **'İlan Durumu'**
  String get petDetailListingStatus;

  /// No description provided for @petDetailActive.
  ///
  /// In tr, this message translates to:
  /// **'Aktif'**
  String get petDetailActive;

  /// No description provided for @petDetailInactive.
  ///
  /// In tr, this message translates to:
  /// **'Pasif'**
  String get petDetailInactive;

  /// No description provided for @petDetailLocation.
  ///
  /// In tr, this message translates to:
  /// **'Konum'**
  String get petDetailLocation;

  /// No description provided for @petDetailLocationShared.
  ///
  /// In tr, this message translates to:
  /// **'Konum paylaşıldı'**
  String get petDetailLocationShared;

  /// No description provided for @petDetailLocationNone.
  ///
  /// In tr, this message translates to:
  /// **'Konum bilgisi yok'**
  String get petDetailLocationNone;

  /// No description provided for @petDetailOpenInMap.
  ///
  /// In tr, this message translates to:
  /// **'Haritada Aç'**
  String get petDetailOpenInMap;

  /// No description provided for @petDetailMapTapHint.
  ///
  /// In tr, this message translates to:
  /// **'Haritada görüntülemek için dokunun'**
  String get petDetailMapTapHint;

  /// No description provided for @petDetailMapOpenError.
  ///
  /// In tr, this message translates to:
  /// **'Harita uygulaması açılamadı'**
  String get petDetailMapOpenError;

  /// No description provided for @petDetailOwnerLabel.
  ///
  /// In tr, this message translates to:
  /// **'İlan Sahibi'**
  String get petDetailOwnerLabel;

  /// No description provided for @petDetailOwnerUnknown.
  ///
  /// In tr, this message translates to:
  /// **'Sahip Bilgisi Yok'**
  String get petDetailOwnerUnknown;

  /// No description provided for @petDetailOwnerBannerTitle.
  ///
  /// In tr, this message translates to:
  /// **'Bu ilan size ait!'**
  String get petDetailOwnerBannerTitle;

  /// No description provided for @petDetailOwnerBannerDesc.
  ///
  /// In tr, this message translates to:
  /// **'İlanınızı güncel tutarak daha fazla ilgi çekebilirsiniz.'**
  String get petDetailOwnerBannerDesc;

  /// No description provided for @petDetailHealthJournal.
  ///
  /// In tr, this message translates to:
  /// **'Sağlık Günlüğü'**
  String get petDetailHealthJournal;

  /// No description provided for @petDetailMessage.
  ///
  /// In tr, this message translates to:
  /// **'Mesaj'**
  String get petDetailMessage;

  /// No description provided for @petDetailAdoptBtn.
  ///
  /// In tr, this message translates to:
  /// **'Sahiplen'**
  String get petDetailAdoptBtn;

  /// No description provided for @petDetailMatingRequest.
  ///
  /// In tr, this message translates to:
  /// **'Eşleştirme İsteği Gönder'**
  String get petDetailMatingRequest;

  /// No description provided for @petDetailQrAge.
  ///
  /// In tr, this message translates to:
  /// **'Yas'**
  String get petDetailQrAge;

  /// No description provided for @petDetailQrGender.
  ///
  /// In tr, this message translates to:
  /// **'Cinsiyet'**
  String get petDetailQrGender;

  /// No description provided for @petDetailQrVaccine.
  ///
  /// In tr, this message translates to:
  /// **'Asi'**
  String get petDetailQrVaccine;

  /// No description provided for @petDetailQrVaccineFull.
  ///
  /// In tr, this message translates to:
  /// **'Tam'**
  String get petDetailQrVaccineFull;

  /// No description provided for @petDetailQrVaccinePartial.
  ///
  /// In tr, this message translates to:
  /// **'Eksik'**
  String get petDetailQrVaccinePartial;

  /// No description provided for @petDetailQrIdCopied.
  ///
  /// In tr, this message translates to:
  /// **'ID panoya kopyalandı'**
  String get petDetailQrIdCopied;

  /// No description provided for @petDetailErrMsgLogin.
  ///
  /// In tr, this message translates to:
  /// **'Mesaj göndermek için giriş yapmalısınız.'**
  String get petDetailErrMsgLogin;

  /// No description provided for @petDetailErrOwnerNotFound.
  ///
  /// In tr, this message translates to:
  /// **'İlan sahibi bilgisi bulunamadı.'**
  String get petDetailErrOwnerNotFound;

  /// No description provided for @petDetailErrSelfMessage.
  ///
  /// In tr, this message translates to:
  /// **'Kendi ilanınıza mesaj gönderemezsiniz.'**
  String get petDetailErrSelfMessage;

  /// No description provided for @petDetailErrMatingLogin.
  ///
  /// In tr, this message translates to:
  /// **'Eşleştirme isteği göndermek için giriş yapmalısınız.'**
  String get petDetailErrMatingLogin;

  /// No description provided for @petDetailNoPetDialog.
  ///
  /// In tr, this message translates to:
  /// **'İlan Gerekli'**
  String get petDetailNoPetDialog;

  /// No description provided for @petDetailNoPetContent.
  ///
  /// In tr, this message translates to:
  /// **'Eşleştirme isteği göndermek için önce bir eşleştirme ilanı oluşturmalısınız.'**
  String get petDetailNoPetContent;

  /// No description provided for @petDetailCreateListing.
  ///
  /// In tr, this message translates to:
  /// **'İlan Oluştur'**
  String get petDetailCreateListing;

  /// No description provided for @petDetailSameSpeciesTitle.
  ///
  /// In tr, this message translates to:
  /// **'Aynı Tür Gerekli'**
  String get petDetailSameSpeciesTitle;

  /// No description provided for @petDetailSameSpeciesContent.
  ///
  /// In tr, this message translates to:
  /// **'Bu ilan \"{species}\" türünde. Eşleştirme isteği gönderebilmek için aynı türden bir ilanınız olmalı.'**
  String petDetailSameSpeciesContent(String species);

  /// No description provided for @petDetailMatingGenericError.
  ///
  /// In tr, this message translates to:
  /// **'Eşleştirme isteği gönderilemedi: {error}'**
  String petDetailMatingGenericError(String error);

  /// No description provided for @petDetailSuccessDialogTitle.
  ///
  /// In tr, this message translates to:
  /// **'İstek Gönderildi!'**
  String get petDetailSuccessDialogTitle;

  /// No description provided for @petDetailSuccessDialogMatch.
  ///
  /// In tr, this message translates to:
  /// **'Tebrikler! Karşılıklı eşleşme oluştu. Artık mesajlaşabilirsiniz.'**
  String get petDetailSuccessDialogMatch;

  /// No description provided for @petDetailSuccessDialogPending.
  ///
  /// In tr, this message translates to:
  /// **'Eşleştirme isteğiniz gönderildi. Karşı tarafın onayını bekliyorsunuz.'**
  String get petDetailSuccessDialogPending;

  /// No description provided for @petDetailSuccessDialogStartChat.
  ///
  /// In tr, this message translates to:
  /// **'Mesajlaşmaya Başla'**
  String get petDetailSuccessDialogStartChat;

  /// No description provided for @petDetailSelectPetTitle.
  ///
  /// In tr, this message translates to:
  /// **'Hayvanınızı Seçin'**
  String get petDetailSelectPetTitle;

  /// No description provided for @petDetailSelectPetSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Eşleştirme için {species} türünden seçim yapın'**
  String petDetailSelectPetSubtitle(String species);

  /// No description provided for @chatDeleteTitle.
  ///
  /// In tr, this message translates to:
  /// **'Sohbeti sil'**
  String get chatDeleteTitle;

  /// No description provided for @chatDeleteContent.
  ///
  /// In tr, this message translates to:
  /// **'Bu sohbeti kalıcı olarak silmek istediğinizden emin misiniz? Bu işlem geri alınamaz.'**
  String get chatDeleteContent;

  /// No description provided for @chatDeleteError.
  ///
  /// In tr, this message translates to:
  /// **'Sohbet silinemedi: {error}'**
  String chatDeleteError(String error);

  /// No description provided for @chatRefresh.
  ///
  /// In tr, this message translates to:
  /// **'Sohbeti yenile'**
  String get chatRefresh;

  /// No description provided for @chatNotifPrefs.
  ///
  /// In tr, this message translates to:
  /// **'Bildirim tercihleri'**
  String get chatNotifPrefs;

  /// No description provided for @chatNotifPrefsSub.
  ///
  /// In tr, this message translates to:
  /// **'Ayarlar > Bildirimler bölümünden yönetebilirsin'**
  String get chatNotifPrefsSub;

  /// No description provided for @chatNotifPrefsInfo.
  ///
  /// In tr, this message translates to:
  /// **'Bildirim tercihlerini ayarlar ekranından düzenleyebilirsin.'**
  String get chatNotifPrefsInfo;

  /// No description provided for @chatDeleteFromList.
  ///
  /// In tr, this message translates to:
  /// **'Sohbeti listeden sil'**
  String get chatDeleteFromList;

  /// No description provided for @chatDeleteFromListSub.
  ///
  /// In tr, this message translates to:
  /// **'Sohbetler ekranından da silebilirsin.'**
  String get chatDeleteFromListSub;

  /// No description provided for @chatBlockReport.
  ///
  /// In tr, this message translates to:
  /// **'Engelle / Şikayet Et'**
  String get chatBlockReport;

  /// No description provided for @chatSelectFromGallery.
  ///
  /// In tr, this message translates to:
  /// **'Galeriden Seç'**
  String get chatSelectFromGallery;

  /// No description provided for @chatSelectFromGallerySub.
  ///
  /// In tr, this message translates to:
  /// **'Fotoğraf galerinizden seçin'**
  String get chatSelectFromGallerySub;

  /// No description provided for @chatCamera.
  ///
  /// In tr, this message translates to:
  /// **'Kamera'**
  String get chatCamera;

  /// No description provided for @chatCameraSub.
  ///
  /// In tr, this message translates to:
  /// **'Yeni fotoğraf çekin'**
  String get chatCameraSub;

  /// No description provided for @chatMsgHint.
  ///
  /// In tr, this message translates to:
  /// **'Mesajını yaz...'**
  String get chatMsgHint;

  /// No description provided for @chatSearchHint.
  ///
  /// In tr, this message translates to:
  /// **'Mesajlarda ara...'**
  String get chatSearchHint;

  /// No description provided for @chatErrMicPermission.
  ///
  /// In tr, this message translates to:
  /// **'Mikrofon izni gerekli.'**
  String get chatErrMicPermission;

  /// No description provided for @chatErrRecordStart.
  ///
  /// In tr, this message translates to:
  /// **'Kayıt başlatılamadı: {error}'**
  String chatErrRecordStart(String error);

  /// No description provided for @chatErrAudioSend.
  ///
  /// In tr, this message translates to:
  /// **'Ses gönderilemedi: {error}'**
  String chatErrAudioSend(String error);

  /// No description provided for @chatErrImagePick.
  ///
  /// In tr, this message translates to:
  /// **'Resim seçilemedi: {error}'**
  String chatErrImagePick(String error);

  /// No description provided for @chatErrImageSend.
  ///
  /// In tr, this message translates to:
  /// **'Resim gönderilemedi: {error}'**
  String chatErrImageSend(String error);

  /// No description provided for @chatErrLoginRequired.
  ///
  /// In tr, this message translates to:
  /// **'Mesaj göndermek için giriş yapmalısınız.'**
  String get chatErrLoginRequired;

  /// No description provided for @chatErrLoginRequiredImage.
  ///
  /// In tr, this message translates to:
  /// **'Resim göndermek için giriş yapmalısınız.'**
  String get chatErrLoginRequiredImage;

  /// No description provided for @chatErrMsgSend.
  ///
  /// In tr, this message translates to:
  /// **'Mesaj gönderilemedi: {error}'**
  String chatErrMsgSend(String error);

  /// No description provided for @chatErrMsgDelete.
  ///
  /// In tr, this message translates to:
  /// **'Mesaj silinemedi: {error}'**
  String chatErrMsgDelete(String error);

  /// No description provided for @chatErrReaction.
  ///
  /// In tr, this message translates to:
  /// **'Reaksiyon gonderilemedi: {error}'**
  String chatErrReaction(String error);

  /// No description provided for @chatMsgDeletedSelf.
  ///
  /// In tr, this message translates to:
  /// **'Bu mesajı sildiniz'**
  String get chatMsgDeletedSelf;

  /// No description provided for @chatDeleteMsgForMe.
  ///
  /// In tr, this message translates to:
  /// **'Bu mesajı kendimden sil'**
  String get chatDeleteMsgForMe;

  /// No description provided for @chatCopyMsg.
  ///
  /// In tr, this message translates to:
  /// **'Kopyala'**
  String get chatCopyMsg;

  /// No description provided for @chatAudioMsg.
  ///
  /// In tr, this message translates to:
  /// **'[Ses Mesajı]'**
  String get chatAudioMsg;

  /// No description provided for @chatSearchNoResults.
  ///
  /// In tr, this message translates to:
  /// **'\"{query}\" için sonuç bulunamadı'**
  String chatSearchNoResults(String query);

  /// No description provided for @chatTooltipBack.
  ///
  /// In tr, this message translates to:
  /// **'Geri'**
  String get chatTooltipBack;

  /// No description provided for @chatTooltipSearch.
  ///
  /// In tr, this message translates to:
  /// **'Mesajlarda Ara'**
  String get chatTooltipSearch;

  /// No description provided for @chatTooltipCloseSearch.
  ///
  /// In tr, this message translates to:
  /// **'Aramayı Kapat'**
  String get chatTooltipCloseSearch;

  /// No description provided for @chatTypeMatching.
  ///
  /// In tr, this message translates to:
  /// **'Eşleştirme sohbeti'**
  String get chatTypeMatching;

  /// No description provided for @chatTypeAdoption.
  ///
  /// In tr, this message translates to:
  /// **'Sahiplendirme sohbeti'**
  String get chatTypeAdoption;

  /// No description provided for @chatTypeGeneral.
  ///
  /// In tr, this message translates to:
  /// **'Sohbet'**
  String get chatTypeGeneral;

  /// No description provided for @ordersTitle.
  ///
  /// In tr, this message translates to:
  /// **'Siparişlerim'**
  String get ordersTitle;

  /// No description provided for @ordersEmpty.
  ///
  /// In tr, this message translates to:
  /// **'Henüz siparişiniz yok'**
  String get ordersEmpty;

  /// No description provided for @ordersEmptyDesc.
  ///
  /// In tr, this message translates to:
  /// **'Mağazadan alışveriş yaparak başlayın'**
  String get ordersEmptyDesc;

  /// No description provided for @orderStatusPending.
  ///
  /// In tr, this message translates to:
  /// **'Onay Bekliyor'**
  String get orderStatusPending;

  /// No description provided for @orderStatusProcessing.
  ///
  /// In tr, this message translates to:
  /// **'Hazırlanıyor'**
  String get orderStatusProcessing;

  /// No description provided for @orderStatusShipped.
  ///
  /// In tr, this message translates to:
  /// **'Kargoya Verildi'**
  String get orderStatusShipped;

  /// No description provided for @orderStatusDelivered.
  ///
  /// In tr, this message translates to:
  /// **'Teslim Edildi'**
  String get orderStatusDelivered;

  /// No description provided for @orderStatusCancelled.
  ///
  /// In tr, this message translates to:
  /// **'İptal Edildi'**
  String get orderStatusCancelled;

  /// No description provided for @orderCancelTitle.
  ///
  /// In tr, this message translates to:
  /// **'Siparişi İptal Et'**
  String get orderCancelTitle;

  /// No description provided for @orderCancelContent.
  ///
  /// In tr, this message translates to:
  /// **'Bu siparişi iptal etmek istediğinize emin misiniz?'**
  String get orderCancelContent;

  /// No description provided for @orderCancelAction.
  ///
  /// In tr, this message translates to:
  /// **'İptal Et'**
  String get orderCancelAction;

  /// No description provided for @orderCancelSuccess.
  ///
  /// In tr, this message translates to:
  /// **'Sipariş iptal edildi'**
  String get orderCancelSuccess;

  /// No description provided for @orderCancelError.
  ///
  /// In tr, this message translates to:
  /// **'İptal edilemedi: {error}'**
  String orderCancelError(String error);

  /// No description provided for @orderNumber.
  ///
  /// In tr, this message translates to:
  /// **'Sipariş #{id}'**
  String orderNumber(String id);

  /// No description provided for @orderItemCount.
  ///
  /// In tr, this message translates to:
  /// **'{count} ürün'**
  String orderItemCount(int count);

  /// No description provided for @orderItemQty.
  ///
  /// In tr, this message translates to:
  /// **'{qty} adet x ₺{price}'**
  String orderItemQty(int qty, String price);

  /// No description provided for @orderProducts.
  ///
  /// In tr, this message translates to:
  /// **'Ürünler'**
  String get orderProducts;

  /// No description provided for @orderTrackingInfo.
  ///
  /// In tr, this message translates to:
  /// **'Kargo Takip Bilgisi'**
  String get orderTrackingInfo;

  /// No description provided for @orderTrackingCopied.
  ///
  /// In tr, this message translates to:
  /// **'Takip no kopyalandı: {no}'**
  String orderTrackingCopied(String no);

  /// No description provided for @orderMyOrdersTitle.
  ///
  /// In tr, this message translates to:
  /// **'Siparişlerim'**
  String get orderMyOrdersTitle;

  /// No description provided for @orderNoOrders.
  ///
  /// In tr, this message translates to:
  /// **'Henüz siparişiniz yok'**
  String get orderNoOrders;

  /// No description provided for @orderNoOrdersDesc.
  ///
  /// In tr, this message translates to:
  /// **'Mağazadan alışveriş yaparak başlayın'**
  String get orderNoOrdersDesc;

  /// No description provided for @orderLoadErr.
  ///
  /// In tr, this message translates to:
  /// **'Hata: {error}'**
  String orderLoadErr(String error);

  /// No description provided for @orderDeliveryAddress.
  ///
  /// In tr, this message translates to:
  /// **'Teslimat Adresi'**
  String get orderDeliveryAddress;

  /// No description provided for @orderReview.
  ///
  /// In tr, this message translates to:
  /// **'Değerlendir'**
  String get orderReview;

  /// No description provided for @copyTooltip.
  ///
  /// In tr, this message translates to:
  /// **'Kopyala'**
  String get copyTooltip;

  /// No description provided for @orderMyRating.
  ///
  /// In tr, this message translates to:
  /// **'Puanınız: {rating}'**
  String orderMyRating(int rating);

  /// No description provided for @nearbyTitle.
  ///
  /// In tr, this message translates to:
  /// **'Yakınımdaki İlanlar'**
  String get nearbyTitle;

  /// No description provided for @nearbyLocating.
  ///
  /// In tr, this message translates to:
  /// **'Konum alınıyor...'**
  String get nearbyLocating;

  /// No description provided for @nearbyNoResults.
  ///
  /// In tr, this message translates to:
  /// **'Bu bölgede ilan bulunamadı'**
  String get nearbyNoResults;

  /// No description provided for @nearbyExpandArea.
  ///
  /// In tr, this message translates to:
  /// **'Alanı genişlet (50 km)'**
  String get nearbyExpandArea;

  /// No description provided for @nearbyShown.
  ///
  /// In tr, this message translates to:
  /// **'{count} ilan gösterildi'**
  String nearbyShown(int count);

  /// No description provided for @nearbyActiveFilters.
  ///
  /// In tr, this message translates to:
  /// **'{count} filtre aktif'**
  String nearbyActiveFilters(int count);

  /// No description provided for @nearbyClearFilters.
  ///
  /// In tr, this message translates to:
  /// **'Temizle'**
  String get nearbyClearFilters;

  /// No description provided for @nearbyErrLocationService.
  ///
  /// In tr, this message translates to:
  /// **'Konum servisi kapalı. Lütfen ayarlardan açın.'**
  String get nearbyErrLocationService;

  /// No description provided for @nearbyErrPermDeniedForever.
  ///
  /// In tr, this message translates to:
  /// **'Konum izni kalıcı olarak reddedildi. Uygulama ayarlarından izin verin.'**
  String get nearbyErrPermDeniedForever;

  /// No description provided for @nearbyErrPermDenied.
  ///
  /// In tr, this message translates to:
  /// **'Konum izni gerekli. Lütfen tekrar deneyin.'**
  String get nearbyErrPermDenied;

  /// No description provided for @nearbyErrTimeout.
  ///
  /// In tr, this message translates to:
  /// **'Konum alınamadı: zaman aşımı. Lütfen tekrar deneyin.'**
  String get nearbyErrTimeout;

  /// No description provided for @nearbyErrPermRequired.
  ///
  /// In tr, this message translates to:
  /// **'Konum izni gerekli. Lütfen ayarlardan izin verin.'**
  String get nearbyErrPermRequired;

  /// No description provided for @nearbyErrGeneric.
  ///
  /// In tr, this message translates to:
  /// **'Konum alınamadı. Lütfen tekrar deneyin.'**
  String get nearbyErrGeneric;

  /// No description provided for @nearbyOpenLocationSettings.
  ///
  /// In tr, this message translates to:
  /// **'Konum Ayarlarını Aç'**
  String get nearbyOpenLocationSettings;

  /// No description provided for @nearbyOpenAppSettings.
  ///
  /// In tr, this message translates to:
  /// **'Uygulama Ayarlarını Aç'**
  String get nearbyOpenAppSettings;

  /// No description provided for @filterTitle.
  ///
  /// In tr, this message translates to:
  /// **'Filtrele'**
  String get filterTitle;

  /// No description provided for @filterReset.
  ///
  /// In tr, this message translates to:
  /// **'Sıfırla'**
  String get filterReset;

  /// No description provided for @filterAdvertType.
  ///
  /// In tr, this message translates to:
  /// **'İlan Türü'**
  String get filterAdvertType;

  /// No description provided for @filterAnimalType.
  ///
  /// In tr, this message translates to:
  /// **'Hayvan Türü'**
  String get filterAnimalType;

  /// No description provided for @filterBreed.
  ///
  /// In tr, this message translates to:
  /// **'Cins'**
  String get filterBreed;

  /// No description provided for @filterVaccine.
  ///
  /// In tr, this message translates to:
  /// **'Aşı Durumu'**
  String get filterVaccine;

  /// No description provided for @filterVaccineAny.
  ///
  /// In tr, this message translates to:
  /// **'Fark Etmez'**
  String get filterVaccineAny;

  /// No description provided for @filterVaccinated.
  ///
  /// In tr, this message translates to:
  /// **'Aşılı'**
  String get filterVaccinated;

  /// No description provided for @filterUnvaccinated.
  ///
  /// In tr, this message translates to:
  /// **'Aşısız'**
  String get filterUnvaccinated;

  /// No description provided for @filterApply.
  ///
  /// In tr, this message translates to:
  /// **'Uygula'**
  String get filterApply;

  /// No description provided for @filterAll.
  ///
  /// In tr, this message translates to:
  /// **'Tümü'**
  String get filterAll;

  /// No description provided for @profileLoginRequired.
  ///
  /// In tr, this message translates to:
  /// **'Profili görmek için giriş yapmalısınız.'**
  String get profileLoginRequired;

  /// No description provided for @profileDeleteTitle.
  ///
  /// In tr, this message translates to:
  /// **'İlanı Sil'**
  String get profileDeleteTitle;

  /// No description provided for @profileDeleteContent.
  ///
  /// In tr, this message translates to:
  /// **'Bu ilanı silmek istediğinizden emin misiniz? Bu işlem geri alınamaz.'**
  String get profileDeleteContent;

  /// No description provided for @profileDeleteSuccess.
  ///
  /// In tr, this message translates to:
  /// **'İlan başarıyla silindi.'**
  String get profileDeleteSuccess;

  /// No description provided for @profileLogoutTitle.
  ///
  /// In tr, this message translates to:
  /// **'Çıkış Yap'**
  String get profileLogoutTitle;

  /// No description provided for @profileLogoutContent.
  ///
  /// In tr, this message translates to:
  /// **'Hesabınızdan çıkmak istediğinizden emin misiniz?'**
  String get profileLogoutContent;

  /// No description provided for @profileAdoptionApplications.
  ///
  /// In tr, this message translates to:
  /// **'Sahiplendirme Başvuruları'**
  String get profileAdoptionApplications;

  /// No description provided for @profileNewAdoptionBtn.
  ///
  /// In tr, this message translates to:
  /// **'Sahiplendirme'**
  String get profileNewAdoptionBtn;

  /// No description provided for @profileNewMatingBtn.
  ///
  /// In tr, this message translates to:
  /// **'Eşleştirme'**
  String get profileNewMatingBtn;

  /// No description provided for @profileLoginBtn.
  ///
  /// In tr, this message translates to:
  /// **'Giriş Yap'**
  String get profileLoginBtn;

  /// No description provided for @profileFavorites.
  ///
  /// In tr, this message translates to:
  /// **'Favoriler'**
  String get profileFavorites;

  /// No description provided for @profileOrders.
  ///
  /// In tr, this message translates to:
  /// **'Siparişler'**
  String get profileOrders;

  /// No description provided for @profileSitterBtn.
  ///
  /// In tr, this message translates to:
  /// **'Sitter'**
  String get profileSitterBtn;

  /// No description provided for @profileNotifications.
  ///
  /// In tr, this message translates to:
  /// **'Bildirimler'**
  String get profileNotifications;

  /// No description provided for @profileMyStore.
  ///
  /// In tr, this message translates to:
  /// **'Mağazam'**
  String get profileMyStore;

  /// No description provided for @profileNoPetsTitle.
  ///
  /// In tr, this message translates to:
  /// **'Henüz ilan yok'**
  String get profileNoPetsTitle;

  /// No description provided for @profileNoPetsDesc.
  ///
  /// In tr, this message translates to:
  /// **'İlk ilanınızı oluşturarak topluluğa yeni bir dost kazandırabilirsiniz.'**
  String get profileNoPetsDesc;

  /// No description provided for @profileRoleSeller.
  ///
  /// In tr, this message translates to:
  /// **'Satıcı'**
  String get profileRoleSeller;

  /// No description provided for @profileRoleSitter.
  ///
  /// In tr, this message translates to:
  /// **'Sitter'**
  String get profileRoleSitter;

  /// No description provided for @profileRoleAdmin.
  ///
  /// In tr, this message translates to:
  /// **'Admin'**
  String get profileRoleAdmin;

  /// No description provided for @profileCompletePercent.
  ///
  /// In tr, this message translates to:
  /// **'Profili tamamla — {percent}%'**
  String profileCompletePercent(int percent);

  /// No description provided for @profileAuthErr.
  ///
  /// In tr, this message translates to:
  /// **'Oturum doğrulanamadı. Tekrar deneyin.'**
  String get profileAuthErr;

  /// No description provided for @profileAdsLoadErr.
  ///
  /// In tr, this message translates to:
  /// **'İlanlar yüklenemedi: {error}'**
  String profileAdsLoadErr(String error);

  /// No description provided for @cartTitle.
  ///
  /// In tr, this message translates to:
  /// **'Sepetim'**
  String get cartTitle;

  /// No description provided for @cartClearAction.
  ///
  /// In tr, this message translates to:
  /// **'Boşalt'**
  String get cartClearAction;

  /// No description provided for @cartClearTitle.
  ///
  /// In tr, this message translates to:
  /// **'Sepeti Boşalt'**
  String get cartClearTitle;

  /// No description provided for @cartClearContent.
  ///
  /// In tr, this message translates to:
  /// **'Sepetteki tüm ürünler silinecek. Emin misiniz?'**
  String get cartClearContent;

  /// No description provided for @cartItemRemoved.
  ///
  /// In tr, this message translates to:
  /// **'Ürün sepetten çıkarıldı'**
  String get cartItemRemoved;

  /// No description provided for @cartItemRemoveError.
  ///
  /// In tr, this message translates to:
  /// **'Ürün çıkarılamadı: {error}'**
  String cartItemRemoveError(String error);

  /// No description provided for @cartUpdateError.
  ///
  /// In tr, this message translates to:
  /// **'Miktar güncellenemedi: {error}'**
  String cartUpdateError(String error);

  /// No description provided for @cartCleared.
  ///
  /// In tr, this message translates to:
  /// **'Sepet boşaltıldı'**
  String get cartCleared;

  /// No description provided for @cartClearError.
  ///
  /// In tr, this message translates to:
  /// **'Sepet boşaltılamadı: {error}'**
  String cartClearError(String error);

  /// No description provided for @cartEmptyTitle.
  ///
  /// In tr, this message translates to:
  /// **'Sepetiniz Boş'**
  String get cartEmptyTitle;

  /// No description provided for @cartEmptyDesc.
  ///
  /// In tr, this message translates to:
  /// **'Henüz sepetinize ürün eklemediniz.\nAlışverişe başlamak için mağazayı keşfedin!'**
  String get cartEmptyDesc;

  /// No description provided for @cartShopNow.
  ///
  /// In tr, this message translates to:
  /// **'Alışverişe Başla'**
  String get cartShopNow;

  /// No description provided for @cartContinueShopping.
  ///
  /// In tr, this message translates to:
  /// **'Alışverişe Devam'**
  String get cartContinueShopping;

  /// No description provided for @cartCheckout.
  ///
  /// In tr, this message translates to:
  /// **'Ödemeye Geç'**
  String get cartCheckout;

  /// No description provided for @cartItemCount.
  ///
  /// In tr, this message translates to:
  /// **'Ürün Sayısı'**
  String get cartItemCount;

  /// No description provided for @cartTotalAmount.
  ///
  /// In tr, this message translates to:
  /// **'Toplam Tutar'**
  String get cartTotalAmount;

  /// No description provided for @cartItemTotal.
  ///
  /// In tr, this message translates to:
  /// **'Toplam: {total} ₺'**
  String cartItemTotal(String total);

  /// No description provided for @cartLoadError.
  ///
  /// In tr, this message translates to:
  /// **'Sepet yüklenemedi'**
  String get cartLoadError;

  /// No description provided for @cartRetry.
  ///
  /// In tr, this message translates to:
  /// **'Yeniden Dene'**
  String get cartRetry;

  /// No description provided for @sellerPanelTitle.
  ///
  /// In tr, this message translates to:
  /// **'Satıcı Paneli'**
  String get sellerPanelTitle;

  /// No description provided for @sellerBecomeSeller.
  ///
  /// In tr, this message translates to:
  /// **'Satıcı Ol'**
  String get sellerBecomeSeller;

  /// No description provided for @sellerBecomeSellerDesc.
  ///
  /// In tr, this message translates to:
  /// **'Bu sayfayı görmek için satıcı olmanız gerekiyor'**
  String get sellerBecomeSellerDesc;

  /// No description provided for @sellerStoreLoadErr.
  ///
  /// In tr, this message translates to:
  /// **'Mağaza bilgileri yüklenemedi'**
  String get sellerStoreLoadErr;

  /// No description provided for @sellerOrderStatsLoadErr.
  ///
  /// In tr, this message translates to:
  /// **'Sipariş istatistikleri yüklenemedi'**
  String get sellerOrderStatsLoadErr;

  /// No description provided for @sellerProductStatsLoadErr.
  ///
  /// In tr, this message translates to:
  /// **'Ürün istatistikleri yüklenemedi'**
  String get sellerProductStatsLoadErr;

  /// No description provided for @sellerRevenueChartLoadErr.
  ///
  /// In tr, this message translates to:
  /// **'Gelir grafiği yüklenemedi'**
  String get sellerRevenueChartLoadErr;

  /// No description provided for @sellerAttentionProducts.
  ///
  /// In tr, this message translates to:
  /// **'Dikkat Gerektiren Ürünler'**
  String get sellerAttentionProducts;

  /// No description provided for @sellerOutOfStock.
  ///
  /// In tr, this message translates to:
  /// **'Stokta Yok'**
  String get sellerOutOfStock;

  /// No description provided for @sellerLowStock.
  ///
  /// In tr, this message translates to:
  /// **'Düşük Stok'**
  String get sellerLowStock;

  /// No description provided for @sellerNoStore.
  ///
  /// In tr, this message translates to:
  /// **'Mağazanız Yok'**
  String get sellerNoStore;

  /// No description provided for @sellerNoStoreDesc.
  ///
  /// In tr, this message translates to:
  /// **'Ürün satmaya başlamak için önce mağazanızı oluşturun'**
  String get sellerNoStoreDesc;

  /// No description provided for @sellerCreateStore.
  ///
  /// In tr, this message translates to:
  /// **'Mağaza Oluştur'**
  String get sellerCreateStore;

  /// No description provided for @sellerActiveStore.
  ///
  /// In tr, this message translates to:
  /// **'Aktif Mağaza'**
  String get sellerActiveStore;

  /// No description provided for @sellerTotalRevenue.
  ///
  /// In tr, this message translates to:
  /// **'Toplam Gelir'**
  String get sellerTotalRevenue;

  /// No description provided for @sellerPendingOrders.
  ///
  /// In tr, this message translates to:
  /// **'Bekleyen'**
  String get sellerPendingOrders;

  /// No description provided for @sellerTotalOrdersCount.
  ///
  /// In tr, this message translates to:
  /// **'{count} toplam'**
  String sellerTotalOrdersCount(int count);

  /// No description provided for @sellerTotalProducts.
  ///
  /// In tr, this message translates to:
  /// **'Toplam Ürün'**
  String get sellerTotalProducts;

  /// No description provided for @sellerQuickActions.
  ///
  /// In tr, this message translates to:
  /// **'Hızlı İşlemler'**
  String get sellerQuickActions;

  /// No description provided for @sellerAddProduct.
  ///
  /// In tr, this message translates to:
  /// **'Ürün Ekle'**
  String get sellerAddProduct;

  /// No description provided for @sellerManageProducts.
  ///
  /// In tr, this message translates to:
  /// **'Ürünlerimi Yönet'**
  String get sellerManageProducts;

  /// No description provided for @sellerViewStore.
  ///
  /// In tr, this message translates to:
  /// **'Mağazamı Gör'**
  String get sellerViewStore;

  /// No description provided for @sellerMyOrders.
  ///
  /// In tr, this message translates to:
  /// **'Siparişlerim'**
  String get sellerMyOrders;

  /// No description provided for @sellerDemoProducts.
  ///
  /// In tr, this message translates to:
  /// **'Demo Ürünler Ekle'**
  String get sellerDemoProducts;

  /// No description provided for @sellerDemoProductsLoading.
  ///
  /// In tr, this message translates to:
  /// **'Demo Ürünler Ekleniyor...'**
  String get sellerDemoProductsLoading;

  /// No description provided for @sellerDemoProductsTitle.
  ///
  /// In tr, this message translates to:
  /// **'Demo Ürünler Ekle'**
  String get sellerDemoProductsTitle;

  /// No description provided for @sellerDemoProductsContent.
  ///
  /// In tr, this message translates to:
  /// **'Bu işlem mağazanızdaki tüm ürünleri silip yerine demo ürünler ekleyecektir. Devam etmek istiyor musunuz?'**
  String get sellerDemoProductsContent;

  /// No description provided for @sellerDemoProductsContinue.
  ///
  /// In tr, this message translates to:
  /// **'Devam Et'**
  String get sellerDemoProductsContinue;

  /// No description provided for @sellerDemoProductsAdded.
  ///
  /// In tr, this message translates to:
  /// **'{count} demo ürün başarıyla eklendi!'**
  String sellerDemoProductsAdded(int count);

  /// No description provided for @sellerErrGeneric.
  ///
  /// In tr, this message translates to:
  /// **'Hata: {error}'**
  String sellerErrGeneric(String error);

  /// No description provided for @sellerLast6Months.
  ///
  /// In tr, this message translates to:
  /// **'Son 6 Ay'**
  String get sellerLast6Months;

  /// No description provided for @sellerChartRevenue.
  ///
  /// In tr, this message translates to:
  /// **'Gelir'**
  String get sellerChartRevenue;

  /// No description provided for @sellerChartOrders.
  ///
  /// In tr, this message translates to:
  /// **'Sipariş'**
  String get sellerChartOrders;

  /// No description provided for @sellerStockLabel.
  ///
  /// In tr, this message translates to:
  /// **'Stok: {count}'**
  String sellerStockLabel(int count);

  /// No description provided for @sellerOrderCountTooltip.
  ///
  /// In tr, this message translates to:
  /// **'{count} sipariş'**
  String sellerOrderCountTooltip(int count);

  /// No description provided for @sellerRetry.
  ///
  /// In tr, this message translates to:
  /// **'Yenile'**
  String get sellerRetry;

  /// No description provided for @productMgmtTitle.
  ///
  /// In tr, this message translates to:
  /// **'Ürün Yönetimi'**
  String get productMgmtTitle;

  /// No description provided for @productMgmtAll.
  ///
  /// In tr, this message translates to:
  /// **'Tümü'**
  String get productMgmtAll;

  /// No description provided for @productMgmtActive.
  ///
  /// In tr, this message translates to:
  /// **'Aktif'**
  String get productMgmtActive;

  /// No description provided for @productMgmtInactive.
  ///
  /// In tr, this message translates to:
  /// **'Pasif'**
  String get productMgmtInactive;

  /// No description provided for @productMgmtLowStock.
  ///
  /// In tr, this message translates to:
  /// **'Düşük Stok'**
  String get productMgmtLowStock;

  /// No description provided for @productMgmtOutOfStock.
  ///
  /// In tr, this message translates to:
  /// **'Stokta Yok'**
  String get productMgmtOutOfStock;

  /// No description provided for @productMgmtNoProducts.
  ///
  /// In tr, this message translates to:
  /// **'Henüz ürün eklenmemiş'**
  String get productMgmtNoProducts;

  /// No description provided for @productMgmtNoCategoryProducts.
  ///
  /// In tr, this message translates to:
  /// **'Bu kategoride ürün yok'**
  String get productMgmtNoCategoryProducts;

  /// No description provided for @productMgmtAddFirst.
  ///
  /// In tr, this message translates to:
  /// **'İlk Ürünü Ekle'**
  String get productMgmtAddFirst;

  /// No description provided for @productMgmtAddProduct.
  ///
  /// In tr, this message translates to:
  /// **'Ürün Ekle'**
  String get productMgmtAddProduct;

  /// No description provided for @productMgmtLoadErr.
  ///
  /// In tr, this message translates to:
  /// **'Ürünler yüklenemedi'**
  String get productMgmtLoadErr;

  /// No description provided for @productMgmtStatusActive.
  ///
  /// In tr, this message translates to:
  /// **'Aktif'**
  String get productMgmtStatusActive;

  /// No description provided for @productMgmtStatusInactive.
  ///
  /// In tr, this message translates to:
  /// **'Pasif'**
  String get productMgmtStatusInactive;

  /// No description provided for @productMgmtStock.
  ///
  /// In tr, this message translates to:
  /// **'Stok: {count}'**
  String productMgmtStock(int count);

  /// No description provided for @productMgmtStockOutBadge.
  ///
  /// In tr, this message translates to:
  /// **'Stokta Yok'**
  String get productMgmtStockOutBadge;

  /// No description provided for @productMgmtStockLowBadge.
  ///
  /// In tr, this message translates to:
  /// **'Düşük'**
  String get productMgmtStockLowBadge;

  /// No description provided for @productMgmtDeactivate.
  ///
  /// In tr, this message translates to:
  /// **'Pasif Yap'**
  String get productMgmtDeactivate;

  /// No description provided for @productMgmtActivate.
  ///
  /// In tr, this message translates to:
  /// **'Aktif Yap'**
  String get productMgmtActivate;

  /// No description provided for @productMgmtStockAction.
  ///
  /// In tr, this message translates to:
  /// **'Stok'**
  String get productMgmtStockAction;

  /// No description provided for @productMgmtEditAction.
  ///
  /// In tr, this message translates to:
  /// **'Düzenle'**
  String get productMgmtEditAction;

  /// No description provided for @productMgmtDeleteAction.
  ///
  /// In tr, this message translates to:
  /// **'Sil'**
  String get productMgmtDeleteAction;

  /// No description provided for @productMgmtToggleDeactivated.
  ///
  /// In tr, this message translates to:
  /// **'Ürün pasif yapıldı'**
  String get productMgmtToggleDeactivated;

  /// No description provided for @productMgmtToggleActivated.
  ///
  /// In tr, this message translates to:
  /// **'Ürün aktif yapıldı'**
  String get productMgmtToggleActivated;

  /// No description provided for @productMgmtStockUpdated.
  ///
  /// In tr, this message translates to:
  /// **'Stok güncellendi'**
  String get productMgmtStockUpdated;

  /// No description provided for @productMgmtEditSoon.
  ///
  /// In tr, this message translates to:
  /// **'Ürün düzenleme yakında eklenecek'**
  String get productMgmtEditSoon;

  /// No description provided for @productMgmtDeleteTitle.
  ///
  /// In tr, this message translates to:
  /// **'Ürünü Sil'**
  String get productMgmtDeleteTitle;

  /// No description provided for @productMgmtDeleteContent.
  ///
  /// In tr, this message translates to:
  /// **'\"{name}\" ürününü silmek istediğinizden emin misiniz?'**
  String productMgmtDeleteContent(String name);

  /// No description provided for @productMgmtDeleteWarning.
  ///
  /// In tr, this message translates to:
  /// **'Bu işlem geri alınamaz!'**
  String get productMgmtDeleteWarning;

  /// No description provided for @productMgmtDeleted.
  ///
  /// In tr, this message translates to:
  /// **'Ürün silindi'**
  String get productMgmtDeleted;

  /// No description provided for @productMgmtUpdateStockTitle.
  ///
  /// In tr, this message translates to:
  /// **'Stok Güncelle'**
  String get productMgmtUpdateStockTitle;

  /// No description provided for @productMgmtCurrentStock.
  ///
  /// In tr, this message translates to:
  /// **'Mevcut Stok'**
  String get productMgmtCurrentStock;

  /// No description provided for @productMgmtStockUnit.
  ///
  /// In tr, this message translates to:
  /// **'adet'**
  String get productMgmtStockUnit;

  /// No description provided for @productMgmtStockChange.
  ///
  /// In tr, this message translates to:
  /// **'Değiştir'**
  String get productMgmtStockChange;

  /// No description provided for @productMgmtStockIncrease.
  ///
  /// In tr, this message translates to:
  /// **'Arttır'**
  String get productMgmtStockIncrease;

  /// No description provided for @productMgmtStockDecrease.
  ///
  /// In tr, this message translates to:
  /// **'Azalt'**
  String get productMgmtStockDecrease;

  /// No description provided for @productMgmtNewStockAmt.
  ///
  /// In tr, this message translates to:
  /// **'Yeni Stok Miktarı'**
  String get productMgmtNewStockAmt;

  /// No description provided for @productMgmtAddAmt.
  ///
  /// In tr, this message translates to:
  /// **'Eklenecek Miktar'**
  String get productMgmtAddAmt;

  /// No description provided for @productMgmtSubtractAmt.
  ///
  /// In tr, this message translates to:
  /// **'Düşülecek Miktar'**
  String get productMgmtSubtractAmt;

  /// No description provided for @productMgmtEnterAmt.
  ///
  /// In tr, this message translates to:
  /// **'Miktar girin'**
  String get productMgmtEnterAmt;

  /// No description provided for @productMgmtUpdate.
  ///
  /// In tr, this message translates to:
  /// **'Güncelle'**
  String get productMgmtUpdate;

  /// No description provided for @matchReqNoRequests.
  ///
  /// In tr, this message translates to:
  /// **'Henüz istek yok.'**
  String get matchReqNoRequests;

  /// No description provided for @matchReqSenderLabel.
  ///
  /// In tr, this message translates to:
  /// **'Gönderen: {name}'**
  String matchReqSenderLabel(String name);

  /// No description provided for @matchReqReceiverLabel.
  ///
  /// In tr, this message translates to:
  /// **'Alıcı: {name}'**
  String matchReqReceiverLabel(String name);

  /// No description provided for @matchReqSenderPet.
  ///
  /// In tr, this message translates to:
  /// **'Gönderen peti: {name}'**
  String matchReqSenderPet(String name);

  /// No description provided for @matchReqSelectedPet.
  ///
  /// In tr, this message translates to:
  /// **'Seçilen petin: {name}'**
  String matchReqSelectedPet(String name);

  /// No description provided for @matchReqViewListing.
  ///
  /// In tr, this message translates to:
  /// **'Gönderen ilanını gör'**
  String get matchReqViewListing;

  /// No description provided for @matchReqActDone.
  ///
  /// In tr, this message translates to:
  /// **'İşlem tamamlandı: {action}'**
  String matchReqActDone(String action);

  /// No description provided for @matchReqMatchSuccess.
  ///
  /// In tr, this message translates to:
  /// **'Eşleşme başarılı! {name} ile sohbete yönlendiriliyorsunuz...'**
  String matchReqMatchSuccess(String name);

  /// No description provided for @matchReqGoNow.
  ///
  /// In tr, this message translates to:
  /// **'Şimdi Git'**
  String get matchReqGoNow;

  /// No description provided for @matchReqChatError.
  ///
  /// In tr, this message translates to:
  /// **'Sohbet açılamadı: {error}'**
  String matchReqChatError(String error);

  /// No description provided for @matchReqAccept.
  ///
  /// In tr, this message translates to:
  /// **'Kabul Et'**
  String get matchReqAccept;

  /// No description provided for @matchReqReject.
  ///
  /// In tr, this message translates to:
  /// **'Reddet'**
  String get matchReqReject;

  /// No description provided for @matchReqGoToChat.
  ///
  /// In tr, this message translates to:
  /// **'Sohbete git'**
  String get matchReqGoToChat;

  /// No description provided for @loginTitle.
  ///
  /// In tr, this message translates to:
  /// **'Giriş Yap'**
  String get loginTitle;

  /// No description provided for @loginEmailError.
  ///
  /// In tr, this message translates to:
  /// **'Geçerli e-posta girin'**
  String get loginEmailError;

  /// No description provided for @loginPasswordError.
  ///
  /// In tr, this message translates to:
  /// **'En az 6 karakter'**
  String get loginPasswordError;

  /// No description provided for @loginNoAccount.
  ///
  /// In tr, this message translates to:
  /// **'Hesabın yok mu?'**
  String get loginNoAccount;

  /// No description provided for @registerTitle.
  ///
  /// In tr, this message translates to:
  /// **'Hesap Oluştur'**
  String get registerTitle;

  /// No description provided for @registerNameError.
  ///
  /// In tr, this message translates to:
  /// **'Ad gerekli'**
  String get registerNameError;

  /// No description provided for @registerPasswordConfirmHint.
  ///
  /// In tr, this message translates to:
  /// **'Şifre Tekrar'**
  String get registerPasswordConfirmHint;

  /// No description provided for @registerPasswordMismatch.
  ///
  /// In tr, this message translates to:
  /// **'Şifreler eşleşmiyor'**
  String get registerPasswordMismatch;

  /// No description provided for @registerHasAccount.
  ///
  /// In tr, this message translates to:
  /// **'Zaten hesabın var mı?'**
  String get registerHasAccount;

  /// No description provided for @forgotTitle.
  ///
  /// In tr, this message translates to:
  /// **'Şifremi Unuttum'**
  String get forgotTitle;

  /// No description provided for @forgotDesc.
  ///
  /// In tr, this message translates to:
  /// **'Şifrenizi sıfırlamak için e-posta adresinizi girin.'**
  String get forgotDesc;

  /// No description provided for @forgotSubmit.
  ///
  /// In tr, this message translates to:
  /// **'Kod Gönder'**
  String get forgotSubmit;

  /// No description provided for @forgotSuccessTitle.
  ///
  /// In tr, this message translates to:
  /// **'E-posta Gönderildi!'**
  String get forgotSuccessTitle;

  /// No description provided for @forgotSuccessDesc.
  ///
  /// In tr, this message translates to:
  /// **'{email} adresine şifre sıfırlama kodu gönderdik.'**
  String forgotSuccessDesc(String email);

  /// No description provided for @forgotEnterCode.
  ///
  /// In tr, this message translates to:
  /// **'Kodu Gir'**
  String get forgotEnterCode;

  /// No description provided for @resetTitle.
  ///
  /// In tr, this message translates to:
  /// **'Şifre Sıfırla'**
  String get resetTitle;

  /// No description provided for @resetDesc.
  ///
  /// In tr, this message translates to:
  /// **'{email} adresine gönderilen kodu girin.'**
  String resetDesc(String email);

  /// No description provided for @resetCodeHint.
  ///
  /// In tr, this message translates to:
  /// **'Doğrulama Kodu'**
  String get resetCodeHint;

  /// No description provided for @resetCodeError.
  ///
  /// In tr, this message translates to:
  /// **'Kod gerekli'**
  String get resetCodeError;

  /// No description provided for @resetNewPasswordHint.
  ///
  /// In tr, this message translates to:
  /// **'Yeni Şifre'**
  String get resetNewPasswordHint;

  /// No description provided for @resetPasswordError.
  ///
  /// In tr, this message translates to:
  /// **'En az 6 karakter'**
  String get resetPasswordError;

  /// No description provided for @resetSubmit.
  ///
  /// In tr, this message translates to:
  /// **'Şifreyi Sıfırla'**
  String get resetSubmit;

  /// No description provided for @resetSuccess.
  ///
  /// In tr, this message translates to:
  /// **'Şifreniz başarıyla sıfırlandı!'**
  String get resetSuccess;

  /// No description provided for @createPetEditTitle.
  ///
  /// In tr, this message translates to:
  /// **'İlanı Düzenle'**
  String get createPetEditTitle;

  /// No description provided for @createPetNewTitle.
  ///
  /// In tr, this message translates to:
  /// **'Yeni İlan'**
  String get createPetNewTitle;

  /// No description provided for @createPetUpdateDesc.
  ///
  /// In tr, this message translates to:
  /// **'İlan bilgilerini güncelle'**
  String get createPetUpdateDesc;

  /// No description provided for @createPetNewDesc.
  ///
  /// In tr, this message translates to:
  /// **'Yeni ilan oluştur'**
  String get createPetNewDesc;

  /// No description provided for @createPetHeroDesc.
  ///
  /// In tr, this message translates to:
  /// **'İlan tipini seç, fotoğraf/video ekle ve patili dostuna uygun evi bul.'**
  String get createPetHeroDesc;

  /// No description provided for @createPetAdoptionChip.
  ///
  /// In tr, this message translates to:
  /// **'Sahiplendirme ilanı'**
  String get createPetAdoptionChip;

  /// No description provided for @createPetMatingChip.
  ///
  /// In tr, this message translates to:
  /// **'Eşleştirme ilanı'**
  String get createPetMatingChip;

  /// No description provided for @createPetBasicInfo.
  ///
  /// In tr, this message translates to:
  /// **'Temel Bilgiler'**
  String get createPetBasicInfo;

  /// No description provided for @createPetNameLabel.
  ///
  /// In tr, this message translates to:
  /// **'İsim'**
  String get createPetNameLabel;

  /// No description provided for @createPetNameError.
  ///
  /// In tr, this message translates to:
  /// **'İsim zorunludur'**
  String get createPetNameError;

  /// No description provided for @createPetSpeciesLabel.
  ///
  /// In tr, this message translates to:
  /// **'Tür'**
  String get createPetSpeciesLabel;

  /// No description provided for @createPetGenderLabel.
  ///
  /// In tr, this message translates to:
  /// **'Cinsiyet'**
  String get createPetGenderLabel;

  /// No description provided for @createPetVaccinatedTitle.
  ///
  /// In tr, this message translates to:
  /// **'Aşıları tam'**
  String get createPetVaccinatedTitle;

  /// No description provided for @createPetVaccinatedSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Aşı bilgileri ilanda rozet olarak gösterilir.'**
  String get createPetVaccinatedSubtitle;

  /// No description provided for @createPetDetailsSection.
  ///
  /// In tr, this message translates to:
  /// **'Detaylar'**
  String get createPetDetailsSection;

  /// No description provided for @createPetAgeLabel.
  ///
  /// In tr, this message translates to:
  /// **'Yaş (Ay)'**
  String get createPetAgeLabel;

  /// No description provided for @createPetAgeError.
  ///
  /// In tr, this message translates to:
  /// **'Yaş zorunlu'**
  String get createPetAgeError;

  /// No description provided for @createPetAgeInvalidError.
  ///
  /// In tr, this message translates to:
  /// **'Geçerli bir sayı girin'**
  String get createPetAgeInvalidError;

  /// No description provided for @createPetBreedLabel.
  ///
  /// In tr, this message translates to:
  /// **'Cins'**
  String get createPetBreedLabel;

  /// No description provided for @createPetBreedSelect.
  ///
  /// In tr, this message translates to:
  /// **'Seçiniz'**
  String get createPetBreedSelect;

  /// No description provided for @createPetBreedSearch.
  ///
  /// In tr, this message translates to:
  /// **'Cins ara...'**
  String get createPetBreedSearch;

  /// No description provided for @createPetDescLabel.
  ///
  /// In tr, this message translates to:
  /// **'Açıklama'**
  String get createPetDescLabel;

  /// No description provided for @createPetDescHint.
  ///
  /// In tr, this message translates to:
  /// **'Karakteri, sağlık durumu ve ihtiyaçları'**
  String get createPetDescHint;

  /// No description provided for @createPetLocationSelected.
  ///
  /// In tr, this message translates to:
  /// **'Konum seçildi'**
  String get createPetLocationSelected;

  /// No description provided for @createPetLocationAdd.
  ///
  /// In tr, this message translates to:
  /// **'Konum ekle'**
  String get createPetLocationAdd;

  /// No description provided for @createPetLocationHint.
  ///
  /// In tr, this message translates to:
  /// **'İl/ilçe seçimi için haritayı aç'**
  String get createPetLocationHint;

  /// No description provided for @createPetMedia.
  ///
  /// In tr, this message translates to:
  /// **'Fotoğraf & Video'**
  String get createPetMedia;

  /// No description provided for @createPetAddPhotoBtn.
  ///
  /// In tr, this message translates to:
  /// **'Fotoğraf ekle'**
  String get createPetAddPhotoBtn;

  /// No description provided for @createPetAddVideoBtn.
  ///
  /// In tr, this message translates to:
  /// **'Video ekle'**
  String get createPetAddVideoBtn;

  /// No description provided for @createPetSave.
  ///
  /// In tr, this message translates to:
  /// **'Kaydet'**
  String get createPetSave;

  /// No description provided for @createPetPublish.
  ///
  /// In tr, this message translates to:
  /// **'Yayınla'**
  String get createPetPublish;

  /// No description provided for @shellOfflineBanner.
  ///
  /// In tr, this message translates to:
  /// **'İnternet bağlantısı yok'**
  String get shellOfflineBanner;

  /// No description provided for @shellReconnected.
  ///
  /// In tr, this message translates to:
  /// **'İnternet bağlantısı yeniden kuruldu'**
  String get shellReconnected;

  /// No description provided for @shellApptSnackView.
  ///
  /// In tr, this message translates to:
  /// **'Görüntüle'**
  String get shellApptSnackView;

  /// No description provided for @shellAdvertsNav.
  ///
  /// In tr, this message translates to:
  /// **'İlanlarım'**
  String get shellAdvertsNav;

  /// No description provided for @shellGuideFab.
  ///
  /// In tr, this message translates to:
  /// **'Rehber Pati'**
  String get shellGuideFab;

  /// No description provided for @addressEditTitle.
  ///
  /// In tr, this message translates to:
  /// **'Adresi Düzenle'**
  String get addressEditTitle;

  /// No description provided for @addressNewTitle.
  ///
  /// In tr, this message translates to:
  /// **'Yeni Adres'**
  String get addressNewTitle;

  /// No description provided for @addressUpdated.
  ///
  /// In tr, this message translates to:
  /// **'Adres güncellendi'**
  String get addressUpdated;

  /// No description provided for @addressAdded.
  ///
  /// In tr, this message translates to:
  /// **'Adres eklendi'**
  String get addressAdded;

  /// No description provided for @addressSaveErr.
  ///
  /// In tr, this message translates to:
  /// **'Hata: {error}'**
  String addressSaveErr(String error);

  /// No description provided for @addressInfoCard.
  ///
  /// In tr, this message translates to:
  /// **'Adres Bilgileri'**
  String get addressInfoCard;

  /// No description provided for @addressTitleLabel.
  ///
  /// In tr, this message translates to:
  /// **'Adres Başlığı'**
  String get addressTitleLabel;

  /// No description provided for @addressTitleHint.
  ///
  /// In tr, this message translates to:
  /// **'Ev, İş, vb.'**
  String get addressTitleHint;

  /// No description provided for @addressRecipientCard.
  ///
  /// In tr, this message translates to:
  /// **'Alıcı Bilgileri'**
  String get addressRecipientCard;

  /// No description provided for @addressFullName.
  ///
  /// In tr, this message translates to:
  /// **'Ad Soyad'**
  String get addressFullName;

  /// No description provided for @addressFullNameHint.
  ///
  /// In tr, this message translates to:
  /// **'Teslimat alacak kişi'**
  String get addressFullNameHint;

  /// No description provided for @addressPhone.
  ///
  /// In tr, this message translates to:
  /// **'Telefon'**
  String get addressPhone;

  /// No description provided for @addressDetailsCard.
  ///
  /// In tr, this message translates to:
  /// **'Adres Detayları'**
  String get addressDetailsCard;

  /// No description provided for @addressCity.
  ///
  /// In tr, this message translates to:
  /// **'İl'**
  String get addressCity;

  /// No description provided for @addressCityHint.
  ///
  /// In tr, this message translates to:
  /// **'İstanbul'**
  String get addressCityHint;

  /// No description provided for @addressDistrict.
  ///
  /// In tr, this message translates to:
  /// **'İlçe'**
  String get addressDistrict;

  /// No description provided for @addressDistrictHint.
  ///
  /// In tr, this message translates to:
  /// **'Kadıköy'**
  String get addressDistrictHint;

  /// No description provided for @addressNeighborhood.
  ///
  /// In tr, this message translates to:
  /// **'Mahalle'**
  String get addressNeighborhood;

  /// No description provided for @addressNeighborhoodHint.
  ///
  /// In tr, this message translates to:
  /// **'Mahalle adı'**
  String get addressNeighborhoodHint;

  /// No description provided for @addressStreet.
  ///
  /// In tr, this message translates to:
  /// **'Sokak/Cadde'**
  String get addressStreet;

  /// No description provided for @addressStreetHint.
  ///
  /// In tr, this message translates to:
  /// **'Sokak veya cadde adı'**
  String get addressStreetHint;

  /// No description provided for @addressBuildingNo.
  ///
  /// In tr, this message translates to:
  /// **'Bina No'**
  String get addressBuildingNo;

  /// No description provided for @addressFloor.
  ///
  /// In tr, this message translates to:
  /// **'Kat'**
  String get addressFloor;

  /// No description provided for @addressApartmentNo.
  ///
  /// In tr, this message translates to:
  /// **'Daire'**
  String get addressApartmentNo;

  /// No description provided for @addressPostalCode.
  ///
  /// In tr, this message translates to:
  /// **'Posta Kodu'**
  String get addressPostalCode;

  /// No description provided for @addressPreferencesCard.
  ///
  /// In tr, this message translates to:
  /// **'Tercihler'**
  String get addressPreferencesCard;

  /// No description provided for @addressSetDefault.
  ///
  /// In tr, this message translates to:
  /// **'Varsayılan adres olarak ayarla'**
  String get addressSetDefault;

  /// No description provided for @addressSetDefaultSub.
  ///
  /// In tr, this message translates to:
  /// **'Siparişlerde bu adres otomatik seçilir'**
  String get addressSetDefaultSub;

  /// No description provided for @addressUpdate.
  ///
  /// In tr, this message translates to:
  /// **'Güncelle'**
  String get addressUpdate;

  /// No description provided for @addressRequired.
  ///
  /// In tr, this message translates to:
  /// **'{field} zorunludur'**
  String addressRequired(String field);

  /// No description provided for @verifyTitle.
  ///
  /// In tr, this message translates to:
  /// **'E-posta Doğrula'**
  String get verifyTitle;

  /// No description provided for @verifyDesc.
  ///
  /// In tr, this message translates to:
  /// **'{email} adresine bir doğrulama kodu gönderdik.'**
  String verifyDesc(String email);

  /// No description provided for @verifyCodeLabel.
  ///
  /// In tr, this message translates to:
  /// **'Doğrulama Kodu'**
  String get verifyCodeLabel;

  /// No description provided for @verifySubmit.
  ///
  /// In tr, this message translates to:
  /// **'Doğrula'**
  String get verifySubmit;

  /// No description provided for @verifySuccess.
  ///
  /// In tr, this message translates to:
  /// **'E-posta doğrulandı! Giriş yapabilirsiniz.'**
  String get verifySuccess;

  /// No description provided for @verifyBackToLogin.
  ///
  /// In tr, this message translates to:
  /// **'Giriş sayfasına dön'**
  String get verifyBackToLogin;

  /// No description provided for @userProfileLoadErr.
  ///
  /// In tr, this message translates to:
  /// **'Profil yüklenemedi'**
  String get userProfileLoadErr;

  /// No description provided for @userProfileAbout.
  ///
  /// In tr, this message translates to:
  /// **'Hakkında'**
  String get userProfileAbout;

  /// No description provided for @userProfileListings.
  ///
  /// In tr, this message translates to:
  /// **'İlanlar ({count})'**
  String userProfileListings(int count);

  /// No description provided for @userProfileNoListings.
  ///
  /// In tr, this message translates to:
  /// **'Henüz ilan yok'**
  String get userProfileNoListings;

  /// No description provided for @userProfileMessageTooltip.
  ///
  /// In tr, this message translates to:
  /// **'Mesaj gönder'**
  String get userProfileMessageTooltip;

  /// No description provided for @userProfileChatErr.
  ///
  /// In tr, this message translates to:
  /// **'Sohbet başlatılamadı: {error}'**
  String userProfileChatErr(String error);

  /// No description provided for @userProfileMemberSince.
  ///
  /// In tr, this message translates to:
  /// **'{year}\'den beri üye'**
  String userProfileMemberSince(int year);

  /// No description provided for @userProfileDefaultName.
  ///
  /// In tr, this message translates to:
  /// **'Kullanıcı'**
  String get userProfileDefaultName;

  /// No description provided for @userProfileTypeAdopt.
  ///
  /// In tr, this message translates to:
  /// **'Sahiplendir'**
  String get userProfileTypeAdopt;

  /// No description provided for @userProfileTypeMating.
  ///
  /// In tr, this message translates to:
  /// **'Çiftleştir'**
  String get userProfileTypeMating;

  /// No description provided for @userProfileTypeLost.
  ///
  /// In tr, this message translates to:
  /// **'Kayıp'**
  String get userProfileTypeLost;

  /// No description provided for @shellBirthdayDefault.
  ///
  /// In tr, this message translates to:
  /// **'Dostunuzun doğum günü bugün!'**
  String get shellBirthdayDefault;

  /// No description provided for @shellApptReminderDefault.
  ///
  /// In tr, this message translates to:
  /// **'Evcil hayvanınız'**
  String get shellApptReminderDefault;

  /// No description provided for @shellAdvertExpiryDefault.
  ///
  /// In tr, this message translates to:
  /// **'İlanınızın süresi doluyor.'**
  String get shellAdvertExpiryDefault;

  /// No description provided for @vacCalendarTitle.
  ///
  /// In tr, this message translates to:
  /// **'Aşı Takvimi'**
  String get vacCalendarTitle;

  /// No description provided for @vacCalendarLoadErr.
  ///
  /// In tr, this message translates to:
  /// **'Hata: {error}'**
  String vacCalendarLoadErr(String error);

  /// No description provided for @vacCalendarEmpty.
  ///
  /// In tr, this message translates to:
  /// **'Aşı takvimi bulunamadı'**
  String get vacCalendarEmpty;

  /// No description provided for @vacCalendarAddRecord.
  ///
  /// In tr, this message translates to:
  /// **'Aşı Kaydı Ekle'**
  String get vacCalendarAddRecord;

  /// No description provided for @vacCalendarNoRecord.
  ///
  /// In tr, this message translates to:
  /// **'Bu gün için kayıt yok'**
  String get vacCalendarNoRecord;

  /// No description provided for @vacCalendarClickDay.
  ///
  /// In tr, this message translates to:
  /// **'Bir güne tıklayın'**
  String get vacCalendarClickDay;

  /// No description provided for @vacCalendarAdd.
  ///
  /// In tr, this message translates to:
  /// **'Ekle'**
  String get vacCalendarAdd;

  /// No description provided for @vacCalendarFirstDose.
  ///
  /// In tr, this message translates to:
  /// **'İlk Doz: {months} ay'**
  String vacCalendarFirstDose(int months);

  /// No description provided for @vacCalendarRepeat.
  ///
  /// In tr, this message translates to:
  /// **'Tekrar: {months} ay'**
  String vacCalendarRepeat(int months);

  /// No description provided for @vacCalendarRequired.
  ///
  /// In tr, this message translates to:
  /// **'Zorunlu'**
  String get vacCalendarRequired;

  /// No description provided for @vacCalendarNext.
  ///
  /// In tr, this message translates to:
  /// **'Sonraki: {date}'**
  String vacCalendarNext(String date);

  /// No description provided for @vetSearchTitle.
  ///
  /// In tr, this message translates to:
  /// **'Veteriner Ara'**
  String get vetSearchTitle;

  /// No description provided for @vetSearchGoogleTitle.
  ///
  /// In tr, this message translates to:
  /// **'Google ile Ara'**
  String get vetSearchGoogleTitle;

  /// No description provided for @vetSearchSortTooltip.
  ///
  /// In tr, this message translates to:
  /// **'Sırala'**
  String get vetSearchSortTooltip;

  /// No description provided for @vetSearchSortByDistance.
  ///
  /// In tr, this message translates to:
  /// **'Mesafeye Göre'**
  String get vetSearchSortByDistance;

  /// No description provided for @vetSearchSortByRating.
  ///
  /// In tr, this message translates to:
  /// **'Puana Göre'**
  String get vetSearchSortByRating;

  /// No description provided for @vetSearchHint.
  ///
  /// In tr, this message translates to:
  /// **'Klinik adı veya adres...'**
  String get vetSearchHint;

  /// No description provided for @vetSearchUseLocation.
  ///
  /// In tr, this message translates to:
  /// **'Konumumu kullan'**
  String get vetSearchUseLocation;

  /// No description provided for @vetSearchErrPermission.
  ///
  /// In tr, this message translates to:
  /// **'Konum izni gerekli'**
  String get vetSearchErrPermission;

  /// No description provided for @vetSearchErrLocation.
  ///
  /// In tr, this message translates to:
  /// **'Konum alınamadı: {error}'**
  String vetSearchErrLocation(String error);

  /// No description provided for @vetSearchPrompt.
  ///
  /// In tr, this message translates to:
  /// **'Aramak için yukarıya yazın veya konumunuzu paylaşın'**
  String get vetSearchPrompt;

  /// No description provided for @vetSearchNoResults.
  ///
  /// In tr, this message translates to:
  /// **'Sonuç bulunamadı'**
  String get vetSearchNoResults;
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
