# T.C. [UNIVERSITE ADI]
## [FAKULTE / BOLUM ADI]
## Yazılım Mühendisliği Dersi Final Projesi Raporu

### Proje Adı
Bulut Tabanlı Dağıtık Evcil Hayvan Hizmet, Sosyal Ağ ve E-Ticaret Platformu

### Hazırlayan
- Öğrenci Adı Soyadı: `[BURAYA YAZ]`
- Öğrenci Numarası: `[BURAYA YAZ]`
- Ders Yürütücüsü: `[BURAYA YAZ]`
- Teslim Tarihi: `13.05.2026`

---

## Belge Kullanım Notu

Bu doküman, Yazılım Mühendisliği final projesi teslimi için hazırlanmış ana rapordur. Rapor; gereksinim analizi, kapsam, paydaşlar, yazılım geliştirme yaşam döngüsü, mimari tasarım, veritabanı tasarımı, güvenlik, kalite, operasyon ve bakım boyutlarını içermektedir. Detaylı kullanım senaryoları ve test-risk-plan ekleri ayrı dosyalara ayrılmıştır:

- [02_KULLANIM_SENARYOLARI_VE_SOZLESMELER.md](./02_KULLANIM_SENARYOLARI_VE_SOZLESMELER.md)
- [03_TEST_RISK_PLAN_EKLERI.md](./03_TEST_RISK_PLAN_EKLERI.md)

Bu üç doküman Word ortamında tek bir teslim dosyasında birleştirildiğinde, diyagramlar, ekran görüntüleri, tablo listeleri ve ekler ile birlikte oldukça kapsamlı bir final raporu elde edilmektedir.

---

## Özet

Evcil hayvan sahipleri, günlük yaşamlarında birden fazla dijital hizmete aynı anda ihtiyaç duymaktadır. Sahiplendirme ilanı verme, veteriner bulma, randevu alma, aşı geçmişini izleme, pet bakıcısı bulma, kayıp hayvan duyurusu paylaşma, sosyal etkileşim kurma ve pet ürünleri satın alma gibi süreçler günümüzde çoğunlukla birbirinden kopuk uygulamalar üzerinden yürütülmektedir. Bu durum kullanıcı deneyimini parçalamakta, veri tekrarına neden olmakta ve güven sorunlarını artırmaktadır.

Bu proje, söz konusu ihtiyacı tek platform altında birleştiren, mobil uygulama merkezli fakat web panel ve bulut servislerle desteklenen dağıtık bir yazılım sistemi olarak ele alınmıştır. Sistem; Flutter tabanlı mobil istemci, React tabanlı yönetim panelleri, Node.js + Express tabanlı REST API sunucusu, Socket.io tabanlı gerçek zamanlı iletişim katmanı ve MongoDB Atlas tabanlı bulut veritabanı bileşenlerinden oluşmaktadır. Sistem yalnızca bir sosyal uygulama ya da yalnızca bir e-ticaret uygulaması değildir; bunun yerine, evcil hayvan ekosisteminin farklı aktörlerini ortak veri modeli altında buluşturan çok modüllü bir dijital platform olarak kurgulanmıştır.

Raporun temel amacı, mevcut proje fikrini ve yaşayan uygulama kapsamını Yazılım Geliştirme Yaşam Döngüsü yaklaşımıyla analiz etmek, gereksinimleri modellemek, kullanım senaryolarını sözleşme biçiminde ifade etmek, mimari ve veri tasarımını açıklamak, güvenlik ve kalite boyutlarını tanımlamak ve projeyi dersin mühendislik odaklı beklentileri doğrultusunda bütünlüklü bir dokümantasyona dönüştürmektir.

Bu kapsamda raporda; problem tanımı, hedefler, kapsam ve kapsam dışı maddeler, paydaş analizi, fizibilite değerlendirmesi, işlevsel ve işlevsel olmayan gereksinimler, proje ekibi ve rol dağılımı, süreç modeli, mimari tasarım, veritabanı yapısı, test yaklaşımı, risk yönetimi, güvenlik önlemleri ve bakım stratejileri ele alınmıştır. Detaylı kullanım senaryoları, kabul ölçütleri, örnek test vakaları ve proje planlama ekleri ayrı dosyalarda desteklenmiştir.

---

## Abstract

Pet owners need multiple digital services in their daily lives, such as adoption listing, veterinary discovery, appointment scheduling, vaccination tracking, pet sitter booking, lost-and-found announcements, social interaction, and online shopping for pet products. These needs are usually handled through disconnected systems, which creates fragmented user experience, repeated data entry, and operational inefficiency.

This project proposes a distributed cloud-based software platform that unifies these services under a single ecosystem. The system is centered around a Flutter mobile client and supported by web panels, a Node.js + Express backend, a Socket.io real-time communication layer, and a MongoDB Atlas cloud database. Rather than functioning as only a social application or only an e-commerce application, the platform is designed as a multi-module digital environment for the broader pet-care domain.

The purpose of this report is to analyze the project in accordance with Software Development Life Cycle principles, model the requirements, define use cases, explain the architecture and database design, identify risks and quality objectives, and transform the project idea into a comprehensive engineering-oriented final report. Detailed use case contracts, testing artifacts, and planning appendices are provided in separate companion documents.

---

## İçindekiler Taslağı

> Word ortamında otomatik içindekiler tablosu oluşturulmalıdır.

1. Giriş
2. Problem Tanımı ve İhtiyaç Analizi
3. Projenin Amacı, Hedefleri ve Katkısı
4. Kapsam, Kapsam Dışı Maddeler, Varsayımlar ve Kısıtlar
5. Paydaş Analizi
6. Fizibilite Analizi
7. Proje Organizasyonu ve Yazılım Geliştirme Yaşam Döngüsü
8. Gereksinim Yönetimi Yaklaşımı
9. Sistem Genel Tanımı
10. Mimari Tasarım
11. Veritabanı Tasarımı ve Veri Yönetimi
12. Arayüz ve Kullanıcı Deneyimi Tasarımı
13. Güvenlik, Gizlilik ve Yetkilendirme
14. Performans, Ölçeklenebilirlik ve Operasyon
15. Bakım, İzleme ve Sürdürülebilirlik
16. Sonuç
17. Kaynaklar
18. Ekler

---

## 1. Giriş

Yazılım mühendisliği yalnızca çalışan bir uygulama üretmekten ibaret değildir. Bir projenin başarılı sayılabilmesi için problemin doğru tanımlanması, gereksinimlerin sistematik şekilde çıkarılması, çözümün uygun mimari ile modellenmesi, kalite hedeflerinin belirlenmesi, risklerin önceden düşünülmesi ve tüm sürecin izlenebilir hale getirilmesi gerekir. Özellikle dağıtık sistemlerin söz konusu olduğu projelerde yalnızca arayüz üretmek ya da birkaç API geliştirmek yeterli değildir; istemci, sunucu, veri depolama, gerçek zamanlı iletişim, dış servisler, yetkilendirme ve operasyon boyutlarının birlikte ele alınması gerekir.

Bu raporda incelenen proje, evcil hayvan ekosistemine yönelik çok yönlü bir dijital platformdur. Projede mobil istemci, admin paneli, satıcı paneli, backend API, gerçek zamanlı mesajlaşma sunucusu ve bulut veritabanı birlikte düşünülmektedir. Bu nedenle proje, ders yönergesinde özellikle vurgulanan "dağıtık sistem", "veritabanı işlemleri", "mobil uygulama ayağı", "internet/bulut üzerinde çalışma" ve "kapsamlı modelleme" gereksinimlerini karşılayabilecek niteliktedir.

Projenin alanı ilk bakışta geniş görünebilir; ancak bu genişlik aslında yazılım mühendisliği final projesi için avantajdır. Çünkü kapsamlı bir final ödevi, farklı aktörlere sahip, birden fazla alt modülü olan, veri akışı ve iş kuralları içeren, mimari kararlar gerektiren ve ayrıntılı dokümantasyona imkân veren bir sistem üzerinden daha güçlü biçimde sunulabilir. Bu raporun yaklaşımı da tam olarak budur: çalışan modülleri "özellik listesi" gibi sıralamak yerine, bunları analitik ve model temelli bir yazılım mühendisliği çalışmasına dönüştürmek.

---

## 2. Problem Tanımı ve İhtiyaç Analizi

### 2.1 Problemin Tanımı

Evcil hayvan sahipleri çoğu zaman farklı işlevler için farklı uygulamalar kullanmak zorunda kalmaktadır. Bir platform sahiplendirme için uygunken veteriner randevusu için yetersiz kalmakta, başka bir uygulama mağaza tarafını desteklerken sosyal etkileşimi içermemekte, bir başkası ise bakım veya kayıp ilanı senaryolarını sunmamaktadır. Bu parçalı yapı aşağıdaki problemlere yol açmaktadır:

- Kullanıcı aynı bilgileri birden fazla sisteme tekrar tekrar girmek zorunda kalmaktadır.
- Platformlar arası veri bütünlüğü bulunmamaktadır.
- Güvenilir bakıcı, satıcı veya veteriner bulma süreci zorlaşmaktadır.
- İletişim süreçleri dağınık hale gelmektedir.
- Kullanıcının hayvanı ile ilgili yaşam döngüsü bilgisi tek yerde toplanamamaktadır.
- Hizmet sağlayıcılar ve son kullanıcılar arasında merkezi bir güven mekanizması oluşmamaktadır.

### 2.2 Problemin Neden Önemli Olduğu

Evcil hayvan sahipliği, yalnızca sosyal paylaşım ya da alışverişten ibaret değildir. Bu alan; sağlık takibi, bakım, zaman yönetimi, acil durumlar, maddi harcamalar, güven ilişkisi ve topluluk etkileşimi gibi çok boyutlu süreçler içerir. Dolayısıyla bu alanı destekleyen dijital çözümün de çok modüllü olması beklenir. Ayrıca:

- Veteriner, bakıcı ve satıcı gibi farklı aktörler sisteme dahil olmaktadır.
- Mobil kullanım ön plandadır; kullanıcı hizmete yolda, evde, klinikte veya açık alanda ihtiyaç duyabilir.
- Konum tabanlı kararlar önemlidir; yakın veteriner, yakın bakıcı, yakın kayıp ilanı gibi.
- Gerçek zamanlı iletişim önemlidir; mesajlaşma, bildirimler, rezervasyon güncellemeleri.
- Güvenlik ve mahremiyet kritiktir; kullanıcı verisi, adres bilgisi, sağlık verisi, sipariş geçmişi gibi alanlar korunmalıdır.

### 2.3 Mevcut Yaklaşımların Eksikleri

Piyasadaki çoğu çözüm aşağıdaki sınırlardan birine sahiptir:

- Yalnızca ilan odaklıdır, işlem veya hizmet takibi sunmaz.
- Yalnızca e-ticaret odaklıdır, sosyal veya sağlık modülleri içermez.
- Yerel/kapalı bir kullanıcı kitlesiyle sınırlıdır.
- Mobil deneyimi zayıftır.
- Gerçek zamanlı iletişim veya bildirim desteği bulunmaz.
- Yönetim paneli ve denetim mekanizmaları yetersizdir.

Bu eksikler, tekil modüller yerine platform yaklaşımının gerekliliğini göstermektedir.

---

## 3. Projenin Amacı, Hedefleri ve Katkısı

### 3.1 Ana Amaç

Evcil hayvan sahipleri, veterinerler, pet bakıcıları, satıcılar ve yöneticiler için ortak dijital platform oluşturarak, farklı hizmetleri tek bir mobil ve bulut tabanlı sistem altında birleştirmek.

### 3.2 Alt Hedefler

1. Kullanıcının tüm evcil hayvan verilerini merkezi biçimde yönetebilmesini sağlamak.
2. Sahiplendirme ve eşleştirme süreçlerini dijitalleştirmek.
3. Veteriner arama, randevu ve aşı takibi süreçlerini mobil üzerinden erişilebilir kılmak.
4. Pet bakıcı rezervasyon akışını ve hizmet takibini desteklemek.
5. Gerçek zamanlı mesajlaşma ile kullanıcılar arası iletişimi hızlandırmak.
6. Mağaza, ürün, sepet ve sipariş süreçlerini tek platformda sunmak.
7. Yönetim ve moderasyon araçları ile platform güvenilirliğini artırmak.
8. Bulut tabanlı mimari ile çok kullanıcılı ve internet üzerinden erişilebilir bir yapı kurmak.

### 3.3 Projenin Katkısı

Bu projenin katkısı yalnızca farklı özellikleri yan yana getirmesi değildir. Daha önemli katkı, bu özellikleri aynı veri modeli, aynı kullanıcı hesabı, aynı bildirim altyapısı ve aynı operasyon mantığı altında birleştirmesidir. Böylece:

- Kullanıcı tek hesapla çok hizmete erişir.
- Veri tekrarının ve dağınıklığın önüne geçilir.
- Güvenilirlik ve izlenebilirlik artar.
- Hizmet sağlayıcılar için merkezi görünürlük oluşur.
- Platform büyüdükçe yeni modüller mevcut mimariyi bozmadan eklenebilir.

---

## 4. Kapsam, Kapsam Dışı Maddeler, Varsayımlar ve Kısıtlar

### 4.1 Kapsam

Proje aşağıdaki ana modülleri kapsamaktadır:

- Kullanıcı kayıt, giriş ve oturum yönetimi
- Kullanıcı profili ve pet profili yönetimi
- Sahiplendirme ilanları
- Çiftleştirme ve eşleştirme sistemi
- Gerçek zamanlı mesajlaşma
- Veteriner arama ve randevu alma
- Aşı takvimi ve sağlık günlüğü
- Pet bakıcı bulma ve rezervasyon
- Kayıp/bulunan hayvan ilanları
- Etkinlik modülü
- Sosyal paylaşım akışı
- Mağaza, ürün, sepet, kupon ve sipariş süreçleri
- Admin paneli
- Satıcı paneli

### 4.2 Kapsam Dışı

- Gerçek banka veya ödeme kuruluşu entegrasyonu
- Donanım sensör entegrasyonları
- Web istemci üzerinden tam son kullanıcı deneyimi
- Çok ülkelili vergi/fatura mevzuatı uyarlamaları
- Çağrı merkezi entegrasyonu

### 4.3 Varsayımlar

1. Kullanıcıların akıllı telefon ve internet erişimine sahip olduğu varsayılmıştır.
2. Konum tabanlı işlemler için cihaz izinlerinin verilmesi beklenmiştir.
3. Bildirim servisi olarak FCM benzeri altyapının erişilebilir olduğu kabul edilmiştir.
4. Admin ve satıcı panellerinin masaüstü veya geniş ekran cihazlarda kullanılacağı varsayılmıştır.
5. Sistem ilk aşamada orta ölçekli kullanıcı yükü için planlanmıştır.

### 4.4 Kısıtlar

- Proje akademik kapsamda modellenmektedir; üretim ortamındaki tüm operasyonel yükler birebir ele alınmamıştır.
- Tam ölçekli canlı operasyon maliyet analizi yaklaşık değerler üzerinden yapılmıştır.
- Hukuki uyumluluk bölümü genel çerçeve düzeyindedir; resmi danışmanlık yerine geçmez.
- Uygulama çok modüllü olduğu için tüm alt alanlar eşit derinlikte gerçeklenmemiş olabilir; ancak raporda mühendislik modellemesi tam kapsamlı tutulmuştur.

---

## 5. Paydaş Analizi

### 5.1 Birincil Paydaşlar

#### 5.1.1 Evcil Hayvan Sahibi Kullanıcılar

Sistemin ana kullanıcı kitlesidir. Hayvan profili oluşturur, ilan verir, başvuru yapar, veteriner arar, randevu alır, aşı kaydı izler, bakıcı bulur, sipariş verir ve mesajlaşır. Beklentileri:

- Kolay kullanım
- Güvenilir hizmet sağlayıcılar
- Hızlı ve anlaşılır arayüz
- Bildirim desteği
- Veri güvenliği

#### 5.1.2 Veterinerler

Klinik bilgilerini yayınlayan, randevu akışı yöneten ve aşı/sağlık odaklı veri girişleriyle sisteme katılan aktörlerdir. Beklentileri:

- Görünürlük
- Randevu akışının düzenli olması
- Müsaitlik yönetimi
- Yorum ve geri bildirim takibi

#### 5.1.3 Pet Bakıcıları

Hizmet profili oluşturan, uygunluk belirten, rezervasyon alan ve hizmet sürecini yöneten aktörlerdir. Beklentileri:

- Profil üzerinden güven oluşturmaya yardımcı yapı
- Kolay rezervasyon yönetimi
- Takvim ve bildirim desteği
- Hizmet sonrası değerlendirme görünürlüğü

#### 5.1.4 Satıcılar

Mağaza açan, ürün yükleyen, sipariş yöneten ve kampanya/kupon süreçlerini kullanan aktörlerdir. Beklentileri:

- Sipariş izlenebilirliği
- Ürün yönetim kolaylığı
- Temel analiz ekranları
- Operasyonel hata oranının düşük olması

### 5.2 İkincil Paydaşlar

- Platform yöneticileri
- Ders yürütücüsü ve değerlendiriciler
- Potansiyel iş ortakları
- Teknik bakım ekibi
- Yasal otoriteler ve veri sahipleri

### 5.3 Paydaş Beklenti Matrisi

| Paydaş | Ana Beklenti | Başarı Ölçütü |
|---|---|---|
| Son kullanıcı | Tek platformdan çok hizmet | Günlük aktif kullanım ve işlem tamamlama oranı |
| Veteriner | Randevu ve görünürlük | Randevu dönüşüm oranı |
| Bakıcı | Rezervasyon akışı | Kabul edilen rezervasyon oranı |
| Satıcı | Satış ve yönetim kolaylığı | Sipariş işleme süresi |
| Admin | Denetlenebilirlik | Şikayet çözüm süresi |
| Proje ekibi | Yönetilebilir mimari | Bakım kolaylığı ve modülerlik |

---

## 6. Fizibilite Analizi

### 6.1 Teknik Fizibilite

Teknik açıdan proje uygulanabilirdir. Kullanılan teknoloji yığını, bu tür dağıtık ve modüler sistemler için yeterli olgunluğa sahiptir:

- Flutter ile mobil istemci geliştirme
- Node.js + Express ile REST API
- Socket.io ile gerçek zamanlı iletişim
- MongoDB Atlas ile bulut veritabanı
- React/Vite ile yönetim panelleri
- Firebase tabanlı bildirim altyapısı

Repo üzerinde yapılan incelemede, yaklaşık 35 route dosyası, 40 veri modeli ve 20'den fazla mobil özellik alanı bulunduğu görülmüştür. Bu durum, projenin yalnızca teorik bir fikir değil, yaşayan bir mimari etrafında şekillendiğini göstermektedir.

### 6.2 Ekonomik Fizibilite

Akademik ölçekte proje için kullanılabilecek servislerin büyük bölümü ücretsiz veya düşük maliyetli kotalar ile prototip seviyesinde sürdürülebilir durumdadır. Yaklaşık maliyet kalemleri:

- Bulut uygulama sunucusu
- Bulut veritabanı
- Dosya depolama
- Bildirim servisi
- Alan adı ve SSL

Erken aşama için maliyet düşük tutulabilir. Kullanıcı sayısı ve medya içeriği arttıkça depolama ve işlem maliyetleri artacaktır. Bu nedenle ekonomik fizibilite, küçük ve orta ölçek için olumlu; yüksek ölçek için ise kapasite planlaması gerektiren yapıdadır.

### 6.3 Operasyonel Fizibilite

Operasyonel olarak sistem anlamlıdır çünkü farklı kullanıcı türlerinin gerçek hayattaki iş akışlarına doğrudan karşılık vermektedir. Kullanıcıya sunulan değer açık ve somuttur:

- Acil durumda veteriner bulma
- Seyahat döneminde bakıcı ayarlama
- Kaybolan hayvan için hızlı ilan yayınlama
- Ürün ihtiyacını uygulama içinden karşılama

Bu nedenle sistem yalnızca gösterim amaçlı değil, günlük yaşama temas eden bir kullanım alanına sahiptir.

### 6.4 Zaman Fizibilitesi

Tam üretim seviyesi bir platformun tüm modülleriyle geliştirilmesi uzun süreli ekip çalışması gerektirir. Ancak bu ders kapsamındaki beklenti, çalışan ürünün tam ticari olgunluğundan ziyade, yazılım mühendisliği modellemesinin doğruluğudur. Dolayısıyla proje, iteratif geliştirme ve önceliklendirme yöntemiyle teslim takvimine uyarlanabilir.

### 6.5 Hukuki ve Etik Fizibilite

Projede kullanıcı verisi, konum bilgisi, mesaj içeriği ve sağlıkla ilişkili veriler bulunduğundan aşağıdaki konular önemlidir:

- Açık rıza ve aydınlatma metni
- Verinin güvenli saklanması
- Erişim yetkilerinin sınırlandırılması
- Kullanıcı silme veya veri talebi senaryoları
- Topluluk kuralları ve kötüye kullanım denetimi

Bu gereksinimler, sistemin teknik uygulanabilirliğinin yanında etik ve hukuki tasarım ihtiyacını da ortaya koymaktadır.

---

## 7. Proje Organizasyonu ve Yazılım Geliştirme Yaşam Döngüsü

### 7.1 Ekip Yapısı

Ödev bireysel teslim olsa da, proje ders şartlarına uygun olacak biçimde en az 6 kişilik proje organizasyonu ile modellenmiştir:

| Rol | Temel Sorumluluk |
|---|---|
| Proje Yöneticisi / İş Analisti | Kapsam, öncelik, paydaş iletişimi, takvim |
| Sistem Analisti / UML Uzmanı | Gereksinim modeli, use case, sınıf ve etkileşim diyagramları |
| Backend Geliştirici | API, iş kuralları, socket, güvenlik |
| Mobil Geliştirici | Flutter istemci, ekran akışları, servis entegrasyonu |
| Web Panel Geliştiricisi | Admin ve satıcı paneli |
| Veritabanı ve DevOps Uzmanı | Veri modeli, indeks, deploy, loglama |
| Test ve Kalite Uzmanı | Test planı, regresyon, kabul testleri |

### 7.2 Seçilen Süreç Modeli

Proje için saf şelale modeli yerine iteratif-artırımlı bir yaklaşım daha uygundur. Çünkü:

- Modüller bağımsız ama birbirine bağlıdır.
- Kullanıcı geri bildirimiyle yön değişebilir.
- Önce temel akışların çalışması, sonra gelişmiş modüllerin eklenmesi daha doğrudur.
- Mobil, backend ve panel geliştirmesi paralel ilerleyebilir.

Bu nedenle önerilen süreç modeli "faz kontrollü çevik/iteratif" yaklaşımdır.

### 7.3 Yaşam Döngüsü Aşamaları

1. Problem ve ihtiyaç analizi
2. Gereksinim toplama ve modelleme
3. Mimari tasarım
4. Veri modeli tasarımı
5. Arayüz tasarımı
6. Artırımlı gerçekleme
7. Test ve doğrulama
8. Yayınlama
9. İzleme ve bakım

### 7.4 Aşama Bazlı Çıktılar

| Aşama | Çıktı |
|---|---|
| Analiz | Paydaş listesi, gereksinimler, use case listesi |
| Tasarım | UML diyagramları, mimari şema, veri modeli |
| Gerçekleme | Mobil, panel ve backend modülleri |
| Test | Test planı, senaryolar, hata listesi |
| Yayınlama | Bulut dağıtım, ortam değişkenleri, sürümleme |
| Bakım | Log izleme, performans takibi, iyileştirme backlog'u |

### 7.5 Neden Bu Süreç Uygun?

Sosyal akış, veteriner modülü, bakıcı modülü ve mağaza modülü birbirinden farklı problem alanlarıdır. Bu nedenle hepsini baştan tek seferde tam tasarlayıp dondurmak yerine, ortak çekirdek üzerinde aşamalı ilerlemek daha gerçekçidir. Ayrıca dağıtık sistemlerde entegrasyon riskleri erken görülmelidir; bu da iteratif yaklaşımı destekler.

---

## 8. Gereksinim Yönetimi Yaklaşımı

### 8.1 Gereksinim Toplama Kaynakları

Gereksinimler aşağıdaki kaynaklardan türetilmiştir:

- Proje konusu ve alan problemi
- Uygulama içindeki mevcut modüller
- Mobil ekranlar ve panel akışları
- Sunucu tarafı route ve model yapısı
- Son kullanıcı ihtiyaçları
- Admin ve hizmet sağlayıcı bakış açıları
- Ders kapsamında işlenen analiz ve modelleme kavramları

### 8.2 Gereksinim Toplama Yöntemleri

- Senaryo bazlı düşünme
- Aktör bazlı ihtiyaç çıkarma
- Modül incelemesi
- Benzer sistemlerden karşılaştırmalı gözlem
- İş kuralı belirleme

### 8.3 Önceliklendirme İlkesi

Gereksinimler aşağıdaki mantıkla önceliklendirilmiştir:

- `Must`: Sistem çekirdeği için zorunlu
- `Should`: Kullanılabilirlik ve değer için güçlü katkı
- `Could`: Gelecek sürüm veya opsiyonel iyileştirme

### 8.4 Temel Gereksinim Grupları

| Grup | İçerik |
|---|---|
| Kimlik ve erişim | Kayıt, giriş, token, rol |
| Çekirdek pet yönetimi | Pet profili, ilan, başvuru |
| Hizmet modülleri | Veteriner, bakıcı, sağlık |
| Etkileşim | Mesajlaşma, yorum, bildirim |
| Ticaret | Ürün, sepet, sipariş, kupon |
| Yönetim | Admin moderasyon, seller operasyonları |

### 8.5 Gereksinimlerin İzlenebilirliği

Her önemli modül için gereksinim -> kullanım senaryosu -> API/ekran -> test zinciri kurulmalıdır. Bu izlenebilirlik sayesinde:

- Eksik analiz maddeleri kolay görülür.
- Test kapsamı daha doğru hazırlanır.
- Değişiklik geldiğinde etkilenen modüller bulunur.

Detaylı kullanım senaryoları ve kabul ölçütleri bu rapora bağlı ek dosyalarda verilmiştir.

---

## 9. Sistem Genel Tanımı

### 9.1 Ürün Bakış Açısı

Sistem, mobil istemci merkezli çalışan ama web paneller ve bulut servislerle desteklenen dağıtık bir platformdur. Kullanıcılar esas olarak mobil uygulamayı kullanır. Admin ve satıcı tarafı ise web paneller aracılığıyla operasyon yürütür. Tüm istemciler merkezi backend API'ye bağlanır ve ortak veritabanını kullanır.

### 9.2 Bileşenler

- Flutter mobil uygulama
- React/Vite admin paneli
- React/Vite satıcı paneli
- Node.js + Express REST API
- Socket.io gerçek zamanlı iletişim katmanı
- MongoDB Atlas veritabanı
- Push bildirim servisi
- Harita ve konum servisleri

### 9.3 Kullanıcı Rolleri

- Ziyaretçi
- Kayıtlı kullanıcı
- Veteriner
- Pet bakıcısı
- Satıcı
- Admin

### 9.4 Fonksiyonel Modüller

1. Kimlik doğrulama
2. Pet yönetimi
3. Sahiplendirme
4. Eşleştirme
5. Mesajlaşma
6. Veteriner ve randevu
7. Aşı ve sağlık
8. Pet bakıcısı
9. Kayıp/bulunan ilanları
10. Etkinlikler
11. Sosyal akış
12. Mağaza ve sipariş
13. Satıcı yönetimi
14. Admin moderasyonu

---

## 10. Mimari Tasarım

### 10.1 Mimari Yaklaşım

Sistem, istemci-sunucu mimarisine dayalı, modüler ve servis tabanlı bir yapı ile tasarlanmıştır. Temel mimari kararlar şunlardır:

- Mobil ve web istemciler sunucudan ayrıdır.
- Sunucu iş kurallarını merkezi olarak uygular.
- Veritabanı erişimi istemcilerden doğrudan değil sunucu üzerinden yapılır.
- Gerçek zamanlı olaylar socket katmanı ile ele alınır.
- Dış servisler, çekirdek sistemden soyutlanmış servis katmanları üzerinden kullanılır.

### 10.2 Katmanlar

#### Sunum Katmanı
- Flutter mobil ekranları
- Admin panel ekranları
- Satıcı panel ekranları

#### Uygulama / İş Mantığı Katmanı
- Controller'lar
- Servis sınıfları
- Yetkilendirme ve doğrulama akışları
- İş kuralı uygulamaları

#### Veri Erişim Katmanı
- Mongoose modelleri
- Sorgu, indeks, ilişki ve kayıt işlemleri

#### Entegrasyon Katmanı
- Push bildirim servisi
- Google Places veya benzeri servisler
- Dosya yükleme altyapısı

### 10.3 Teknoloji Yığını

| Katman | Teknoloji |
|---|---|
| Mobil istemci | Flutter, Dart |
| Mobil state yönetimi | Riverpod |
| Mobil yönlendirme | GoRouter |
| Mobil ağ katmanı | Dio |
| Web paneller | React, Vite |
| Backend | Node.js, Express |
| Gerçek zamanlı katman | Socket.io |
| Veritabanı | MongoDB Atlas, Mongoose |
| Kimlik doğrulama | JWT, Bcrypt |
| Bildirim | Firebase Cloud Messaging |
| Harita/konum | Google Maps / Places |

### 10.4 Bileşen Sorumlulukları

#### Mobil Uygulama
- Son kullanıcı akışlarını yürütür
- Ekran, form ve liste etkileşimlerini sağlar
- Token saklama ve istemci tarafı durum yönetimini yapar
- Bildirimleri gösterir

#### Admin Paneli
- Kullanıcı, içerik, rapor ve operasyonel görünürlük sağlar
- Moderasyon işlerini merkezileştirir

#### Satıcı Paneli
- Ürün, kupon, sipariş ve mağaza yönetimi sunar

#### Backend API
- Kimlik doğrulama
- Yetkilendirme
- İş kuralları
- Veri bütünlüğü
- Modüller arası tutarlılık

#### Socket Katmanı
- Gerçek zamanlı mesajlaşma
- Canlı konum/servis durumu güncellemeleri
- Olay tabanlı bildirimler

### 10.5 Dağıtım Mimarisi

Sistemin önerilen dağıtım topolojisi aşağıdaki diyagram dosyasında gösterilmiştir:

- [deployment_diagram.puml](./deployment_diagram.puml)

Bu topoloji; mobil istemci, web panelleri, backend uygulama sunucusu, socket katmanı, bulut veritabanı ve dış servisleri birbirinden ayrılmış ama koordineli bileşenler halinde göstermektedir.

### 10.6 Mimarinin Güçlü Yönleri

- Modüler genişlemeye uygundur.
- Mobil ve panel tarafı bağımsız geliştirilebilir.
- Gerçek zamanlı iletişim için ayrı mekanizma kullanır.
- Bulut veritabanı ile merkezi veri yönetimi sağlar.
- Kimlik doğrulama tek merkezden yürütülür.

### 10.7 Mimarinin Zayıf Yönleri ve Dikkat Noktaları

- Çok modüllü yapı operasyonel karmaşıklık yaratabilir.
- Bildirim, socket ve konum entegrasyonları hata ayıklamayı zorlaştırabilir.
- Dosya yükleme ve medya yönetimi büyüdükçe maliyet artar.
- Yetkilendirme kuralları doğru kurgulanmazsa güvenlik açığı doğabilir.

---

## 11. Veritabanı Tasarımı ve Veri Yönetimi

### 11.1 Veritabanı Yaklaşımı

Projede belge tabanlı veritabanı yaklaşımı tercih edilmiştir. Bunun temel nedenleri:

- Modüller arası veri yapılarının esnek olması
- Bazı alanların opsiyonel veya değişken nitelikte bulunması
- Hızlı prototipleme ve iteratif geliştirme ihtiyacı
- Konum temelli sorgular için uygun modelleme imkânı

### 11.2 Temel Varlıklar

Öne çıkan temel veri varlıkları şunlardır:

- User
- Pet
- Veterinary
- Appointment
- VaccinationRecord
- HealthRecord
- PetSitter
- SitterBooking
- Store
- Product
- Order
- Conversation
- Message
- AdoptionApplication
- LostFoundPet
- Post
- Coupon
- Review
- Favorite
- AuditLog

### 11.3 Temel İlişkiler

- Bir kullanıcı birden fazla pet profiline sahip olabilir.
- Bir kullanıcı birden fazla sipariş verebilir.
- Bir veteriner birden fazla randevuya sahip olabilir.
- Bir pet birden fazla aşı ve sağlık kaydına sahip olabilir.
- Bir bakıcı birden fazla rezervasyon alabilir.
- Bir mağaza birden fazla ürün içerebilir.
- Bir konuşma birden fazla mesaj içerir.

### 11.4 Veri Bütünlüğü İlkeleri

1. Kimlikler sunucu tarafından üretilir.
2. Yetkisiz kullanıcı başkasına ait verilere erişemez.
3. Kritik durum değişiklikleri kayıt altına alınır.
4. Sipariş, rezervasyon ve başvuru gibi işlemler durum makinesi mantığı ile yönetilir.
5. Silme işlemlerinde veri kaybı ve referans bozulmaları dikkate alınır.

### 11.5 İndeksleme ve Performans

Özellikle aşağıdaki alanlarda indeksleme önemlidir:

- E-posta ve kullanıcı erişim alanları
- Randevu tarih-saat alanları
- Sipariş numarası
- Mesajlaşma konuşma kimlikleri
- Konum tabanlı aramalar için `2dsphere` indeksleri

Coğrafi sorguların yoğun olduğu modüllerde doğru indeks seçimi kullanıcı deneyimi açısından kritik önemdedir. Yakın veteriner, yakın bakıcı ve yakın kayıp ilanı akışları bu nedenle tasarımın erken aşamasında düşünülmüştür.

### 11.6 Veri Yaşam Döngüsü

Veri yaşam döngüsü aşağıdaki gibi özetlenebilir:

1. Kullanıcı veya sistem veri oluşturur.
2. Veri doğrulama ve iş kuralı kontrolünden geçer.
3. Veritabanına kaydedilir.
4. İlgili olaylar bildirim, socket veya log katmanına yansır.
5. Veri güncellenir, arşivlenir veya gerekli ise yumuşak silme ile işaretlenir.

### 11.7 Denetim ve Loglama

Moderasyon ve operasyonel izlenebilirlik için audit log yaklaşımı önemlidir. Özellikle şu işlemlerde kayıt tutulmalıdır:

- Admin müdahaleleri
- Rol değişiklikleri
- Kritik sipariş ve rezervasyon durum güncellemeleri
- Kural dışı erişim denemeleri
- Giriş başarısızlıkları ve güvenlik olayları

---

## 12. Arayüz ve Kullanıcı Deneyimi Tasarımı

### 12.1 Tasarım İlkeleri

Sistem çok modüllü olduğundan, arayüz tasarımında tutarlılık temel ilkedir. Kullanıcı veteriner, mağaza, mesajlaşma ve bakım gibi çok farklı alanlarda gezinirken tamamen farklı uygulamalardaymış hissine kapılmamalıdır. Bu nedenle:

- Tek tip bileşen dili
- Tutarlı renk sistemi
- Anlaşılır ikonografi
- Hızlı erişim sağlayan gezinme kurgusu
- Boş durum, hata durumu ve yüklenme durumlarının standartlaşması

önceliklendirilmiştir.

### 12.2 Mobil Deneyim

Mobil uygulama son kullanıcı sistemidir. Bu nedenle aşağıdaki noktalar kritik kabul edilmiştir:

- Tek elle kullanım kolaylığı
- Harita ve liste ekranlarında akıcı deneyim
- Formlarda sade veri girişi
- Bildirimlerden ilgili ekrana doğrudan geçiş
- Düşük ağ kalitesinde kabul edilebilir davranış

### 12.3 Panel Deneyimi

Admin ve satıcı paneli daha çok tablo, filtre, operasyonel liste ve analiz odaklıdır. Bu nedenle mobil uygulamadan farklı olarak:

- Daha yoğun veri görünümü
- Filtreleme ve sıralama araçları
- Çok sütunlu yerleşim
- Yönetim odaklı işlem butonları

tasarlanmalıdır.

### 12.4 Erişilebilirlik ve Yerelleştirme

Sistem farklı yaş ve teknik yeterlilikte kullanıcılar tarafından kullanılabileceğinden aşağıdaki ilkeler önerilmiştir:

- Yeterli kontrast
- Anlaşılır metinler
- Durum mesajlarının açık olması
- Türkçe ve İngilizce dil desteği
- Tarih, para birimi ve bildirim metinlerinin yerelleştirilebilir olması

---

## 13. Güvenlik, Gizlilik ve Yetkilendirme

### 13.1 Güvenlik Hedefleri

1. Yalnızca doğrulanmış kullanıcılar korumalı kaynaklara erişebilmelidir.
2. Rol bazlı yetkilendirme uygulanmalıdır.
3. Hassas bilgiler düz metin halinde saklanmamalıdır.
4. Kötüye kullanım, istek suistimali ve kaba kuvvet denemeleri sınırlandırılmalıdır.
5. Kullanıcı verisi aktarım sırasında korunmalıdır.

### 13.2 Kimlik Doğrulama

Sistemde JWT tabanlı oturum yönetimi yaklaşımı kullanılmaktadır. Temel mantık:

- Kullanıcı giriş yapar
- Sunucu kimlik bilgilerini doğrular
- Token üretir
- İstemci token saklar
- Korumalı isteklerde token gönderilir

### 13.3 Yetkilendirme

Rol bazlı yetkilendirme aşağıdaki ayrımı desteklemelidir:

- Standart kullanıcı
- Satıcı
- Veteriner
- Admin

Her rolün erişebileceği kaynaklar ve yapabileceği işlemler açıkça sınırlandırılmalıdır.

### 13.4 Girdi Doğrulama ve Saldırı Yüzeyi Azaltma

Projede önerilen temel korumalar:

- Girdi doğrulama
- Rate limiting
- NoSQL injection koruması
- Yetkisiz erişim kontrolleri
- Dosya yüklemede tür ve boyut kısıtı
- Log izleme

### 13.5 Gizlilik

Toplanan veri türleri:

- Kimlik ve hesap verileri
- Konum verileri
- Mesaj içerikleri
- Sipariş ve adres verileri
- Sağlık/aşı bilgileri
- Yorumlar ve etkileşim verileri

Bu nedenle veri minimizasyonu, amaç sınırlılığı ve erişim kayıtlarının tutulması önemlidir.

---

## 14. Performans, Ölçeklenebilirlik ve Operasyon

### 14.1 Performans Hedefleri

Sistemin kabul edilebilir kullanıcı deneyimi sunabilmesi için aşağıdaki hedefler belirlenmiştir:

- Temel API çağrılarında düşük gecikme
- Liste ekranlarında sayfalama veya kademeli yükleme
- Bildirimlerin makul sürede iletilmesi
- Mesajlaşmada düşük gecikme

### 14.2 Ölçeklenebilirlik Yaklaşımı

İlk aşamada tek backend servisi ile başlanabilir; ancak büyüme halinde aşağıdaki alanlar ayrıştırılabilir:

- Medya yükleme servisi
- Bildirim işleyici
- Arka plan görevleri
- Analitik ve raporlama

### 14.3 Arka Plan İşleri

Aşı hatırlatma, doğum günü hatırlatma, ilan süresi kontrolü veya rezervasyon hatırlatmaları gibi işler eşzamansız görev mantığı ile ele alınmalıdır.

### 14.4 Operasyonel İzleme

Operasyon sırasında izlenmesi önerilen göstergeler:

- Başarısız giriş oranı
- API hata oranı
- Ortalama yanıt süresi
- Bildirim başarısı
- Socket bağlantı sayısı
- Randevu ve sipariş dönüşüm oranları

---

## 15. Bakım, İzleme ve Sürdürülebilirlik

### 15.1 Bakım Türleri

- Düzeltici bakım
- Uyarlayıcı bakım
- İyileştirici bakım
- Önleyici bakım

### 15.2 Sürüm Yönetimi

Sistemde aşağıdaki sürümleme yaklaşımı önerilir:

- Mobil istemci sürümleri
- Backend sürümleri
- Panel sürümleri
- Veritabanı şema değişiklik notları

### 15.3 Dokümantasyonun Önemi

Bu proje çok modüllü olduğundan, sözlü bilgiye dayalı geliştirme sürdürülemez. Bu nedenle:

- API sözleşmeleri
- UML diyagramları
- Test planları
- Rol matrisi
- Risk listesi
- Değişiklik kayıtları

gibi belgeler sistemin sürdürülebilirliğini doğrudan etkiler.

### 15.4 Gelecek Geliştirme Alanları

- Gerçek ödeme entegrasyonu
- Gelişmiş arama ve öneri sistemi
- Daha güçlü raporlama panelleri
- Makine öğrenmesi destekli öneriler
- Çoklu şehir ve çoklu ülke desteği
- Gelişmiş moderasyon otomasyonu

---

## 16. Sonuç

Bu proje, Yazılım Mühendisliği final ödevi için uygun olmanın ötesinde, kapsamlı bir analiz ve modelleme çalışmasına elverişli güçlü bir örnektir. Çünkü proje tek sayfalık veya mikro ölçekli bir uygulama değildir; farklı kullanıcı tiplerine, dağıtık mimariye, veritabanı yoğun süreçlere, mobil istemciye, gerçek zamanlı iletişime ve operasyonel panellere sahip bütünleşik bir platformdur.

Ders yönergesi açısından bakıldığında proje şu şartları sağlamaktadır:

- Yazılım projesidir.
- Dağıtık sistem niteliğindedir.
- İnternet/bulut üzerinde çalışabilir yapıdadır.
- Veritabanı işlemlerini yoğun biçimde içerir.
- Mobil uygulama ayağı vardır.
- En az 6 kişilik ekip modeli ile ele alınabilir.
- Gereksinim, kullanım senaryosu ve UML modellemesine uygundur.

Ancak bu tür bir projede başarıyı belirleyen şey yalnızca modül sayısı değildir. Asıl belirleyici unsur, bu modüllerin yazılım mühendisliği disiplini ile ifade edilmesidir. Bu nedenle bu rapor; proje fikrini tanıtan yüzeysel bir metin üretmek yerine, projeyi problem tanımı, fizibilite, paydaş, gereksinim, süreç, mimari, veri tasarımı, güvenlik, operasyon ve bakım boyutlarıyla ele alan mühendislik odaklı bir çerçeve sunmuştur.

Detaylı kullanım senaryoları, test senaryoları, risk planları, backlog yapısı ve kabul ölçütleri ile desteklendiğinde bu rapor tek başına değil, bir bütün teslim paketi olarak değerlendirilebilir. Böylece proje; "uygulama var" düzeyinden çıkıp "analiz edilmiş, modellenmiş, planlanmış ve dokümante edilmiş yazılım sistemi" düzeyine taşınmış olur.

---

## 17. Kaynaklar

1. Flutter Resmi Dokümantasyonu
2. Dart Dil Dokümantasyonu
3. Node.js Resmi Dokümantasyonu
4. Express.js Resmi Dokümantasyonu
5. MongoDB ve MongoDB Atlas Dokümantasyonu
6. Mongoose Dokümantasyonu
7. Socket.io Dokümantasyonu
8. JWT ve modern kimlik doğrulama kaynakları
9. Firebase Cloud Messaging dokümantasyonu
10. Google Maps / Places API dokümantasyonu
11. Yazılım Mühendisliği ders notları
12. UML ve nesneye dayalı analiz/tasarım kaynakları

> İstersen bu kaynak bölümünü APA/IEEE formatına da çevirebilirim.

---

## 18. Word'e Taşıma Notları

Bu ana raporu Word ortamında teslim dosyasına dönüştürürken aşağıdaki yapı önerilir:

1. Kapak sayfası
2. İç kapak
3. Özet
4. Abstract
5. İçindekiler
6. Şekiller listesi
7. Tablolar listesi
8. Ana rapor
9. Kullanım senaryoları eki
10. Test, risk ve plan ekleri
11. UML diyagramları
12. Ekran görüntüleri

Bu sıra kullanıldığında ve her modül için 1-2 ekran görüntüsü ile diyagramlar eklendiğinde, rapor rahatlıkla geniş hacimli bir teslim dosyasına dönüşür.
