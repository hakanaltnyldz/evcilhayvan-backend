// lib/features/auth/domain/user_model.dart

class User {
  final String id;
  final String name;
  final String email;
  final String role; // 'user', 'admin', 'seller'
  final String? city; // ? -> null olabilir
  
  // --- GÜNCELLEME: BU İKİSİNİ EKLE ---
  // (EditProfileScreen'in hata vermemesi için)
  final String? avatarUrl;
  final String? about;
  final bool isSeller;
  final int points;
  final List<String> badges;
  final int followersCount;
  final int followingCount;
  final bool isFollowing;

  // profilePicture getter for backwards compatibility
  String? get profilePicture => avatarUrl;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.city,
    this.avatarUrl,
    this.about,
    this.isSeller = false,
    this.points = 0,
    this.badges = const [],
    this.followersCount = 0,
    this.followingCount = 0,
    this.isFollowing = false,
  });

  // --- GÜNCELLEME: ÇÖKMEYİ ENGELLEYEN YER ---
  // Bu factory, backend'den gelen JSON'ı bir User nesnesine çevirir
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      // Backend'de _id olarak geliyor, biz id olarak alıyoruz
      // ID null gelirse boş string ata (hiçbir şeyin çökmemesi için)
      id: json['_id'] ?? json['id'] ?? '', 
      
      // 'name', 'email', 'role' null gelirse varsayılan değer ata
      name: json['name'] ?? 'Bilinmeyen Kullanıcı',
      email: json['email'] ?? 'eposta-yok@bilinmiyor.com',
      role: json['role'] ?? 'user',
      
      city: json['city'],
      avatarUrl: json['avatarUrl'], // Eklendi
      about: json['about'],        // Eklendi
      isSeller: json['isSeller'] == true || json['role'] == 'seller',
      points: (json['points'] as num?)?.toInt() ?? 0,
      badges: (json['badges'] as List?)?.map((e) => e.toString()).toList() ?? [],
      followersCount: (json['followersCount'] as num?)?.toInt() ?? 0,
      followingCount: (json['followingCount'] as num?)?.toInt() ?? 0,
      isFollowing: json['isFollowing'] == true,
    );
  }
  // --- GÜNCELLEME BİTTİ ---
}
