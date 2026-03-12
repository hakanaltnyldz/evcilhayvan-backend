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
import '../features/store/screens/seller_apply_page.dart';
import '../features/store/screens/admin_applications_page.dart';
import '../features/store/screens/seller/products_page.dart';
import '../features/store/screens/seller/product_add_page.dart';
import '../features/store/screens/seller/product_edit_page.dart';
import '../features/store/screens/product_detail_page.dart';
import '../features/store/screens/cart_page.dart';
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
import '../features/auth/presentation/screens/splash_screen.dart';
import '../features/auth/presentation/screens/user_profile_screen.dart';
import '../features/auth/presentation/screens/privacy_policy_screen.dart';

// Auth gerektirmeyen sayfalar
const _publicRoutes = {
  '/login',
  '/register',
  '/verify-email',
  '/forgot-password',
  '/reset-password',
  '/onboarding',
  '/splash',
  '/privacy-policy',
};

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);
  final onboardingSeen = ref.watch(onboardingSeenProvider);

  return GoRouter(
    initialLocation: '/splash',
    errorBuilder: (context, state) => const Scaffold(
      body: Center(child: Text('Sayfa Bulunamadi!')),
    ),
    redirect: (context, state) {
      final isLoggedIn = authState != null;
      final isPublicRoute = _publicRoutes.contains(state.matchedLocation);

      // Onboarding henuz gosterilmediyse /onboarding'e yonlendir
      if (!onboardingSeen && state.matchedLocation != '/onboarding' && state.matchedLocation != '/splash') {
        return '/onboarding';
      }

      // Giris yapmis kullanici login/register'a gitmeye calisirsa ana sayfaya yonlendir
      if (isLoggedIn && (state.matchedLocation == '/login' || state.matchedLocation == '/register')) {
        return '/';
      }

      // Giris yapmamis kullanici korunmus sayfaya gitmeye calisirsa login'e yonlendir
      if (!isLoggedIn && !isPublicRoute) {
        return '/login';
      }

      return null;
    },
  routes: [
    // Alt navigasyonlu sayfalar
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
      builder: (context, state) => const SplashScreen(),
    ),
    // Onboarding
    GoRoute(
      path: '/onboarding',
      name: 'onboarding',
      builder: (context, state) => const OnboardingScreen(),
    ),
    // Health Journal
    GoRoute(
      path: '/health/:petId',
      name: 'health-journal',
      builder: (context, state) {
        final petId = state.pathParameters['petId']!;
        final extra = state.extra as Map<String, dynamic>?;
        final petName = extra?['petName'] as String? ?? 'Pet';
        return HealthJournalScreen(petId: petId, petName: petName);
      },
    ),

    // Global Search
    GoRoute(
      path: '/search',
      name: 'search',
      builder: (context, state) => const GlobalSearchScreen(),
    ),
    // AI Assistant
    GoRoute(
      path: '/ai-assistant',
      name: 'ai-assistant',
      builder: (context, state) => const AiAssistantScreen(),
    ),

    // Alt bar olmayan sayfalar
    GoRoute(
      path: '/login',
      name: 'login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/register',
      name: 'register',
      builder: (context, state) => const RegisterScreen(),
    ),
    GoRoute(
      path: '/verify-email',
      name: 'verify-email',
      builder: (context, state) {
        final String email = state.extra as String;
        return VerificationScreen(email: email);
      },
    ),
    GoRoute(
      path: '/forgot-password',
      name: 'forgot-password',
      builder: (context, state) => const ForgotPasswordScreen(),
    ),
    GoRoute(
      path: '/reset-password',
      name: 'reset-password',
      builder: (context, state) {
        final String email = state.extra as String;
        return ResetPasswordScreen(email: email);
      },
    ),
    GoRoute(
      path: '/create-pet',
      name: 'create-pet',
      builder: (context, state) {
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
        return CreatePetScreen(
          petToEdit: petToEdit,
          initialAdvertType: presetType,
          initialSpecies: presetSpecies,
        );
      },
    ),
    GoRoute(
      path: '/pet/:id',
      name: 'pet-detail',
      builder: (context, state) {
        final String petId = state.pathParameters['id']!;
        return PetDetailScreen(petId: petId);
      },
    ),
    GoRoute(
      path: '/mating',
      name: 'mating',
      builder: (context, state) => const MatingScreen(),
    ),
    GoRoute(
      path: '/mating/requests',
      name: 'mating-requests',
      builder: (context, state) => const MatchRequestsScreen(),
    ),

    // Chat
    GoRoute(
      path: '/chat/:conversationId',
      name: 'chat',
      builder: (context, state) {
        final String convId = state.pathParameters['conversationId']!;
        String receiverName = 'KullanŽñcŽñ';
        String? avatarUrl;

        final extra = state.extra;
        if (extra is Map<String, dynamic>) {
          receiverName = extra['name'] as String? ?? receiverName;
          avatarUrl = extra['avatar'] as String?;
        } else if (extra is String) {
          receiverName = extra;
        }

        return ChatScreen(
          conversationId: convId,
          receiverName: receiverName,
          receiverAvatarUrl: avatarUrl,
        );
      },
    ),

    GoRoute(
      path: '/settings',
      name: 'settings',
      builder: (context, state) => const SettingsScreen(),
    ),
    GoRoute(
      path: '/edit-profile',
      name: 'edit-profile',
      builder: (context, state) => const EditProfileScreen(),
    ),
    GoRoute(
      path: '/store/apply',
      name: 'store-apply',
      builder: (context, state) => const ApplySellerScreen(),
    ),
    GoRoute(
      path: '/store/add',
      name: 'store-add-product',
      builder: (context, state) {
        final product = state.extra is ProductModel ? state.extra as ProductModel : null;
        return AddProductScreen(product: product);
      },
    ),
    GoRoute(
      path: '/store/checkout',
      name: 'store-checkout',
      builder: (context, state) => const CheckoutScreen(),
    ),
    GoRoute(
      path: '/store/orders',
      name: 'my-orders',
      builder: (context, state) => const MyOrdersScreen(),
    ),
    GoRoute(
      path: '/store/cart',
      name: 'store-cart',
      builder: (context, state) => const CartScreen(),
    ),
    GoRoute(
      path: '/store/address/add',
      name: 'add-address',
      builder: (context, state) => const AddAddressScreen(),
    ),
    // IMPORTANT: Dynamic route must come AFTER specific /store/* routes
    GoRoute(
      path: '/store/:storeId',
      name: 'store-detail',
      builder: (context, state) {
        final id = state.pathParameters['storeId']!;
        return StoreDetailScreen(storeId: id);
      },
    ),
    GoRoute(
      path: '/seller/apply-new',
      name: 'seller-apply-new',
      builder: (context, state) => const SellerApplyPage(),
    ),
    GoRoute(
      path: '/admin/seller/applications',
      name: 'admin-seller-applications',
      builder: (context, state) => const AdminApplicationsPage(),
    ),
    GoRoute(
      path: '/seller/products',
      name: 'seller-products',
      builder: (context, state) => const ProductsPage(),
    ),
    GoRoute(
      path: '/seller/products/add',
      name: 'seller-product-add',
      builder: (context, state) => const ProductAddPage(),
    ),
    GoRoute(
      path: '/store-new',
      name: 'store-new',
      builder: (context, state) => const StoreHomeScreen(),
    ),
    GoRoute(
      path: '/store-new/product/:id',
      name: 'store-new-product',
      builder: (context, state) => ProductDetailPage(
        id: state.pathParameters['id']!,
      ),
    ),
    GoRoute(
      path: '/product/:id',
      name: 'product-detail',
      builder: (context, state) => ProductDetailPage(
        id: state.pathParameters['id']!,
      ),
    ),
    GoRoute(
      path: '/store-new/cart',
      name: 'store-new-cart',
      builder: (context, state) => const CartScreen(),
    ),
    GoRoute(
      path: '/seller/dashboard',
      name: 'seller-dashboard',
      builder: (context, state) => const SellerDashboardScreen(),
    ),
    GoRoute(
      path: '/seller/products/manage',
      name: 'product-management',
      builder: (context, state) => const ProductManagementScreen(),
    ),
    GoRoute(
      path: '/seller/orders',
      name: 'seller-orders',
      builder: (context, state) => const SellerOrdersScreen(),
    ),
    GoRoute(
      path: '/stores',
      name: 'stores-list',
      builder: (context, state) => const StoresListScreen(),
    ),
    GoRoute(
      path: '/favorites',
      name: 'favorites',
      builder: (context, state) => const FavoritesScreen(),
    ),

    // Bildirim ekrani
    GoRoute(
      path: '/notifications',
      name: 'notifications',
      builder: (context, state) => const NotificationsScreen(),
    ),

    // Kayip & Bulunan ekranlari
    GoRoute(
      path: '/lost-found',
      name: 'lost-found',
      builder: (context, state) => const LostFoundHomeScreen(),
    ),
    GoRoute(
      path: '/lost-found/report',
      name: 'report-lost-found',
      builder: (context, state) => const ReportLostFoundScreen(),
    ),
    GoRoute(
      path: '/lost-found/:id',
      name: 'lost-found-detail',
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        return LostFoundDetailScreen(reportId: id);
      },
    ),

    // Bakici ekranlari
    GoRoute(
      path: '/sitters',
      name: 'sitters',
      builder: (context, state) => const SitterHomeScreen(),
    ),
    GoRoute(
      path: '/sitters/bookings',
      name: 'sitter-bookings',
      builder: (context, state) => const MyBookingsScreen(),
    ),
    GoRoute(
      path: '/sitters/become',
      name: 'become-sitter',
      builder: (context, state) {
        final extra = state.extra;
        final existing = extra is PetSitterModel ? extra : null;
        return BecomeSitterScreen(existing: existing);
      },
    ),
    GoRoute(
      path: '/sitters/:id',
      name: 'sitter-detail',
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        return SitterDetailScreen(sitterId: id);
      },
    ),
    GoRoute(
      path: '/sitter-booking',
      name: 'sitter-booking',
      builder: (context, state) {
        final sitter = state.extra as PetSitterModel;
        return SitterBookingScreen(sitter: sitter);
      },
    ),

    // Etkinlik ekranlari
    GoRoute(
      path: '/events',
      name: 'events',
      builder: (context, state) => const EventsHomeScreen(),
    ),
    GoRoute(
      path: '/events/create',
      name: 'create-event',
      builder: (context, state) => const CreateEventScreen(),
    ),
    GoRoute(
      path: '/events/attending',
      name: 'my-events',
      builder: (context, state) => const MyEventsScreen(),
    ),
    GoRoute(
      path: '/events/:id',
      name: 'event-detail',
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        return EventDetailScreen(eventId: id);
      },
    ),

    // Adoption ekranlari
    GoRoute(
      path: '/adoption/apply',
      name: 'adoption-apply',
      builder: (context, state) {
        final pet = state.extra as Pet;
        return AdoptionApplyScreen(pet: pet);
      },
    ),
    GoRoute(
      path: '/adoption/applications',
      name: 'adoption-applications',
      builder: (context, state) => const AdoptionApplicationsScreen(),
    ),

    // Veteriner alt ekranlari
    GoRoute(
      path: '/veterinary/search',
      name: 'vet-search',
      builder: (context, state) {
        final extra = state.extra;
        bool nearMe = false;
        bool googleSearch = false;
        if (extra is Map<String, dynamic>) {
          nearMe = extra['nearMe'] == true;
          googleSearch = extra['googleSearch'] == true;
        }
        return VetSearchScreen(nearMe: nearMe, googleSearch: googleSearch);
      },
    ),
    GoRoute(
      path: '/veterinary/detail/:id',
      name: 'vet-detail',
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        return VetDetailScreen(vetId: id);
      },
    ),
    GoRoute(
      path: '/veterinary/register',
      name: 'vet-register',
      builder: (context, state) => const VetRegisterScreen(),
    ),
    GoRoute(
      path: '/veterinary/appointment/create',
      name: 'appointment-create',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>;
        return AppointmentCreateScreen(
          vetId: extra['vetId'] as String,
          vetName: extra['vetName'] as String,
        );
      },
    ),
    GoRoute(
      path: '/veterinary/appointment/:id',
      name: 'appointment-detail',
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        return AppointmentDetailScreen(appointmentId: id);
      },
    ),
    GoRoute(
      path: '/veterinary/vaccination/:petId',
      name: 'vaccination-calendar',
      builder: (context, state) {
        final petId = state.pathParameters['petId']!;
        return VaccinationCalendarScreen(petId: petId);
      },
    ),
    GoRoute(
      path: '/veterinary/vaccination/:petId/add',
      name: 'vaccination-add',
      builder: (context, state) {
        final petId = state.pathParameters['petId']!;
        return VaccinationAddScreen(petId: petId);
      },
    ),
    GoRoute(
      path: '/veterinary/reminders',
      name: 'vaccination-reminders',
      builder: (context, state) => const VetHomeScreen(initialTabIndex: 2),
    ),

    // Harita Kesfet
    GoRoute(
      path: '/map',
      name: 'map',
      builder: (context, state) => const MapDiscoverScreen(),
    ),

    // Sosyal Feed
    GoRoute(
      path: '/feed',
      name: 'feed',
      builder: (context, state) => const FeedScreen(),
    ),
    GoRoute(
      path: '/feed/create',
      name: 'create-post',
      builder: (context, state) => const CreatePostScreen(),
    ),

    // Kullanici public profili
    GoRoute(
      path: '/user/:userId',
      name: 'user-profile',
      builder: (context, state) {
        final userId = state.pathParameters['userId']!;
        return UserProfileScreen(userId: userId);
      },
    ),

    // Gizlilik Politikasi
    GoRoute(
      path: '/privacy-policy',
      name: 'privacy-policy',
      builder: (context, state) => const PrivacyPolicyScreen(),
    ),
  ],
  );
});
