const fs = require('fs');
const zlib = require('zlib');
const path = require('path');

function createPNG(width, height, getPixel) {
  // PNG signature
  const sig = Buffer.from([137,80,78,71,13,10,26,10]);

  // IHDR
  const ihdr = Buffer.alloc(13);
  ihdr.writeUInt32BE(width, 0);
  ihdr.writeUInt32BE(height, 4);
  ihdr[8] = 8;  // bit depth
  ihdr[9] = 2;  // color type: RGB
  ihdr[10] = 0; ihdr[11] = 0; ihdr[12] = 0;

  // Raw image data (filter byte 0 + RGB per pixel)
  const raw = Buffer.alloc(height * (1 + width * 3));
  for (let y = 0; y < height; y++) {
    raw[y * (1 + width * 3)] = 0; // filter none
    for (let x = 0; x < width; x++) {
      const [r, g, b] = getPixel(x, y);
      const off = y * (1 + width * 3) + 1 + x * 3;
      raw[off] = r; raw[off+1] = g; raw[off+2] = b;
    }
  }

  const idat = zlib.deflateSync(raw, {level: 1});

  function chunk(type, data) {
    const len = Buffer.alloc(4);
    len.writeUInt32BE(data.length, 0);
    const t = Buffer.from(type, 'ascii');
    const crc = crc32(Buffer.concat([t, data]));
    const c = Buffer.alloc(4);
    c.writeUInt32BE(crc >>> 0, 0);
    return Buffer.concat([len, t, data, c]);
  }

  return Buffer.concat([
    sig,
    chunk('IHDR', ihdr),
    chunk('IDAT', idat),
    chunk('IEND', Buffer.alloc(0))
  ]);
}

function crc32(buf) {
  let crc = 0xFFFFFFFF;
  for (let i = 0; i < buf.length; i++) {
    crc ^= buf[i];
    for (let j = 0; j < 8; j++) {
      crc = (crc >>> 1) ^ ((crc & 1) ? 0xEDB88320 : 0);
    }
  }
  return (crc ^ 0xFFFFFFFF) >>> 0;
}

function ellipseHit(px, py, cx, cy, rw, rh) {
  const dx = (px - cx) / rw;
  const dy = (py - cy) / rh;
  return dx*dx + dy*dy <= 1.0;
}

function makePaw(size, bgR, bgG, bgB, bgA) {
  const cx = size / 2;
  const cy = size / 2 + size * 0.15;
  const s = size / 400.0;

  return function(x, y) {
    const inPalm = ellipseHit(x, y, cx, cy, 85*s, 70*s);
    const inP1 = ellipseHit(x, y, cx - 75*s, cy - 90*s, 28*s, 33*s);
    const inP2 = ellipseHit(x, y, cx - 25*s, cy - 115*s, 28*s, 33*s);
    const inP3 = ellipseHit(x, y, cx + 25*s, cy - 115*s, 28*s, 33*s);
    const inP4 = ellipseHit(x, y, cx + 75*s, cy - 90*s, 28*s, 33*s);
    if (inPalm || inP1 || inP2 || inP3 || inP4) return [255, 255, 255];
    return [bgR, bgG, bgB];
  };
}

const outDir = path.join(__dirname, 'evcilhayvan_mobil2', 'assets', 'icon');
fs.mkdirSync(outDir, { recursive: true });

const size = 512; // 512 yeterli, launcher_icons büyütür

// Ana ikon: mor arka plan
const pngMain = createPNG(size, size, makePaw(size, 108, 99, 255));
fs.writeFileSync(path.join(outDir, 'app_icon.png'), pngMain);

// Foreground (adaptive): seffaf olmak zorunda ama RGB PNG'de seffaf yok
// Beyaz pati, koyu mor arka plan (adaptive bg ayri tanimli)
const pngFg = createPNG(size, size, makePaw(size, 108, 99, 255));
fs.writeFileSync(path.join(outDir, 'app_icon_fg.png'), pngFg);

console.log('Icons created:', outDir);
