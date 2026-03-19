// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Pet App';

  @override
  String get login => 'Log In';

  @override
  String get logout => 'Log Out';

  @override
  String get register => 'Sign Up';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get forgotPassword => 'Forgot Password';

  @override
  String get resetPassword => 'Reset Password';

  @override
  String get name => 'Full Name';

  @override
  String get save => 'Save';

  @override
  String get cancel => 'Cancel';

  @override
  String get delete => 'Delete';

  @override
  String get edit => 'Edit';

  @override
  String get confirm => 'Confirm';

  @override
  String get back => 'Back';

  @override
  String get close => 'Close';

  @override
  String get retry => 'Retry';

  @override
  String get loading => 'Loading...';

  @override
  String get error => 'Error';

  @override
  String get success => 'Success';

  @override
  String get noData => 'No data found';

  @override
  String get send => 'Send';

  @override
  String get tabHome => 'Adopt';

  @override
  String get tabMessages => 'Messages';

  @override
  String get tabVet => 'Veterinary';

  @override
  String get tabStore => 'Store';

  @override
  String get tabProfile => 'Profile';

  @override
  String get homeTitle => 'Listings';

  @override
  String get homeSearchHint => 'Search breed, species...';

  @override
  String get homeNearby => 'Near Me';

  @override
  String get homeNoAds => 'No listings yet';

  @override
  String get homeNoAdsDesc => 'No listings found nearby.';

  @override
  String get homeAdoptionTab => 'Adoption';

  @override
  String get homeMatingTab => 'Mating';

  @override
  String get petDetailTitle => 'Listing Detail';

  @override
  String get petDetailAge => 'Age';

  @override
  String get petDetailBreed => 'Breed';

  @override
  String get petDetailGender => 'Gender';

  @override
  String get petDetailVaccinated => 'Vaccinated';

  @override
  String get petDetailOwner => 'Owner';

  @override
  String get petDetailContact => 'Contact';

  @override
  String get petDetailAdopt => 'I Want to Adopt';

  @override
  String get createPetTitle => 'Create Listing';

  @override
  String get createPetName => 'Pet Name';

  @override
  String get createPetSpecies => 'Species';

  @override
  String get createPetBreed => 'Breed';

  @override
  String get createPetAge => 'Age (months)';

  @override
  String get createPetGender => 'Gender';

  @override
  String get createPetBio => 'About';

  @override
  String get createPetPhotos => 'Photos';

  @override
  String get createPetAddPhoto => 'Add Photo';

  @override
  String get createPetSubmit => 'Publish Listing';

  @override
  String get matingTitle => 'Find a Match';

  @override
  String get matingSubtitle => 'Discover compatible matches for your pet.';

  @override
  String get matingSpecies => 'Species';

  @override
  String get matingGender => 'Gender';

  @override
  String matingMaxDistance(int km) {
    return 'Max distance: $km km';
  }

  @override
  String get matingRequests => 'Match requests';

  @override
  String get matingEndTitle => 'That\'s all!';

  @override
  String get matingEndDesc => 'No more profiles found nearby.';

  @override
  String get matingRefresh => 'Refresh';

  @override
  String get matingEmptyTitle => 'Try relaxing the filters';

  @override
  String get matingEmptyDesc => 'No suitable matches found nearby yet.';

  @override
  String get matingAll => 'All';

  @override
  String get matingMale => 'Male';

  @override
  String get matingFemale => 'Female';

  @override
  String get matingLikeStamp => 'LIKE';

  @override
  String get matingNopeStamp => 'NOPE';

  @override
  String get matingVaccinated => 'Vaccinated';

  @override
  String get messagesTitle => 'Messages';

  @override
  String get messagesEmpty => 'No conversations yet';

  @override
  String get messagesEmptyDesc => 'Contact someone from a listing.';

  @override
  String get messagesTypeHint => 'Write a message...';

  @override
  String get messagesSend => 'Send';

  @override
  String get messagesImage => 'Send image';

  @override
  String get messagesDeleted => '[deleted]';

  @override
  String get matchRequestsTitle => 'Match Requests';

  @override
  String get matchRequestsInbox => 'Received';

  @override
  String get matchRequestsOutbox => 'Sent';

  @override
  String get matchRequestsEmpty => 'No requests';

  @override
  String get matchRequestAccept => 'Accept';

  @override
  String get matchRequestReject => 'Reject';

  @override
  String get matchRequestCancel => 'Cancel';

  @override
  String get profileTitle => 'Profile';

  @override
  String get profileEdit => 'Edit Profile';

  @override
  String get profileMyPets => 'My Listings';

  @override
  String get profileSettings => 'Settings';

  @override
  String get profileLogout => 'Log Out';

  @override
  String get profileSeller => 'Seller';

  @override
  String get profileMember => 'Member';

  @override
  String profileSince(String date) {
    return 'Joined: $date';
  }

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsDarkMode => 'Dark Mode';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get settingsLanguageTr => 'Türkçe';

  @override
  String get settingsLanguageEn => 'English';

  @override
  String get settingsReview => 'Rate the App';

  @override
  String get settingsPrivacy => 'Privacy Policy';

  @override
  String get settingsNotifications => 'Notifications';

  @override
  String get settingsLogout => 'Log Out';

  @override
  String get vetTitle => 'Veterinarians';

  @override
  String get vetSearch => 'Search vet...';

  @override
  String get vetNoResults => 'No veterinarian found';

  @override
  String vetDistance(String km) {
    return '$km km away';
  }

  @override
  String get vetAppointment => 'Book Appointment';

  @override
  String get vetVaccination => 'Vaccination Schedule';

  @override
  String get vetReminders => 'Reminders';

  @override
  String get storeTitle => 'Store';

  @override
  String get storeSearch => 'Search products...';

  @override
  String get storeCart => 'Cart';

  @override
  String get storeCheckout => 'Checkout';

  @override
  String get storeMyOrders => 'My Orders';

  @override
  String get storeAddToCart => 'Add to Cart';

  @override
  String get storeOutOfStock => 'Out of Stock';

  @override
  String get storeOrderPlaced => 'Order Placed';

  @override
  String get lostFoundTitle => 'Lost & Found';

  @override
  String get lostFoundReport => 'Add Listing';

  @override
  String get lostFoundLost => 'Lost';

  @override
  String get lostFoundFound => 'Found';

  @override
  String get eventsTitle => 'Events';

  @override
  String get eventsJoin => 'Join';

  @override
  String get eventsLeave => 'Leave';

  @override
  String get sitterTitle => 'Pet Sitter';

  @override
  String get sitterBecomeSitter => 'Become a Sitter';

  @override
  String get sitterBook => 'Book';

  @override
  String get sitterMyBookings => 'My Bookings';

  @override
  String get adoptionApply => 'Apply';

  @override
  String get adoptionMyApps => 'My Applications';

  @override
  String get notificationsTitle => 'Notifications';

  @override
  String get notificationsEmpty => 'No notifications';

  @override
  String get notificationsClearAll => 'Clear All';

  @override
  String get favoritesTitle => 'Favorites';

  @override
  String get favoritesEmpty => 'No favorite listings';

  @override
  String hello(String name) {
    return 'Hello, $name!';
  }

  @override
  String get genderMale => 'Male';

  @override
  String get genderFemale => 'Female';

  @override
  String get genderUnknown => 'Unknown';

  @override
  String get speciesDog => 'Dog';

  @override
  String get speciesCat => 'Cat';

  @override
  String get speciesBird => 'Bird';

  @override
  String get speciesFish => 'Fish';

  @override
  String get speciesOther => 'Other';

  @override
  String get advertTypeAdoption => 'Adoption';

  @override
  String get advertTypeMating => 'Mating';

  @override
  String get privacyPolicyTitle => 'Privacy Policy';

  @override
  String get reviewDialogTitle => 'Rate the App';

  @override
  String get reviewDialogDesc =>
      'Enjoying the app? Your rating helps us a lot.';

  @override
  String get errorGeneric => 'Something went wrong. Please try again.';

  @override
  String get errorNetwork => 'No internet connection.';

  @override
  String get errorUnauthorized => 'Session expired. Please log in again.';

  @override
  String get errorNotFound => 'Not found.';

  @override
  String get yes => 'Yes';

  @override
  String get no => 'No';

  @override
  String get or => 'or';

  @override
  String get km => 'km';

  @override
  String get month => 'month';

  @override
  String get year => 'year';

  @override
  String months(int count) {
    return '$count months';
  }

  @override
  String years(int count) {
    return '$count years';
  }

  @override
  String get settingsSectionAccount => 'My Account';

  @override
  String get settingsSectionAccountSub =>
      'Update your profile and manage security settings.';

  @override
  String get settingsSectionStore => 'Store Management';

  @override
  String get settingsSectionStoreSub => 'Manage your store and orders.';

  @override
  String get settingsSectionNotif => 'Notifications';

  @override
  String get settingsSectionNotifSub => 'Stay connected with the community.';

  @override
  String get settingsSectionAppExp => 'App Experience';

  @override
  String get settingsSectionAppExpSub =>
      'Customize appearance and personal preferences.';

  @override
  String get settingsSectionSupport => 'Support';

  @override
  String get settingsSectionSupportSub => 'Need help? We\'re here for you.';

  @override
  String get settingsEditProfile => 'Edit Profile';

  @override
  String get settingsEditProfileSub => 'Update your personal info and bio';

  @override
  String get settingsChangePassword => 'Change Password';

  @override
  String get settingsChangePasswordSub => 'Create a new password via email';

  @override
  String get settingsMyOrders => 'My Orders';

  @override
  String get settingsMyOrdersSub => 'View and track your order history';

  @override
  String get settingsMyFavorites => 'Favorites';

  @override
  String get settingsMyFavoritesSub => 'View products you liked';

  @override
  String get settingsMyStore => 'My Store';

  @override
  String get settingsMyStoreSub => 'View and edit store information';

  @override
  String get settingsIncomingOrders => 'Incoming Orders';

  @override
  String get settingsIncomingOrdersSub =>
      'Manage orders received in your store';

  @override
  String get settingsManageProducts => 'Manage Products';

  @override
  String get settingsManageProductsSub => 'Add, edit or update stock';

  @override
  String get settingsNotifChat => 'Chat notifications';

  @override
  String get settingsNotifChatSub =>
      'Get notified about new messages and chat requests';

  @override
  String get settingsNotifMatch => 'Match alerts';

  @override
  String get settingsNotifMatchSub => 'Instant notifications for new matches';

  @override
  String get settingsAutoChat => 'Auto-prepare chat on match';

  @override
  String get settingsAutoChatSub =>
      'Quickly open the chat screen when a match is made';

  @override
  String get settingsCompactCards => 'Show compact cards';

  @override
  String get settingsCompactCardsSub => 'See more content in list view';

  @override
  String get settingsDarkModeSub =>
      'A more comfortable dark theme for your eyes';

  @override
  String get settingsLanguageSub => 'Change app language';

  @override
  String get settingsExportData => 'Export my data';

  @override
  String get settingsExportDataSub =>
      'Request listings and chat history via email';

  @override
  String get settingsHelp => 'FAQ & Help Center';

  @override
  String get settingsContact => 'Contact Support';

  @override
  String get settingsShare => 'Share App';

  @override
  String get settingsShareSub => 'Recommend to friends';

  @override
  String get profileTabMyAds => 'My Adoption Listings';

  @override
  String get profileTabMatingAds => 'My Mating Listings';

  @override
  String get profileAdoptionCount => 'Adoption';

  @override
  String get profileMatingCount => 'Mating';

  @override
  String get profileViewCount => 'Views';

  @override
  String get profileNewAdoption => 'Adoption';

  @override
  String get profileNewMating => 'Mating';

  @override
  String get homeGreeting => 'Hello';

  @override
  String get homeShortcutMating => 'Match';

  @override
  String get homeShortcutLost => 'Lost';

  @override
  String get homeShortcutEvents => 'Events';

  @override
  String get homeShortcutSitter => 'Sitter';

  @override
  String get homeShortcutAi => 'Pati AI';

  @override
  String get homeShortcutFeed => 'Feed';

  @override
  String get homeShortcutSearch => 'Search';

  @override
  String get homeUpcomingAppointments => 'Upcoming Appointments';

  @override
  String get homeNearbyAds => 'Nearby Listings';

  @override
  String get navMessages => 'Messages';

  @override
  String get navAdopt => 'Adopt';

  @override
  String get navVet => 'Veterinary';

  @override
  String get navStore => 'Store';

  @override
  String get navProfile => 'Profile';

  @override
  String get darkModeOn => 'Dark mode on';

  @override
  String get darkModeOff => 'Dark mode off';

  @override
  String get languageLabel => 'Language';

  @override
  String get selectLanguage => 'Select Language';

  @override
  String get today => 'Today';

  @override
  String get tomorrow => 'Tomorrow';

  @override
  String get profileCompleteTitle => 'Complete profile';

  @override
  String get profileCompletePhoto => 'Photo';

  @override
  String get profileCompleteCity => 'City';

  @override
  String get profileCompleteAbout => 'About';

  @override
  String get searchMessages => 'Search messages...';

  @override
  String noSearchResults(String query) {
    return 'No results for \"$query\"';
  }
}
