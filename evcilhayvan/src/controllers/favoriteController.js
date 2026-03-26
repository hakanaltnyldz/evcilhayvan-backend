// src/controllers/favoriteController.js

import Favorite from '../models/Favorite.js';
import Pet from '../models/Pet.js';
import Product from '../models/Product.js';
import Store from '../models/Store.js';
import { sendOk, sendError } from '../utils/apiResponse.js';

// Yardımcı: favori listesini N+1 olmadan popüle et ($lookup ile)
async function populateFavoriteItems(favorites) {
  // Tip bazında grupla
  const petIds = [];
  const productIds = [];
  const storeIds = [];

  for (const fav of favorites) {
    if (fav.itemType === 'pet') petIds.push(fav.itemId);
    else if (fav.itemType === 'product') productIds.push(fav.itemId);
    else if (fav.itemType === 'store') storeIds.push(fav.itemId);
  }

  // Tek sorguda her tipi çek
  const [pets, products, stores] = await Promise.all([
    petIds.length ? Pet.find({ _id: { $in: petIds } }).lean() : [],
    productIds.length ? Product.find({ _id: { $in: productIds } }).populate('store', 'name logoUrl description').populate('category', 'name').lean() : [],
    storeIds.length ? Store.find({ _id: { $in: storeIds } }).lean() : [],
  ]);

  // Hızlı arama için map oluştur
  const petMap = Object.fromEntries(pets.map(p => [String(p._id), p]));
  const productMap = Object.fromEntries(products.map(p => [String(p._id), p]));
  const storeMap = Object.fromEntries(stores.map(s => [String(s._id), s]));

  return favorites
    .map(fav => {
      let item = null;
      if (fav.itemType === 'pet') item = petMap[String(fav.itemId)] || null;
      else if (fav.itemType === 'product') item = productMap[String(fav.itemId)] || null;
      else if (fav.itemType === 'store') item = storeMap[String(fav.itemId)] || null;
      if (!item) return null; // Silinmiş öğe
      return { _id: fav._id, itemType: fav.itemType, item, createdAt: fav.createdAt };
    })
    .filter(Boolean);
}

// Get all favorites for the current user
export const getFavorites = async (req, res) => {
  try {
    const { type } = req.query;
    const userId = req.user.sub || req.user._id;

    const filter = { user: userId };
    if (type && ['pet', 'product', 'store'].includes(type)) {
      filter.itemType = type;
    }

    const favorites = await Favorite.find(filter).sort({ createdAt: -1 }).lean();
    const formatted = await populateFavoriteItems(favorites);

    return sendOk(res, 200, { favorites: formatted });
  } catch (error) {
    console.error('Get favorites error:', error);
    return sendError(res, 500, 'Favoriler yüklenirken hata oluştu', 'internal_error', error.message);
  }
};

// Add item to favorites
export const addFavorite = async (req, res) => {
  try {
    const { itemType, itemId } = req.body;
    const userId = req.user.sub || req.user._id;

    if (!['pet', 'product', 'store'].includes(itemType)) {
      return sendError(res, 400, 'Geçersiz favori tipi', 'validation_error');
    }

    if (!itemId) {
      return sendError(res, 400, 'itemId gerekli', 'validation_error');
    }

    // Verify item exists
    let itemExists = false;
    if (itemType === 'pet') itemExists = !!(await Pet.exists({ _id: itemId }));
    else if (itemType === 'product') itemExists = !!(await Product.exists({ _id: itemId }));
    else if (itemType === 'store') itemExists = !!(await Store.exists({ _id: itemId }));

    if (!itemExists) {
      return sendError(res, 404, 'Öğe bulunamadı', 'not_found');
    }

    // Check if already favorited
    const existingFavorite = await Favorite.findOne({ user: userId, itemType, itemId });
    if (existingFavorite) {
      return sendError(res, 400, 'Bu öğe zaten favorilerde', 'already_favorited');
    }

    const itemTypeToModel = { pet: 'Pet', product: 'Product', store: 'Store' };

    const favorite = await Favorite.create({
      user: userId,
      itemType,
      itemModel: itemTypeToModel[itemType],
      itemId,
    });

    // Populate item
    let item = null;
    if (itemType === 'pet') item = await Pet.findById(itemId).lean();
    else if (itemType === 'product') item = await Product.findById(itemId).populate('store', 'name logoUrl description').populate('category', 'name').lean();
    else if (itemType === 'store') item = await Store.findById(itemId).lean();

    return sendOk(res, 201, {
      message: 'Favorilere eklendi',
      favorite: { _id: favorite._id, itemType: favorite.itemType, item, createdAt: favorite.createdAt },
    });
  } catch (error) {
    console.error('Add favorite error:', error);
    return sendError(res, 500, 'Favorilere eklenirken hata oluştu', 'internal_error', error.message);
  }
};

// Remove item from favorites
export const removeFavorite = async (req, res) => {
  try {
    const { itemType, itemId } = req.body;
    const userId = req.user.sub || req.user._id;

    const favorite = await Favorite.findOneAndDelete({ user: userId, itemType, itemId });
    if (!favorite) {
      return sendError(res, 404, 'Favori bulunamadı', 'not_found');
    }

    return sendOk(res, 200, { message: 'Favorilerden kaldırıldı' });
  } catch (error) {
    console.error('Remove favorite error:', error);
    return sendError(res, 500, 'Favorilerden kaldırılırken hata oluştu', 'internal_error', error.message);
  }
};

// Check if item is favorited by current user
export const checkFavorite = async (req, res) => {
  try {
    const { itemType, itemId } = req.query;
    const userId = req.user.sub || req.user._id;

    const favorite = await Favorite.findOne({ user: userId, itemType, itemId });
    return sendOk(res, 200, { isFavorite: !!favorite });
  } catch (error) {
    console.error('Check favorite error:', error);
    return sendError(res, 500, 'Favori kontrolü yapılırken hata oluştu', 'internal_error', error.message);
  }
};

// Get favorites count by type
export const getFavoritesCount = async (req, res) => {
  try {
    const userId = req.user.sub || req.user._id;

    const [petCount, productCount, storeCount] = await Promise.all([
      Favorite.countDocuments({ user: userId, itemType: 'pet' }),
      Favorite.countDocuments({ user: userId, itemType: 'product' }),
      Favorite.countDocuments({ user: userId, itemType: 'store' }),
    ]);

    return sendOk(res, 200, {
      counts: {
        pet: petCount,
        product: productCount,
        store: storeCount,
        total: petCount + productCount + storeCount,
      },
    });
  } catch (error) {
    console.error('Get favorites count error:', error);
    return sendError(res, 500, 'Favori sayısı alınırken hata oluştu', 'internal_error', error.message);
  }
};
