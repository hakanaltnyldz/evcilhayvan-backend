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
  String get msgConvDeleted => 'Conversation deleted';

  @override
  String msgConvDeleteErr(String error) {
    return 'Could not delete conversation: $error';
  }

  @override
  String get msgConvStart => 'Start chatting';

  @override
  String get msgListingNotFound => 'Listing info not found';

  @override
  String get msgListingLoading => 'Loading listing...';

  @override
  String get msgListingLoadErr => 'Could not load listing info';

  @override
  String get msgMatingRequestsTitle => 'Mating Requests';

  @override
  String get msgNoMatingRequests => 'No mating requests yet.';

  @override
  String get msgAdoptionRequestsTitle => 'Adoption Applications';

  @override
  String get msgNoAdoptionRequests => 'No applications yet.';

  @override
  String get msgHeaderTitle => 'Brighten your inbox';

  @override
  String get msgHeaderSubtitle =>
      'Manage adoption conversations, listing questions and new friendships here.';

  @override
  String get msgConvLoadErr => 'Could not load conversations';

  @override
  String msgSenderLabel(String name) {
    return 'From: $name';
  }

  @override
  String msgSelectedPet(String name) {
    return 'Selected pet: $name';
  }

  @override
  String get msgViewSenderListing => 'View sender\'s listing';

  @override
  String msgApplicantLabel(String name) {
    return 'Applicant: $name';
  }

  @override
  String get msgGoToChat => 'Go to chat';

  @override
  String get msgStatusAccepted => 'Accepted';

  @override
  String get msgStatusRejected => 'Rejected';

  @override
  String get msgStatusCancelled => 'Cancelled';

  @override
  String get msgStatusPending => 'Pending';

  @override
  String get msgActionDone => 'Action completed';

  @override
  String get msgNoRecipient => 'Recipient info not found.';

  @override
  String get msgLoginRequired => 'Please log in to chat.';

  @override
  String get msgOpenFailed => 'Could not open conversation.';

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
  String get speciesHamster => 'Hamster';

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
  String get homeDiscoverTitle => 'Discover Listings';

  @override
  String get homeSearchTooltip => 'Search';

  @override
  String get homeLostFoundTooltip => 'Lost & Found';

  @override
  String get homeBreedSelect => 'Select breed';

  @override
  String get homeClearFilter => 'Clear filter';

  @override
  String get homeWelcome => 'Welcome!';

  @override
  String homeGreetingWith(String greeting, String name) {
    return '$greeting, $name!';
  }

  @override
  String get homeHeaderDesc => 'Discover the perfect pet companion for you.';

  @override
  String get homeGoodMorning => 'Good morning';

  @override
  String get homeGoodDay => 'Good afternoon';

  @override
  String get homeGoodEvening => 'Good evening';

  @override
  String get homeGoodNight => 'Good night';

  @override
  String get homeShortcutSitterFull => 'Find\nSitter';

  @override
  String get homeShortcutLostFull => 'Lost &\nFound';

  @override
  String get homeShortcutAiFull => 'Pati\nAssistant';

  @override
  String get homeShortcutMap => 'Map';

  @override
  String get homeEmptyListings => 'No listings yet';

  @override
  String get homeEmptyListingsDesc =>
      'No listings in this category yet. Be the first to add!';

  @override
  String get homeApptFallback => 'Vet Appointment';

  @override
  String get homeNotifTooltip => 'Notifications';

  @override
  String get homeBreedSearch => 'Search breed...';

  @override
  String get homeLocationPermErr => 'Location permission required';

  @override
  String homeLocationErr(String error) {
    return 'Could not get location: $error';
  }

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

  @override
  String get vetVerified => 'Verified';

  @override
  String get vetOnlineAppointment => 'Online Appointment';

  @override
  String get vetAbout => 'About';

  @override
  String get vetServices => 'Services';

  @override
  String get vetSpeciesServed => 'Species Served';

  @override
  String get vetWorkingHours => 'Working Hours';

  @override
  String get vetClosed => 'Closed';

  @override
  String get vetOpenInMaps => 'Open in Maps';

  @override
  String get vetSendMessage => 'Send Message';

  @override
  String get vetClaimProfile => 'Claim This Clinic';

  @override
  String get vetClaimDialogTitle => 'Claim Profile';

  @override
  String get vetClaimDialogContent =>
      'Are you sure you want to link this clinic profile to your account?\n\nAfter claiming, customers can message you directly.';

  @override
  String get vetClaimAction => 'Claim';

  @override
  String get vetClaimSuccess =>
      'Profile claimed successfully! You can now receive messages.';

  @override
  String get vetReviews => 'Reviews';

  @override
  String get vetReviewsRate => 'Rate';

  @override
  String get vetReviewsLoadError => 'Could not load reviews.';

  @override
  String get vetReviewsEmpty => 'No reviews yet. Be the first to review!';

  @override
  String vetReviewCount(int count) {
    return '$count reviews';
  }

  @override
  String get vetReviewAdded => 'Your review has been added.';

  @override
  String vetReviewDeleteError(String error) {
    return 'Could not delete: $error';
  }

  @override
  String get vetReviewDialogTitle => 'Rate Veterinarian';

  @override
  String get vetReviewCommentHint => 'Your comment (optional)';

  @override
  String get vetSpeciesDog => 'Dog';

  @override
  String get vetSpeciesCat => 'Cat';

  @override
  String get vetSpeciesBird => 'Bird';

  @override
  String get vetSpeciesFish => 'Fish';

  @override
  String get vetSpeciesRodent => 'Rodent';

  @override
  String get vetSpeciesOther => 'Other';

  @override
  String vetRating(String rating, int count) {
    return '$rating ($count reviews)';
  }

  @override
  String get checkoutTitle => 'Checkout';

  @override
  String get checkoutDeliveryAddress => 'Delivery Address';

  @override
  String get checkoutPaymentMethod => 'Payment Method';

  @override
  String get checkoutCardInfo => 'Card Details';

  @override
  String get checkoutCreditCard => 'Credit Card';

  @override
  String get checkoutCashOnDelivery => 'Cash on Delivery';

  @override
  String get checkoutCardNumber => 'Card Number';

  @override
  String get checkoutCardHolder => 'Cardholder Name';

  @override
  String get checkoutCardHolderHint => 'FULL NAME';

  @override
  String get checkoutExpiry => 'Expiry Date';

  @override
  String get checkoutExpiryHint => 'MM/YY';

  @override
  String get checkoutCoupon => 'Discount Coupon';

  @override
  String get checkoutCouponHint => 'Your coupon code';

  @override
  String get checkoutApply => 'Apply';

  @override
  String get checkoutOrderNote => 'Order Note (Optional)';

  @override
  String get checkoutOrderNoteHint => 'Notes about your order...';

  @override
  String get checkoutOrderSummary => 'Order Summary';

  @override
  String get checkoutSubtotal => 'Subtotal';

  @override
  String get checkoutShipping => 'Shipping';

  @override
  String get checkoutFreeShipping => 'Free';

  @override
  String get checkoutDiscount => 'Discount';

  @override
  String get checkoutTotal => 'Total';

  @override
  String get checkoutCompleteOrder => 'Place Order';

  @override
  String get checkoutDefaultAddress => 'Default';

  @override
  String get checkoutAddNewAddress => 'Add New Address';

  @override
  String checkoutAddressLoadError(String error) {
    return 'Could not load addresses: $error';
  }

  @override
  String checkoutCartLoadError(String error) {
    return 'Could not load cart: $error';
  }

  @override
  String get checkoutErrNoAddress => 'Please select a delivery address';

  @override
  String get checkoutErrCardNumber => 'Enter a valid 16-digit card number';

  @override
  String get checkoutErrCardNumberInvalid => 'Card number is invalid';

  @override
  String get checkoutErrCardHolder =>
      'Enter cardholder name using letters only';

  @override
  String get checkoutErrExpiry => 'Enter expiry date in MM/YY format';

  @override
  String get checkoutErrExpiryPast => 'Card expiry date has passed';

  @override
  String get checkoutErrCvv => 'Enter 3 or 4 digit CVV';

  @override
  String get checkoutErrEmptyCart => 'Your cart is empty';

  @override
  String get checkoutErrCouponEmpty => 'Please enter a coupon code';

  @override
  String get checkoutErrCouponInvalid => 'Invalid coupon code';

  @override
  String get checkoutErrCouponNotApplicable =>
      'Coupon not applicable to this order';

  @override
  String get checkoutErrCouponFailed => 'Could not apply coupon';

  @override
  String get checkoutErrCouponExpired => 'This coupon has expired';

  @override
  String get checkoutErrCouponUsageLimit => 'Coupon usage limit reached';

  @override
  String get couponsMyCouponsTitle => 'My Coupons';

  @override
  String get couponsAvailableTab => 'Available';

  @override
  String get couponsHistoryTab => 'Usage History';

  @override
  String couponsCopied(String code) {
    return '$code copied';
  }

  @override
  String get couponsEmptyTitle => 'No coupons available right now';

  @override
  String get couponsEmptySubtitle => 'Stay tuned for upcoming deals!';

  @override
  String get couponsLoadError => 'Could not load coupons';

  @override
  String get couponsRetry => 'Retry';

  @override
  String couponsValidUntil(String date) {
    return 'Until $date';
  }

  @override
  String get sellerCouponManagementTitle => 'Coupon Management';

  @override
  String get sellerCouponNew => 'New Coupon';

  @override
  String get sellerCouponShowExpired => 'Show Expired';

  @override
  String get sellerCouponHideExpired => 'Hide Expired';

  @override
  String get sellerCouponLoadError => 'Could not load coupons';

  @override
  String get sellerCouponEmptyTitle => 'No coupons yet';

  @override
  String get sellerCouponEmptySubtitle => 'Tap the button below to create one';

  @override
  String get sellerCouponCreateDialogTitle => 'Create New Coupon';

  @override
  String get sellerCouponCodeLabel => 'Coupon Code';

  @override
  String get sellerCouponRandom => 'Random';

  @override
  String get sellerCouponDescLabel => 'Description (optional)';

  @override
  String get sellerCouponTypeLabel => 'Discount Type';

  @override
  String get sellerCouponPercent => 'Percentage (%)';

  @override
  String get sellerCouponFixed => 'Fixed (₺)';

  @override
  String get sellerCouponRateLabel => 'Discount Rate (%)';

  @override
  String get sellerCouponAmountLabel => 'Discount Amount (₺)';

  @override
  String get sellerCouponMinPurchase => 'Min. Cart Amount (₺)';

  @override
  String get sellerCouponMaxDiscount => 'Max Discount Amount ₺ (optional)';

  @override
  String get sellerCouponPerUserLimit => 'Per User Usage Limit';

  @override
  String get sellerCouponTotalLimit => 'Total Usage Limit (optional)';

  @override
  String get sellerCouponStartDate => 'Start';

  @override
  String get sellerCouponEndDate => 'End';

  @override
  String get sellerCouponFirstOrderOnly => 'First Order Only';

  @override
  String get sellerCouponCreate => 'Create';

  @override
  String get sellerCouponValidationError =>
      'Code and discount value are required';

  @override
  String sellerCouponCreated(String code) {
    return '$code coupon created';
  }

  @override
  String get sellerCouponCreateFailed => 'Could not create coupon';

  @override
  String get sellerCouponToggleFailed => 'Could not change status';

  @override
  String get sellerCouponDeleteTitle => 'Delete Coupon';

  @override
  String sellerCouponDeleteConfirm(String code) {
    return 'Are you sure you want to delete the $code coupon?';
  }

  @override
  String sellerCouponDeleted(String code) {
    return '$code deleted';
  }

  @override
  String get sellerCouponDeleteFailed => 'Could not delete coupon';

  @override
  String sellerCouponValidUntil(String date) {
    return 'Until $date';
  }

  @override
  String sellerCouponUsageLimited(String count, String total) {
    return '$count / $total uses';
  }

  @override
  String sellerCouponUsage(String count) {
    return '$count uses';
  }

  @override
  String get sellerCouponFirstOrderLabel => 'First Order';

  @override
  String get sellerCouponExpiredLabel => 'Expired';

  @override
  String checkoutCouponApplied(String amount) {
    return 'Coupon applied! ₺$amount discount';
  }

  @override
  String checkoutCouponDiscount(String amount) {
    return '₺$amount discount applied';
  }

  @override
  String get checkoutOrderSuccess => 'Order Received!';

  @override
  String get checkoutOrderSuccessDesc =>
      'Your order was placed successfully. Track it in My Orders.';

  @override
  String get checkoutGoToOrders => 'Go to My Orders';

  @override
  String checkoutOrderError(String error) {
    return 'Could not place order: $error';
  }

  @override
  String healthJournalTitle(String petName) {
    return '$petName Health Journal';
  }

  @override
  String get healthAddRecord => 'Add Record';

  @override
  String get healthTypeAll => 'All';

  @override
  String get healthTypeWeight => 'Weight';

  @override
  String get healthTypeMedication => 'Medication';

  @override
  String get healthTypeVetVisit => 'Vet Visit';

  @override
  String get healthTypeNote => 'Note';

  @override
  String get healthRecordAdded => 'Record added.';

  @override
  String get healthRecordDeleteTitle => 'Delete Record';

  @override
  String get healthRecordDeleteContent =>
      'Are you sure you want to delete this health record?';

  @override
  String get healthNoRecords => 'No health records yet';

  @override
  String healthNoFilterRecords(String type) {
    return 'No $type records';
  }

  @override
  String get healthAddHint =>
      'Tap the + button at the bottom right to add a record';

  @override
  String get healthWeightChart => 'Weight Tracker';

  @override
  String get healthWeightChartMin =>
      'At least 2 weight records required for chart';

  @override
  String get healthWeightChartError => 'Could not load weight chart';

  @override
  String get healthRefresh => 'Refresh';

  @override
  String healthLoadError(String error) {
    return 'Could not load: $error';
  }

  @override
  String healthDose(String dose) {
    return 'Dose: $dose';
  }

  @override
  String healthFrequency(String freq) {
    return 'Frequency: $freq';
  }

  @override
  String healthVetName(String name) {
    return 'Vet: $name';
  }

  @override
  String healthDiagnosis(String diagnosis) {
    return 'Diagnosis: $diagnosis';
  }

  @override
  String get healthAddDialogTitle => 'Add Health Record';

  @override
  String get healthRecordType => 'Record Type';

  @override
  String get healthRecordDate => 'Record date';

  @override
  String get healthWeightKg => 'Weight (kg)';

  @override
  String get healthMedName => 'Medication Name *';

  @override
  String get healthMedDosage => 'Dosage (e.g. 5mg)';

  @override
  String get healthMedFreq => 'Frequency (e.g. Twice daily)';

  @override
  String get healthVetNameLabel => 'Vet Name';

  @override
  String get healthDiagnosisTreatment => 'Diagnosis / Treatment';

  @override
  String get healthNotes => 'Notes (optional)';

  @override
  String get healthErrWeight => 'Enter a valid weight.';

  @override
  String get healthErrMedName => 'Medication name is required.';

  @override
  String get blockUserTitle => 'Block User';

  @override
  String blockUserContent(String name) {
    return 'Are you sure you want to block $name? You will no longer see their listings.';
  }

  @override
  String get blockUserAction => 'Block';

  @override
  String blockUserSuccess(String name) {
    return '$name has been blocked.';
  }

  @override
  String blockUserError(String error) {
    return 'Block failed: $error';
  }

  @override
  String get blockUserSubtitle => 'I don\'t want to see this user\'s listings';

  @override
  String get reportUserTitle => 'Report';

  @override
  String get reportUserSubtitle => 'Report inappropriate behavior or content';

  @override
  String reportDialogTitle(String name) {
    return 'Report $name';
  }

  @override
  String get reportReasonLabel => 'Reason for report:';

  @override
  String get reportReasonSpam => 'Spam';

  @override
  String get reportReasonHarassment => 'Harassment or bullying';

  @override
  String get reportReasonInappropriate => 'Inappropriate content';

  @override
  String get reportReasonFakeProfile => 'Fake profile';

  @override
  String get reportReasonOther => 'Other';

  @override
  String get reportDescHint => 'Additional details (optional)';

  @override
  String get reportAction => 'Report';

  @override
  String get reportErrNoReason => 'Please select a reason.';

  @override
  String get reportSuccess => 'Your report has been received, thank you.';

  @override
  String get goBack => 'Go Back';

  @override
  String get petDetailLoadError => 'Could not load listing';

  @override
  String get petDetailGoBack => 'Go Back';

  @override
  String get petDetailShare => 'Share';

  @override
  String get petDetailQrTooltip => 'QR ID Card';

  @override
  String get petDetailQrCard => 'QR ID Card';

  @override
  String get petDetailVaccine => 'Vaccine';

  @override
  String get petDetailVaccineFull => 'Vaccinated';

  @override
  String get petDetailVaccineMissing => 'Not Vaccinated';

  @override
  String petDetailAgeYearsMonths(int years, int months) {
    return '$years yr $months mo';
  }

  @override
  String petDetailShareText(String name) {
    return '$name - Discover on Pati Arkadaşı!';
  }

  @override
  String petDetailShareSubject(String name) {
    return '$name listing';
  }

  @override
  String get petDetailStatusActive => 'Active';

  @override
  String get petDetailStatusInactive => 'Inactive';

  @override
  String get petDetailBreedUnspecified => 'Breed not specified';

  @override
  String get petDetailAbout => 'About';

  @override
  String get petDetailDetails => 'Detailed Info';

  @override
  String get petDetailSpecies => 'Species';

  @override
  String get petDetailBreedLabel => 'Breed';

  @override
  String get petDetailBreedUnset => 'Not specified';

  @override
  String get petDetailGenderLabel => 'Gender';

  @override
  String get petDetailAgeLabel => 'Age';

  @override
  String petDetailAgeMonths(int months) {
    return '$months months';
  }

  @override
  String get petDetailAdvertType => 'Listing Type';

  @override
  String get petDetailHealth => 'Health Info';

  @override
  String get petDetailVaccineStatus => 'Vaccination Status';

  @override
  String get petDetailVaccineComplete => 'Fully Vaccinated';

  @override
  String get petDetailVaccineNeeded => 'Needs Vaccination';

  @override
  String get petDetailListingStatus => 'Listing Status';

  @override
  String get petDetailActive => 'Active';

  @override
  String get petDetailInactive => 'Inactive';

  @override
  String get petDetailLocation => 'Location';

  @override
  String get petDetailLocationShared => 'Location shared';

  @override
  String get petDetailLocationNone => 'No location info';

  @override
  String get petDetailOpenInMap => 'Open in Map';

  @override
  String get petDetailMapTapHint => 'Tap to view on map';

  @override
  String get petDetailMapOpenError => 'Could not open map app';

  @override
  String get petDetailOwnerLabel => 'Owner';

  @override
  String get petDetailOwnerUnknown => 'Owner Unknown';

  @override
  String get petDetailOwnerBannerTitle => 'This listing is yours!';

  @override
  String get petDetailOwnerBannerDesc =>
      'Keeping your listing updated attracts more interest.';

  @override
  String get petDetailHealthJournal => 'Health Journal';

  @override
  String get petDetailMessage => 'Message';

  @override
  String get petDetailAdoptBtn => 'Adopt';

  @override
  String get petDetailMatingRequest => 'Send Mating Request';

  @override
  String get petDetailQrAge => 'Age';

  @override
  String get petDetailQrGender => 'Gender';

  @override
  String get petDetailQrVaccine => 'Vaccine';

  @override
  String get petDetailQrVaccineFull => 'Complete';

  @override
  String get petDetailQrVaccinePartial => 'Incomplete';

  @override
  String get petDetailQrIdCopied => 'ID copied to clipboard';

  @override
  String get petDetailErrMsgLogin => 'You must be logged in to send a message.';

  @override
  String get petDetailErrOwnerNotFound => 'Owner information not found.';

  @override
  String get petDetailErrSelfMessage => 'You cannot message your own listing.';

  @override
  String get petDetailErrMatingLogin =>
      'You must be logged in to send a mating request.';

  @override
  String get petDetailNoPetDialog => 'Listing Required';

  @override
  String get petDetailNoPetContent =>
      'You need to create a mating listing first before sending a mating request.';

  @override
  String get petDetailCreateListing => 'Create Listing';

  @override
  String get petDetailSameSpeciesTitle => 'Same Species Required';

  @override
  String petDetailSameSpeciesContent(String species) {
    return 'This listing is \"$species\" species. You need a listing of the same species to send a mating request.';
  }

  @override
  String petDetailMatingGenericError(String error) {
    return 'Could not send mating request: $error';
  }

  @override
  String get petDetailSuccessDialogTitle => 'Request Sent!';

  @override
  String get petDetailSuccessDialogMatch =>
      'Congratulations! A mutual match was created. You can now chat.';

  @override
  String get petDetailSuccessDialogPending =>
      'Your mating request has been sent. Waiting for the other party\'s approval.';

  @override
  String get petDetailSuccessDialogStartChat => 'Start Chatting';

  @override
  String get petDetailSelectPetTitle => 'Select Your Pet';

  @override
  String petDetailSelectPetSubtitle(String species) {
    return 'Select a $species for mating';
  }

  @override
  String get chatDeleteTitle => 'Delete conversation';

  @override
  String get chatDeleteContent =>
      'Are you sure you want to permanently delete this conversation? This cannot be undone.';

  @override
  String chatDeleteError(String error) {
    return 'Could not delete conversation: $error';
  }

  @override
  String get chatRefresh => 'Refresh conversation';

  @override
  String get chatNotifPrefs => 'Notification preferences';

  @override
  String get chatNotifPrefsSub => 'Manage in Settings > Notifications';

  @override
  String get chatNotifPrefsInfo =>
      'You can edit notification preferences from the settings screen.';

  @override
  String get chatDeleteFromList => 'Remove from list';

  @override
  String get chatDeleteFromListSub =>
      'You can also delete from the Messages screen.';

  @override
  String get chatBlockReport => 'Block / Report';

  @override
  String get chatSelectFromGallery => 'Choose from Gallery';

  @override
  String get chatSelectFromGallerySub => 'Select from your photo gallery';

  @override
  String get chatCamera => 'Camera';

  @override
  String get chatCameraSub => 'Take a new photo';

  @override
  String get chatMsgHint => 'Write a message...';

  @override
  String get chatSearchHint => 'Search messages...';

  @override
  String get chatErrMicPermission => 'Microphone permission required.';

  @override
  String chatErrRecordStart(String error) {
    return 'Could not start recording: $error';
  }

  @override
  String chatErrAudioSend(String error) {
    return 'Could not send audio: $error';
  }

  @override
  String chatErrImagePick(String error) {
    return 'Could not pick image: $error';
  }

  @override
  String chatErrImageSend(String error) {
    return 'Could not send image: $error';
  }

  @override
  String get chatErrLoginRequired => 'You must be logged in to send a message.';

  @override
  String get chatErrLoginRequiredImage =>
      'You must be logged in to send an image.';

  @override
  String chatErrMsgSend(String error) {
    return 'Could not send message: $error';
  }

  @override
  String chatErrMsgDelete(String error) {
    return 'Could not delete message: $error';
  }

  @override
  String chatErrReaction(String error) {
    return 'Could not send reaction: $error';
  }

  @override
  String get chatMsgDeletedSelf => 'You deleted this message';

  @override
  String get chatDeleteMsgForMe => 'Delete this message for me';

  @override
  String get chatCopyMsg => 'Copy';

  @override
  String get chatAudioMsg => '[Audio Message]';

  @override
  String chatSearchNoResults(String query) {
    return 'No results for \"$query\"';
  }

  @override
  String get chatTooltipBack => 'Back';

  @override
  String get chatTooltipSearch => 'Search Messages';

  @override
  String get chatTooltipCloseSearch => 'Close Search';

  @override
  String get chatTypeMatching => 'Mating conversation';

  @override
  String get chatTypeAdoption => 'Adoption conversation';

  @override
  String get chatTypeGeneral => 'Conversation';

  @override
  String get ordersTitle => 'My Orders';

  @override
  String get ordersEmpty => 'No orders yet';

  @override
  String get ordersEmptyDesc => 'Start shopping at the store';

  @override
  String get orderStatusPending => 'Pending';

  @override
  String get orderStatusProcessing => 'Processing';

  @override
  String get orderStatusShipped => 'Shipped';

  @override
  String get orderStatusDelivered => 'Delivered';

  @override
  String get orderStatusCancelled => 'Cancelled';

  @override
  String get orderCancelTitle => 'Cancel Order';

  @override
  String get orderCancelContent =>
      'Are you sure you want to cancel this order?';

  @override
  String get orderCancelAction => 'Cancel Order';

  @override
  String get orderCancelSuccess => 'Order cancelled';

  @override
  String orderCancelError(String error) {
    return 'Could not cancel: $error';
  }

  @override
  String orderNumber(String id) {
    return 'Order #$id';
  }

  @override
  String orderItemCount(int count) {
    return '$count items';
  }

  @override
  String orderItemQty(int qty, String price) {
    return '$qty pcs x ₺$price';
  }

  @override
  String get orderProducts => 'Products';

  @override
  String get orderTrackingInfo => 'Tracking Information';

  @override
  String orderTrackingCopied(String no) {
    return 'Tracking no copied: $no';
  }

  @override
  String get orderMyOrdersTitle => 'My Orders';

  @override
  String get orderNoOrders => 'No orders yet';

  @override
  String get orderNoOrdersDesc => 'Start shopping in the store';

  @override
  String orderLoadErr(String error) {
    return 'Error: $error';
  }

  @override
  String get orderDeliveryAddress => 'Delivery Address';

  @override
  String get orderReview => 'Review';

  @override
  String get copyTooltip => 'Copy';

  @override
  String orderMyRating(int rating) {
    return 'Your rating: $rating';
  }

  @override
  String get nearbyTitle => 'Nearby Listings';

  @override
  String get nearbyLocating => 'Getting location...';

  @override
  String get nearbyNoResults => 'No listings found in this area';

  @override
  String get nearbyExpandArea => 'Expand area (50 km)';

  @override
  String nearbyShown(int count) {
    return '$count listings shown';
  }

  @override
  String nearbyActiveFilters(int count) {
    return '$count filters active';
  }

  @override
  String get nearbyClearFilters => 'Clear';

  @override
  String get nearbyErrLocationService =>
      'Location service is off. Please enable it in settings.';

  @override
  String get nearbyErrPermDeniedForever =>
      'Location permission permanently denied. Enable it in app settings.';

  @override
  String get nearbyErrPermDenied =>
      'Location permission required. Please try again.';

  @override
  String get nearbyErrTimeout =>
      'Could not get location: timeout. Please try again.';

  @override
  String get nearbyErrPermRequired =>
      'Location permission required. Please enable in settings.';

  @override
  String get nearbyErrGeneric => 'Could not get location. Please try again.';

  @override
  String get nearbyOpenLocationSettings => 'Open Location Settings';

  @override
  String get nearbyOpenAppSettings => 'Open App Settings';

  @override
  String get filterTitle => 'Filter';

  @override
  String get filterReset => 'Reset';

  @override
  String get filterAdvertType => 'Listing Type';

  @override
  String get filterAnimalType => 'Animal Type';

  @override
  String get filterBreed => 'Breed';

  @override
  String get filterVaccine => 'Vaccination';

  @override
  String get filterVaccineAny => 'Any';

  @override
  String get filterVaccinated => 'Vaccinated';

  @override
  String get filterUnvaccinated => 'Unvaccinated';

  @override
  String get filterApply => 'Apply';

  @override
  String get filterAll => 'All';

  @override
  String get profileLoginRequired =>
      'You must be logged in to view the profile.';

  @override
  String get profileDeleteTitle => 'Delete Listing';

  @override
  String get profileDeleteContent =>
      'Are you sure you want to delete this listing? This cannot be undone.';

  @override
  String get profileDeleteSuccess => 'Listing deleted successfully.';

  @override
  String get profileLogoutTitle => 'Log Out';

  @override
  String get profileLogoutContent =>
      'Are you sure you want to log out of your account?';

  @override
  String get profileAdoptionApplications => 'Adoption Applications';

  @override
  String get profileNewAdoptionBtn => 'Adoption';

  @override
  String get profileNewMatingBtn => 'Mating';

  @override
  String get profileLoginBtn => 'Log In';

  @override
  String get profileFavorites => 'Favorites';

  @override
  String get profileOrders => 'Orders';

  @override
  String get profileSitterBtn => 'Sitter';

  @override
  String get profileNotifications => 'Notifications';

  @override
  String get profileMyStore => 'My Store';

  @override
  String get profileNoPetsTitle => 'No listings yet';

  @override
  String get profileNoPetsDesc =>
      'Create your first listing to find a new friend for the community.';

  @override
  String get profileRoleSeller => 'Seller';

  @override
  String get profileRoleSitter => 'Sitter';

  @override
  String get profileRoleAdmin => 'Admin';

  @override
  String profileCompletePercent(int percent) {
    return 'Complete profile — $percent%';
  }

  @override
  String get profileAuthErr =>
      'Session could not be verified. Please try again.';

  @override
  String profileAdsLoadErr(String error) {
    return 'Could not load listings: $error';
  }

  @override
  String get cartTitle => 'My Cart';

  @override
  String get cartClearAction => 'Clear';

  @override
  String get cartClearTitle => 'Clear Cart';

  @override
  String get cartClearContent =>
      'All items in the cart will be removed. Are you sure?';

  @override
  String get cartItemRemoved => 'Item removed from cart';

  @override
  String cartItemRemoveError(String error) {
    return 'Could not remove item: $error';
  }

  @override
  String cartUpdateError(String error) {
    return 'Could not update quantity: $error';
  }

  @override
  String get cartCleared => 'Cart cleared';

  @override
  String cartClearError(String error) {
    return 'Could not clear cart: $error';
  }

  @override
  String get cartEmptyTitle => 'Your Cart is Empty';

  @override
  String get cartEmptyDesc =>
      'You haven\'t added any items yet.\nExplore the store to start shopping!';

  @override
  String get cartShopNow => 'Start Shopping';

  @override
  String get cartContinueShopping => 'Continue Shopping';

  @override
  String get cartCheckout => 'Proceed to Checkout';

  @override
  String get cartItemCount => 'Item Count';

  @override
  String get cartTotalAmount => 'Total Amount';

  @override
  String cartItemTotal(String total) {
    return 'Total: $total ₺';
  }

  @override
  String get cartLoadError => 'Could not load cart';

  @override
  String get cartRetry => 'Try Again';

  @override
  String get sellerPanelTitle => 'Seller Dashboard';

  @override
  String get sellerBecomeSeller => 'Become a Seller';

  @override
  String get sellerBecomeSellerDesc =>
      'You need to be a seller to view this page';

  @override
  String get sellerStoreLoadErr => 'Could not load store info';

  @override
  String get sellerOrderStatsLoadErr => 'Could not load order statistics';

  @override
  String get sellerProductStatsLoadErr => 'Could not load product statistics';

  @override
  String get sellerRevenueChartLoadErr => 'Could not load revenue chart';

  @override
  String get sellerAttentionProducts => 'Products Needing Attention';

  @override
  String get sellerOutOfStock => 'Out of Stock';

  @override
  String get sellerLowStock => 'Low Stock';

  @override
  String get sellerNoStore => 'You Have No Store';

  @override
  String get sellerNoStoreDesc =>
      'Create your store first to start selling products';

  @override
  String get sellerCreateStore => 'Create Store';

  @override
  String get sellerActiveStore => 'Active Store';

  @override
  String get sellerTotalRevenue => 'Total Revenue';

  @override
  String get sellerPendingOrders => 'Pending';

  @override
  String sellerTotalOrdersCount(int count) {
    return '$count total';
  }

  @override
  String get sellerTotalProducts => 'Total Products';

  @override
  String get sellerQuickActions => 'Quick Actions';

  @override
  String get sellerAddProduct => 'Add Product';

  @override
  String get sellerManageProducts => 'Manage My Products';

  @override
  String get sellerViewStore => 'View My Store';

  @override
  String get sellerMyOrders => 'My Orders';

  @override
  String get sellerDemoProducts => 'Add Demo Products';

  @override
  String get sellerDemoProductsLoading => 'Adding Demo Products...';

  @override
  String get sellerDemoProductsTitle => 'Add Demo Products';

  @override
  String get sellerDemoProductsContent =>
      'This will delete all products in your store and replace them with demo products. Do you want to continue?';

  @override
  String get sellerDemoProductsContinue => 'Continue';

  @override
  String sellerDemoProductsAdded(int count) {
    return '$count demo products added successfully!';
  }

  @override
  String sellerErrGeneric(String error) {
    return 'Error: $error';
  }

  @override
  String get sellerLast6Months => 'Last 6 Months';

  @override
  String get sellerChartRevenue => 'Revenue';

  @override
  String get sellerChartOrders => 'Orders';

  @override
  String sellerStockLabel(int count) {
    return 'Stock: $count';
  }

  @override
  String sellerOrderCountTooltip(int count) {
    return '$count orders';
  }

  @override
  String get sellerRetry => 'Refresh';

  @override
  String get productMgmtTitle => 'Product Management';

  @override
  String get productMgmtAll => 'All';

  @override
  String get productMgmtActive => 'Active';

  @override
  String get productMgmtInactive => 'Inactive';

  @override
  String get productMgmtLowStock => 'Low Stock';

  @override
  String get productMgmtOutOfStock => 'Out of Stock';

  @override
  String get productMgmtNoProducts => 'No products added yet';

  @override
  String get productMgmtNoCategoryProducts => 'No products in this category';

  @override
  String get productMgmtAddFirst => 'Add First Product';

  @override
  String get productMgmtAddProduct => 'Add Product';

  @override
  String get productMgmtLoadErr => 'Could not load products';

  @override
  String get productMgmtStatusActive => 'Active';

  @override
  String get productMgmtStatusInactive => 'Inactive';

  @override
  String productMgmtStock(int count) {
    return 'Stock: $count';
  }

  @override
  String get productMgmtStockOutBadge => 'Out of Stock';

  @override
  String get productMgmtStockLowBadge => 'Low';

  @override
  String get productMgmtDeactivate => 'Deactivate';

  @override
  String get productMgmtActivate => 'Activate';

  @override
  String get productMgmtStockAction => 'Stock';

  @override
  String get productMgmtEditAction => 'Edit';

  @override
  String get productMgmtDeleteAction => 'Delete';

  @override
  String get productMgmtToggleDeactivated => 'Product deactivated';

  @override
  String get productMgmtToggleActivated => 'Product activated';

  @override
  String get productMgmtStockUpdated => 'Stock updated';

  @override
  String get productMgmtEditSoon => 'Product editing coming soon';

  @override
  String get productMgmtDeleteTitle => 'Delete Product';

  @override
  String productMgmtDeleteContent(String name) {
    return 'Are you sure you want to delete \"$name\"?';
  }

  @override
  String get productMgmtDeleteWarning => 'This action cannot be undone!';

  @override
  String get productMgmtDeleted => 'Product deleted';

  @override
  String get productMgmtUpdateStockTitle => 'Update Stock';

  @override
  String get productMgmtCurrentStock => 'Current Stock';

  @override
  String get productMgmtStockUnit => 'units';

  @override
  String get productMgmtStockChange => 'Set';

  @override
  String get productMgmtStockIncrease => 'Increase';

  @override
  String get productMgmtStockDecrease => 'Decrease';

  @override
  String get productMgmtNewStockAmt => 'New Stock Amount';

  @override
  String get productMgmtAddAmt => 'Amount to Add';

  @override
  String get productMgmtSubtractAmt => 'Amount to Subtract';

  @override
  String get productMgmtEnterAmt => 'Enter amount';

  @override
  String get productMgmtUpdate => 'Update';

  @override
  String get matchReqNoRequests => 'No requests yet.';

  @override
  String matchReqSenderLabel(String name) {
    return 'Sender: $name';
  }

  @override
  String matchReqReceiverLabel(String name) {
    return 'Receiver: $name';
  }

  @override
  String matchReqSenderPet(String name) {
    return 'Sender\'s pet: $name';
  }

  @override
  String matchReqSelectedPet(String name) {
    return 'Selected pet: $name';
  }

  @override
  String get matchReqViewListing => 'View sender\'s listing';

  @override
  String matchReqActDone(String action) {
    return 'Action completed: $action';
  }

  @override
  String matchReqMatchSuccess(String name) {
    return 'Match successful! Redirecting you to chat with $name...';
  }

  @override
  String get matchReqGoNow => 'Go Now';

  @override
  String matchReqChatError(String error) {
    return 'Could not open chat: $error';
  }

  @override
  String get matchReqAccept => 'Accept';

  @override
  String get matchReqReject => 'Reject';

  @override
  String get matchReqGoToChat => 'Go to chat';

  @override
  String get loginTitle => 'Sign In';

  @override
  String get loginEmailError => 'Enter a valid email';

  @override
  String get loginPasswordError => 'At least 6 characters';

  @override
  String get loginNoAccount => 'Don\'t have an account?';

  @override
  String get registerTitle => 'Create Account';

  @override
  String get registerNameError => 'Name is required';

  @override
  String get registerPasswordConfirmHint => 'Confirm Password';

  @override
  String get registerPasswordMismatch => 'Passwords do not match';

  @override
  String get registerHasAccount => 'Already have an account?';

  @override
  String get forgotTitle => 'Forgot Password';

  @override
  String get forgotDesc => 'Enter your email address to reset your password.';

  @override
  String get forgotSubmit => 'Send Code';

  @override
  String get forgotSuccessTitle => 'Email Sent!';

  @override
  String forgotSuccessDesc(String email) {
    return 'We sent a password reset code to $email.';
  }

  @override
  String get forgotEnterCode => 'Enter Code';

  @override
  String get resetTitle => 'Reset Password';

  @override
  String resetDesc(String email) {
    return 'Enter the code sent to $email.';
  }

  @override
  String get resetCodeHint => 'Verification Code';

  @override
  String get resetCodeError => 'Code is required';

  @override
  String get resetNewPasswordHint => 'New Password';

  @override
  String get resetPasswordError => 'At least 6 characters';

  @override
  String get resetSubmit => 'Reset Password';

  @override
  String get resetSuccess => 'Your password has been reset successfully!';

  @override
  String get createPetEditTitle => 'Edit Listing';

  @override
  String get createPetNewTitle => 'New Listing';

  @override
  String get createPetUpdateDesc => 'Update listing information';

  @override
  String get createPetNewDesc => 'Create new listing';

  @override
  String get createPetHeroDesc =>
      'Choose listing type, add photos/videos and find the right home for your pet.';

  @override
  String get createPetAdoptionChip => 'Adoption listing';

  @override
  String get createPetMatingChip => 'Mating listing';

  @override
  String get createPetBasicInfo => 'Basic Information';

  @override
  String get createPetNameLabel => 'Name';

  @override
  String get createPetNameError => 'Name is required';

  @override
  String get createPetSpeciesLabel => 'Species';

  @override
  String get createPetGenderLabel => 'Gender';

  @override
  String get createPetVaccinatedTitle => 'Vaccinations complete';

  @override
  String get createPetVaccinatedSubtitle =>
      'Vaccination info will be shown as a badge on the listing.';

  @override
  String get createPetDetailsSection => 'Details';

  @override
  String get createPetAgeLabel => 'Age (Months)';

  @override
  String get createPetAgeError => 'Age is required';

  @override
  String get createPetAgeInvalidError => 'Enter a valid number';

  @override
  String get createPetBreedLabel => 'Breed';

  @override
  String get createPetBreedSelect => 'Select';

  @override
  String get createPetBreedSearch => 'Search breed...';

  @override
  String get createPetDescLabel => 'Description';

  @override
  String get createPetDescHint => 'Personality, health status and needs';

  @override
  String get createPetLocationSelected => 'Location selected';

  @override
  String get createPetLocationAdd => 'Add location';

  @override
  String get createPetLocationHint => 'Open map to select city/district';

  @override
  String get createPetMedia => 'Photos & Video';

  @override
  String get createPetAddPhotoBtn => 'Add photo';

  @override
  String get createPetAddVideoBtn => 'Add video';

  @override
  String get createPetSave => 'Save';

  @override
  String get createPetPublish => 'Publish';

  @override
  String get shellOfflineBanner => 'No internet connection';

  @override
  String get shellReconnected => 'Internet connection restored';

  @override
  String get shellApptSnackView => 'View';

  @override
  String get shellAdvertsNav => 'My Listings';

  @override
  String get shellGuideFab => 'Guide Pati';

  @override
  String get addressEditTitle => 'Edit Address';

  @override
  String get addressNewTitle => 'New Address';

  @override
  String get addressUpdated => 'Address updated';

  @override
  String get addressAdded => 'Address added';

  @override
  String addressSaveErr(String error) {
    return 'Error: $error';
  }

  @override
  String get addressInfoCard => 'Address Info';

  @override
  String get addressTitleLabel => 'Address Title';

  @override
  String get addressTitleHint => 'Home, Work, etc.';

  @override
  String get addressRecipientCard => 'Recipient Info';

  @override
  String get addressFullName => 'Full Name';

  @override
  String get addressFullNameHint => 'Person receiving the delivery';

  @override
  String get addressPhone => 'Phone';

  @override
  String get addressDetailsCard => 'Address Details';

  @override
  String get addressCity => 'City';

  @override
  String get addressCityHint => 'Istanbul';

  @override
  String get addressDistrict => 'District';

  @override
  String get addressDistrictHint => 'Kadıköy';

  @override
  String get addressNeighborhood => 'Neighborhood';

  @override
  String get addressNeighborhoodHint => 'Neighborhood name';

  @override
  String get addressStreet => 'Street/Avenue';

  @override
  String get addressStreetHint => 'Street or avenue name';

  @override
  String get addressBuildingNo => 'Building No';

  @override
  String get addressFloor => 'Floor';

  @override
  String get addressApartmentNo => 'Apt No';

  @override
  String get addressPostalCode => 'Postal Code';

  @override
  String get addressPreferencesCard => 'Preferences';

  @override
  String get addressSetDefault => 'Set as default address';

  @override
  String get addressSetDefaultSub =>
      'This address will be auto-selected in orders';

  @override
  String get addressUpdate => 'Update';

  @override
  String addressRequired(String field) {
    return '$field is required';
  }

  @override
  String get verifyTitle => 'Verify Email';

  @override
  String verifyDesc(String email) {
    return 'We sent a verification code to $email.';
  }

  @override
  String get verifyCodeLabel => 'Verification Code';

  @override
  String get verifySubmit => 'Verify';

  @override
  String get verifySuccess => 'Email verified! You can now sign in.';

  @override
  String get verifyBackToLogin => 'Back to login';

  @override
  String get userProfileLoadErr => 'Could not load profile';

  @override
  String get userProfileAbout => 'About';

  @override
  String userProfileListings(int count) {
    return 'Listings ($count)';
  }

  @override
  String get userProfileNoListings => 'No listings yet';

  @override
  String get userProfileMessageTooltip => 'Send message';

  @override
  String userProfileChatErr(String error) {
    return 'Could not start chat: $error';
  }

  @override
  String userProfileMemberSince(int year) {
    return 'Member since $year';
  }

  @override
  String get userProfileDefaultName => 'User';

  @override
  String get userProfileTypeAdopt => 'Adopt';

  @override
  String get userProfileTypeMating => 'Mating';

  @override
  String get userProfileTypeLost => 'Lost';

  @override
  String get shellBirthdayDefault => 'Your pet\'s birthday is today!';

  @override
  String get shellApptReminderDefault => 'Your pet';

  @override
  String get shellAdvertExpiryDefault => 'Your listing is about to expire.';

  @override
  String get vacCalendarTitle => 'Vaccination Calendar';

  @override
  String vacCalendarLoadErr(String error) {
    return 'Error: $error';
  }

  @override
  String get vacCalendarEmpty => 'No vaccination schedule found';

  @override
  String get vacCalendarAddRecord => 'Add Vaccination Record';

  @override
  String get vacCalendarNoRecord => 'No records for this day';

  @override
  String get vacCalendarClickDay => 'Click a day';

  @override
  String get vacCalendarAdd => 'Add';

  @override
  String vacCalendarFirstDose(int months) {
    return 'First Dose: $months mo';
  }

  @override
  String vacCalendarRepeat(int months) {
    return 'Repeat: $months mo';
  }

  @override
  String get vacCalendarRequired => 'Required';

  @override
  String vacCalendarNext(String date) {
    return 'Next: $date';
  }

  @override
  String get vetSearchTitle => 'Search Veterinary';

  @override
  String get vetSearchGoogleTitle => 'Search with Google';

  @override
  String get vetSearchSortTooltip => 'Sort';

  @override
  String get vetSearchSortByDistance => 'By Distance';

  @override
  String get vetSearchSortByRating => 'By Rating';

  @override
  String get vetSearchHint => 'Clinic name or address...';

  @override
  String get vetSearchUseLocation => 'Use my location';

  @override
  String get vetSearchErrPermission => 'Location permission required';

  @override
  String vetSearchErrLocation(String error) {
    return 'Could not get location: $error';
  }

  @override
  String get vetSearchPrompt => 'Type above to search or share your location';

  @override
  String get vetSearchNoResults => 'No results found';

  @override
  String get vetHomeTabSearch => 'Search';

  @override
  String get vetHomeTabAppointments => 'Appointments';

  @override
  String get vetHomeTabVaccine => 'Vaccine Schedule';

  @override
  String get vetHomeSearchHint => 'Search veterinary clinic...';

  @override
  String get vetHomeNearMe => 'Near Me';

  @override
  String get vetHomeSaveClinic => 'Register Clinic';

  @override
  String get vetHomeGoogleSearch => 'Search with Google';

  @override
  String get vetHomeReminders => 'Reminders';

  @override
  String get vetHomeNearbyTitle => 'Nearby Veterinarians';

  @override
  String get vetHomeNearbyPermRequired =>
      'Allow location access to see nearby vets';

  @override
  String get vetHomeNearbyEmpty => 'No nearby vets found';

  @override
  String get vetHomeApptsEmpty => 'No appointments yet';

  @override
  String get vetHomeApptsEmptyDesc =>
      'Search for a vet and book an appointment';

  @override
  String get vetHomeVaccineTitle => 'Vaccine Reminders';

  @override
  String get vetHomeVaccineEmpty => 'No upcoming vaccine reminders';

  @override
  String get vetHomeVaccineEmptyDesc =>
      'View the vaccine schedule from your pet\'s profile page';

  @override
  String get vetHomeVaccineOverdue => 'Overdue';

  @override
  String get vetHomeVaccineUpcoming => 'Upcoming';

  @override
  String vetHomeLoadError(String error) {
    return 'Error: $error';
  }

  @override
  String get storeHomeLive => 'Live Store';

  @override
  String get storeHomeLiveDesc => 'Real stores and real products are here.';

  @override
  String get storeHomeQuickExplore => 'Quick explore';

  @override
  String get storeHomeAll => 'All';

  @override
  String get storeHomeFeatured => 'Featured stores';

  @override
  String get storeHomeNoDesc => 'No description.';

  @override
  String get storeHomeGoToStore => 'Go to store';

  @override
  String get storeHomeProducts => 'Products';

  @override
  String get storeHomeLatest => 'Latest';

  @override
  String get storeNoDescAdded => 'No description added.';

  @override
  String get storeHomeCategoryLoadErr => 'Could not load categories.';

  @override
  String get storeHomeFeaturedEmpty => 'No featured stores for now.';

  @override
  String get storeHomeStoresLoadErr => 'Could not load stores.';

  @override
  String get storeHomeProductsEmpty => 'No products found';

  @override
  String get storeHomeProductsNotFound =>
      'No products match your search criteria.';

  @override
  String get storeHomeProductsNone => 'No products added yet.';

  @override
  String get storeHomeProductsLoadErr => 'Could not load products.';

  @override
  String get storeHomeFiltersClear => 'Clear filters';

  @override
  String storeHomeMyStoreLoadErr(String error) {
    return 'Could not get your store: $error';
  }

  @override
  String get storeHomeCategoryNotFound => 'Category not found.';

  @override
  String get storeHomeSearchHint => 'Search product or store';

  @override
  String get storeHomeSearchBtn => 'Search';

  @override
  String get storeHomeOpenStore => 'Open a store, showcase your products!';

  @override
  String get storeHomeOpenStoreDesc => 'Apply in minutes, reach pet lovers.';

  @override
  String get storeHomeOpenStoreBtn => 'Open Store';

  @override
  String get storeHomeRetry => 'Retry';

  @override
  String get storeMyCouponsLabel => 'My Coupons & Deals';

  @override
  String get productDetailSelectAllVariants => 'Please select all options';

  @override
  String get productVariantsTitle => 'Variants';

  @override
  String get productVariantsDesc => 'Options like size, color, dimension';

  @override
  String get productVariantAdd => 'Add';

  @override
  String get productVariantNameHint => 'Variant name (e.g. Size, Color)';

  @override
  String get productVariantLabelHint => 'Label (e.g. S, Red)';

  @override
  String get storeHomeSoldOut => 'Sold Out';

  @override
  String storeHomeLastStock(int count) {
    return 'Last $count';
  }

  @override
  String get storePriceAsc => 'Price ↑';

  @override
  String get storePriceDesc => 'Price ↓';

  @override
  String get storeNameAz => 'A–Z';

  @override
  String get storesListTitle => 'Stores';

  @override
  String get storesListSearchHint => 'Search store...';

  @override
  String get storesListEmpty => 'No stores yet';

  @override
  String get storesListSearchEmpty => 'No search results found';

  @override
  String get storesListLoadErr => 'Could not load stores';

  @override
  String get storesListRetry => 'Retry';

  @override
  String get storeDetailTitle => 'Store';

  @override
  String get storeDetailLoadErr => 'Could not load store';

  @override
  String get storeDetailProductsLoadErr => 'Could not load products';

  @override
  String get storeDetailNoProducts => 'This store has no products yet.';

  @override
  String get storeDetailTotalProducts => 'Total products';

  @override
  String get storeDetailAddProduct => 'Add product';

  @override
  String get storeDetailFavorited => 'In favorites';

  @override
  String get storeDetailAddToFavorites => 'Add to favorites';

  @override
  String get storeDetailRemovedFav => 'Removed from favorites';

  @override
  String get storeDetailAddedFav => 'Added to favorites';

  @override
  String storeDetailFavError(String error) {
    return 'Error: $error';
  }

  @override
  String get storeDetailShare => 'Share';

  @override
  String get storeDetailProductActive => 'Active';

  @override
  String get storeDetailProductInactive => 'Inactive';

  @override
  String get storeDetailProductSoldOut => 'Sold Out';

  @override
  String storeDetailProductStock(int count) {
    return 'Stock: $count';
  }

  @override
  String get storeDetailMenuEdit => 'Edit';

  @override
  String get storeDetailMenuToggle => 'Active/Inactive';

  @override
  String get storeDetailMenuDelete => 'Delete';

  @override
  String get storeDetailDeleteTitle => 'Delete product';

  @override
  String get storeDetailDeleteContent =>
      'Are you sure you want to delete this product?';

  @override
  String get storeDetailDeleteCancel => 'Cancel';

  @override
  String get storeDetailProductActivated => 'Product activated.';

  @override
  String get storeDetailProductDeactivated => 'Product deactivated.';

  @override
  String storeDetailProductUpdateErr(String error) {
    return 'Could not update product: $error';
  }

  @override
  String get storeDetailProductDeleted => 'Product deleted.';

  @override
  String storeDetailProductDeleteErr(String error) {
    return 'Could not delete product: $error';
  }

  @override
  String get storeDetailRetry => 'Retry';

  @override
  String get applySellerTitle => 'Open Store';

  @override
  String get applySellerLogoTitle => 'Select Store Logo';

  @override
  String get applySellerPickGallery => 'Choose from Gallery';

  @override
  String get applySellerPickCamera => 'Open Camera';

  @override
  String get applySellerLogoSection => 'Store Logo';

  @override
  String get applySellerLogoAdd => 'Add Logo';

  @override
  String get applySellerLogoHint =>
      'Square format, minimum 200x200 pixels recommended';

  @override
  String get applySellerInfoSection => 'Store Information';

  @override
  String get applySellerNameLabel => 'Store Name *';

  @override
  String get applySellerNameHint => 'E.g.: Happy Pets Store';

  @override
  String get applySellerNameRequired => 'Store name is required';

  @override
  String get applySellerNameTooShort => 'Must be at least 3 characters';

  @override
  String get applySellerDescLabel => 'Store Description';

  @override
  String get applySellerDescHint => 'Introduce your store...';

  @override
  String get applySellerTermsTitle => 'Seller Agreement';

  @override
  String get applySellerTermsAccepted => 'Accepted';

  @override
  String get applySellerTermsRead =>
      'I have read and accept the seller agreement';

  @override
  String get applySellerTermsDialogTitle => 'Seller Agreement';

  @override
  String get applySellerTermsAcceptBtn => 'I Have Read and Accept';

  @override
  String get applySellerStepLogo => 'Logo';

  @override
  String get applySellerStepInfo => 'Info';

  @override
  String get applySellerStepContract => 'Agreement';

  @override
  String get applySellerOpenBtn => 'Open My Store';

  @override
  String get applySellerApprovalNote =>
      'You can start adding products after your store is approved.';

  @override
  String get applySellerSuccessTitle => 'Congratulations!';

  @override
  String applySellerSuccessDesc(String storeName) {
    return 'Your store \"$storeName\" has been successfully created!';
  }

  @override
  String get applySellerGoToStore => 'OK';

  @override
  String get applySellerGenericError => 'An error occurred, please try again.';

  @override
  String get applySellerCompanyTitleLabel => 'Company Title *';

  @override
  String get applySellerCompanyTitleHint => 'E.g.: ABC Pet Products Ltd.';

  @override
  String get applySellerCompanyTitleRequired => 'Company title is required';

  @override
  String get applySellerTaxNumberLabel => 'Tax Number *';

  @override
  String get applySellerTaxNumberHint => '10-digit tax number';

  @override
  String get applySellerTaxNumberRequired => 'Tax number is required';

  @override
  String get applySellerTaxOfficeLabel => 'Tax Office *';

  @override
  String get applySellerTaxOfficeHint => 'E.g.: Kadıköy Tax Office';

  @override
  String get applySellerTaxOfficeRequired => 'Tax office is required';

  @override
  String get applySellerAddressLabel => 'Company Address *';

  @override
  String get applySellerAddressHint => 'Enter full address...';

  @override
  String get applySellerAddressRequired => 'Company address is required';

  @override
  String get applySellerContactInfoLabel => 'Contact Info *';

  @override
  String get applySellerContactInfoHint => 'Phone or email';

  @override
  String get applySellerContactInfoRequired => 'Contact info is required';

  @override
  String get applySellerIbanLabel => 'IBAN *';

  @override
  String get applySellerIbanHint => '26-digit IBAN starting with TR';

  @override
  String get applySellerIbanRequired => 'IBAN is required';

  @override
  String get applySellerIbanInvalid => 'Enter a valid IBAN (must start with TR)';

  @override
  String get applySellerNameTooLong => 'Must be at most 120 characters';

  @override
  String get applySellerLegalInfoSection => 'Legal Information';

  @override
  String get addProductTitle => 'Add Product';

  @override
  String get addProductEditTitle => 'Edit Product';

  @override
  String get addProductPhotosSection => 'Product Photos';

  @override
  String get addProductPickGallery => 'Choose from Gallery';

  @override
  String get addProductPickGallerySub => 'Select from your existing photos';

  @override
  String get addProductPickCamera => 'Open Camera';

  @override
  String get addProductPickCameraSub => 'Take a new photo';

  @override
  String get addProductPickDialogTitle => 'Add Photo';

  @override
  String get addProductAddBtn => 'Add';

  @override
  String addProductMaxWarning(int max) {
    return 'You can add at most $max photos';
  }

  @override
  String addProductPhotosHint(int max) {
    return 'Add photos of your product (max $max)';
  }

  @override
  String get addProductTitleField => 'Product Title';

  @override
  String get addProductTitleHint => 'E.g.: Colorful cat toy';

  @override
  String get addProductTitleRequired => 'Title is required';

  @override
  String get addProductCategoryLabel => 'Category';

  @override
  String get addProductCategoryRequired => 'Select a category';

  @override
  String get addProductDescLabel => 'Description';

  @override
  String get addProductDescHint => 'Product features, size, material...';

  @override
  String get addProductPriceLabel => 'Price';

  @override
  String get addProductPriceRequired => 'Required';

  @override
  String get addProductPriceInvalid => 'Invalid';

  @override
  String get addProductStockLabel => 'Stock';

  @override
  String get addProductActiveLabel => 'Product Active';

  @override
  String get addProductInactiveLabel => 'Product Inactive';

  @override
  String get addProductSaving => 'Saving...';

  @override
  String get addProductSaveBtn => 'Save';

  @override
  String get addProductUpdated => 'Product updated!';

  @override
  String get addProductAdded => 'Product added!';

  @override
  String get addProductCategoryLoadErr => 'Could not load categories.';

  @override
  String get addProductCategoryNotFound => 'Category not found.';

  @override
  String get addProductRetry => 'Retry';

  @override
  String addProductCategoryLoading(String label) {
    return 'Loading $label...';
  }

  @override
  String get sellerOrdersTitle => 'My Orders';

  @override
  String get sellerOrdersTabAll => 'All';

  @override
  String get sellerOrdersTabPending => 'Pending';

  @override
  String get sellerOrdersTabProcessing => 'Processing';

  @override
  String get sellerOrdersTabShipped => 'Shipped';

  @override
  String get sellerOrdersTabCompleted => 'Completed';

  @override
  String get sellerOrdersEmpty => 'No orders yet';

  @override
  String get sellerOrdersEmptyDesc =>
      'Orders for your products will appear here';

  @override
  String sellerOrdersLoadErr(String error) {
    return 'Could not load orders: $error';
  }

  @override
  String get sellerOrdersCategoryEmpty => 'No orders in this category';

  @override
  String get sellerOrdersStatusUpdated => 'Order status updated';

  @override
  String sellerOrdersStatusError(String error) {
    return 'Error: $error';
  }

  @override
  String get sellerOrdersStatTotal => 'Total';

  @override
  String get sellerOrdersStatPending => 'Pending';

  @override
  String get sellerOrdersStatSales => 'Sales';

  @override
  String get sellerOrdersStatRevenue => 'Revenue';

  @override
  String get sellerOrdersPrepare => 'Prepare';

  @override
  String get sellerOrdersShip => 'Ship';

  @override
  String get sellerOrdersDelivered => 'Delivered';

  @override
  String sellerOrdersItemCount(int count) {
    return '$count items';
  }

  @override
  String sellerOrdersItemQty(int qty, String price) {
    return '$qty pcs x \$$price';
  }

  @override
  String get petCardMating => 'Mating';

  @override
  String get petCardAdoption => 'Adoption';

  @override
  String get petCardVaccinated => 'Vaccinated';

  @override
  String get petCardOwnerUnknown => 'Unknown';

  @override
  String get apptCreateTitle => 'Create Appointment';

  @override
  String get apptCreateSelectPet => 'Select Pet';

  @override
  String get apptCreateDate => 'Date';

  @override
  String get apptCreateTime => 'Time';

  @override
  String get apptCreateReason => 'Reason for Appointment';

  @override
  String get apptCreateNotes => 'Notes (optional)';

  @override
  String get apptCreateBtn => 'Create Appointment';

  @override
  String get apptCreateSuccess => 'Appointment created!';

  @override
  String get apptCreateSelectDateBtn => 'Select date';

  @override
  String get apptCreateNoPets => 'You haven\'t added any pets yet';

  @override
  String get apptCreateNoSlots => 'No available slots on this date';

  @override
  String get apptCreateValidation => 'Please select pet, date and time';

  @override
  String apptCreateSlotsError(String error) {
    return 'Could not get slots: $error';
  }

  @override
  String apptCreatePetsError(String error) {
    return 'Could not load pets: $error';
  }

  @override
  String apptCreateError(String error) {
    return 'Error: $error';
  }

  @override
  String get apptDetailTitle => 'Appointment Detail';

  @override
  String get apptDetailDate => 'Date and Time';

  @override
  String get apptDetailVet => 'Veterinarian';

  @override
  String get apptDetailPet => 'Pet';

  @override
  String get apptDetailReason => 'Reason for Appointment';

  @override
  String get apptDetailNotes => 'Notes';

  @override
  String get apptDetailVetNotes => 'Vet Notes';

  @override
  String get apptDetailCancelBtn => 'Cancel Appointment';

  @override
  String get apptDetailCancelTitle => 'Cancel Appointment';

  @override
  String get apptDetailCancelContent =>
      'Are you sure you want to cancel the appointment?';

  @override
  String get apptDetailCancelConfirm => 'Cancel';

  @override
  String get apptDetailCancelBack => 'Go Back';

  @override
  String get apptDetailCancelSuccess => 'Appointment cancelled';

  @override
  String apptDetailError(String error) {
    return 'Error: $error';
  }

  @override
  String get vetRegisterTitle => 'Register Clinic';

  @override
  String get vetRegisterClinicName => 'Clinic Name *';

  @override
  String get vetRegisterAddress => 'Address *';

  @override
  String get vetRegisterPhone => 'Phone';

  @override
  String get vetRegisterEmail => 'Email';

  @override
  String get vetRegisterDesc => 'Description';

  @override
  String vetRegisterLocationLabel(String lat, String lng) {
    return 'Location: $lat, $lng';
  }

  @override
  String get vetRegisterLocationNone => 'No location added';

  @override
  String get vetRegisterGetLocation => 'Get Location';

  @override
  String get vetRegisterGettingLocation => 'Getting...';

  @override
  String get vetRegisterSpecies => 'Species Served';

  @override
  String get vetRegisterSaveBtn => 'Save';

  @override
  String get vetRegisterSuccess =>
      'Clinic registered and linked to your account!';

  @override
  String get vetRegisterClinicNameRequired => 'Clinic name is required';

  @override
  String get vetRegisterAddressRequired => 'Address is required';

  @override
  String vetRegisterLocationError(String error) {
    return 'Could not get location: $error';
  }

  @override
  String get vetRegisterLocationDenied =>
      'Location permission denied. Please allow it in settings.';

  @override
  String vetRegisterError(String error) {
    return 'Error: $error';
  }

  @override
  String get searchHint => 'Search listings, stores or vets...';

  @override
  String get searchTypeHint => 'Type what you want to search';

  @override
  String get searchTypeHintSub => 'You can search listings, stores or vets';

  @override
  String get searchHistory => 'Recent Searches';

  @override
  String get searchClearHistory => 'Clear All';

  @override
  String searchError(String error) {
    return 'Search error: $error';
  }

  @override
  String searchNoResults(String query) {
    return 'No results found for \"$query\"';
  }

  @override
  String get searchSectionListings => 'Listings';

  @override
  String get searchSectionStores => 'Stores';

  @override
  String get searchSectionVets => 'Vets';

  @override
  String get searchStoreSubtitle => 'Store';

  @override
  String get searchVetSubtitle => 'Vet';

  @override
  String get aiAssistantTitle => 'Pati Assistant';

  @override
  String get aiModeReset => 'Reset';

  @override
  String get aiModeDiagnosis => 'Diagnosis';

  @override
  String get aiModeGeneral => 'General';

  @override
  String get aiSymptomLabel => 'Select symptoms (multiple):';

  @override
  String get aiDiagnoseBtn => 'Diagnose →';

  @override
  String aiSymptomSelected(String symptoms) {
    return 'Selected: $symptoms';
  }

  @override
  String get aiWelcomeDiagnosis => 'Select or type symptom → Get diagnosis';

  @override
  String get aiWelcomeGeneral => 'What do you want to ask about your pet?';

  @override
  String get aiWelcomeDiagnosisSub =>
      'Select the species and symptoms above,\nor type directly in the text box.';

  @override
  String get aiWelcomeGeneralSub =>
      'Get short and practical answers\nabout care, nutrition, and training.';

  @override
  String get aiExampleLabel => 'Example questions:';

  @override
  String get aiInputDiagnosisHint => 'Add extra info or type directly...';

  @override
  String get aiInputGeneralHint => 'Type your question...';

  @override
  String get aiErrorResponse =>
      'Sorry, I can\'t respond right now. Please try again.';

  @override
  String get aiNoReply => 'No reply received.';

  @override
  String get guideTitle => 'Guide Pati';

  @override
  String get guideNewChat => 'New chat';

  @override
  String get guideWelcome => 'Hello! 👋';

  @override
  String get guideWelcomeSub =>
      'What do you want to do?\nLet me help you the fastest way.';

  @override
  String get guideQuickOptions => 'Quick options:';

  @override
  String get guideNavigateBtn => 'Take me there →';

  @override
  String get guideInputHint => 'What do you want to do?';

  @override
  String get guideConnError => 'Connection error, please try again.';

  @override
  String get guideUnknown => 'I didn\'t understand.';

  @override
  String get monthJan => 'Jan';

  @override
  String get monthFeb => 'Feb';

  @override
  String get monthMar => 'Mar';

  @override
  String get monthApr => 'Apr';

  @override
  String get monthMay => 'May';

  @override
  String get monthJun => 'Jun';

  @override
  String get monthJul => 'Jul';

  @override
  String get monthAug => 'Aug';

  @override
  String get monthSep => 'Sep';

  @override
  String get monthOct => 'Oct';

  @override
  String get monthNov => 'Nov';

  @override
  String get monthDec => 'Dec';

  @override
  String get sitterFindTitle => 'Find a Sitter';

  @override
  String get sitterMyBookingsTooltip => 'My Bookings';

  @override
  String get sitterServiceAll => 'All';

  @override
  String get sitterServiceWalking => 'Walking';

  @override
  String get sitterServiceHomeSitting => 'Home Sitting';

  @override
  String get sitterServiceBoarding => 'Boarding';

  @override
  String get sitterServiceDaycare => 'Daycare';

  @override
  String get sitterServiceGrooming => 'Grooming';

  @override
  String get sitterEmptyTitle => 'No sitters found nearby';

  @override
  String get sitterEmptySubtitle =>
      'Create the first sitter profile and serve other users!';

  @override
  String get sitterBecomeSitterBtn => 'Become a Sitter';

  @override
  String get sitterEditProfile => 'Edit Profile';

  @override
  String get sitterBasicInfo => 'Basic Information';

  @override
  String get sitterDisplayName => 'Display Name *';

  @override
  String get sitterDisplayNameRequired => 'Name is required';

  @override
  String get sitterBio => 'About / Introduction';

  @override
  String get sitterExperience => 'Experience';

  @override
  String get sitterLocation => 'Location';

  @override
  String get sitterUseLocation => 'Use My Location';

  @override
  String get sitterLocationObtained => 'Location Obtained ✓';

  @override
  String get sitterAddress => 'Address / Neighborhood';

  @override
  String get sitterSpeciesTitle => 'Which Animals Do You Work With?';

  @override
  String get sitterSpeciesDog => 'Dog';

  @override
  String get sitterSpeciesCat => 'Cat';

  @override
  String get sitterSpeciesBird => 'Bird';

  @override
  String get sitterSpeciesRabbit => 'Rabbit';

  @override
  String get sitterSpeciesOther => 'Other';

  @override
  String get sitterServicesTitle => 'Services You Offer';

  @override
  String get sitterServicesAdd => 'Add';

  @override
  String get sitterServicesAllAdded => 'All services added';

  @override
  String get sitterServiceType => 'Service Type';

  @override
  String get sitterServiceWalkingLabel => 'Walking';

  @override
  String get sitterServiceHomeSittingLabel => 'Home Sitting';

  @override
  String get sitterServiceBoardingLabel => 'Boarding';

  @override
  String get sitterServiceDaycareLabel => 'Daycare';

  @override
  String get sitterServiceGroomingLabel => 'Grooming/Care';

  @override
  String get sitterHourlyPrice => 'Hourly Rate (₺)';

  @override
  String get sitterDailyPrice => 'Daily Rate (₺)';

  @override
  String get sitterSpeciesRequired => 'Select at least one animal type';

  @override
  String get sitterLocationPermRequired => 'Location permission required';

  @override
  String sitterLocationErr(String error) {
    return 'Could not get location: $error';
  }

  @override
  String get sitterAvailableNow => 'Available Now';

  @override
  String get sitterCurrentlyBusy => 'Currently Busy';

  @override
  String get sitterVerifiedLabel => 'Verified';

  @override
  String get sitterAboutSection => 'About';

  @override
  String get sitterServicesAndPrices => 'Services & Prices';

  @override
  String get sitterPhotosSection => 'Photos';

  @override
  String get sitterReviewsSection => 'Reviews';

  @override
  String sitterHourlyRate(int price) {
    return '$price TL/hr';
  }

  @override
  String sitterDailyRate(int price) {
    return '$price TL/day';
  }

  @override
  String get sitterErrorPrefix => 'Error: ';

  @override
  String get sitterProfileUpdated => 'Profile updated!';

  @override
  String get sitterProfileCreated => 'Sitter profile created!';

  @override
  String sitterSubmitErr(String error) {
    return 'Error: $error';
  }

  @override
  String get sitterCreateBtn => 'Create Sitter Profile';

  @override
  String get sitterUpdateBtn => 'Update Profile';

  @override
  String get bookingsTitle => 'Bookings';

  @override
  String get bookingsTabMine => 'My Bookings';

  @override
  String get bookingsTabIncoming => 'Incoming Requests';

  @override
  String get bookingsEmptyTitle => 'No bookings yet';

  @override
  String get bookingsEmptySubtitle => 'Confirmed bookings will appear here.';

  @override
  String get bookingsOwnerLabel => 'Owner';

  @override
  String get bookingsSitterLabel => 'Sitter';

  @override
  String get bookingsAccept => 'Accept';

  @override
  String get bookingsReject => 'Reject';

  @override
  String get bookingsMarkCompleted => 'Mark as Completed';

  @override
  String get bookingsReview => 'Review';

  @override
  String get bookingsReviewDialogTitle => 'Rate the Sitter';

  @override
  String get bookingsReviewHint => 'Comment (optional)';

  @override
  String get bookingsReviewCancel => 'Cancel';

  @override
  String get bookingsReviewSend => 'Send';

  @override
  String bookingsActionErr(String error) {
    return 'Error: $error';
  }

  @override
  String get adoptionAppsTitle => 'Adoption Applications';

  @override
  String get adoptionAppsTabInbox => 'Received Applications';

  @override
  String get adoptionAppsTabSent => 'Sent';

  @override
  String get adoptionAppsInboxEmpty => 'No incoming applications';

  @override
  String get adoptionAppsInboxEmptyDesc =>
      'Applications for your adoption listings will appear here.';

  @override
  String get adoptionAppsSentEmpty => 'No sent applications';

  @override
  String get adoptionAppsSentEmptyDesc =>
      'Applications you sent to adoption listings will appear here.';

  @override
  String adoptionAppsErrGeneric(String error) {
    return 'Error: $error';
  }

  @override
  String get adoptionAppsAcceptTitle => 'Accept Application';

  @override
  String get adoptionAppsRejectTitle => 'Reject Application';

  @override
  String get adoptionAppsAcceptContent =>
      'Are you sure you want to accept this application? A conversation will be started.';

  @override
  String get adoptionAppsRejectContent =>
      'Are you sure you want to reject this application?';

  @override
  String get adoptionAppsCancel => 'Cancel';

  @override
  String get adoptionAppsAcceptBtn => 'Accept';

  @override
  String get adoptionAppsRejectBtn => 'Reject';

  @override
  String get adoptionAppsAcceptedStarted =>
      'Application accepted! Conversation started.';

  @override
  String get adoptionAppsAccepted => 'Application accepted';

  @override
  String get adoptionAppsRejected => 'Application rejected';

  @override
  String get adoptionAppsGoToChat => 'Go to Chat';

  @override
  String adoptionAppsApplicant(String name) {
    return 'Applicant: $name';
  }

  @override
  String get adoptionAppsListing => 'Listing';

  @override
  String get adoptionAppsStatusAccepted => 'Accepted';

  @override
  String get adoptionAppsStatusRejected => 'Rejected';

  @override
  String get adoptionAppsStatusCancelled => 'Cancelled';

  @override
  String get adoptionAppsStatusPending => 'Pending';

  @override
  String get adoptionAppsTimelineApplication => 'Application';

  @override
  String get adoptionAppsTimelineReview => 'Review';

  @override
  String get adoptionAppsTimelineApproval => 'Approval';

  @override
  String get adoptionAppsTimelineCompleted => 'Completed';

  @override
  String get adoptionAppsTimelineRejected => 'Rejected';

  @override
  String get adoptionAppsTimelineCancelled => 'Cancelled';

  @override
  String get adoptionAppsTimelineDecision => 'Decision';

  @override
  String get adoptionApplyTitle => 'Adoption Application';

  @override
  String get adoptionApplyInfoText =>
      'Your application will be sent to the listing owner. If accepted, a conversation will be started.';

  @override
  String get adoptionApplyNoteLabel => 'Application Note (optional)';

  @override
  String get adoptionApplyNoteHint =>
      'Introduce yourself, explain why you want to adopt this animal...';

  @override
  String adoptionApplyErrGeneric(String error) {
    return 'Error: $error';
  }

  @override
  String get adoptionApplySuccessTitle => 'Application Sent!';

  @override
  String get adoptionApplySuccessContent =>
      'Your adoption application has been sent to the listing owner. You can track the result in My Applications.';

  @override
  String get adoptionApplySuccessOk => 'OK';

  @override
  String get adoptionApplySending => 'Sending...';

  @override
  String get adoptionApplySendBtn => 'Send Application';

  @override
  String get lostFoundTitle2 => 'Lost & Found';

  @override
  String get lostFoundListView => 'List View';

  @override
  String get lostFoundMapView => 'Map View';

  @override
  String get lostFoundLostTab => 'Lost';

  @override
  String get lostFoundFoundTab => 'Found';

  @override
  String get lostFoundEmptyTitle => 'No listings nearby';

  @override
  String get lostFoundEmptySubtitle =>
      'Lost or found animal listings near you will appear here.';

  @override
  String get lostFoundCreateBtn => 'Create Listing';

  @override
  String get eventsTitle2 => 'Events';

  @override
  String get eventsMyEventsTooltip => 'My Events';

  @override
  String get eventsCreateBtn => 'Create Event';

  @override
  String get eventsCatAll => 'All';

  @override
  String get eventsCatPark => 'Park';

  @override
  String get eventsCatAdoption => 'Adopt';

  @override
  String get eventsCatTraining => 'Training';

  @override
  String get eventsCatCompetition => 'Race';

  @override
  String get eventsCatGrooming => 'Care';

  @override
  String get eventsCatHealth => 'Health';

  @override
  String get eventsEmptyTitle => 'No Events Found';

  @override
  String get eventsEmptySubtitle => 'No events in this area or category yet.';

  @override
  String get eventsLocationBannerText => 'Location required for nearby events';

  @override
  String get eventsLocationBannerBtn => 'Allow';

  @override
  String get myEventsTitle => 'My Events';

  @override
  String get myEventsTabAttending => 'Attending';

  @override
  String get myEventsTabOrganized => 'Organizing';

  @override
  String get myEventsEmptyTitle => 'No Events';

  @override
  String get myEventsEmptySubtitle =>
      'You have no events in this category yet.';

  @override
  String get createPostTitle => 'Create Post';

  @override
  String get createPostShareBtn => 'Share';

  @override
  String get createPostPhotosLabel => 'Photos';

  @override
  String get createPostAddBtn => 'Add';

  @override
  String get createPostEmptyHint => 'Tap to add photos';

  @override
  String get createPostHint =>
      'What are you sharing? Tell us about your adorable pet...';

  @override
  String get createPostMaxImages => 'You can add up to 4 photos';

  @override
  String get createPostValidation => 'Please write something or add a photo';

  @override
  String createPostErr(String error) {
    return 'Error: $error';
  }

  @override
  String get connectTitle => 'Discover';

  @override
  String get connectSocialFeed => 'Social Feed';

  @override
  String get connectSocialFeedSub => 'Follow pet owners';

  @override
  String get connectSearch => 'Search';

  @override
  String get connectSearchSub => 'Find pets, stores and vets';

  @override
  String get connectMapDiscover => 'Discover on Map';

  @override
  String get connectMapDiscoverSub => 'View nearby listings on the map';

  @override
  String get connectFavorites => 'Favorites';

  @override
  String get connectFavoritesSub => 'Saved listings';

  @override
  String get reviewAddTitle => 'Write a Review';

  @override
  String get reviewEditTitle => 'Edit Review';

  @override
  String get reviewProductLabel => 'Product';

  @override
  String get reviewRatingLabel => 'Your Rating *';

  @override
  String get reviewCommentLabel => 'Your Comment (Optional)';

  @override
  String get reviewCommentHint => 'Share your thoughts about the product...';

  @override
  String get reviewSubmitBtn => 'Submit';

  @override
  String get reviewUpdateBtn => 'Update';

  @override
  String get reviewRating1 => 'Very Bad';

  @override
  String get reviewRating2 => 'Bad';

  @override
  String get reviewRating3 => 'Average';

  @override
  String get reviewRating4 => 'Good';

  @override
  String get reviewRating5 => 'Excellent';

  @override
  String get reviewNoRatingErr => 'Please select a rating';

  @override
  String get reviewUpdated => 'Review updated';

  @override
  String get reviewAdded => 'Review added';

  @override
  String reviewErr(String error) {
    return 'Error: $error';
  }

  @override
  String get reviewsSectionTitle => 'Reviews';

  @override
  String get reviewsSectionEdit => 'Edit';

  @override
  String get reviewsSectionAdd => 'Write a Review';

  @override
  String reviewsCount(int count) {
    return '$count reviews';
  }

  @override
  String get reviewsVerifiedBuyer => 'Buyer';

  @override
  String reviewsLoadErr(String error) {
    return 'Could not load reviews: $error';
  }

  @override
  String get reviewsEmptyTitle => 'No reviews yet';

  @override
  String get reviewsEmptySubtitle => 'Be the first to review!';

  @override
  String get editProfileTitle => 'Edit Profile';

  @override
  String get editProfilePhotoUpdated => 'Profile photo updated!';

  @override
  String get editProfileNameLabel => 'Full Name';

  @override
  String get editProfileCityLabel => 'City';

  @override
  String get editProfileAboutLabel => 'About Me';

  @override
  String get editProfileNameRequired => 'Name cannot be empty';

  @override
  String get editProfileSaveBtn => 'Save Changes';

  @override
  String get onboardingSkip => 'Skip';

  @override
  String get onboardingNext => 'Continue';

  @override
  String get onboardingStart => 'Let\'s Get Started!';

  @override
  String get onboardingPage1Title => 'Discover Your Pet Companion';

  @override
  String get onboardingPage1Subtitle =>
      'Browse thousands of pet listings. Find the right friend for adoption or matching.';

  @override
  String get onboardingPage2Title => 'Matching & Adoption';

  @override
  String get onboardingPage2Subtitle =>
      'Match or adopt pets based on birth dates, breed and location filters.';

  @override
  String get onboardingPage3Title => 'Health Tracking';

  @override
  String get onboardingPage3Subtitle =>
      'Keep your friend\'s health under control with vaccination schedule, vet appointments and health journal.';

  @override
  String get onboardingPage4Title => 'Store & Community';

  @override
  String get onboardingPage4Subtitle =>
      'Buy pet products, hire sitters, join events and be part of the social community.';

  @override
  String get adminAppsTitle => 'Seller Applications';

  @override
  String adminAppsStatus(String status) {
    return 'Status: $status';
  }

  @override
  String get adminAppsLoadErr => 'Could not load applications.';

  @override
  String get productDetailOwnProduct => 'This is your product';

  @override
  String get productDetailOwnProductErr =>
      'You cannot add your own products to cart';

  @override
  String get productDetailOutOfStock => 'This product is out of stock';

  @override
  String productDetailMaxStock(int stock) {
    return 'You can add maximum $stock items';
  }

  @override
  String productDetailAddedToCart(int count) {
    return '$count item(s) added to cart';
  }

  @override
  String get productDetailGoToCart => 'Go to Cart';

  @override
  String productDetailAddErr(String error) {
    return 'Could not add to cart: $error';
  }

  @override
  String get productDetailShareSoon => 'Share feature coming soon';

  @override
  String get productDetailAddingToCart => 'Adding...';

  @override
  String get productDetailAddToCartBtn => 'Add to Cart';

  @override
  String get productDetailNoTitle => 'No product name';

  @override
  String get productDetailNoDesc => 'No description';

  @override
  String productDetailStock(int count) {
    return 'Stock: $count';
  }

  @override
  String get productDetailNotFound => 'Product not found.';

  @override
  String get sellerApplyTitle => 'Become a Seller';

  @override
  String get sellerApplyCompanyName => 'Company Name';

  @override
  String get sellerApplyCompanyTitle => 'Company Title';

  @override
  String get sellerApplyTaxNumber => 'Tax Number';

  @override
  String get sellerApplyTaxOffice => 'Tax Office';

  @override
  String get sellerApplyAddress => 'Address';

  @override
  String get sellerApplyContact => 'Contact';

  @override
  String get sellerApplyIban => 'IBAN';

  @override
  String get sellerApplyRequired => 'Required';

  @override
  String get sellerApplyKvkk => 'I approve the KVKK text';

  @override
  String get sellerApplyContract => 'I approve the seller agreement';

  @override
  String get sellerApplyApprovalsRequired => 'Approvals are required';

  @override
  String get sellerApplySending => 'Sending...';

  @override
  String get sellerApplySendBtn => 'Submit Application';

  @override
  String get sellerApplyFailed => 'Application could not be sent.';

  @override
  String get sellerApplyPending => 'Your application is under review';

  @override
  String get productsPageTitle => 'My Products';

  @override
  String get productsActive => 'Active';

  @override
  String get productsPassive => 'Inactive';

  @override
  String get productsLoadErr => 'Could not load products.';

  @override
  String productsStockStatus(int stock, String status) {
    return 'Stock: $stock • $status';
  }

  @override
  String get productAddTitle => 'Add Product';

  @override
  String get productAddName => 'Product Name';

  @override
  String get productAddRequired => 'Required';

  @override
  String get productAddCategory => 'Category';

  @override
  String get productAddNoCategoryFound => 'No category found.';

  @override
  String get productAddCategoryLoading => 'Loading categories...';

  @override
  String productAddCategoryLoadErr(String error) {
    return 'Could not load categories: $error';
  }

  @override
  String get productAddCategorySelect => 'Select category';

  @override
  String get productAddDescription => 'Description';

  @override
  String get productAddPrice => 'Price';

  @override
  String get productAddStock => 'Stock';

  @override
  String get productAddSaving => 'Saving...';

  @override
  String get productAddSaveBtn => 'Save';

  @override
  String get productEditTitle => 'Edit Product';

  @override
  String get productEditUpdating => 'Updating...';

  @override
  String get productEditUpdateBtn => 'Update';

  @override
  String get productEditFailed => 'Update failed.';

  @override
  String get productEditActive => 'Active';

  @override
  String get storeCategoryAll => 'All';

  @override
  String productCardAddedToCart(String title) {
    return '$title added to cart';
  }

  @override
  String productCardAddErr(String error) {
    return 'Could not add to cart: $error';
  }

  @override
  String get productCardNoTitle => 'No product name';

  @override
  String get aiSpeciesDog => 'Dog';

  @override
  String get aiSpeciesCat => 'Cat';

  @override
  String get aiSpeciesBird => 'Bird';

  @override
  String get aiSpeciesOther => 'Other';

  @override
  String get aiSymptomLossOfAppetite => 'Loss of appetite';

  @override
  String get aiSymptomFever => 'Fever';

  @override
  String get aiSymptomDiarrhea => 'Diarrhea';

  @override
  String get aiSymptomVomiting => 'Vomiting';

  @override
  String get aiSymptomCough => 'Cough';

  @override
  String get aiSymptomShortnessOfBreath => 'Shortness of breath';

  @override
  String get aiSymptomLethargy => 'Lethargy';

  @override
  String get aiSymptomBloodyStool => 'Bloody stool';

  @override
  String get aiSymptomExcessiveItching => 'Excessive itching';

  @override
  String get aiSymptomHairLoss => 'Hair loss';

  @override
  String get aiSymptomLimping => 'Limping';

  @override
  String get aiSymptomExcessiveThirst => 'Excessive thirst';

  @override
  String get aiSymptomUnableToUrinate => 'Unable to urinate';

  @override
  String get aiSymptomBloatedBelly => 'Bloated belly';

  @override
  String get aiSymptomLossOfConsciousness => 'Loss of consciousness';

  @override
  String get aiSymptomRunnyNose => 'Runny nose';

  @override
  String get aiSymptomEyeDischarge => 'Eye discharge';

  @override
  String get aiSymptomBreathingDifficulty => 'Breathing difficulty';

  @override
  String get aiSymptomWeightLoss => 'Weight loss';

  @override
  String get aiSymptomFeatherPlucking => 'Feather plucking';

  @override
  String get aiSymptomBloodyUrine => 'Bloody urine';

  @override
  String get aiSymptomJaundice => 'Jaundice';

  @override
  String get aiSymptomSeizures => 'Seizure / Tremors';

  @override
  String get aiSymptomFeatherLoss => 'Feather loss';

  @override
  String get aiSymptomNotEating => 'Not eating';

  @override
  String get aiSymptomPuffed => 'Swollen / Puffy';

  @override
  String get aiSymptomUnableToStand => 'Unable to stand';

  @override
  String get aiSymptomHavingSeizure => 'Having seizures';

  @override
  String get aiSymptomBleeding => 'Bleeding';

  @override
  String get aiSymptomScratch => 'Scratching';

  @override
  String aiSymptomPrefix(String species) {
    return '$species, symptoms: ';
  }

  @override
  String get aiGenSug1 => 'How much water should I give my dog?';

  @override
  String get aiGenSug2 => 'How often should cat litter be changed?';

  @override
  String get aiGenSug3 => 'How to train a puppy?';

  @override
  String get aiGenSug4 => 'Why does my cat cry at night?';

  @override
  String get aiGenSug5 => 'What to do after a dog bite?';

  @override
  String get guideSug1 => 'Browse adoption listings';

  @override
  String get guideSug2 => 'Find a veterinarian';

  @override
  String get guideSug3 => 'Find a match';

  @override
  String get guideSug4 => 'Show my cart';

  @override
  String get guideSug5 => 'Create lost pet listing';

  @override
  String get guideSug6 => 'Join events';

  @override
  String get eventLocationObtained => 'Location Obtained ✓';

  @override
  String get eventUseMyLocation => 'Use My Location';

  @override
  String get eventCreateTitle => 'Create Event';

  @override
  String get eventCatParkMeetup => 'Park Meetup';

  @override
  String get eventCatAdoptionDay => 'Adoption Day';

  @override
  String get eventCatTraining => 'Training Seminar';

  @override
  String get eventCatCompetition => 'Race / Show';

  @override
  String get eventCatGrooming => 'Grooming Day';

  @override
  String get eventCatHealth => 'Health / Vaccination';

  @override
  String get eventCatOther => 'Other';

  @override
  String get eventSpeciesAll => 'All';

  @override
  String get eventSpeciesDog => 'Dog';

  @override
  String get eventSpeciesCat => 'Cat';

  @override
  String get eventSpeciesBird => 'Bird';

  @override
  String get eventSpeciesRabbit => 'Rabbit';

  @override
  String get eventSpeciesOther => 'Other';

  @override
  String get eventErrLocationPerm => 'Location permission required';

  @override
  String get eventErrMaxPhotos => 'Maximum 5 photos can be added';

  @override
  String get eventErrEndBeforeStart => 'End date cannot be before start date';

  @override
  String get eventCreated => 'Event created!';

  @override
  String get eventPhotosLabel => 'Photos (max 5)';

  @override
  String get eventDateTimeLabel => 'Date and Time';

  @override
  String get eventStartLabel => 'Start *';

  @override
  String get eventEndLabel => 'End *';

  @override
  String get eventLocationLabel => 'Location';

  @override
  String get eventCapacityLabel => 'Capacity and Fee';

  @override
  String get eventFreeLabel => 'Free Event';

  @override
  String get eventAnimalsLabel => 'Animals Allowed';

  @override
  String get eventCreateBtn => 'Create Event';

  @override
  String eventErrLocationFail(String error) {
    return 'Could not get location: $error';
  }

  @override
  String eventCreateErr(String error) {
    return 'Error: $error';
  }

  @override
  String get themeSelectTitle => 'Choose Your Theme';

  @override
  String get themeSelectSub => 'Pick the look that suits you best';

  @override
  String get themeSelectLight => 'Light';

  @override
  String get themeSelectDark => 'Dark';

  @override
  String get themeSelectConfirm => 'Continue';

  @override
  String get themeSelectChangeHint => 'You can change this anytime in Settings';
}
