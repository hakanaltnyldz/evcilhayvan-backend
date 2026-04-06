import 'package:evcilhayvan_mobil2/features/messages/presentation/chat_screen.dart';
import 'package:evcilhayvan_mobil2/features/messages/presentation/messages_screen.dart';
import 'package:evcilhayvan_mobil2/features/mating/presentation/screens/mating_screen.dart';
import 'package:evcilhayvan_mobil2/features/pets/presentation/screens/pet_detail.screen.dart' show PetDetailScreen;
import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:evcilhayvan_mobil2/main_shell.dart';
import '../features/auth/data/repositories/auth_repository.dart';

// Auth ekranlari
import '../features/auth/presentation/screens/edit_profile_screen.dart';
import '../features/auth/presentation/screens/forgot_password_screen.dart';
import '../features/auth/presentation/screens/login_screen.dart';
import '../features/auth/presentation/screens/profile_screen.dart';
import '../features/auth/presentation/screens/register_screen.dart';
import '../features/auth/presentation/screens/reset_password_screen.dart';
import '../features/auth/presentation/screens/settings_screen.dart';
import '../features/auth/presentation/screens/verification_screen.dart';

// Diger ekranlar
import '../features/connect/presentation/screens/connect_screen.dart';
import '../features/pets/domain/models/pet_model.dart';
import '../features/pets/presentation/screens/create_pet_screen.dart';
import '../features/pets/presentation/screens/home_screen.dart';
import '../features/mating/presentation/screens/match_requests_screen.dart';
import '../features/store/presentation/screens/add_product_screen.dart';
import '../features/store/presentation/screens/apply_seller_screen.dart';
import '../features/store/presentation/screens/store_detail_screen.dart';
import '../features/store/presentation/screens/store_home_screen.dart';
import '../features/store/domain/models/product_model.dart';
import '../features/store/presentation/screens/admin_applications_screen.dart';
import '../features/store/presentation/screens/product_detail_screen.dart';
import '../features/store/presentation/screens/cart_screen.dart';
import '../features/store/presentation/screens/seller_dashboard_screen.dart';
import '../features/store/presentation/screens/stores_list_screen.dart';
import '../features/store/presentation/screens/product_management_screen.dart';
import '../features/store/presentation/screens/seller_orders_screen.dart';
import '../features/store/presentation/screens/checkout_screen.dart';
import '../features/store/presentation/screens/my_orders_screen.dart';
import '../features/store/presentation/screens/add_address_screen.dart';
import '../features/favorites/presentation/screens/favorites_screen.dart';

// Veteriner ekranlari
import '../features/veterinary/presentation/screens/vet_home_screen.dart';
import '../features/veterinary/presentation/screens/vet_search_screen.dart';
import '../features/veterinary/presentation/screens/vet_detail_screen.dart';
import '../features/veterinary/presentation/screens/vet_register_screen.dart';
import '../features/veterinary/presentation/screens/appointment_create_screen.dart';
import '../features/veterinary/presentation/screens/appointment_detail_screen.dart';
import '../features/veterinary/presentation/screens/vaccination_calendar_screen.dart';
import '../features/veterinary/presentation/screens/vaccination_add_screen.dart';

// Adoption ekranlari
import '../features/adoption/presentation/screens/adoption_apply_screen.dart';
import '../features/adoption/presentation/screens/adoption_applications_screen.dart';

// Bildirim ekranlari
import '../features/notifications/presentation/screens/notifications_screen.dart';
import '../features/notifications/presentation/screens/notification_preferences_screen.dart';
import '../features/store/presentation/screens/my_addresses_screen.dart';

// Kayip & Bulunan ekranlari
import '../features/lost_found/presentation/screens/lost_found_home_screen.dart';
import '../features/lost_found/presentation/screens/lost_found_detail_screen.dart';
import '../features/lost_found/presentation/screens/report_lost_found_screen.dart';

// Bakici ekranlari
import '../features/pet_sitter/presentation/screens/sitter_home_screen.dart';
import '../features/pet_sitter/presentation/screens/sitter_detail_screen.dart';
import '../features/pet_sitter/presentation/screens/sitter_booking_screen.dart';
import '../features/pet_sitter/presentation/screens/my_bookings_screen.dart';
import '../features/pet_sitter/presentation/screens/become_sitter_screen.dart';
import '../features/pet_sitter/domain/models/pet_sitter_model.dart';

// Etkinlik ekranlari
import '../features/events/presentation/screens/events_home_screen.dart';
import '../features/events/presentation/screens/event_detail_screen.dart';
import '../features/events/presentation/screens/create_event_screen.dart';
import '../features/events/presentation/screens/my_events_screen.dart';

// Harita & Sosyal Feed ekranlari
import '../features/map/presentation/screens/map_discover_screen.dart';
import '../features/social/presentation/screens/feed_screen.dart';
import '../features/social/presentation/screens/create_post_screen.dart';
import '../features/auth/presentation/screens/onboarding_screen.dart';
import '../core/providers/onboarding_provider.dart';
import '../features/search/presentation/global_search_screen.dart';
import '../features/health/presentation/screens/health_journal_screen.dart';
import '../features/ai/presentation/screens/ai_assistant_screen.dart';
import '../features/ai/presentation/screens/guide_screen.dart';
import '../features/auth/presentation/screens/splash_screen.dart';
import '../features/auth/presentation/screens/user_profile_screen.dart';
import '../features/auth/presentation/screens/privacy_policy_screen.dart';
import '../features/auth/presentation/screens/theme_selection_screen.dart';
import '../features/pets/presentation/screens/nearby_ads_screen.dart';
import '../core/providers/theme_provider.dart';
import '../features/store/presentation/screens/my_coupons_screen.dart';
import '../features/store/presentation/screens/seller_coupons_screen.dart';
import '../features/support/presentation/screens/complaint_screen.dart';

// Auth gerektirmeyen sayfalar
// Tamamen açık rotalar (giriş gerektirmez)
const _publicRoutes = {
  '/login',
  '/register',
  '/verify-email',
  '/forgot-password',
  '/reset-password',
  '/onboarding',
  '/splash',
  '/privacy-policy',
  '/theme-selection',
};

// Misafir kullanıcıların GEZEBİLECEĞİ ama işlem yapmak için giriş gereken rotalar
// (yani router bunları login'e yönlendirmez; ilanlar, vet, mağaza vb.)
const _guestBrowseRoutes = {
  '/',
  '/veterinary',
  '/store',
  '/lost-found',
  '/events',
  '/sitters',
  '/search',
};

// Misafir redirect kontrolünde kullanılmak üzere
bool _isGuestBrowsable(String location) {
  if (_guestBrowseRoutes.contains(location)) return true;
  // Dinamik rotalar: /pet/:id, /vet/:id, /sitter/:id, /event/:id, /lost-found/:id
  if (location.startsWith('/pet/')) return true;
  if (location.startsWith('/veterinary/')) return true;
  if (location.startsWith('/sitter/')) return true;
  if (location.startsWith('/event/')) return true;
  if (location.startsWith('/lost-found/')) return true;
  if (location.startsWith('/store/')) return true;
  if (location.startsWith('/user/')) return true;
  return false;
}

/// MongoDB ObjectId format doğrulama (24 hex karakter).
bool _isValidObjectId(String id) =>
    RegExp(r'^[a-f\d]{24}$', caseSensitive: false).hasMatch(id);

Page<void> _notFoundPage(GoRouterState state) => _buildPage(
      state,
      const Scaffold(body: Center(child: Text('Sayfa bulunamadı'))),
    );

/// Tüm push rotalarında tutarlı fade + hafif slideY geçiş animasyonu.
Page<void> _buildPage(GoRouterState state, Widget child) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 220),
    reverseTransitionDuration: const Duration(milliseconds: 180),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(parent: animation, curve: Curves.easeOut);
      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.03),
            end: Offset.zero,
          ).animate(curved),
          child: child,
        ),
      );
    },
  );
}

/// Detail ekranlar için scale + fade geçişi.
Page<void> _buildDetailPage(GoRouterState state, Widget child) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 280),
    reverseTransitionDuration: const Duration(milliseconds: 200),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
      return FadeTransition(
        opacity: curved,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.94, end: 1.0).animate(curved),
          child: child,
        ),
      );
    },
  );
}

/// Modal ekranlar (create/booking) için slideUp geçişi.
Page<void> _buildModalPage(GoRouterState state, Widget child) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 300),
    reverseTransitionDuration: const Duration(milliseconds: 220),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.15),
            end: Offset.zero,
          ).animate(curved),
          child: child,
        ),
      );
    },
  );
}

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);
  final onboardingSeen = ref.watch(onboardingSeenProvider);
  final themeSelected = ref.watch(themeSelectedProvider);

  return GoRouter(
    initialLocation: '/splash',
    errorBuilder: (context, state) => const Scaffold(
      body: Center(child: Text('Sayfa Bulunamadi!')),
    ),
    redirect: (context, state) {
      final isLoggedIn = authState != null;
      final isPublicRoute = _publicRoutes.contains(state.matchedLocation);

      // Tema henuz secilmediyse /theme-selection'a yonlendir
      if (!themeSelected &&
          state.matchedLocation != '/theme-selection' &&
          state.matchedLocation != '/splash') {
        return '/theme-selection';
      }

      // Onboarding henuz gosterilmediyse /onboarding'e yonlendir
      if (!onboardingSeen &&
          state.matchedLocation != '/onboarding' &&
          state.matchedLocation != '/splash' &&
          state.matchedLocation != '/theme-selection') {
        return '/onboarding';
      }

      // Giris yapmis kullanici login/register'a gitmeye calisirsa ana sayfaya yonlendir
      if (isLoggedIn && (state.matchedLocation == '/login' || state.matchedLocation == '/register')) {
        return '/';
      }

      // Giris yapmamis kullanici korunmus sayfaya gitmeye calisirsa login'e yonlendir
      // Ancak gezinme rotaları (home, vet, store, ilan detay) için yönlendirme yapma
      if (!isLoggedIn && !isPublicRoute && !_isGuestBrowsable(state.matchedLocation)) {
        return '/login';
      }

      return null;
    },
  routes: [
    // Alt navigasyonlu sayfalar (tab geçişleri ayrı animasyon mekanizması kullanır)
    ShellRoute(
      builder: (BuildContext context, GoRouterState state, Widget child) {
        return MainShell(child: child);
      },
      routes: <RouteBase>[
        GoRoute(
          path: '/',
          name: 'home',
          builder: (context, state) => const HomeScreen(),
        ),
        GoRoute(
          path: '/connect',
          name: 'connect',
          builder: (context, state) => const ConnectScreen(),
        ),
        GoRoute(
          path: '/store',
          name: 'store',
          builder: (context, state) => const StoreHomeScreen(),
        ),
        GoRoute(
          path: '/profile',
          name: 'profile',
          builder: (context, state) => const ProfileScreen(),
        ),
        GoRoute(
          path: '/messages',
          name: 'messages',
          builder: (context, state) {
            final tab = state.uri.queryParameters['tab'];
            final initialTab = tab == 'requests' ? 1 : 0;
            return MessagesScreen(initialTabIndex: initialTab);
          },
        ),
        GoRoute(
          path: '/veterinary',
          name: 'veterinary',
          builder: (context, state) => const VetHomeScreen(),
        ),
      ],
    ),

    // Splash
    GoRoute(
      path: '/splash',
      name: 'splash',
      pageBuilder: (context, state) => _buildPage(state, const SplashScreen()),
    ),
    // Theme Selection (first-launch)
    GoRoute(
      path: '/theme-selection',
      name: 'theme-selection',
      pageBuilder: (context, state) => _buildPage(state, const ThemeSelectionScreen()),
    ),
    // Onboarding
    GoRoute(
      path: '/onboarding',
      name: 'onboarding',
      pageBuilder: (context, state) => _buildPage(state, const OnboardingScreen()),
    ),
    // Health Journal
    GoRoute(
      path: '/health/:petId',
      name: 'health-journal',
      pageBuilder: (context, state) {
        final petId = state.pathParameters['petId']!;
        final extra = state.extra as Map<String, dynamic>?;
        final petName = extra?['petName'] as String? ?? 'Pet';
        return _buildPage(state, HealthJournalScreen(petId: petId, petName: petName));
      },
    ),

    // Yakındaki İlanlar
    GoRoute(
      path: '/nearby-ads',
      name: 'nearby-ads',
      pageBuilder: (context, state) => _buildPage(state, const NearbyAdsScreen()),
    ),
    // Global Search
    GoRoute(
      path: '/search',
      name: 'search',
      pageBuilder: (context, state) => _buildPage(state, const GlobalSearchScreen()),
    ),
    // AI Assistant
    GoRoute(
      path: '/ai-assistant',
      name: 'ai-assistant',
      pageBuilder: (context, state) => _buildPage(state, const AiAssistantScreen()),
    ),
    // Rehber Pati — uygulama içi navigasyon asistanı
    GoRoute(
      path: '/guide',
      name: 'guide',
      pageBuilder: (context, state) => _buildPage(state, const GuideScreen()),
    ),

    // Alt bar olmayan sayfalar
    GoRoute(
      path: '/login',
      name: 'login',
      pageBuilder: (context, state) => _buildPage(state, const LoginScreen()),
    ),
    GoRoute(
      path: '/register',
      name: 'register',
      pageBuilder: (context, state) => _buildPage(state, const RegisterScreen()),
    ),
    GoRoute(
      path: '/verify-email',
      name: 'verify-email',
      pageBuilder: (context, state) {
        final String email = state.extra as String;
        return _buildPage(state, VerificationScreen(email: email));
      },
    ),
    GoRoute(
      path: '/forgot-password',
      name: 'forgot-password',
      pageBuilder: (context, state) => _buildPage(state, const ForgotPasswordScreen()),
    ),
    GoRoute(
      path: '/reset-password',
      name: 'reset-password',
      pageBuilder: (context, state) {
        final String email = state.extra as String;
        return _buildPage(state, ResetPasswordScreen(email: email));
      },
    ),
    GoRoute(
      path: '/create-pet',
      name: 'create-pet',
      pageBuilder: (context, state) {
        Pet? petToEdit;
        String? presetType;
        String? presetSpecies;
        final extra = state.extra;
        if (extra != null && extra is Pet) {
          petToEdit = extra;
        } else if (extra is Map<String, dynamic>) {
          if (extra['pet'] is Pet) petToEdit = extra['pet'] as Pet;
          if (extra['advertType'] is String) presetType = extra['advertType'] as String;
          if (extra['species'] is String) presetSpecies = extra['species'] as String;
        }
        return _buildPage(state, CreatePetScreen(
          petToEdit: petToEdit,
          initialAdvertType: presetType,
          initialSpecies: presetSpecies,
        ));
      },
    ),
    GoRoute(
      path: '/pet/:id',
      name: 'pet-detail',
      pageBuilder: (context, state) {
        final String petId = state.pathParameters['id']!;
        if (!_isValidObjectId(petId)) return _notFoundPage(state);
        return _buildDetailPage(state, PetDetailScreen(petId: petId));
      },
    ),
    GoRoute(
      path: '/mating',
      name: 'mating',
      pageBuilder: (context, state) => _buildPage(state, const MatingScreen()),
    ),
    GoRoute(
      path: '/mating/requests',
      name: 'mating-requests',
      pageBuilder: (context, state) => _buildPage(state, const MatchRequestsScreen()),
    ),

    // Chat
    GoRoute(
      path: '/chat/:conversationId',
      name: 'chat',
      pageBuilder: (context, state) {
        final String convId = state.pathParameters['conversationId']!;
        if (!_isValidObjectId(convId)) return _notFoundPage(state);
        String receiverName = 'Kullanıcı';
        String? avatarUrl;

        final extra = state.extra;
        if (extra is Map<String, dynamic>) {
          final name = extra['name'] as String? ?? receiverName;
          receiverName = name.length > 50 ? name.substring(0, 50) : name;
          avatarUrl = extra['avatar'] as String?;
        } else if (extra is String) {
          receiverName = extra.length > 50 ? extra.substring(0, 50) : extra;
        }

        return _buildPage(state, ChatScreen(
          conversationId: convId,
          receiverName: receiverName,
          receiverAvatarUrl: avatarUrl,
        ));
      },
    ),

    GoRoute(
      path: '/settings',
      name: 'settings',
      pageBuilder: (context, state) => _buildPage(state, const SettingsScreen()),
    ),
    GoRoute(
      path: '/edit-profile',
      name: 'edit-profile',
      pageBuilder: (context, state) => _buildPage(state, const EditProfileScreen()),
    ),
    GoRoute(
      path: '/store/apply',
      name: 'store-apply',
      pageBuilder: (context, state) => _buildPage(state, const ApplySellerScreen()),
    ),
    GoRoute(
      path: '/store/add',
      name: 'store-add-product',
      pageBuilder: (context, state) {
        final product = state.extra is ProductModel ? state.extra as ProductModel : null;
        return _buildPage(state, AddProductScreen(product: product));
      },
    ),
    GoRoute(
      path: '/store/checkout',
      name: 'store-checkout',
      pageBuilder: (context, state) => _buildPage(state, const CheckoutScreen()),
    ),
    GoRoute(
      path: '/store/orders',
      name: 'my-orders',
      pageBuilder: (context, state) => _buildPage(state, const MyOrdersScreen()),
    ),
    GoRoute(
      path: '/store/cart',
      name: 'store-cart',
      pageBuilder: (context, state) => _buildPage(state, const CartScreen()),
    ),
    GoRoute(
      path: '/store/address/add',
      name: 'add-address',
      pageBuilder: (context, state) => _buildPage(state, const AddAddressScreen()),
    ),
    // IMPORTANT: Dynamic route must come AFTER specific /store/* routes
    GoRoute(
      path: '/store/:storeId',
      name: 'store-detail',
      pageBuilder: (context, state) {
        final id = state.pathParameters['storeId']!;
        return _buildPage(state, StoreDetailScreen(storeId: id));
      },
    ),
    GoRoute(
      path: '/seller/apply-new',
      name: 'seller-apply-new',
      pageBuilder: (context, state) => _buildPage(state, const ApplySellerScreen()),
    ),
    GoRoute(
      path: '/admin/seller/applications',
      name: 'admin-seller-applications',
      pageBuilder: (context, state) => _buildPage(state, const AdminApplicationsPage()),
    ),
    GoRoute(
      path: '/seller/products',
      name: 'seller-products',
      pageBuilder: (context, state) => _buildPage(state, const ProductManagementScreen()),
    ),
    GoRoute(
      path: '/seller/products/add',
      name: 'seller-product-add',
      pageBuilder: (context, state) => _buildPage(state, const AddProductScreen()),
    ),
    GoRoute(
      path: '/store-new',
      name: 'store-new',
      pageBuilder: (context, state) => _buildPage(state, const StoreHomeScreen()),
    ),
    GoRoute(
      path: '/store-new/product/:id',
      name: 'store-new-product',
      pageBuilder: (context, state) => _buildPage(state, ProductDetailPage(
        id: state.pathParameters['id']!,
      )),
    ),
    GoRoute(
      path: '/product/:id',
      name: 'product-detail',
      pageBuilder: (context, state) => _buildPage(state, ProductDetailPage(
        id: state.pathParameters['id']!,
      )),
    ),
    GoRoute(
      path: '/store-new/cart',
      name: 'store-new-cart',
      pageBuilder: (context, state) => _buildPage(state, const CartScreen()),
    ),
    GoRoute(
      path: '/seller/dashboard',
      name: 'seller-dashboard',
      pageBuilder: (context, state) => _buildPage(state, const SellerDashboardScreen()),
    ),
    GoRoute(
      path: '/seller/products/manage',
      name: 'product-management',
      pageBuilder: (context, state) => _buildPage(state, const ProductManagementScreen()),
    ),
    GoRoute(
      path: '/seller/orders',
      name: 'seller-orders',
      pageBuilder: (context, state) => _buildPage(state, const SellerOrdersScreen()),
    ),
    GoRoute(
      path: '/stores',
      name: 'stores-list',
      pageBuilder: (context, state) => _buildPage(state, const StoresListScreen()),
    ),
    GoRoute(
      path: '/favorites',
      name: 'favorites',
      pageBuilder: (context, state) => _buildPage(state, const FavoritesScreen()),
    ),

    // Bildirim ekrani
    GoRoute(
      path: '/notifications',
      name: 'notifications',
      pageBuilder: (context, state) => _buildPage(state, const NotificationsScreen()),
    ),

    // Kayip & Bulunan ekranlari
    GoRoute(
      path: '/lost-found',
      name: 'lost-found',
      pageBuilder: (context, state) => _buildPage(state, const LostFoundHomeScreen()),
    ),
    GoRoute(
      path: '/lost-found/report',
      name: 'report-lost-found',
      pageBuilder: (context, state) => _buildModalPage(state, const ReportLostFoundScreen()),
    ),
    GoRoute(
      path: '/lost-found/:id',
      name: 'lost-found-detail',
      pageBuilder: (context, state) {
        final id = state.pathParameters['id']!;
        return _buildDetailPage(state, LostFoundDetailScreen(reportId: id));
      },
    ),

    // Bakici ekranlari
    GoRoute(
      path: '/sitters',
      name: 'sitters',
      pageBuilder: (context, state) => _buildPage(state, const SitterHomeScreen()),
    ),
    GoRoute(
      path: '/sitters/bookings',
      name: 'sitter-bookings',
      pageBuilder: (context, state) => _buildPage(state, const MyBookingsScreen()),
    ),
    GoRoute(
      path: '/sitters/become',
      name: 'become-sitter',
      pageBuilder: (context, state) {
        final extra = state.extra;
        final existing = extra is PetSitterModel ? extra : null;
        return _buildPage(state, BecomeSitterScreen(existing: existing));
      },
    ),
    GoRoute(
      path: '/sitters/:id',
      name: 'sitter-detail',
      pageBuilder: (context, state) {
        final id = state.pathParameters['id']!;
        return _buildDetailPage(state, SitterDetailScreen(sitterId: id));
      },
    ),
    GoRoute(
      path: '/sitter-booking',
      name: 'sitter-booking',
      pageBuilder: (context, state) {
        final sitter = state.extra as PetSitterModel;
        return _buildModalPage(state, SitterBookingScreen(sitter: sitter));
      },
    ),

    // Etkinlik ekranlari
    GoRoute(
      path: '/events',
      name: 'events',
      pageBuilder: (context, state) => _buildPage(state, const EventsHomeScreen()),
    ),
    GoRoute(
      path: '/events/create',
      name: 'create-event',
      pageBuilder: (context, state) => _buildModalPage(state, const CreateEventScreen()),
    ),
    GoRoute(
      path: '/events/attending',
      name: 'my-events',
      pageBuilder: (context, state) => _buildPage(state, const MyEventsScreen()),
    ),
    GoRoute(
      path: '/events/:id',
      name: 'event-detail',
      pageBuilder: (context, state) {
        final id = state.pathParameters['id']!;
        return _buildDetailPage(state, EventDetailScreen(eventId: id));
      },
    ),

    // Adoption ekranlari
    GoRoute(
      path: '/adoption/apply',
      name: 'adoption-apply',
      pageBuilder: (context, state) {
        final pet = state.extra as Pet;
        return _buildPage(state, AdoptionApplyScreen(pet: pet));
      },
    ),
    GoRoute(
      path: '/adoption/applications',
      name: 'adoption-applications',
      pageBuilder: (context, state) => _buildPage(state, const AdoptionApplicationsScreen()),
    ),

    // Veteriner alt ekranlari
    GoRoute(
      path: '/veterinary/search',
      name: 'vet-search',
      pageBuilder: (context, state) {
        final extra = state.extra;
        bool nearMe = false;
        bool googleSearch = false;
        if (extra is Map<String, dynamic>) {
          nearMe = extra['nearMe'] == true;
          googleSearch = extra['googleSearch'] == true;
        }
        return _buildPage(state, VetSearchScreen(nearMe: nearMe, googleSearch: googleSearch));
      },
    ),
    GoRoute(
      path: '/veterinary/detail/:id',
      name: 'vet-detail',
      pageBuilder: (context, state) {
        final id = state.pathParameters['id']!;
        return _buildDetailPage(state, VetDetailScreen(vetId: id));
      },
    ),
    GoRoute(
      path: '/veterinary/register',
      name: 'vet-register',
      pageBuilder: (context, state) => _buildPage(state, const VetRegisterScreen()),
    ),
    GoRoute(
      path: '/veterinary/appointment/create',
      name: 'appointment-create',
      pageBuilder: (context, state) {
        final extra = state.extra as Map<String, dynamic>;
        return _buildModalPage(state, AppointmentCreateScreen(
          vetId: extra['vetId'] as String,
          vetName: extra['vetName'] as String,
        ));
      },
    ),
    GoRoute(
      path: '/veterinary/appointment/:id',
      name: 'appointment-detail',
      pageBuilder: (context, state) {
        final id = state.pathParameters['id']!;
        return _buildDetailPage(state, AppointmentDetailScreen(appointmentId: id));
      },
    ),
    GoRoute(
      path: '/veterinary/vaccination/:petId',
      name: 'vaccination-calendar',
      pageBuilder: (context, state) {
        final petId = state.pathParameters['petId']!;
        return _buildPage(state, VaccinationCalendarScreen(petId: petId));
      },
    ),
    GoRoute(
      path: '/veterinary/vaccination/:petId/add',
      name: 'vaccination-add',
      pageBuilder: (context, state) {
        final petId = state.pathParameters['petId']!;
        return _buildPage(state, VaccinationAddScreen(petId: petId));
      },
    ),
    GoRoute(
      path: '/veterinary/reminders',
      name: 'vaccination-reminders',
      pageBuilder: (context, state) => _buildPage(state, const VetHomeScreen(initialTabIndex: 2)),
    ),

    // Harita Kesfet
    GoRoute(
      path: '/map',
      name: 'map',
      pageBuilder: (context, state) => _buildPage(state, const MapDiscoverScreen()),
    ),

    // Sosyal Feed
    GoRoute(
      path: '/feed',
      name: 'feed',
      pageBuilder: (context, state) => _buildPage(state, const FeedScreen()),
    ),
    GoRoute(
      path: '/feed/create',
      name: 'create-post',
      pageBuilder: (context, state) => _buildModalPage(state, const CreatePostScreen()),
    ),

    // Kullanici public profili
    GoRoute(
      path: '/user/:userId',
      name: 'user-profile',
      pageBuilder: (context, state) {
        final userId = state.pathParameters['userId']!;
        if (!_isValidObjectId(userId)) return _notFoundPage(state);
        return _buildPage(state, UserProfileScreen(userId: userId));
      },
    ),

    // Gizlilik Politikasi
    GoRoute(
      path: '/privacy-policy',
      name: 'privacy-policy',
      pageBuilder: (context, state) => _buildPage(state, const PrivacyPolicyScreen()),
    ),

    // Kuponlarım
    GoRoute(
      path: '/my-coupons',
      name: 'my-coupons',
      pageBuilder: (context, state) => _buildPage(state, const MyCouponsScreen()),
    ),
    // Satıcı kupon yönetimi
    GoRoute(
      path: '/seller/coupons',
      name: 'seller-coupons',
      pageBuilder: (context, state) => _buildPage(state, const SellerCouponsScreen()),
    ),
    // Şikayet ekranı
    GoRoute(
      path: '/complaint',
      name: 'complaint',
      pageBuilder: (context, state) => _buildPage(state, const ComplaintScreen()),
    ),
    // Adreslerim
    GoRoute(
      path: '/my-addresses',
      name: 'my-addresses',
      pageBuilder: (context, state) => _buildPage(state, const MyAddressesScreen()),
    ),
    // Bildirim Tercihleri
    GoRoute(
      path: '/notification-preferences',
      name: 'notification-preferences',
      pageBuilder: (context, state) => _buildPage(state, const NotificationPreferencesScreen()),
    ),
  ],
  );
});
