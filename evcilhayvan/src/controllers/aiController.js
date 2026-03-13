import { config } from "../config/config.js";

const ANTHROPIC_API_URL = "https://api.anthropic.com/v1/messages";
const MODEL = "claude-haiku-4-5-20251001";

// ─── Hastalık / Durum Listesi (token tasarrufu için sabit bağlam) ───────────
// AI bu listeden seçim yapar, kendi bilgisini "uydurma" riski azalır
const DISEASE_LIST = `KÖPEK: Parvoviroz|Distemper|Leptospiroz|Kuduz|Enfeksiyöz Hepatit|Kennel Öksürüğü|Leishmaniasis|Ehrlichiosis|Babesiosis|Demodikoz|Sarkoptik Uyuz|Otitis Externa|Piyometra|Hip Displazisi|Epilepsi|Deri Alerjisi|Giardia|Ankilostomiyaz|Toksokaroz|Kalp Kurdu|Gastrit|Pankreatit|Zehirlenme
KEDİ: FIP|FIV|FeLV|Panloykopeni|Kedi Calicivirüsü|Kedi Herpesvirus|Toksoplazmoz|FLUTD/Sistit|Böbrek Yetmezliği|Hipertiroidi|Diyabet|Uyuz|Ringworm|Üst Solunum Enfeksiyonu|Stomatit|Zehirlenme
KUŞ: Psittakoz|Aspergilloz|Poliomavirus|Tüy Yolma|Beyin Nöbet|Koles|Krop Enfeksiyonu
GENEL: Keneler|Bitler|Pireler|Konjunktivit|İshal|Kusma|Şişkinlik|Tümör|Kırık/Çıkık|Güneş Çarpması|Doğum Güçlüğü|Anemi|Sarılık|Zatürree`;

// Kısa ve token-verimli sistem promptu
const SYSTEM_PROMPT = `Sen bir evcil hayvan sağlık asistanısın. Türkçe, kısa ve yapılandırılmış yanıt ver.

HASTALИК LİSTESİ (yalnızca bu listeden teşhis yap):
${DISEASE_LIST}

YANIT FORMATI (bu 3 bölümü kullan, fazlasını yazma):
🔍 Olası Durum: [listeden 1-3 seçenek]
⚠️ Aciliyet: [Düşük / Orta / Yüksek / ACİL-veterinere git]
💡 Tavsiye: [1-2 cümle pratik öneri]

KURALLAR:
- Listede yoksa "Listede yok, veterinere git" yaz
- Aciliyeti Yüksek/ACİL ise mutlaka veteriner vurgula
- Tanı koymak değil, yönlendirmek amacındasın
- 150 kelimeyi geçme`;

// ─── POST /api/ai/chat ───────────────────────────────────────────────────────
export const chatWithAI = async (req, res) => {
  try {
    const apiKey = config.anthropicApiKey;
    if (!apiKey) {
      return res.sendError("AI servisi şu anda kullanılamıyor.", 503);
    }

    const { messages, mode } = req.body; // mode: 'diagnosis' | 'general'
    if (!messages || !Array.isArray(messages) || messages.length === 0) {
      return res.sendError("Geçersiz mesaj formatı.", 400);
    }

    // Genel sohbet modu için farklı sistem promptu (daha kısa)
    const systemPrompt = mode === "general"
      ? "Sen evcil hayvan bakım asistanısın. Türkçe, kısa (max 100 kelime) pratik tavsiyeler ver. Tıbbi acilde veterinere yönlendir."
      : SYSTEM_PROMPT;

    const maxTokens = mode === "general" ? 300 : 256;

    // Son 6 mesajı al (daha az token)
    const recentMessages = messages.slice(-6).map((m) => ({
      role: m.role === "user" ? "user" : "assistant",
      content: String(m.content || "").slice(0, 500), // mesaj başına 500 karakter max
    }));

    const response = await fetch(ANTHROPIC_API_URL, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "x-api-key": apiKey,
        "anthropic-version": "2023-06-01",
      },
      body: JSON.stringify({
        model: MODEL,
        max_tokens: maxTokens,
        system: systemPrompt,
        messages: recentMessages,
      }),
    });

    if (!response.ok) {
      const errBody = await response.text();
      console.error("Anthropic API error:", response.status, errBody);
      return res.sendError("AI servisi yanıt vermedi.", 502);
    }

    const data = await response.json();
    const reply = data?.content?.[0]?.text;
    if (!reply) return res.sendError("AI yanıtı alınamadı.", 502);

    res.sendOk({ reply });
  } catch (err) {
    console.error("AI chat error:", err.message);
    res.sendError("AI servisi hatası: " + err.message);
  }
};

// GET /api/ai/diseases  — hastalık listesini döndür (Flutter'da chip gösterimi için)
export const getDiseases = (_req, res) => {
  const categories = {};
  DISEASE_LIST.split("\n").forEach((line) => {
    const [cat, items] = line.split(": ");
    if (cat && items) {
      categories[cat] = items.split("|");
    }
  });
  res.sendOk({ categories });
};
