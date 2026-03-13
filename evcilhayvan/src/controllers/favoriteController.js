// src/controllers/favoriteController.js

import Favorite from '../models/Favorite.js';
import Pet from '../models/Pet.js';
import Product from '../models/Product.js';
import Store from '../models/Store.js';

// Get all favorites for the current user
export const getFavorites = async (req, res) => {
  try {
    const { type } = req.query; // Optional filter by type (pet, product, store)
    const userId = req.user._id;

    const filter = { user: userId };
    if (type && ['pet', 'product', 'store'].includes(type)) {
      filter.itemType = type;
    }

    // Get favorites without population first
    const favorites = await Favorite.find(filter).sort({ createdAt: -1 }).lean();

    // Manually populate each item based on itemType
    const formattedFavorites = await Promise.all(
      favorites.map(async (fav) => {
        let item = null;
        try {
          if (fav.itemType === 'pet') {
            item = await Pet.findById(fav.itemId)
              .populate('owner', 'name email profilePicture')
              .lean();
          } else if (fav.itemType === 'product') {
            item = await Product.findById(fav.itemId)
              .populate('store', 'name logoUrl description')
              .populate('category', 'name')
              .lean();
          } else if (fav.itemType === 'store') {
            item = await Store.findById(fav.itemId)
              .populate('owner', 'name email profilePicture')
              .lean();
          }
        } catch (err) {
          console.error(`Error populating favorite ${fav._id}:`, err.message);
        }

        return {
          _id: fav._id,
          itemType: fav.itemType,
          item: item,
          createdAt: fav.createdAt,
        };
      })
    );

    // Filter out favorites where item is null (deleted items)
    const validFavorites = formattedFavorites.filter(fav => fav.item !== null);

    res.json({
      success: true,
      favorites: validFavorites,
    });
  } catch (error) {
    console.error('Get favorites error:', error);
    res.status(500).json({
      success: false,
      message: 'Favoriler yüklenirken hata oluştu',
      error: error.message,
    });
  }
};

// Add item to favorites
export const addFavorite = async (req, res) => {
  try {
    const { itemType, itemId } = req.body;
    const userId = req.user._id;

    // Validate itemType
    if (!['pet', 'product', 'store'].includes(itemType)) {
      return res.status(400).json({
        success: false,
        message: 'Geçersiz favori tipi',
      });
    }

    // Verify item exists
    let itemExists = false;
    if (itemType === 'pet') {
      itemExists = await Pet.exists({ _id: itemId });
    } else if (itemType === 'product') {
      itemExists = await Product.exists({ _id: itemId });
    } else if (itemType === 'store') {
      itemExists = await Store.exists({ _id: itemId });
    }

    if (!itemExists) {
      return res.status(404).json({
        success: false,
        message: 'Öğe bulunamadı',
      });
    }

    // Check if already favorited
    const existingFavorite = await Favorite.findOne({
      user: userId,
      itemType,
      itemId,
    });

    if (existingFavorite) {
      return res.status(400).json({
        success: false,
        message: 'Bu öğe zaten favorilerde',
      });
    }

    // Map itemType to model name for refPath
    const itemTypeToModel = {
      pet: 'Pet',
      product: 'Product',
      store: 'Store',
    };

    // Create favorite
    const favorite = await Favorite.create({
      user: userId,
      itemType,
      itemModel: itemTypeToModel[itemType],
      itemId,
    });

    // Manually populate based on itemType
    let item = null;
    if (itemType === 'pet') {
      item = await Pet.findById(itemId)
        .populate('owner', 'name email profilePicture')
        .lean();
    } else if (itemType === 'product') {
      item = await Product.findById(itemId)
        .populate('store', 'name logoUrl description')
        .populate('category', 'name')
        .lean();
    } else if (itemType === 'store') {
      item = await Store.findById(itemId)
        .populate('owner', 'name email profilePicture')
        .lean();
    }

    res.status(201).json({
      success: true,
      message: 'Favorilere eklendi',
      favorite: {
        _id: favorite._id,
        itemType: favorite.itemType,
        item: item,
        createdAt: favorite.createdAt,
      },
    });
  } catch (error) {
    console.error('Add favorite error:', error);
    res.status(500).json({
      success: false,
      message: 'Favorilere eklenirken hata oluştu',
      error: error.message,
    });
  }
};

// Remove item from favorites
export const removeFavorite = async (req, res) => {
  try {
    const { itemType, itemId } = req.body;
    const userId = req.user._id;

    const favorite = await Favorite.findOneAndDelete({
      user: userId,
      itemType,
      itemId,
    });

    if (!favorite) {
      return res.status(404).json({
        success: false,
        message: 'Favori bulunamadı',
      });
    }

    res.json({
      success: true,
      message: 'Favorilerden kaldırıldı',
    });
  } catch (error) {
    console.error('Remove favorite error:', error);
    res.status(500).json({
      success: false,
      message: 'Favorilerden kaldırılırken hata oluştu',
      error: error.message,
    });
  }
};

// Check if item is favorited by current user
export const checkFavorite = async (req, res) => {
  try {
    const { itemType, itemId } = req.query;
    const userId = req.user._id;

    const favorite = await Favorite.findOne({
      user: userId,
      itemType,
      itemId,
    });

    res.json({
      success: true,
      isFavorite: !!favorite,
    });
  } catch (error) {
    console.error('Check favorite error:', error);
    res.status(500).json({
      success: false,
      message: 'Favori kontrolü yapılırken hata oluştu',
      error: error.message,
    });
  }
};

// Get favorites count by type
export const getFavoritesCount = async (req, res) => {
  try {
    const userId = req.user._id;

    const [petCount, productCount, storeCount] = await Promise.all([
      Favorite.countDocuments({ user: userId, itemType: 'pet' }),
      Favorite.countDocuments({ user: userId, itemType: 'product' }),
      Favorite.countDocuments({ user: userId, itemType: 'store' }),
    ]);

    res.json({
      success: true,
      counts: {
        pet: petCount,
        product: productCount,
        store: storeCount,
        total: petCount + productCount + storeCount,
      },
    });
  } catch (error) {
    console.error('Get favorites count error:', error);
    res.status(500).json({
      success: false,
      message: 'Favori sayısı alınırken hata oluştu',
      error: error.message,
    });
  }
};
