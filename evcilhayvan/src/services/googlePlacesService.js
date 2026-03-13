import { config } from "../config/config.js";

const BASE_URL = "https://maps.googleapis.com/maps/api/place";

export async function searchNearbyVets(lat, lng, radiusMeters = 5000) {
  if (!config.googlePlacesApiKey) {
    console.warn("[GooglePlaces] API key not configured");
    return [];
  }

  const params = new URLSearchParams({
    location: `${lat},${lng}`,
    radius: String(radiusMeters),
    type: "veterinary_care",
    key: config.googlePlacesApiKey,
    language: "tr",
  });

  try {
    const response = await fetch(`${BASE_URL}/nearbysearch/json?${params}`);
    const data = await response.json();
    if (data.status !== "OK" && data.status !== "ZERO_RESULTS") {
      console.error("[GooglePlaces] API error:", data.status, data.error_message);
    }
    return data.results || [];
  } catch (err) {
    console.error("[GooglePlaces] fetch error:", err.message);
    return [];
  }
}

export async function getPlaceDetails(placeId) {
  if (!config.googlePlacesApiKey) return null;

  const params = new URLSearchParams({
    place_id: placeId,
    fields:
      "name,formatted_address,formatted_phone_number,geometry,website,opening_hours,rating,user_ratings_total,photos",
    key: config.googlePlacesApiKey,
    language: "tr",
  });

  try {
    const response = await fetch(`${BASE_URL}/details/json?${params}`);
    const data = await response.json();
    return data.result || null;
  } catch (err) {
    console.error("[GooglePlaces] details error:", err.message);
    return null;
  }
}

export function mapGoogleResultToVet(result) {
  const loc = result.geometry?.location;
  return {
    name: result.name || "Bilinmeyen",
    address: result.vicinity || result.formatted_address || "",
    phone: result.formatted_phone_number || "",
    website: result.website || "",
    location: {
      type: "Point",
      coordinates: loc ? [loc.lng, loc.lat] : [0, 0],
    },
    source: "google_places",
    googlePlaceId: result.place_id,
    googleRating: result.rating || 0,
    googleReviewCount: result.user_ratings_total || 0,
    isVerified: true,
    isActive: true,
  };
}
