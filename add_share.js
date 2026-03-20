const fs = require('fs');
const file = 'c:/Users/PC/Desktop/evcilhayvanoriginal/evcilhayvan_mobil2/lib/features/pets/presentation/screens/pet_detail.screen.dart';
let content = fs.readFileSync(file, 'utf8');

// 1. Add share_plus import
content = content.replace(
  "import 'package:qr_flutter/qr_flutter.dart';",
  "import 'package:qr_flutter/qr_flutter.dart';\nimport 'package:share_plus/share_plus.dart';"
);

// 2. Add share button before QR button
const qrBtn = "        Container(\r\n          margin: const EdgeInsets.all(8),\r\n          decoration: BoxDecoration(\r\n            color: Colors.black.withOpacity(0.3),\r\n            shape: BoxShape.circle,\r\n          ),\r\n          child: IconButton(\r\n            icon: const Icon(Icons.qr_code_rounded, color: Colors.white),\r\n            tooltip: 'QR Kimlik Karti',\r\n            onPressed: () => _showQrCard(context, pet),\r\n          ),\r\n        ),";

const shareAndQr = "        Container(\r\n          margin: const EdgeInsets.all(8),\r\n          decoration: BoxDecoration(\r\n            color: Colors.black.withOpacity(0.3),\r\n            shape: BoxShape.circle,\r\n          ),\r\n          child: IconButton(\r\n            icon: const Icon(Icons.share_rounded, color: Colors.white),\r\n            tooltip: 'Paylaş',\r\n            onPressed: () {\r\n              HapticFeedback.lightImpact();\r\n              Share.share(\r\n                '${pet.name} - Pati Arkadaşı uygulamasında keşfet!',\r\n                subject: '${pet.name} ilanı',\r\n              );\r\n            },\r\n          ),\r\n        ),\r\n        Container(\r\n          margin: const EdgeInsets.all(8),\r\n          decoration: BoxDecoration(\r\n            color: Colors.black.withOpacity(0.3),\r\n            shape: BoxShape.circle,\r\n          ),\r\n          child: IconButton(\r\n            icon: const Icon(Icons.qr_code_rounded, color: Colors.white),\r\n            tooltip: 'QR Kimlik Karti',\r\n            onPressed: () => _showQrCard(context, pet),\r\n          ),\r\n        ),";

if (content.includes(qrBtn)) {
  content = content.replace(qrBtn, shareAndQr);
  console.log('Share button added');
} else {
  console.log('QR button pattern NOT found, trying alternative...');
  // Try without \r
  const qrBtn2 = "        Container(\n          margin: const EdgeInsets.all(8),\n          decoration: BoxDecoration(\n            color: Colors.black.withOpacity(0.3),\n            shape: BoxShape.circle,\n          ),\n          child: IconButton(\n            icon: const Icon(Icons.qr_code_rounded, color: Colors.white),\n            tooltip: 'QR Kimlik Karti',\n            onPressed: () => _showQrCard(context, pet),\n          ),\n        ),";
  if (content.includes(qrBtn2)) {
    console.log('Found without \\r');
  } else {
    // Search line by line
    const lines = content.split('\n');
    for (let i = 0; i < lines.length; i++) {
      if (lines[i].includes('qr_code_rounded')) {
        console.log('QR line found at:', i, JSON.stringify(lines[i]));
      }
    }
  }
}

fs.writeFileSync(file, content, 'utf8');
