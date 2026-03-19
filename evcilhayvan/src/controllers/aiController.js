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

// ─── Uygulama İçi Navigasyon / Rehber Sistemi ───────────────────────────────
const NAV_SYSTEM_PROMPT = `Sen "Rehber Pati" adlı bir uygulama yardım asistanısın.
Kullanıcının ne yapmak istediğini anlayıp JSON formatında yanıt verirsin.

UYGULAMA ROTALARI:
- home: Ana sayfa (ilan listesi)
- mating: Eşleştirme (swipe kartları)
- mating-requests: Eşleştirme istekleri gelen kutusu
- vet-search: Veteriner ara (queryParams: nearMe=true)
- veterinary: Veteriner ana sayfa
- store: Mağaza ana sayfası
- stores-list: Tüm mağazalar listesi
- cart: Alışveriş sepeti
- favorites: Favorilerim
- messages: Mesajlar / Sohbetler
- lost-found: Kayıp & Bulunan ilanları
- events: Etkinlikler
- create-pet: İlan oluştur (extra: {advertType: "adoption"} veya {advertType: "mating"})
- profile: Profil sayfam
- ai-assistant: Evcil hayvan sağlık asistanı (Pati Asistan)
- search: Genel arama (queryParams: q=aramaMetni)
- notifications: Bildirimler
- sitters: Evcil hayvan bakıcıları
- nearby-ads: Yakınımdaki ilanlar

YANIT FORMATI (sadece geçerli JSON, başka bir şey yazma):
{
  "reply": "Kullanıcıya kısa, samimi Türkçe yanıt (max 30 kelime)",
  "action": {
    "route": "rota-adı",
    "pathParams": {},
    "queryParams": {},
    "extra": {}
  },
  "suggestions": ["İlk öneri", "İkinci öneri", "Üçüncü öneri"]
}

KURALLAR:
- action, bulunamazsa null olabilir
- suggestions her zaman 2-4 adet kısa öneri içermeli
- Yanıt Türkçe, samimi ve kısa olmalı
- Rota bulamazsan reply'da açıkla ve suggestions ver
- Kullanıcı ilan oluşturmak istiyorsa advertType'ı doğru ayarla`;

// ─── POST /api/ai/navigate ───────────────────────────────────────────────────
export const navigateWithAI = async (req, res) => {
  try {
    const apiKey = config.anthropicApiKey;
    if (!apiKey) {
      return res.sendOk({
        reply: "AI şu an kullanılamıyor.",
        action: null,
        suggestions: ["Ana Sayfa", "Veteriner Ara", "Eşleştirme", "Mağaza"],
      });
    }

    const { message } = req.body;
    if (!message || typeof message !== "string") {
      return res.sendError("Mesaj gerekli.", 400);
    }

    const response = await fetch(ANTHROPIC_API_URL, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "x-api-key": apiKey,
        "anthropic-version": "2023-06-01",
      },
      body: JSON.stringify({
        model: MODEL,
        max_tokens: 256,
        system: NAV_SYSTEM_PROMPT,
        messages: [{ role: "user", content: String(message).slice(0, 300) }],
      }),
    });

    if (!response.ok) {
      console.error("Anthropic navigate error:", response.status);
      return res.sendOk({
        reply: "Şu an yardım edemiyorum, lütfen tekrar dene.",
        action: null,
        suggestions: ["Ana Sayfa", "Veteriner Ara", "Eşleştirme"],
      });
    }

    const data = await response.json();
    const text = data?.content?.[0]?.text ?? "";

    // JSON parse — model bazen ```json ... ``` bloğu içinde döndürebilir
    let parsed;
    try {
      const cleaned = text.replace(/```json|```/g, "").trim();
      parsed = JSON.parse(cleaned);
    } catch {
      parsed = {
        reply: text.slice(0, 120) || "Anlayamadım, lütfen tekrar dene.",
        action: null,
        suggestions: ["Ana Sayfa", "Veteriner Ara", "Eşleştirme", "Mağaza"],
      };
    }

    res.sendOk({
      reply: parsed.reply ?? "Tamam!",
      action: parsed.action ?? null,
      suggestions: Array.isArray(parsed.suggestions) ? parsed.suggestions.slice(0, 4) : [],
    });
  } catch (err) {
    console.error("Navigate AI error:", err.message);
    res.sendOk({
      reply: "Bir hata oluştu, lütfen tekrar dene.",
      action: null,
      suggestions: ["Ana Sayfa", "Veteriner Ara", "Mağaza"],
    });
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
