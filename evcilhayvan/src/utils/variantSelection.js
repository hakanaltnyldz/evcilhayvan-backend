function createVariantError(code, message, details = undefined) {
  const error = new Error(message);
  error.code = code;
  error.statusCode = 400;
  error.details = details;
  return error;
}

export function normalizeSelectedVariants(
  input,
  { variantName = null, variantLabel = null } = {},
) {
  const rawVariants = Array.isArray(input)
    ? input
    : variantName && variantLabel
      ? [{ name: variantName, label: variantLabel }]
      : [];

  const map = new Map();
  for (const rawVariant of rawVariants) {
    const name = String(rawVariant?.name ?? "").trim();
    const label = String(rawVariant?.label ?? "").trim();
    if (!name || !label) continue;
    map.set(name, { name, label });
  }

  return Array.from(map.values()).sort((a, b) => a.name.localeCompare(b.name));
}

export function buildVariantKey(selectedVariants = []) {
  if (!selectedVariants.length) return "default";
  return selectedVariants
    .map((variant) => `${variant.name}:${variant.label}`)
    .join("|");
}

export function getPrimaryVariant(selectedVariants = []) {
  return selectedVariants.length > 0 ? selectedVariants[0] : null;
}

export function describeSelectedVariants(selectedVariants = []) {
  return selectedVariants.map((variant) => `${variant.name}: ${variant.label}`).join(", ");
}

export function resolveProductVariantSelection(
  product,
  input,
  quantity = 1,
  { skipStockCheck = false } = {},
) {
  const selectedVariants = normalizeSelectedVariants(input, input || {});
  const basePrice = Number(product?.price || 0);
  const productVariants = Array.isArray(product?.variants) ? product.variants : [];

  if (productVariants.length === 0) {
    if (selectedVariants.length > 0) {
      throw createVariantError(
        "invalid_variant",
        `${product?.name || product?.title || "Urun"} icin variant secimi beklenmiyor`,
      );
    }
    const availableStock = Number(product?.stock || 0);
    if (!skipStockCheck && availableStock < quantity) {
      throw createVariantError(
        "insufficient_stock",
        `Yetersiz stok: ${product?.name || product?.title || "Urun"} (Mevcut: ${availableStock}, Istenen: ${quantity})`,
      );
    }
    return {
      selectedVariants: [],
      variantKey: buildVariantKey([]),
      unitPrice: basePrice,
      availableStock,
      primaryVariant: null,
    };
  }

  if (selectedVariants.length !== productVariants.length) {
    throw createVariantError(
      "variant_required",
      `${product?.name || product?.title || "Urun"} icin tum varyantlar secilmelidir`,
    );
  }

  let priceDiff = 0;
  let availableStock = null;
  const resolvedSelections = [];

  for (const group of productVariants) {
    const selected = selectedVariants.find((variant) => variant.name === group.name);
    if (!selected) {
      throw createVariantError(
        "variant_required",
        `${product?.name || product?.title || "Urun"} icin ${group.name} secimi zorunludur`,
      );
    }

    const option = group.options?.find((candidate) => candidate.label === selected.label);
    if (!option) {
      throw createVariantError(
        "invalid_variant",
        `Gecersiz variant: ${selected.name}/${selected.label}`,
      );
    }

    const optionStock = Number(option.stock || 0);
    if (availableStock == null || optionStock < availableStock) {
      availableStock = optionStock;
    }
    priceDiff += Number(option.priceDiff || 0);
    resolvedSelections.push({ name: group.name, label: option.label });
  }

  const normalizedStock = Number(availableStock || 0);
  if (!skipStockCheck && normalizedStock < quantity) {
    throw createVariantError(
      "insufficient_stock",
      `Variant stok yetersiz: ${describeSelectedVariants(resolvedSelections)} (Mevcut: ${normalizedStock})`,
    );
  }

  return {
    selectedVariants: resolvedSelections,
    variantKey: buildVariantKey(resolvedSelections),
    unitPrice: basePrice + priceDiff,
    availableStock: normalizedStock,
    primaryVariant: getPrimaryVariant(resolvedSelections),
  };
}
