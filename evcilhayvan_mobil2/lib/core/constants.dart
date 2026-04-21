/// Application-wide constants. Prefer these over repeated magic numbers.

// Image quality
/// General uploads like profile photos, product images, and store logos.
const int kImageQualityMedium = 80;

/// Higher quality uploads like chat images and pet photos.
const int kImageQualityHigh = 85;

/// Lower priority previews like post and event thumbnails.
const int kImageQualityLow = 70;

/// Maximum width for profile and other small images in pixels.
const double kImageMaxWidthSmall = 800;

/// Maximum width for gallery uploads in pixels.
const double kImageMaxWidth = 1200;

// Location and distance
/// Default search radius for nearby pet listings in kilometers.
const double kDefaultPetRadiusKm = 25;

/// Default veterinarian search radius in kilometers.
const double kDefaultVetRadiusKm = 10;

/// Default lost and found search radius in kilometers.
const double kDefaultLostFoundRadiusKm = 50;

/// Default sitter search radius in kilometers.
const double kDefaultSitterRadiusKm = 20;

/// Default event listing radius in kilometers.
const double kDefaultEventRadiusKm = 50;

/// Default map discovery radius in kilometers.
const double kDefaultMapRadiusKm = 15;

/// Default max distance for mating matches in kilometers.
const double kDefaultMatingMaxDistanceKm = 20;

// Pagination
/// Default page size for generic lists.
const int kDefaultPageSize = 10;

/// Page size for the store product feed.
const int kStoreFeedLimit = 40;

// Store / inventory
/// Stock count at or below which a product is considered "low stock".
const int kLowStockThreshold = 5;
