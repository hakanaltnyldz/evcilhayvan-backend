// src/controllers/addressController.js

import Address from "../models/Address.js";
import { sendError, sendOk } from "../utils/apiResponse.js";

// Tüm adresleri getir
export async function getAddresses(req, res) {
  try {
    const userId = req.user?.sub || req.user?._id;
    if (!userId) return sendError(res, 401, "Kimlik doğrulama gerekli", "auth_required");

    const addresses = await Address.find({ user: userId }).sort({ isDefault: -1, createdAt: -1 });
    return sendOk(res, 200, { addresses });
  } catch (err) {
    console.error("[getAddresses] error", err);
    return sendError(res, 500, "Adresler getirilemedi", "internal_error", err.message);
  }
}

// Adres ekle
export async function addAddress(req, res) {
  try {
    const userId = req.user?.sub || req.user?._id;
    if (!userId) return sendError(res, 401, "Kimlik doğrulama gerekli", "auth_required");

    const { title, fullName, phone, city, district, neighborhood, street, buildingNo, floor, apartmentNo, postalCode, isDefault } = req.body || {};

    if (!title || !fullName || !phone || !city || !district || !street) {
      return sendError(res, 400, "Zorunlu alanlar eksik", "validation_error");
    }

    // Eğer varsayılan olarak işaretlendiyse, diğer adreslerin varsayılanını kaldır
    if (isDefault) {
      await Address.updateMany({ user: userId }, { isDefault: false });
    }

    // İlk adres ise varsayılan yap
    const addressCount = await Address.countDocuments({ user: userId });

    const address = await Address.create({
      user: userId,
      title,
      fullName,
      phone,
      city,
      district,
      neighborhood,
      street,
      buildingNo,
      floor,
      apartmentNo,
      postalCode,
      isDefault: isDefault || addressCount === 0,
    });

    return sendOk(res, 201, { address });
  } catch (err) {
    console.error("[addAddress] error", err);
    return sendError(res, 500, "Adres eklenemedi", "internal_error", err.message);
  }
}

// Adres güncelle
export async function updateAddress(req, res) {
  try {
    const userId = req.user?.sub || req.user?._id;
    const { id } = req.params;

    const address = await Address.findOne({ _id: id, user: userId });
    if (!address) {
      return sendError(res, 404, "Adres bulunamadı", "address_not_found");
    }

    const { title, fullName, phone, city, district, neighborhood, street, buildingNo, floor, apartmentNo, postalCode, isDefault } = req.body || {};

    // Eğer varsayılan olarak işaretlendiyse, diğer adreslerin varsayılanını kaldır
    if (isDefault && !address.isDefault) {
      await Address.updateMany({ user: userId, _id: { $ne: id } }, { isDefault: false });
    }

    Object.assign(address, {
      title: title ?? address.title,
      fullName: fullName ?? address.fullName,
      phone: phone ?? address.phone,
      city: city ?? address.city,
      district: district ?? address.district,
      neighborhood: neighborhood ?? address.neighborhood,
      street: street ?? address.street,
      buildingNo: buildingNo ?? address.buildingNo,
      floor: floor ?? address.floor,
      apartmentNo: apartmentNo ?? address.apartmentNo,
      postalCode: postalCode ?? address.postalCode,
      isDefault: isDefault ?? address.isDefault,
    });

    await address.save();

    return sendOk(res, 200, { address });
  } catch (err) {
    console.error("[updateAddress] error", err);
    return sendError(res, 500, "Adres güncellenemedi", "internal_error", err.message);
  }
}

// Adres sil
export async function deleteAddress(req, res) {
  try {
    const userId = req.user?.sub || req.user?._id;
    const { id } = req.params;

    const address = await Address.findOneAndDelete({ _id: id, user: userId });
    if (!address) {
      return sendError(res, 404, "Adres bulunamadı", "address_not_found");
    }

    // Silinen adres varsayılansa, başka bir adresi varsayılan yap
    if (address.isDefault) {
      const anotherAddress = await Address.findOne({ user: userId });
      if (anotherAddress) {
        anotherAddress.isDefault = true;
        await anotherAddress.save();
      }
    }

    return sendOk(res, 200, { message: "Adres silindi" });
  } catch (err) {
    console.error("[deleteAddress] error", err);
    return sendError(res, 500, "Adres silinemedi", "internal_error", err.message);
  }
}

// Varsayılan adres yap
export async function setDefaultAddress(req, res) {
  try {
    const userId = req.user?.sub || req.user?._id;
    const { id } = req.params;

    const address = await Address.findOne({ _id: id, user: userId });
    if (!address) {
      return sendError(res, 404, "Adres bulunamadı", "address_not_found");
    }

    // Tüm adreslerin varsayılanını kaldır
    await Address.updateMany({ user: userId }, { isDefault: false });

    // Bu adresi varsayılan yap
    address.isDefault = true;
    await address.save();

    return sendOk(res, 200, { address });
  } catch (err) {
    console.error("[setDefaultAddress] error", err);
    return sendError(res, 500, "Varsayılan adres ayarlanamadı", "internal_error", err.message);
  }
}

// Varsayılan adresi getir
export async function getDefaultAddress(req, res) {
  try {
    const userId = req.user?.sub || req.user?._id;
    if (!userId) return sendError(res, 401, "Kimlik doğrulama gerekli", "auth_required");

    let address = await Address.findOne({ user: userId, isDefault: true });

    // Varsayılan yoksa ilk adresi getir
    if (!address) {
      address = await Address.findOne({ user: userId }).sort({ createdAt: -1 });
    }

    return sendOk(res, 200, { address });
  } catch (err) {
    console.error("[getDefaultAddress] error", err);
    return sendError(res, 500, "Adres getirilemedi", "internal_error", err.message);
  }
}