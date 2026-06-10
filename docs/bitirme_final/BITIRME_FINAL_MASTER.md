# T.C. KONYA TEKNIK UNIVERSITESI
## BILGISAYAR MUHENDISLIGI BOLUMU
## BITIRME PROJESI FINAL RAPORU

| Alan | Bilgi |
|---|---|
| Proje Adi | EvcilHayvan Platformu |
| Ogrenci Adi Soyadi | [AD SOYAD] |
| Ogrenci Numarasi | [NUMARA] |
| Danisman / Ders Yurutucusu | [DANISMAN ADI] |
| Teslim Tarihi | [TARIH] |

# On Bilgi

Bu master belge, projede bulunan final rapor paketi, ara rapor kaynaklari, teknik denetim notlari ve son tamamlanan gelistirmeler birlestirilerek hazirlanmistir.

## Guncel Tamamlama Notu - 09.06.2026

Bu bolum, rapor paketinin ilk hazirlanmasindan sonra tamamlanan ve bitirme final raporuna eklenmesi gereken son proje gelistirmelerini ozetler.

### Veteriner Modulu Son Durum

- Veteriner arama ekranina tur ve hizmet filtresi eklendi.
- Backend listeleme sorgulari `species` ve `service` parametrelerini destekleyecek sekilde guncellendi.
- Randevu detay ekranina yeniden planlama arayuzu eklendi.
- Randevu yeniden planlama akisi backend `PATCH /api/appointments/:id/reschedule` endpoint'i ile baglandi.
- Online randevular icin sahte `meet.google.com/...` linki otomatik uretimi kaldirildi.
- Veteriner, online randevuyu onaylarken gercek gorusme linki girebilecek hale getirildi.
- Giris yapmadan veteriner mesajlasmasina gidildiginde, login sonrasi ilgili veteriner detayina geri donus akisi duzeltildi.

### Bakici Modulu Son Durum

- Bakici profil fotografi yuklemek icin backend `POST /api/pet-sitters/:id/avatar` endpoint'i eklendi.
- Flutter bakici profil olusturma/duzenleme akisi avatar yukleme endpoint'ine baglandi.
- Bakici finansal ozet ekrani dashboard uzerinden erisilebilir hale getirildi.
- Bakici rezervasyon ekraninda calisma saatleri gosterildi.
- Calisma saatleri disinda rezervasyon olusturma mobil arayuzde engellendi.
- Bakici yorumlarinda ayni kullanicinin ayni bakiciya birden fazla yorum yazmasi backend tarafinda engellendi.
- Bakim raporu fotograf yukleme ve canli konum takip akislarinin backend ve mobil baglantilari kontrol edildi.

### Dogrulama ve Kurulum Sonuclari

- Backend Jest testleri calistirildi: 2 test suite ve 10 test basarili.
- Flutter widget testleri calistirildi: bakici finansal ozet, bakim raporu detayi ve veteriner kazanc ekranlari basarili.
- Android debug APK basariyla derlendi.
- Dogru mobil proje uzerinden uretilen APK fiziksel Android cihaza ADB ile yeniden kuruldu.
- `flutter analyze` komutu Flutter analyzer internal crash verdigi icin sonuc uretmedi; buna karsin build ve testler basarili tamamlandi.

### Kalan Not

Gercek Google Meet linkinin otomatik uretilmesi icin Google Calendar/Meet OAuth entegrasyonu gerekir. Mevcut uygulamada sahte link uretilmemekte, veteriner tarafindan girilen gercek link saklanmaktadir.

## Onceki Rapor Kaynaklari ve Birlesim Notu

Projede daha once hazirlanan `RAPOR.md`, `BITIRME_RAPORU.md`, `BITIRME_RAPORU.txt` ve `docs/bitirme2_ara_rapor_guncel.md` dosyalari incelenmistir. Bu belgeler proje gecmisi, ara rapor anlatimi, okul form sablonu ve ekran goruntusu yer tutuculari acisindan kaynak olarak kullanilabilir. Ancak final raporda tekrar olusmamasi icin ana govde `docs/yazilim_muh_final/` klasorundeki kapsamli final paketinden uretilmistir.

Eski raporlarin final belgeye kattigi ana bilgiler sunlardir:

- Bitirme-1 ve Bitirme-2 surecinde proje kapsamının nasil genisledigi.
- Canli sunucu, MongoDB Atlas, mobil uygulama, admin paneli ve satici paneli gibi katmanlarin proje boyunca olgunlasmasi.
- Veteriner, bakici, magaza, sosyal akis, kayip/bulunan, sahiplendirme, mesajlasma ve bildirim modullerinin donemsel gelisim ozeti.
- Rapor icin kullanilabilecek ekran goruntusu basliklari.

Bu nedenle eski raporlar ek kaynak olarak saklanmis, final raporun ana akisi ise tek ve tutarli bir akademik rapor duzeninde yeniden toparlanmistir.

## Sekil ve Diyagram Kaynaklari

Final rapor paketinde Word'e veya postere eklenebilecek hazir gorsel kaynaklar bulunmaktadir.

### Diyagram SVG Ciktilari

- `docs/yazilim_muh_final/rendered/diagrams/`: 25 adet UML ve sistem diyagrami.
- Oncelikli diyagramlar: use case, context, data flow, deployment, component, class, MongoDB view, veteriner randevu sequence, siparis sequence, bakici booking activity ve durum diyagramlari.

### Grafik SVG Ciktilari

- `docs/yazilim_muh_final/rendered/charts/`: 5 adet grafik.
- Grafikler: maliyet dagilimi, rol bazli is gucu, faz sureleri, modul kapsam yogunlugu ve proje Gantt plani.

### Ekran Goruntusu Adaylari

- Kok dizindeki `adb_*.png` ve `store_*.png` dosyalari magaza ve mobil dogrulama ekranlari icin adaydir.
- Final Word duzenlemesinde ekran goruntuleri secilerek ilgili modul bolumlerine yerlestirilmelidir.

# 01 Ana Rapor

### Özet

Evcil hayvan sahipleri, günlük yaşamlarında birden fazla dijital hizmete aynı anda ihtiyaç duymaktadır. Sahiplendirme ilanı verme, veteriner bulma, randevu alma, aşı geçmişini izleme, pet bakıcısı bulma, kayıp hayvan duyurusu paylaşma, sosyal etkileşim kurma ve pet ürünleri satın alma gibi süreçler günümüzde çoğunlukla birbirinden kopuk uygulamalar üzerinden yürütülmektedir. Bu durum kullanıcı deneyimini parçalamakta, veri tekrarına neden olmakta ve güven sorunlarını artırmaktadır.

Bu proje, söz konusu ihtiyacı tek platform altında birleştiren, mobil uygulama merkezli fakat web panel ve bulut servislerle desteklenen dağıtık bir yazılım sistemi olarak ele alınmıştır. Sistem; Flutter tabanlı mobil istemci, React tabanlı yönetim panelleri, Node.js + Express tabanlı REST API sunucusu, Socket.io tabanlı gerçek zamanlı iletişim katmanı ve MongoDB Atlas tabanlı bulut veritabanı bileşenlerinden oluşmaktadır. Sistem yalnızca bir sosyal uygulama ya da yalnızca bir e-ticaret uygulaması değildir; bunun yerine, evcil hayvan ekosisteminin farklı aktörlerini ortak veri modeli altında buluşturan çok modüllü bir dijital platform olarak kurgulanmıştır.

Raporun temel amacı, mevcut proje fikrini ve yaşayan uygulama kapsamını Yazılım Geliştirme Yaşam Döngüsü yaklaşımıyla analiz etmek, gereksinimleri modellemek, kullanım senaryolarını sözleşme biçiminde ifade etmek, mimari ve veri tasarımını açıklamak, güvenlik ve kalite boyutlarını tanımlamak ve projeyi dersin mühendislik odaklı beklentileri doğrultusunda bütünlüklü bir dokümantasyona dönüştürmektir.

Bu kapsamda raporda; problem tanımı, hedefler, kapsam ve kapsam dışı maddeler, paydaş analizi, fizibilite değerlendirmesi, işlevsel ve işlevsel olmayan gereksinimler, proje ekibi ve rol dağılımı, süreç modeli, mimari tasarım, veritabanı yapısı, test yaklaşımı, risk yönetimi, güvenlik önlemleri ve bakım stratejileri ele alınmıştır. Detaylı kullanım senaryoları, kabul ölçütleri, örnek test vakaları ve proje planlama ekleri ayrı dosyalarda desteklenmiştir.

---

### Abstract

Pet owners need multiple digital services in their daily lives, such as adoption listing, veterinary discovery, appointment scheduling, vaccination tracking, pet sitter booking, lost-and-found announcements, social interaction, and online shopping for pet products. These needs are usually handled through disconnected systems, which creates fragmented user experience, repeated data entry, and operational inefficiency.

This project proposes a distributed cloud-based software platform that unifies these services under a single ecosystem. The system is centered around a Flutter mobile client and supported by web panels, a Node.js + Express backend, a Socket.io real-time communication layer, and a MongoDB Atlas cloud database. Rather than functioning as only a social application or only an e-commerce application, the platform is designed as a multi-module digital environment for the broader pet-care domain.

The purpose of this report is to analyze the project in accordance with Software Development Life Cycle principles, model the requirements, define use cases, explain the architecture and database design, identify risks and quality objectives, and transform the project idea into a comprehensive engineering-oriented final report. Detailed use case contracts, testing artifacts, and planning appendices are provided in separate companion documents.

---

### İçindekiler Taslağı

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

### 1. Giriş

Yazılım mühendisliği yalnızca çalışan bir uygulama üretmekten ibaret değildir. Bir projenin başarılı sayılabilmesi için problemin doğru tanımlanması, gereksinimlerin sistematik şekilde çıkarılması, çözümün uygun mimari ile modellenmesi, kalite hedeflerinin belirlenmesi, risklerin önceden düşünülmesi ve tüm sürecin izlenebilir hale getirilmesi gerekir. Özellikle dağıtık sistemlerin söz konusu olduğu projelerde yalnızca arayüz üretmek ya da birkaç API geliştirmek yeterli değildir; istemci, sunucu, veri depolama, gerçek zamanlı iletişim, dış servisler, yetkilendirme ve operasyon boyutlarının birlikte ele alınması gerekir.

Bu raporda incelenen proje, evcil hayvan ekosistemine yönelik çok yönlü bir dijital platformdur. Projede mobil istemci, admin paneli, satıcı paneli, backend API, gerçek zamanlı mesajlaşma sunucusu ve bulut veritabanı birlikte düşünülmektedir. Bu nedenle proje, ders yönergesinde özellikle vurgulanan "dağıtık sistem", "veritabanı işlemleri", "mobil uygulama ayağı", "internet/bulut üzerinde çalışma" ve "kapsamlı modelleme" gereksinimlerini karşılayabilecek niteliktedir.

Projenin alanı ilk bakışta geniş görünebilir; ancak bu genişlik aslında yazılım mühendisliği final projesi için avantajdır. Çünkü kapsamlı bir final ödevi, farklı aktörlere sahip, birden fazla alt modülü olan, veri akışı ve iş kuralları içeren, mimari kararlar gerektiren ve ayrıntılı dokümantasyona imkân veren bir sistem üzerinden daha güçlü biçimde sunulabilir. Bu raporun yaklaşımı da tam olarak budur: çalışan modülleri "özellik listesi" gibi sıralamak yerine, bunları analitik ve model temelli bir yazılım mühendisliği çalışmasına dönüştürmek.

---

### 2. Problem Tanımı ve İhtiyaç Analizi

#### 2.1 Problemin Tanımı

Evcil hayvan sahipleri çoğu zaman farklı işlevler için farklı uygulamalar kullanmak zorunda kalmaktadır. Bir platform sahiplendirme için uygunken veteriner randevusu için yetersiz kalmakta, başka bir uygulama mağaza tarafını desteklerken sosyal etkileşimi içermemekte, bir başkası ise bakım veya kayıp ilanı senaryolarını sunmamaktadır. Bu parçalı yapı aşağıdaki problemlere yol açmaktadır:

- Kullanıcı aynı bilgileri birden fazla sisteme tekrar tekrar girmek zorunda kalmaktadır.
- Platformlar arası veri bütünlüğü bulunmamaktadır.
- Güvenilir bakıcı, satıcı veya veteriner bulma süreci zorlaşmaktadır.
- İletişim süreçleri dağınık hale gelmektedir.
- Kullanıcının hayvanı ile ilgili yaşam döngüsü bilgisi tek yerde toplanamamaktadır.
- Hizmet sağlayıcılar ve son kullanıcılar arasında merkezi bir güven mekanizması oluşmamaktadır.

#### 2.2 Problemin Neden Önemli Olduğu

Evcil hayvan sahipliği, yalnızca sosyal paylaşım ya da alışverişten ibaret değildir. Bu alan; sağlık takibi, bakım, zaman yönetimi, acil durumlar, maddi harcamalar, güven ilişkisi ve topluluk etkileşimi gibi çok boyutlu süreçler içerir. Dolayısıyla bu alanı destekleyen dijital çözümün de çok modüllü olması beklenir. Ayrıca:

- Veteriner, bakıcı ve satıcı gibi farklı aktörler sisteme dahil olmaktadır.
- Mobil kullanım ön plandadır; kullanıcı hizmete yolda, evde, klinikte veya açık alanda ihtiyaç duyabilir.
- Konum tabanlı kararlar önemlidir; yakın veteriner, yakın bakıcı, yakın kayıp ilanı gibi.
- Gerçek zamanlı iletişim önemlidir; mesajlaşma, bildirimler, rezervasyon güncellemeleri.
- Güvenlik ve mahremiyet kritiktir; kullanıcı verisi, adres bilgisi, sağlık verisi, sipariş geçmişi gibi alanlar korunmalıdır.

#### 2.3 Mevcut Yaklaşımların Eksikleri

Piyasadaki çoğu çözüm aşağıdaki sınırlardan birine sahiptir:

- Yalnızca ilan odaklıdır, işlem veya hizmet takibi sunmaz.
- Yalnızca e-ticaret odaklıdır, sosyal veya sağlık modülleri içermez.
- Yerel/kapalı bir kullanıcı kitlesiyle sınırlıdır.
- Mobil deneyimi zayıftır.
- Gerçek zamanlı iletişim veya bildirim desteği bulunmaz.
- Yönetim paneli ve denetim mekanizmaları yetersizdir.

Bu eksikler, tekil modüller yerine platform yaklaşımının gerekliliğini göstermektedir.

---

### 3. Projenin Amacı, Hedefleri ve Katkısı

#### 3.1 Ana Amaç

Evcil hayvan sahipleri, veterinerler, pet bakıcıları, satıcılar ve yöneticiler için ortak dijital platform oluşturarak, farklı hizmetleri tek bir mobil ve bulut tabanlı sistem altında birleştirmek.

#### 3.2 Alt Hedefler

1. Kullanıcının tüm evcil hayvan verilerini merkezi biçimde yönetebilmesini sağlamak.
2. Sahiplendirme ve eşleştirme süreçlerini dijitalleştirmek.
3. Veteriner arama, randevu ve aşı takibi süreçlerini mobil üzerinden erişilebilir kılmak.
4. Pet bakıcı rezervasyon akışını ve hizmet takibini desteklemek.
5. Gerçek zamanlı mesajlaşma ile kullanıcılar arası iletişimi hızlandırmak.
6. Mağaza, ürün, sepet ve sipariş süreçlerini tek platformda sunmak.
7. Yönetim ve moderasyon araçları ile platform güvenilirliğini artırmak.
8. Bulut tabanlı mimari ile çok kullanıcılı ve internet üzerinden erişilebilir bir yapı kurmak.

#### 3.3 Projenin Katkısı

Bu projenin katkısı yalnızca farklı özellikleri yan yana getirmesi değildir. Daha önemli katkı, bu özellikleri aynı veri modeli, aynı kullanıcı hesabı, aynı bildirim altyapısı ve aynı operasyon mantığı altında birleştirmesidir. Böylece:

- Kullanıcı tek hesapla çok hizmete erişir.
- Veri tekrarının ve dağınıklığın önüne geçilir.
- Güvenilirlik ve izlenebilirlik artar.
- Hizmet sağlayıcılar için merkezi görünürlük oluşur.
- Platform büyüdükçe yeni modüller mevcut mimariyi bozmadan eklenebilir.

---

### 4. Kapsam, Kapsam Dışı Maddeler, Varsayımlar ve Kısıtlar

#### 4.1 Kapsam

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

#### 4.2 Kapsam Dışı

- Gerçek banka veya ödeme kuruluşu entegrasyonu
- Donanım sensör entegrasyonları
- Web istemci üzerinden tam son kullanıcı deneyimi
- Çok ülkelili vergi/fatura mevzuatı uyarlamaları
- Çağrı merkezi entegrasyonu

#### 4.3 Varsayımlar

1. Kullanıcıların akıllı telefon ve internet erişimine sahip olduğu varsayılmıştır.
2. Konum tabanlı işlemler için cihaz izinlerinin verilmesi beklenmiştir.
3. Bildirim servisi olarak FCM benzeri altyapının erişilebilir olduğu kabul edilmiştir.
4. Admin ve satıcı panellerinin masaüstü veya geniş ekran cihazlarda kullanılacağı varsayılmıştır.
5. Sistem ilk aşamada orta ölçekli kullanıcı yükü için planlanmıştır.

#### 4.4 Kısıtlar

- Proje akademik kapsamda modellenmektedir; üretim ortamındaki tüm operasyonel yükler birebir ele alınmamıştır.
- Tam ölçekli canlı operasyon maliyet analizi yaklaşık değerler üzerinden yapılmıştır.
- Hukuki uyumluluk bölümü genel çerçeve düzeyindedir; resmi danışmanlık yerine geçmez.
- Uygulama çok modüllü olduğu için tüm alt alanlar eşit derinlikte gerçeklenmemiş olabilir; ancak raporda mühendislik modellemesi tam kapsamlı tutulmuştur.

---

### 5. Paydaş Analizi

#### 5.1 Birincil Paydaşlar

##### 5.1.1 Evcil Hayvan Sahibi Kullanıcılar

Sistemin ana kullanıcı kitlesidir. Hayvan profili oluşturur, ilan verir, başvuru yapar, veteriner arar, randevu alır, aşı kaydı izler, bakıcı bulur, sipariş verir ve mesajlaşır. Beklentileri:

- Kolay kullanım
- Güvenilir hizmet sağlayıcılar
- Hızlı ve anlaşılır arayüz
- Bildirim desteği
- Veri güvenliği

##### 5.1.2 Veterinerler

Klinik bilgilerini yayınlayan, randevu akışı yöneten ve aşı/sağlık odaklı veri girişleriyle sisteme katılan aktörlerdir. Beklentileri:

- Görünürlük
- Randevu akışının düzenli olması
- Müsaitlik yönetimi
- Yorum ve geri bildirim takibi

##### 5.1.3 Pet Bakıcıları

Hizmet profili oluşturan, uygunluk belirten, rezervasyon alan ve hizmet sürecini yöneten aktörlerdir. Beklentileri:

- Profil üzerinden güven oluşturmaya yardımcı yapı
- Kolay rezervasyon yönetimi
- Takvim ve bildirim desteği
- Hizmet sonrası değerlendirme görünürlüğü

##### 5.1.4 Satıcılar

Mağaza açan, ürün yükleyen, sipariş yöneten ve kampanya/kupon süreçlerini kullanan aktörlerdir. Beklentileri:

- Sipariş izlenebilirliği
- Ürün yönetim kolaylığı
- Temel analiz ekranları
- Operasyonel hata oranının düşük olması

#### 5.2 İkincil Paydaşlar

- Platform yöneticileri
- Ders yürütücüsü ve değerlendiriciler
- Potansiyel iş ortakları
- Teknik bakım ekibi
- Yasal otoriteler ve veri sahipleri

#### 5.3 Paydaş Beklenti Matrisi

| Paydaş | Ana Beklenti | Başarı Ölçütü |
|---|---|---|
| Son kullanıcı | Tek platformdan çok hizmet | Günlük aktif kullanım ve işlem tamamlama oranı |
| Veteriner | Randevu ve görünürlük | Randevu dönüşüm oranı |
| Bakıcı | Rezervasyon akışı | Kabul edilen rezervasyon oranı |
| Satıcı | Satış ve yönetim kolaylığı | Sipariş işleme süresi |
| Admin | Denetlenebilirlik | Şikayet çözüm süresi |
| Proje ekibi | Yönetilebilir mimari | Bakım kolaylığı ve modülerlik |

---

### 6. Fizibilite Analizi

#### 6.1 Teknik Fizibilite

Teknik açıdan proje uygulanabilirdir. Kullanılan teknoloji yığını, bu tür dağıtık ve modüler sistemler için yeterli olgunluğa sahiptir:

- Flutter ile mobil istemci geliştirme
- Node.js + Express ile REST API
- Socket.io ile gerçek zamanlı iletişim
- MongoDB Atlas ile bulut veritabanı
- React/Vite ile yönetim panelleri
- Firebase tabanlı bildirim altyapısı

Repo üzerinde yapılan incelemede, yaklaşık 35 route dosyası, 40 veri modeli ve 20'den fazla mobil özellik alanı bulunduğu görülmüştür. Bu durum, projenin yalnızca teorik bir fikir değil, yaşayan bir mimari etrafında şekillendiğini göstermektedir.

#### 6.2 Ekonomik Fizibilite

Akademik ölçekte proje için kullanılabilecek servislerin büyük bölümü ücretsiz veya düşük maliyetli kotalar ile prototip seviyesinde sürdürülebilir durumdadır. Yaklaşık maliyet kalemleri:

- Bulut uygulama sunucusu
- Bulut veritabanı
- Dosya depolama
- Bildirim servisi
- Alan adı ve SSL

Erken aşama için maliyet düşük tutulabilir. Kullanıcı sayısı ve medya içeriği arttıkça depolama ve işlem maliyetleri artacaktır. Bu nedenle ekonomik fizibilite, küçük ve orta ölçek için olumlu; yüksek ölçek için ise kapasite planlaması gerektiren yapıdadır.

#### 6.3 Operasyonel Fizibilite

Operasyonel olarak sistem anlamlıdır çünkü farklı kullanıcı türlerinin gerçek hayattaki iş akışlarına doğrudan karşılık vermektedir. Kullanıcıya sunulan değer açık ve somuttur:

- Acil durumda veteriner bulma
- Seyahat döneminde bakıcı ayarlama
- Kaybolan hayvan için hızlı ilan yayınlama
- Ürün ihtiyacını uygulama içinden karşılama

Bu nedenle sistem yalnızca gösterim amaçlı değil, günlük yaşama temas eden bir kullanım alanına sahiptir.

#### 6.4 Zaman Fizibilitesi

Tam üretim seviyesi bir platformun tüm modülleriyle geliştirilmesi uzun süreli ekip çalışması gerektirir. Ancak bu ders kapsamındaki beklenti, çalışan ürünün tam ticari olgunluğundan ziyade, yazılım mühendisliği modellemesinin doğruluğudur. Dolayısıyla proje, iteratif geliştirme ve önceliklendirme yöntemiyle teslim takvimine uyarlanabilir.

#### 6.5 Hukuki ve Etik Fizibilite

Projede kullanıcı verisi, konum bilgisi, mesaj içeriği ve sağlıkla ilişkili veriler bulunduğundan aşağıdaki konular önemlidir:

- Açık rıza ve aydınlatma metni
- Verinin güvenli saklanması
- Erişim yetkilerinin sınırlandırılması
- Kullanıcı silme veya veri talebi senaryoları
- Topluluk kuralları ve kötüye kullanım denetimi

Bu gereksinimler, sistemin teknik uygulanabilirliğinin yanında etik ve hukuki tasarım ihtiyacını da ortaya koymaktadır.

---

### 7. Proje Organizasyonu ve Yazılım Geliştirme Yaşam Döngüsü

#### 7.1 Ekip Yapısı

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

#### 7.2 Seçilen Süreç Modeli

Proje için saf şelale modeli yerine iteratif-artırımlı bir yaklaşım daha uygundur. Çünkü:

- Modüller bağımsız ama birbirine bağlıdır.
- Kullanıcı geri bildirimiyle yön değişebilir.
- Önce temel akışların çalışması, sonra gelişmiş modüllerin eklenmesi daha doğrudur.
- Mobil, backend ve panel geliştirmesi paralel ilerleyebilir.

Bu nedenle önerilen süreç modeli "faz kontrollü çevik/iteratif" yaklaşımdır.

#### 7.3 Yaşam Döngüsü Aşamaları

1. Problem ve ihtiyaç analizi
2. Gereksinim toplama ve modelleme
3. Mimari tasarım
4. Veri modeli tasarımı
5. Arayüz tasarımı
6. Artırımlı gerçekleme
7. Test ve doğrulama
8. Yayınlama
9. İzleme ve bakım

#### 7.4 Aşama Bazlı Çıktılar

| Aşama | Çıktı |
|---|---|
| Analiz | Paydaş listesi, gereksinimler, use case listesi |
| Tasarım | UML diyagramları, mimari şema, veri modeli |
| Gerçekleme | Mobil, panel ve backend modülleri |
| Test | Test planı, senaryolar, hata listesi |
| Yayınlama | Bulut dağıtım, ortam değişkenleri, sürümleme |
| Bakım | Log izleme, performans takibi, iyileştirme backlog'u |

#### 7.5 Neden Bu Süreç Uygun?

Sosyal akış, veteriner modülü, bakıcı modülü ve mağaza modülü birbirinden farklı problem alanlarıdır. Bu nedenle hepsini baştan tek seferde tam tasarlayıp dondurmak yerine, ortak çekirdek üzerinde aşamalı ilerlemek daha gerçekçidir. Ayrıca dağıtık sistemlerde entegrasyon riskleri erken görülmelidir; bu da iteratif yaklaşımı destekler.

---

### 8. Gereksinim Yönetimi Yaklaşımı

#### 8.1 Gereksinim Toplama Kaynakları

Gereksinimler aşağıdaki kaynaklardan türetilmiştir:

- Proje konusu ve alan problemi
- Uygulama içindeki mevcut modüller
- Mobil ekranlar ve panel akışları
- Sunucu tarafı route ve model yapısı
- Son kullanıcı ihtiyaçları
- Admin ve hizmet sağlayıcı bakış açıları
- Ders kapsamında işlenen analiz ve modelleme kavramları

#### 8.2 Gereksinim Toplama Yöntemleri

- Senaryo bazlı düşünme
- Aktör bazlı ihtiyaç çıkarma
- Modül incelemesi
- Benzer sistemlerden karşılaştırmalı gözlem
- İş kuralı belirleme

#### 8.3 Önceliklendirme İlkesi

Gereksinimler aşağıdaki mantıkla önceliklendirilmiştir:

- `Must`: Sistem çekirdeği için zorunlu
- `Should`: Kullanılabilirlik ve değer için güçlü katkı
- `Could`: Gelecek sürüm veya opsiyonel iyileştirme

#### 8.4 Temel Gereksinim Grupları

| Grup | İçerik |
|---|---|
| Kimlik ve erişim | Kayıt, giriş, token, rol |
| Çekirdek pet yönetimi | Pet profili, ilan, başvuru |
| Hizmet modülleri | Veteriner, bakıcı, sağlık |
| Etkileşim | Mesajlaşma, yorum, bildirim |
| Ticaret | Ürün, sepet, sipariş, kupon |
| Yönetim | Admin moderasyon, seller operasyonları |

#### 8.5 Gereksinimlerin İzlenebilirliği

Her önemli modül için gereksinim -> kullanım senaryosu -> API/ekran -> test zinciri kurulmalıdır. Bu izlenebilirlik sayesinde:

- Eksik analiz maddeleri kolay görülür.
- Test kapsamı daha doğru hazırlanır.
- Değişiklik geldiğinde etkilenen modüller bulunur.

Detaylı kullanım senaryoları ve kabul ölçütleri bu rapora bağlı ek dosyalarda verilmiştir.

---

### 9. Sistem Genel Tanımı

#### 9.1 Ürün Bakış Açısı

Sistem, mobil istemci merkezli çalışan ama web paneller ve bulut servislerle desteklenen dağıtık bir platformdur. Kullanıcılar esas olarak mobil uygulamayı kullanır. Admin ve satıcı tarafı ise web paneller aracılığıyla operasyon yürütür. Tüm istemciler merkezi backend API'ye bağlanır ve ortak veritabanını kullanır.

#### 9.2 Bileşenler

- Flutter mobil uygulama
- React/Vite admin paneli
- React/Vite satıcı paneli
- Node.js + Express REST API
- Socket.io gerçek zamanlı iletişim katmanı
- MongoDB Atlas veritabanı
- Push bildirim servisi
- Harita ve konum servisleri

#### 9.3 Kullanıcı Rolleri

- Ziyaretçi
- Kayıtlı kullanıcı
- Veteriner
- Pet bakıcısı
- Satıcı
- Admin

#### 9.4 Fonksiyonel Modüller

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

### 10. Mimari Tasarım

#### 10.1 Mimari Yaklaşım

Sistem, istemci-sunucu mimarisine dayalı, modüler ve servis tabanlı bir yapı ile tasarlanmıştır. Temel mimari kararlar şunlardır:

- Mobil ve web istemciler sunucudan ayrıdır.
- Sunucu iş kurallarını merkezi olarak uygular.
- Veritabanı erişimi istemcilerden doğrudan değil sunucu üzerinden yapılır.
- Gerçek zamanlı olaylar socket katmanı ile ele alınır.
- Dış servisler, çekirdek sistemden soyutlanmış servis katmanları üzerinden kullanılır.

#### 10.2 Katmanlar

##### Sunum Katmanı
- Flutter mobil ekranları
- Admin panel ekranları
- Satıcı panel ekranları

##### Uygulama / İş Mantığı Katmanı
- Controller'lar
- Servis sınıfları
- Yetkilendirme ve doğrulama akışları
- İş kuralı uygulamaları

##### Veri Erişim Katmanı
- Mongoose modelleri
- Sorgu, indeks, ilişki ve kayıt işlemleri

##### Entegrasyon Katmanı
- Push bildirim servisi
- Google Places veya benzeri servisler
- Dosya yükleme altyapısı

#### 10.3 Teknoloji Yığını

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

#### 10.4 Bileşen Sorumlulukları

##### Mobil Uygulama
- Son kullanıcı akışlarını yürütür
- Ekran, form ve liste etkileşimlerini sağlar
- Token saklama ve istemci tarafı durum yönetimini yapar
- Bildirimleri gösterir

##### Admin Paneli
- Kullanıcı, içerik, rapor ve operasyonel görünürlük sağlar
- Moderasyon işlerini merkezileştirir

##### Satıcı Paneli
- Ürün, kupon, sipariş ve mağaza yönetimi sunar

##### Backend API
- Kimlik doğrulama
- Yetkilendirme
- İş kuralları
- Veri bütünlüğü
- Modüller arası tutarlılık

##### Socket Katmanı
- Gerçek zamanlı mesajlaşma
- Canlı konum/servis durumu güncellemeleri
- Olay tabanlı bildirimler

#### 10.5 Dağıtım Mimarisi

Sistemin önerilen dağıtım topolojisi aşağıdaki diyagram dosyasında gösterilmiştir:

- [deployment_diagram.puml](./deployment_diagram.puml)

Bu topoloji; mobil istemci, web panelleri, backend uygulama sunucusu, socket katmanı, bulut veritabanı ve dış servisleri birbirinden ayrılmış ama koordineli bileşenler halinde göstermektedir.

#### 10.6 Mimarinin Güçlü Yönleri

- Modüler genişlemeye uygundur.
- Mobil ve panel tarafı bağımsız geliştirilebilir.
- Gerçek zamanlı iletişim için ayrı mekanizma kullanır.
- Bulut veritabanı ile merkezi veri yönetimi sağlar.
- Kimlik doğrulama tek merkezden yürütülür.

#### 10.7 Mimarinin Zayıf Yönleri ve Dikkat Noktaları

- Çok modüllü yapı operasyonel karmaşıklık yaratabilir.
- Bildirim, socket ve konum entegrasyonları hata ayıklamayı zorlaştırabilir.
- Dosya yükleme ve medya yönetimi büyüdükçe maliyet artar.
- Yetkilendirme kuralları doğru kurgulanmazsa güvenlik açığı doğabilir.

---

### 11. Veritabanı Tasarımı ve Veri Yönetimi

#### 11.1 Veritabanı Yaklaşımı

Projede belge tabanlı veritabanı yaklaşımı tercih edilmiştir. Bunun temel nedenleri:

- Modüller arası veri yapılarının esnek olması
- Bazı alanların opsiyonel veya değişken nitelikte bulunması
- Hızlı prototipleme ve iteratif geliştirme ihtiyacı
- Konum temelli sorgular için uygun modelleme imkânı

#### 11.2 Temel Varlıklar

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

#### 11.3 Temel İlişkiler

- Bir kullanıcı birden fazla pet profiline sahip olabilir.
- Bir kullanıcı birden fazla sipariş verebilir.
- Bir veteriner birden fazla randevuya sahip olabilir.
- Bir pet birden fazla aşı ve sağlık kaydına sahip olabilir.
- Bir bakıcı birden fazla rezervasyon alabilir.
- Bir mağaza birden fazla ürün içerebilir.
- Bir konuşma birden fazla mesaj içerir.

#### 11.4 Veri Bütünlüğü İlkeleri

1. Kimlikler sunucu tarafından üretilir.
2. Yetkisiz kullanıcı başkasına ait verilere erişemez.
3. Kritik durum değişiklikleri kayıt altına alınır.
4. Sipariş, rezervasyon ve başvuru gibi işlemler durum makinesi mantığı ile yönetilir.
5. Silme işlemlerinde veri kaybı ve referans bozulmaları dikkate alınır.

#### 11.5 İndeksleme ve Performans

Özellikle aşağıdaki alanlarda indeksleme önemlidir:

- E-posta ve kullanıcı erişim alanları
- Randevu tarih-saat alanları
- Sipariş numarası
- Mesajlaşma konuşma kimlikleri
- Konum tabanlı aramalar için `2dsphere` indeksleri

Coğrafi sorguların yoğun olduğu modüllerde doğru indeks seçimi kullanıcı deneyimi açısından kritik önemdedir. Yakın veteriner, yakın bakıcı ve yakın kayıp ilanı akışları bu nedenle tasarımın erken aşamasında düşünülmüştür.

#### 11.6 Veri Yaşam Döngüsü

Veri yaşam döngüsü aşağıdaki gibi özetlenebilir:

1. Kullanıcı veya sistem veri oluşturur.
2. Veri doğrulama ve iş kuralı kontrolünden geçer.
3. Veritabanına kaydedilir.
4. İlgili olaylar bildirim, socket veya log katmanına yansır.
5. Veri güncellenir, arşivlenir veya gerekli ise yumuşak silme ile işaretlenir.

#### 11.7 Denetim ve Loglama

Moderasyon ve operasyonel izlenebilirlik için audit log yaklaşımı önemlidir. Özellikle şu işlemlerde kayıt tutulmalıdır:

- Admin müdahaleleri
- Rol değişiklikleri
- Kritik sipariş ve rezervasyon durum güncellemeleri
- Kural dışı erişim denemeleri
- Giriş başarısızlıkları ve güvenlik olayları

---

### 12. Arayüz ve Kullanıcı Deneyimi Tasarımı

#### 12.1 Tasarım İlkeleri

Sistem çok modüllü olduğundan, arayüz tasarımında tutarlılık temel ilkedir. Kullanıcı veteriner, mağaza, mesajlaşma ve bakım gibi çok farklı alanlarda gezinirken tamamen farklı uygulamalardaymış hissine kapılmamalıdır. Bu nedenle:

- Tek tip bileşen dili
- Tutarlı renk sistemi
- Anlaşılır ikonografi
- Hızlı erişim sağlayan gezinme kurgusu
- Boş durum, hata durumu ve yüklenme durumlarının standartlaşması

önceliklendirilmiştir.

#### 12.2 Mobil Deneyim

Mobil uygulama son kullanıcı sistemidir. Bu nedenle aşağıdaki noktalar kritik kabul edilmiştir:

- Tek elle kullanım kolaylığı
- Harita ve liste ekranlarında akıcı deneyim
- Formlarda sade veri girişi
- Bildirimlerden ilgili ekrana doğrudan geçiş
- Düşük ağ kalitesinde kabul edilebilir davranış

#### 12.3 Panel Deneyimi

Admin ve satıcı paneli daha çok tablo, filtre, operasyonel liste ve analiz odaklıdır. Bu nedenle mobil uygulamadan farklı olarak:

- Daha yoğun veri görünümü
- Filtreleme ve sıralama araçları
- Çok sütunlu yerleşim
- Yönetim odaklı işlem butonları

tasarlanmalıdır.

#### 12.4 Erişilebilirlik ve Yerelleştirme

Sistem farklı yaş ve teknik yeterlilikte kullanıcılar tarafından kullanılabileceğinden aşağıdaki ilkeler önerilmiştir:

- Yeterli kontrast
- Anlaşılır metinler
- Durum mesajlarının açık olması
- Türkçe ve İngilizce dil desteği
- Tarih, para birimi ve bildirim metinlerinin yerelleştirilebilir olması

---

### 13. Güvenlik, Gizlilik ve Yetkilendirme

#### 13.1 Güvenlik Hedefleri

1. Yalnızca doğrulanmış kullanıcılar korumalı kaynaklara erişebilmelidir.
2. Rol bazlı yetkilendirme uygulanmalıdır.
3. Hassas bilgiler düz metin halinde saklanmamalıdır.
4. Kötüye kullanım, istek suistimali ve kaba kuvvet denemeleri sınırlandırılmalıdır.
5. Kullanıcı verisi aktarım sırasında korunmalıdır.

#### 13.2 Kimlik Doğrulama

Sistemde JWT tabanlı oturum yönetimi yaklaşımı kullanılmaktadır. Temel mantık:

- Kullanıcı giriş yapar
- Sunucu kimlik bilgilerini doğrular
- Token üretir
- İstemci token saklar
- Korumalı isteklerde token gönderilir

#### 13.3 Yetkilendirme

Rol bazlı yetkilendirme aşağıdaki ayrımı desteklemelidir:

- Standart kullanıcı
- Satıcı
- Veteriner
- Admin

Her rolün erişebileceği kaynaklar ve yapabileceği işlemler açıkça sınırlandırılmalıdır.

#### 13.4 Girdi Doğrulama ve Saldırı Yüzeyi Azaltma

Projede önerilen temel korumalar:

- Girdi doğrulama
- Rate limiting
- NoSQL injection koruması
- Yetkisiz erişim kontrolleri
- Dosya yüklemede tür ve boyut kısıtı
- Log izleme

#### 13.5 Gizlilik

Toplanan veri türleri:

- Kimlik ve hesap verileri
- Konum verileri
- Mesaj içerikleri
- Sipariş ve adres verileri
- Sağlık/aşı bilgileri
- Yorumlar ve etkileşim verileri

Bu nedenle veri minimizasyonu, amaç sınırlılığı ve erişim kayıtlarının tutulması önemlidir.

---

### 14. Performans, Ölçeklenebilirlik ve Operasyon

#### 14.1 Performans Hedefleri

Sistemin kabul edilebilir kullanıcı deneyimi sunabilmesi için aşağıdaki hedefler belirlenmiştir:

- Temel API çağrılarında düşük gecikme
- Liste ekranlarında sayfalama veya kademeli yükleme
- Bildirimlerin makul sürede iletilmesi
- Mesajlaşmada düşük gecikme

#### 14.2 Ölçeklenebilirlik Yaklaşımı

İlk aşamada tek backend servisi ile başlanabilir; ancak büyüme halinde aşağıdaki alanlar ayrıştırılabilir:

- Medya yükleme servisi
- Bildirim işleyici
- Arka plan görevleri
- Analitik ve raporlama

#### 14.3 Arka Plan İşleri

Aşı hatırlatma, doğum günü hatırlatma, ilan süresi kontrolü veya rezervasyon hatırlatmaları gibi işler eşzamansız görev mantığı ile ele alınmalıdır.

#### 14.4 Operasyonel İzleme

Operasyon sırasında izlenmesi önerilen göstergeler:

- Başarısız giriş oranı
- API hata oranı
- Ortalama yanıt süresi
- Bildirim başarısı
- Socket bağlantı sayısı
- Randevu ve sipariş dönüşüm oranları

---

### 15. Bakım, İzleme ve Sürdürülebilirlik

#### 15.1 Bakım Türleri

- Düzeltici bakım
- Uyarlayıcı bakım
- İyileştirici bakım
- Önleyici bakım

#### 15.2 Sürüm Yönetimi

Sistemde aşağıdaki sürümleme yaklaşımı önerilir:

- Mobil istemci sürümleri
- Backend sürümleri
- Panel sürümleri
- Veritabanı şema değişiklik notları

#### 15.3 Dokümantasyonun Önemi

Bu proje çok modüllü olduğundan, sözlü bilgiye dayalı geliştirme sürdürülemez. Bu nedenle:

- API sözleşmeleri
- UML diyagramları
- Test planları
- Rol matrisi
- Risk listesi
- Değişiklik kayıtları

gibi belgeler sistemin sürdürülebilirliğini doğrudan etkiler.

#### 15.4 Gelecek Geliştirme Alanları

- Gerçek ödeme entegrasyonu
- Gelişmiş arama ve öneri sistemi
- Daha güçlü raporlama panelleri
- Makine öğrenmesi destekli öneriler
- Çoklu şehir ve çoklu ülke desteği
- Gelişmiş moderasyon otomasyonu

---

### 16. Sonuç

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

### 17. Kaynaklar

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

# 02 Kullanim Senaryolari Ve Sozlesmeler

## Ek A: Kullanım Senaryoları ve Sözleşmeleri

### 1. Amaç

Bu dokümanın amacı, sistemin temel işlevlerini aktör merkezli olarak modellemek ve her önemli akış için ayrıntılı kullanım senaryosu sözleşmeleri oluşturmaktır. Bu sayede gereksinimlerin yalnızca madde listesi olarak kalması engellenir; iş kuralları, ön koşullar, alternatif akışlar ve son durumlar açıkça tanımlanır.

Bu doküman, Yazılım Mühendisliği dersi kapsamında özellikle istenen aşağıdaki gereksinimlere doğrudan karşılık vermektedir:

- Kullanım senaryolarının ortaya konulması
- Gerekli durumlarda kullanım senaryosu sözleşmelerinin eklenmesi
- Sorumlulukların ve aktörlerin netleştirilmesi
- Tasarım etkileşim diyagramlarına temel oluşturulması

---

### 2. Aktör Kataloğu

#### 2.1 Ziyaretçi

Henüz sisteme kayıt olmamış veya giriş yapmamış kullanıcıdır. Kayıt olabilir, giriş ekranlarını görebilir, sınırlı keşif yapabilir.

#### 2.2 Kayıtlı Kullanıcı

Sistemin ana aktörüdür. Pet profili açar, ilan verir, başvuru yapar, mesajlaşır, sipariş verir, bakıcı ve veteriner bulur.

#### 2.3 Veteriner

Klinik bilgilerini yönetir, randevu akışına katılır, müsaitlik ve hizmet bilgisi sunar, yorum alabilir.

#### 2.4 Pet Bakıcısı

Hizmet profili oluşturur, rezervasyon kabul eder veya reddeder, bakım sürecini yönetir.

#### 2.5 Satıcı

Mağaza açar, ürün yükler, stok ve sipariş yönetimi yapar.

#### 2.6 Admin

Platform güvenliğini, içerik moderasyonunu, başvuru yönetimini ve operasyonel denetimi yürütür.

---

### 3. Kullanım Senaryosu Listesi

| Kod | Kullanım Senaryosu | Birincil Aktör |
|---|---|---|
| UC-01 | Kayıt Olma | Ziyaretçi |
| UC-02 | Giriş Yapma | Ziyaretçi/Kullanıcı |
| UC-03 | Pet Profili Oluşturma | Kullanıcı |
| UC-04 | Sahiplendirme İlanı Oluşturma | Kullanıcı |
| UC-05 | Sahiplendirme Başvurusu Yapma | Kullanıcı |
| UC-06 | Yakındaki Veterinerleri Listeleme | Kullanıcı |
| UC-07 | Veteriner Randevusu Oluşturma | Kullanıcı |
| UC-08 | Aşı Kaydı Ekleme | Kullanıcı/Veteriner |
| UC-09 | Pet Bakıcısı Profili Oluşturma | Kullanıcı/Bakıcı |
| UC-10 | Pet Bakıcısı Rezervasyonu Oluşturma | Kullanıcı |
| UC-11 | Gerçek Zamanlı Mesaj Gönderme | Kullanıcı |
| UC-12 | Kayıp/Bulunan Hayvan İlanı Verme | Kullanıcı |
| UC-13 | Ürünü Sepete Ekleme ve Sipariş Verme | Kullanıcı |
| UC-14 | Ürün Yönetme | Satıcı |
| UC-15 | İçerik Moderasyonu Yapma | Admin |
| UC-16 | Etkinliğe Katılım Bildirme | Kullanıcı |

---

### 4. Kullanım Senaryosu Sözleşmeleri

### UC-01 Kayıt Olma

#### Genel Bilgiler
- Kod: `UC-01`
- Ad: `Kayıt Olma`
- Amaç: Yeni kullanıcının sisteme hesap açabilmesi
- Birincil Aktör: `Ziyaretçi`
- İkincil Aktörler: `Bildirim Servisi`, `Kimlik Doğrulama Servisi`
- Ön Koşullar: Kullanıcının daha önce aynı e-posta ile kayıt olmamış olması
- Son Koşullar: Sistem yeni kullanıcı hesabını oluşturur ve kullanıcının giriş yapmasına izin verir

#### Tetikleyici
Ziyaretçi kayıt ekranında bilgilerini doldurup "Kayıt Ol" butonuna basar.

#### Ana Akış
1. Ziyaretçi kayıt ekranını açar.
2. Sistem ad, soyad, e-posta, şifre ve gerekli diğer alanları gösterir.
3. Ziyaretçi bilgileri girer.
4. Sistem alan doğrulaması yapar.
5. Sistem e-posta adresinin daha önce kullanılıp kullanılmadığını kontrol eder.
6. Sistem kullanıcı kaydını oluşturur.
7. Sistem gerekirse doğrulama kodu veya onay mesajı üretir.
8. Kullanıcıya kayıt başarılı bilgisi gösterilir.

#### Alternatif Akışlar
1. E-posta zaten kayıtlı ise sistem kullanıcıyı uyarır.
2. Şifre güvenlik koşullarını sağlamıyorsa kayıt tamamlanmaz.
3. Ağ veya sunucu hatasında sistem uygun hata mesajı gösterir.

#### İş Kuralları
- E-posta benzersiz olmalıdır.
- Şifre belirli karmaşıklık kurallarını sağlamalıdır.
- Rol bilgisi varsayılan olarak standart kullanıcıdır.

#### Özel Gereksinimler
- Şifre alanı maskeli gösterilmelidir.
- Hata mesajları kullanıcı dostu olmalıdır.

---

### UC-02 Giriş Yapma

#### Genel Bilgiler
- Kod: `UC-02`
- Ad: `Giriş Yapma`
- Amaç: Kayıtlı kullanıcının sisteme güvenli biçimde giriş yapması
- Birincil Aktör: `Ziyaretçi/Kullanıcı`
- Ön Koşullar: Kullanıcının hesabı mevcut olmalıdır
- Son Koşullar: Sistem geçerli oturum üretir

#### Ana Akış
1. Kullanıcı giriş ekranını açar.
2. E-posta ve şifre bilgilerini girer.
3. Sistem kimlik doğrulama yapar.
4. Doğrulama başarılı ise token üretir.
5. Kullanıcı ana ekrana yönlendirilir.

#### Alternatif Akışlar
1. Yanlış parola girilirse hata gösterilir.
2. Hesap kısıtlı ise giriş engellenir.
3. Çok sayıda başarısız deneme yapılmışsa rate limit devreye girer.

#### İş Kuralları
- Hatalı denemeler izlenmelidir.
- Token süresi ve yenileme politikası tanımlı olmalıdır.

---

### UC-03 Pet Profili Oluşturma

#### Genel Bilgiler
- Kod: `UC-03`
- Ad: `Pet Profili Oluşturma`
- Amaç: Kullanıcının kendi evcil hayvanı için profil açması
- Birincil Aktör: `Kullanıcı`
- Ön Koşullar: Kullanıcının giriş yapmış olması
- Son Koşullar: Pet kaydı veritabanına eklenir

#### Ana Akış
1. Kullanıcı "Pet Ekle" ekranını açar.
2. Ad, tür, cinsiyet, yaş, açıklama, fotoğraf ve sağlıkla ilgili temel bilgileri girer.
3. Sistem zorunlu alanları doğrular.
4. Kullanıcı konum veya şehir bilgisi ekleyebilir.
5. Sistem pet kaydını oluşturur.
6. Kullanıcı pet detay ekranına yönlendirilir.

#### Alternatif Akışlar
1. Fotoğraf yükleme başarısız olur; kullanıcı tekrar deneyebilir.
2. Eksik alan varsa kaydetme yapılamaz.

#### İş Kuralları
- Her pet bir kullanıcıya bağlı olmalıdır.
- Tür ve cins gibi alanlar belirli sözlüklerle sınırlanabilir.

---

### UC-04 Sahiplendirme İlanı Oluşturma

#### Genel Bilgiler
- Kod: `UC-04`
- Ad: `Sahiplendirme İlanı Oluşturma`
- Amaç: Kullanıcının peti için sahiplendirme ilanı açması
- Birincil Aktör: `Kullanıcı`
- Ön Koşullar: Kullanıcının pet profili bulunmalıdır
- Son Koşullar: İlan yayınlanır veya inceleme kuyruğuna alınır

#### Ana Akış
1. Kullanıcı mevcut petlerinden birini seçer.
2. İlan tipi olarak sahiplendirmeyi işaretler.
3. Açıklama, şehir, iletişim tercihi ve ek medya girer.
4. Sistem ilanın doğrulamasını yapar.
5. İlan kaydedilir.
6. Sistem ilanı yayına alır veya moderasyon kuyruğuna gönderir.

#### Alternatif Akışlar
1. Pet bulunmuyorsa sistem önce pet profili oluşturulmasını ister.
2. Yasaklı içerik saptanırsa ilan reddedilir.

#### İş Kuralları
- Aynı pet için eş zamanlı çakışan ilan tipleri sınırlandırılabilir.
- Uygunsuz içerikler moderasyona yönlendirilir.

---

### UC-05 Sahiplendirme Başvurusu Yapma

#### Genel Bilgiler
- Kod: `UC-05`
- Ad: `Sahiplendirme Başvurusu Yapma`
- Amaç: Kullanıcının uygun bir sahiplendirme ilanına başvuru yapması
- Birincil Aktör: `Kullanıcı`
- İkincil Aktör: `İlan Sahibi`, `Bildirim Servisi`

#### Ana Akış
1. Kullanıcı sahiplendirme ilanını açar.
2. Başvuru formunu görüntüler.
3. Gerekli açıklama ve kişisel uygunluk bilgilerini girer.
4. Sistem başvuruyu kaydeder.
5. İlan sahibine bildirim gönderir.
6. Başvuru durumu "beklemede" olarak işaretlenir.

#### Alternatif Akışlar
1. Kullanıcı kendi ilanına başvuramaz.
2. Aynı kullanıcı aynı ilana ikinci kez başvuramaz.

#### İş Kuralları
- Başvurular durum bazlı yönetilir: beklemede, kabul, red, iptal.

---

### UC-06 Yakındaki Veterinerleri Listeleme

#### Genel Bilgiler
- Kod: `UC-06`
- Ad: `Yakındaki Veterinerleri Listeleme`
- Amaç: Kullanıcının konumuna göre yakın veterinerleri bulması
- Birincil Aktör: `Kullanıcı`
- İkincil Aktör: `Konum Servisi`, `Harita Servisi`

#### Ön Koşullar
- Kullanıcı konum izni vermelidir veya manuel konum belirlemelidir.

#### Ana Akış
1. Kullanıcı veteriner arama ekranını açar.
2. Sistem cihazdan konum alır.
3. Sistem sunucuya konum bilgisi gönderir.
4. Sunucu belirlenen yarıçap içindeki veterinerleri sorgular.
5. Sonuçlar liste ve/veya harita biçiminde gösterilir.

#### Alternatif Akışlar
1. Konum izni reddedilirse manuel şehir seçimi sunulur.
2. Yakında veteriner yoksa daha geniş yarıçapla öneri yapılır.

#### İş Kuralları
- Uzaklık sıralaması desteklenmelidir.
- Sonuçlar yorum, puan veya hizmet türüne göre filtrelenebilir.

---

### UC-07 Veteriner Randevusu Oluşturma

#### Genel Bilgiler
- Kod: `UC-07`
- Ad: `Veteriner Randevusu Oluşturma`
- Amaç: Kullanıcının bir veteriner için randevu alması
- Birincil Aktör: `Kullanıcı`
- İkincil Aktörler: `Veteriner`, `Bildirim Servisi`
- Ön Koşullar: Kullanıcının giriş yapmış olması ve en az bir pet profiline sahip olması
- Son Koşullar: Randevu kaydı beklemede veya onaylandı durumunda oluşturulur

#### Ana Akış
1. Kullanıcı veteriner detay ekranını açar.
2. "Randevu Al" seçeneğini seçer.
3. Sistem uygun gün ve saatleri listeler.
4. Kullanıcı petini seçer.
5. Kullanıcı tarih, saat ve kısa not girer.
6. Sistem slot uygunluğunu yeniden doğrular.
7. Sistem randevu kaydını oluşturur.
8. Kullanıcıya başarı mesajı gösterilir.
9. Veteriner veya klinik paneline bildirim gönderilir.

#### Alternatif Akışlar
1. Seçilen slot başka kullanıcı tarafından dolmuşsa sistem yeni slot seçtirir.
2. Kullanıcının pet profili yoksa sistem önce pet eklemeye yönlendirir.
3. Veteriner artık aktif değilse işlem iptal edilir.

#### Son Durum
- Randevu veritabanında saklanır.
- Bildirimler tetiklenir.

#### İş Kuralları
- Aynı zaman aralığına çakışan randevu alınamaz.
- Geçmiş tarihe randevu oluşturulamaz.
- İptal süresi kuralı ayrıca tanımlanabilir.

#### İlişkili Diyagram
- [sequence_vet_appointment.puml](./sequence_vet_appointment.puml)

---

### UC-08 Aşı Kaydı Ekleme

#### Genel Bilgiler
- Kod: `UC-08`
- Ad: `Aşı Kaydı Ekleme`
- Amaç: Pet için aşı kaydı ve gelecek takvim planı oluşturma
- Birincil Aktör: `Kullanıcı` veya `Veteriner`

#### Ana Akış
1. Aktör ilgili petin sağlık ekranını açar.
2. Aşı türü, uygulama tarihi ve bir sonraki tarih girilir.
3. Sistem veriyi doğrular.
4. Kayıt veritabanına eklenir.
5. Hatırlatma mekanizması planlanır.

#### Alternatif Akışlar
1. Tarih alanı hatalı ise kayıt alınmaz.
2. Aynı kaydın tekrar eklenmesi durumunda kullanıcı uyarılır.

#### İş Kuralları
- Gelecek aşı tarihi mevcut aşı tarihinden önce olamaz.
- Hatırlatma tercihleri kullanıcı tarafından kapatılmış olabilir.

---

### UC-09 Pet Bakıcısı Profili Oluşturma

#### Genel Bilgiler
- Kod: `UC-09`
- Ad: `Pet Bakıcısı Profili Oluşturma`
- Amaç: Kullanıcının kendisini hizmet sağlayıcı bakıcı olarak sisteme tanıtması
- Birincil Aktör: `Kullanıcı/Bakıcı`

#### Ana Akış
1. Kullanıcı "Bakıcı Ol" sürecini başlatır.
2. Deneyim, hizmet türleri, fiyat bilgisi, müsaitlik ve konum girer.
3. Sistem gerekli alanları doğrular.
4. Profil oluşturulur.
5. Profil inceleme veya aktif statüsüne alınır.

#### Alternatif Akışlar
1. Belgeler eksikse başvuru beklemeye alınır.
2. Uygunsuz içerik veya eksik açıklama varsa kullanıcıdan düzeltme istenir.

#### İş Kuralları
- Bakıcı profili kullanıcı hesabına bağlıdır.
- Hizmet alanları belirli kategorilerle sınırlıdır.

---

### UC-10 Pet Bakıcısı Rezervasyonu Oluşturma

#### Genel Bilgiler
- Kod: `UC-10`
- Ad: `Pet Bakıcısı Rezervasyonu Oluşturma`
- Amaç: Kullanıcının bakıcı için tarih aralıklı rezervasyon oluşturması
- Birincil Aktör: `Kullanıcı`
- İkincil Aktör: `Bakıcı`, `Bildirim Servisi`

#### Ana Akış
1. Kullanıcı bakıcı profilini görüntüler.
2. Hizmet türü seçer.
3. Başlangıç ve bitiş tarihi girer.
4. Pet ve ek not bilgisi seçilir.
5. Sistem uygunluk ve çakışma kontrolü yapar.
6. Rezervasyon oluşturulur.
7. Bakıcıya bildirim gönderilir.

#### Alternatif Akışlar
1. Tarihler çakışıyorsa kullanıcı yeni aralık seçer.
2. Bakıcı pasif ise rezervasyon alınmaz.

#### İş Kuralları
- Başlangıç tarihi bitiş tarihinden sonra olamaz.
- Geçmiş tarihli rezervasyon kabul edilmez.
- Rezervasyon durumları: beklemede, kabul, red, aktif, tamamlandı, iptal.

---

### UC-11 Gerçek Zamanlı Mesaj Gönderme

#### Genel Bilgiler
- Kod: `UC-11`
- Ad: `Gerçek Zamanlı Mesaj Gönderme`
- Amaç: Kullanıcıların uygulama içi anlık iletişim kurması
- Birincil Aktör: `Kullanıcı`
- İkincil Aktör: `Socket Servisi`

#### Ana Akış
1. Kullanıcı bir konuşma ekranını açar.
2. Metin veya medya mesajı hazırlar.
3. Mesaj sunucuya gönderilir.
4. Sistem kullanıcının konuşma yetkisini kontrol eder.
5. Mesaj kaydedilir.
6. İlgili alıcılara anlık olarak iletilir.
7. Arayüz yeni mesajı gösterir.

#### Alternatif Akışlar
1. Alıcı çevrimdışı ise sistem push bildirim gönderir.
2. Socket bağlantısı yoksa istemci tekrar deneme veya yenileme yapar.

#### İş Kuralları
- Kullanıcı yalnızca dahil olduğu konuşmalara mesaj gönderebilir.
- Engellenen kullanıcılar arasında mesajlaşma sınırlandırılabilir.

---

### UC-12 Kayıp/Bulunan Hayvan İlanı Verme

#### Genel Bilgiler
- Kod: `UC-12`
- Ad: `Kayıp/Bulunan Hayvan İlanı Verme`
- Amaç: Kullanıcının kayıp veya bulunan hayvan için duyuru oluşturması
- Birincil Aktör: `Kullanıcı`

#### Ana Akış
1. Kullanıcı kayıp/bulunan ilan ekranını açar.
2. İlan türü seçilir: kayıp veya bulundu.
3. Konum, açıklama, fotoğraf ve iletişim bilgisi girilir.
4. Sistem konum bilgisini doğrular.
5. İlan kaydedilir.
6. Yakındaki kullanıcılara görünür hale gelir.

#### Alternatif Akışlar
1. Konum olmadan harita tabanlı görünürlük sınırlı olur.
2. Yetersiz açıklama için kullanıcı uyarılabilir.

#### İş Kuralları
- İlanın durumu sonradan "bulundu/çözüldü" olarak işaretlenebilir.

---

### UC-13 Ürünü Sepete Ekleme ve Sipariş Verme

#### Genel Bilgiler
- Kod: `UC-13`
- Ad: `Ürünü Sepete Ekleme ve Sipariş Verme`
- Amaç: Kullanıcının ürün seçip sipariş oluşturması
- Birincil Aktör: `Kullanıcı`
- İkincil Aktörler: `Satıcı`, `Bildirim Servisi`

#### Ana Akış
1. Kullanıcı mağaza veya ürün detay ekranını açar.
2. Ürünü sepete ekler.
3. Sepet ekranına gider.
4. Adres seçer veya yeni adres ekler.
5. Gerekirse kupon uygular.
6. Siparişi onaylar.
7. Sistem stok ve toplam tutarı doğrular.
8. Sipariş kaydı oluşturulur.
9. Satıcı tarafına sipariş bildirimi düşer.

#### Alternatif Akışlar
1. Stok yetersizse sipariş alınmaz.
2. Kupon geçersiz ise kullanıcı uyarılır.
3. Adres eksikse sipariş tamamlanamaz.

#### İş Kuralları
- Sipariş yalnızca mevcut stoktan verilebilir.
- Kuponların süre ve kullanım limiti olabilir.
- Sipariş durumları belirli yaşam döngüsü ile ilerler.

---

### UC-14 Ürün Yönetme

#### Genel Bilgiler
- Kod: `UC-14`
- Ad: `Ürün Yönetme`
- Amaç: Satıcının ürün ekleme, güncelleme ve kaldırma işlemlerini yapması
- Birincil Aktör: `Satıcı`

#### Ana Akış
1. Satıcı panelde ürün yönetimi ekranını açar.
2. Yeni ürün ekler veya mevcut ürünü seçer.
3. İsim, fiyat, stok, açıklama, kategori ve görsel bilgisi girer.
4. Sistem doğrulama yapar.
5. Kayıt oluşturulur veya güncellenir.
6. Sonuç ekranda listelenir.

#### Alternatif Akışlar
1. Zorunlu alanlar eksikse ürün kaydedilmez.
2. Yüklenen görsel kabul edilmeyen formatta ise işlem iptal edilir.

#### İş Kuralları
- Yalnızca ilgili satıcı kendi mağazasındaki ürünleri yönetebilir.
- Fiyat ve stok alanları negatif olamaz.

---

### UC-15 İçerik Moderasyonu Yapma

#### Genel Bilgiler
- Kod: `UC-15`
- Ad: `İçerik Moderasyonu Yapma`
- Amaç: Adminin raporlanmış veya sorunlu içerik/kullanıcı üzerinde işlem yapması
- Birincil Aktör: `Admin`

#### Ana Akış
1. Admin moderasyon kuyruğunu açar.
2. Raporlanmış içerik veya kullanıcı kaydını seçer.
3. İçeriği, geçmiş raporları ve ilgili detayları inceler.
4. Gerekirse içerik kaldırma, uyarı verme, engelleme veya hesap kısıtlama işlemi yapar.
5. Sistem tüm müdahaleleri audit log'a yazar.

#### Alternatif Akışlar
1. Rapor asılsız ise admin kaydı kapatır.
2. Kanıt yetersizse manuel inceleme kuyruğuna aktarılır.

#### İş Kuralları
- Admin işlemleri izlenebilir olmalıdır.
- Geri alınabilir veya kademeli yaptırım modeli tercih edilebilir.

---

### UC-16 Etkinliğe Katılım Bildirme

#### Genel Bilgiler
- Kod: `UC-16`
- Ad: `Etkinliğe Katılım Bildirme`
- Amaç: Kullanıcının sistemde listelenen bir etkinliğe katılım göstermesi
- Birincil Aktör: `Kullanıcı`

#### Ana Akış
1. Kullanıcı etkinlik detay ekranını açar.
2. Kontenjan ve konum bilgilerini inceler.
3. "Katıl" seçeneğine basar.
4. Sistem kontenjan ve tarih kontrolü yapar.
5. Katılım kaydı oluşturulur.
6. Kullanıcıya onay gösterilir.

#### Alternatif Akışlar
1. Etkinlik doluysa kayıt alınmaz.
2. Etkinlik tarihi geçmişse işlem engellenir.

#### İş Kuralları
- Aynı kullanıcı aynı etkinliğe bir kez katılabilir.

---

### 5. Analiz Sınıfları

#### 5.1 Varlık Sınıfları

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
- LostFoundPet
- Post
- AdoptionApplication

#### 5.2 Sınır Sınıfları

- Mobil giriş ekranları
- Mobil veteriner ve randevu ekranları
- Mobil mağaza ekranları
- Admin panel tabloları
- Satıcı panel formları
- REST endpoint katmanı

#### 5.3 Kontrol Sınıfları

- AuthController
- AppointmentController
- VaccinationController
- PetSitterController
- OrderController
- MessageController
- AdminController

Bu ayrım, nesneye dayalı analiz ve tasarım sürecinde sorumluluk dağılımını netleştirmektedir.

---

### 6. İş Kuralları Özeti

1. Her kullanıcı benzersiz e-posta ile kayıt olur.
2. Yetkisiz kullanıcı korumalı kaynağa erişemez.
3. Kullanıcı yalnızca kendi petlerini düzenleyebilir.
4. Sahiplendirme başvuruları durum bazlı izlenir.
5. Aynı slot için çakışan veteriner randevusu açılamaz.
6. Aşı tarihi mantıksal zaman akışına uygun olmalıdır.
7. Bakıcı rezervasyonlarında çakışan tarih aralıkları engellenmelidir.
8. Mesaj gönderen kullanıcı konuşmanın tarafı olmalıdır.
9. Ürün siparişi stok sınırını aşamaz.
10. Admin işlemleri kayıt altına alınmalıdır.

---

### 7. Diyagram Referansları

Bu kullanım senaryolarına bağlı diyagram dosyaları:

- [use_case_diagram.puml](./use_case_diagram.puml)
- [class_diagram.puml](./class_diagram.puml)
- [sequence_vet_appointment.puml](./sequence_vet_appointment.puml)

İstersen bir sonraki adımda bu kullanım senaryolarının her biri için ayrı activity veya sequence diyagramları da üretebilirim.

# 04 Gereksinim Izlenebilirlik Ve Veri Sozlugu

## Ek C: Gereksinim İzlenebilirlik Matrisi ve Veri Sözlüğü

### 1. Amaç

Bu ekin amacı, proje gereksinimlerinin daha sistematik ve denetlenebilir biçimde sunulmasıdır. Yazılım mühendisliğinde gereksinimlerin yalnızca metin halinde sıralanması yeterli değildir; her gereksinimin hangi modüle, hangi kullanım senaryosuna ve hangi test alanına karşılık geldiğinin görülebilmesi gerekir. Buna ek olarak, veri sözlüğü bölümü ile sistemdeki temel varlıkların anlamı ve kritik alanları açıklanır.

---

### 2. İşlevsel Gereksinim Matrisi

| Gereksinim ID | Gereksinim Tanımı | Öncelik | Modül | İlgili Use Case |
|---|---|---|---|---|
| FR-01 | Sistem kullanıcı kaydı oluşturabilmelidir | Must | Auth | UC-01 |
| FR-02 | Sistem kullanıcı girişini desteklemelidir | Must | Auth | UC-02 |
| FR-03 | Sistem rol bazlı yetkilendirme yapmalıdır | Must | Auth/Admin | UC-02, UC-15 |
| FR-04 | Kullanıcı profil bilgilerini güncelleyebilmelidir | Must | Profil | UC-02 |
| FR-05 | Kullanıcı pet profili oluşturabilmelidir | Must | Pet | UC-03 |
| FR-06 | Kullanıcı pet profilini güncelleyebilmelidir | Must | Pet | UC-03 |
| FR-07 | Kullanıcı sahiplendirme ilanı oluşturabilmelidir | Must | İlan | UC-04 |
| FR-08 | Kullanıcı sahiplendirme ilanlarına başvurabilmelidir | Must | İlan | UC-05 |
| FR-09 | İlan sahibi başvuruları görüntüleyebilmelidir | Should | İlan | UC-05 |
| FR-10 | Kullanıcı eşleştirme profillerini listeleyebilmelidir | Should | Eşleştirme | - |
| FR-11 | Kullanıcı eşleştirme isteği gönderebilmelidir | Should | Eşleştirme | - |
| FR-12 | Kullanıcı yakındaki veterinerleri görebilmelidir | Must | Veteriner | UC-06 |
| FR-13 | Kullanıcı veteriner detaylarını görüntüleyebilmelidir | Must | Veteriner | UC-06 |
| FR-14 | Kullanıcı veteriner randevusu oluşturabilmelidir | Must | Randevu | UC-07 |
| FR-15 | Veteriner randevu durumunu güncelleyebilmelidir | Should | Randevu | UC-07 |
| FR-16 | Kullanıcı pet için aşı kaydı ekleyebilmelidir | Should | Aşı | UC-08 |
| FR-17 | Sistem yaklaşan aşılar için hatırlatma oluşturabilmelidir | Should | Aşı/Bildirim | UC-08 |
| FR-18 | Kullanıcı bakıcı profillerini listeleyebilmelidir | Must | Bakıcı | UC-10 |
| FR-19 | Kullanıcı bakıcı rezervasyonu oluşturabilmelidir | Must | Bakıcı | UC-10 |
| FR-20 | Bakıcı rezervasyon talebini kabul veya reddedebilmelidir | Should | Bakıcı | UC-10 |
| FR-21 | Kullanıcı uygulama içi mesaj gönderebilmelidir | Must | Mesajlaşma | UC-11 |
| FR-22 | Sistem yeni mesajı gerçek zamanlı iletebilmelidir | Must | Mesajlaşma/Socket | UC-11 |
| FR-23 | Kullanıcı kayıp/bulunan hayvan ilanı açabilmelidir | Should | Kayıp/Bulunan | UC-12 |
| FR-24 | Kullanıcı ürünleri listeleyebilmelidir | Must | Mağaza | UC-13 |
| FR-25 | Kullanıcı ürünü sepete ekleyebilmelidir | Must | Mağaza | UC-13 |
| FR-26 | Kullanıcı sipariş oluşturabilmelidir | Must | Mağaza/Sipariş | UC-13 |
| FR-27 | Kullanıcı kupon uygulayabilmelidir | Could | Kupon | UC-13 |
| FR-28 | Satıcı ürün ekleyebilmelidir | Must | Seller | UC-14 |
| FR-29 | Satıcı ürün bilgilerini güncelleyebilmelidir | Must | Seller | UC-14 |
| FR-30 | Satıcı siparişlerini görüntüleyebilmelidir | Must | Seller | UC-14 |
| FR-31 | Admin raporlanan içerikleri inceleyebilmelidir | Must | Admin | UC-15 |
| FR-32 | Admin içerik kaldırma işlemi yapabilmelidir | Must | Admin | UC-15 |
| FR-33 | Admin kullanıcı kısıtlama işlemi yapabilmelidir | Should | Admin | UC-15 |
| FR-34 | Sistem admin işlemlerini audit log'a yazmalıdır | Should | Admin/Audit | UC-15 |
| FR-35 | Kullanıcı etkinlik listelerini görüntüleyebilmelidir | Could | Etkinlik | UC-16 |
| FR-36 | Kullanıcı etkinliğe katılım bildirebilmelidir | Could | Etkinlik | UC-16 |

---

### 3. İşlevsel Olmayan Gereksinim Matrisi

| NFR ID | Gereksinim | Ölçüm / Kabul Kriteri | Doğrulama Yöntemi |
|---|---|---|---|
| NFR-01 | Sistem internet üzerinden erişilebilir olmalıdır | Uygulama dış ağdan erişebilmelidir | Yayın testi |
| NFR-02 | Yetkisiz erişim engellenmelidir | Korunmalı endpoint'lerde 401/403 | Güvenlik testi |
| NFR-03 | Şifreler güvenli saklanmalıdır | Hashlenmiş saklama | Kod/DB incelemesi |
| NFR-04 | İstek suistimali sınırlandırılmalıdır | Rate limit uygulanır | API testi |
| NFR-05 | Kritik akışlar mobilde anlaşılır olmalıdır | Kullanıcı görevini tamamlayabilmeli | Kullanılabilirlik testi |
| NFR-06 | Konum tabanlı sorgular anlamlı sürede dönmelidir | Yakın arama kabul edilebilir hızda | Performans testi |
| NFR-07 | Mesajlaşma gecikmesi düşük olmalıdır | Mesaj kabul edilebilir sürede görünür | Gerçek zaman testi |
| NFR-08 | Sistem yeni modüllere açık olmalıdır | Modüler yapı korunmalı | Mimari inceleme |
| NFR-09 | Log ve audit kaydı tutulmalıdır | Kritik işlemler loglanmalı | Operasyon testi |
| NFR-10 | Hata mesajları kullanıcı dostu olmalıdır | Anlaşılır hata metinleri | Arayüz testi |
| NFR-11 | Sistem çoklu rol desteklemelidir | Kullanıcı/satıcı/admin ayrışmalı | Rol testi |
| NFR-12 | Veritabanı merkezi ve sürdürülebilir olmalıdır | Bulut DB üzerinden çalışmalı | Ortam incelemesi |
| NFR-13 | Dosya yükleme güvenli olmalıdır | Tür/boyut doğrulama | Negatif test |
| NFR-14 | Bildirim altyapısı devreye alınabilir olmalıdır | Push akışları desteklenmeli | Entegrasyon testi |
| NFR-15 | Arayüz yerelleştirilebilir olmalıdır | TR/EN desteği | UI testi |

---

### 4. Gereksinim İzlenebilirlik Matrisi

| Gereksinim | Use Case | Test Örneği | İlgili Modül |
|---|---|---|---|
| FR-01 | UC-01 | T-01, T-02 | Auth |
| FR-02 | UC-02 | T-03, T-04 | Auth |
| FR-03 | UC-02, UC-15 | T-05, T-35 | Auth/Admin |
| FR-05 | UC-03 | T-06, T-07 | Pet |
| FR-07 | UC-04 | T-08 | İlan |
| FR-08 | UC-05 | T-09, T-10 | İlan |
| FR-12 | UC-06 | T-11 | Veteriner |
| FR-14 | UC-07 | T-12, T-13 | Randevu |
| FR-16 | UC-08 | T-14, T-15 | Aşı |
| FR-19 | UC-10 | T-17, T-18 | Bakıcı |
| FR-20 | UC-10 | T-19, T-20 | Bakıcı |
| FR-21 | UC-11 | T-21, T-22 | Mesajlaşma |
| FR-22 | UC-11 | T-23 | Socket |
| FR-23 | UC-12 | - | Kayıp/Bulunan |
| FR-25 | UC-13 | T-26 | Sepet |
| FR-26 | UC-13 | T-27, T-30 | Sipariş |
| FR-27 | UC-13 | T-28, T-29 | Kupon |
| FR-28 | UC-14 | - | Seller |
| FR-31 | UC-15 | T-31, T-32 | Admin |
| FR-34 | UC-15 | T-34 | Audit |
| FR-36 | UC-16 | - | Etkinlik |

Bu tablo, analiz ile test arasındaki köprüyü açıkça göstermektedir. Değerlendirme sırasında bu tip izlenebilirlik tabloları rapora ciddi ağırlık katar.

---

### 5. Veri Sözlüğü

#### 5.1 User

| Alan | Açıklama |
|---|---|
| userId | Kullanıcı benzersiz kimliği |
| name | Kullanıcının görünen adı |
| email | Giriş için kullanılan benzersiz e-posta |
| passwordHash | Hashlenmiş parola |
| role | Kullanıcı rolü |
| notificationPreferences | Bildirim tercihleri |
| createdAt | Oluşturulma zamanı |

#### 5.2 Pet

| Alan | Açıklama |
|---|---|
| petId | Pet benzersiz kimliği |
| ownerId | Pet sahibi kullanıcı kimliği |
| name | Pet adı |
| species | Tür bilgisi |
| breed | Irk bilgisi |
| gender | Cinsiyet |
| age | Yaş |
| photos | Fotoğraf listesi |
| location | Konum bilgisi |

#### 5.3 Veterinary

| Alan | Açıklama |
|---|---|
| vetId | Veteriner/klinik kimliği |
| clinicName | Klinik adı |
| address | Adres bilgisi |
| location | Koordinat bilgisi |
| services | Verilen hizmetler |
| rating | Ortalama puan |
| workingHours | Çalışma saatleri |

#### 5.4 Appointment

| Alan | Açıklama |
|---|---|
| appointmentId | Randevu kimliği |
| userId | Randevuyu oluşturan kullanıcı |
| petId | İlgili pet |
| vetId | İlgili veteriner |
| dateTime | Tarih-saat |
| status | Randevu durumu |
| note | Kullanıcı notu |

#### 5.5 VaccinationRecord

| Alan | Açıklama |
|---|---|
| recordId | Aşı kaydı kimliği |
| petId | İlgili pet |
| vaccineName | Aşı adı |
| appliedDate | Uygulanma tarihi |
| nextDueDate | Sonraki tarih |
| status | Tamamlandı/bekleniyor |

#### 5.6 HealthRecord

| Alan | Açıklama |
|---|---|
| recordId | Sağlık kaydı kimliği |
| petId | İlgili pet |
| weight | Kilo bilgisi |
| symptom | Belirti/not |
| medication | İlaç bilgisi |
| createdAt | Kayıt tarihi |

#### 5.7 PetSitter

| Alan | Açıklama |
|---|---|
| sitterId | Bakıcı kimliği |
| userId | Kullanıcı bağlantısı |
| serviceTypes | Hizmet türleri |
| dailyPrice | Günlük veya hizmet bazlı ücret |
| location | Konum bilgisi |
| availability | Müsaitlik durumu |
| rating | Ortalama puan |

#### 5.8 SitterBooking

| Alan | Açıklama |
|---|---|
| bookingId | Rezervasyon kimliği |
| ownerId | Hizmet alan kullanıcı |
| sitterId | Bakıcı kimliği |
| petId | İlgili pet |
| startDate | Başlangıç |
| endDate | Bitiş |
| status | Rezervasyon durumu |
| note | Ek not |

#### 5.9 Store

| Alan | Açıklama |
|---|---|
| storeId | Mağaza kimliği |
| sellerId | Satıcı kullanıcı kimliği |
| name | Mağaza adı |
| description | Açıklama |
| rating | Ortalama puan |

#### 5.10 Product

| Alan | Açıklama |
|---|---|
| productId | Ürün kimliği |
| storeId | Bağlı mağaza |
| categoryId | Kategori |
| name | Ürün adı |
| price | Satış fiyatı |
| stock | Stok miktarı |
| images | Görseller |
| active | Yayın durumu |

#### 5.11 Order

| Alan | Açıklama |
|---|---|
| orderId | Sipariş kimliği |
| userId | Siparişi veren kullanıcı |
| orderNumber | Takip numarası |
| items | Sipariş kalemleri |
| totalAmount | Toplam tutar |
| addressId | Teslimat adresi |
| status | Sipariş durumu |
| createdAt | Oluşturma tarihi |

#### 5.12 Conversation

| Alan | Açıklama |
|---|---|
| conversationId | Konuşma kimliği |
| participantIds | Katılımcı kullanıcılar |
| lastMessage | Son mesaj özeti |
| updatedAt | Son güncelleme |

#### 5.13 Message

| Alan | Açıklama |
|---|---|
| messageId | Mesaj kimliği |
| conversationId | Bağlı konuşma |
| senderId | Gönderen kullanıcı |
| content | Mesaj içeriği |
| attachments | Medya ekleri |
| createdAt | Gönderim zamanı |

#### 5.14 AdoptionApplication

| Alan | Açıklama |
|---|---|
| applicationId | Başvuru kimliği |
| advertId / petId | İlgili ilan veya pet |
| applicantId | Başvuran kullanıcı |
| message | Başvuru açıklaması |
| status | Beklemede/kabul/red |
| createdAt | Oluşturulma zamanı |

#### 5.15 LostFoundPet

| Alan | Açıklama |
|---|---|
| lostFoundId | İlan kimliği |
| ownerId | Oluşturan kullanıcı |
| type | Kayıp veya bulundu |
| description | Açıklama |
| location | Koordinat |
| status | Açık/çözüldü |

#### 5.16 AuditLog

| Alan | Açıklama |
|---|---|
| auditId | Log kimliği |
| actorId | İşlemi yapan kullanıcı |
| action | Yapılan işlem |
| targetType | Etkilenen nesne tipi |
| targetId | Etkilenen nesne kimliği |
| createdAt | Zaman damgası |

---

### 6. Durum Alanları İçin Örnek Yaşam Döngüleri

#### 6.1 Appointment Status

- `pending`
- `confirmed`
- `completed`
- `cancelled`

#### 6.2 SitterBooking Status

- `pending`
- `accepted`
- `rejected`
- `active`
- `completed`
- `cancelled`

#### 6.3 Order Status

- `pending`
- `paid` veya `confirmed`
- `preparing`
- `shipped`
- `delivered`
- `cancelled`

Bu durum alanları, tasarım etkileşim diyagramları ve test senaryoları için temel oluşturmaktadır.

---

### 7. Son Not

Bu ek, projenin soyut düzeyde anlatılmasını değil, gereksinimlerin takip edilebilir hale getirilmesini hedeflemektedir. Final raporlarında en sık görülen eksikliklerden biri, "özellik anlatımı" ile "gereksinim mühendisliği" arasındaki farkın bulanıklaşmasıdır. Bu dosya o açığı kapatmak için hazırlanmıştır.

# 09 Modul Bazli Detayli Analiz

## Ek G: Modül Bazlı Detaylı Analiz

### 1. Amaç

Bu bölüm, Evcil Hayvan Hizmet, Sosyal Ağ ve E-Ticaret Platformu'nun ana modüllerini ayrı ayrı analiz eder. Amaç, sistemi yalnızca genel mimari üzerinden anlatmak yerine her modülün amacı, aktörleri, iş kuralları, veri girdileri, çıktıları, hata durumları ve test ilişkileri ile açıklanmasını sağlamaktır.

Bu yaklaşım raporu gereksiz tekrarlarla büyütmez; her modülün yazılım mühendisliği açısından hangi sorumluluğu taşıdığını görünür hale getirir.

---

### 2. Modül Listesi

| Kod | Modül | Temel Sorumluluk |
|---|---|---|
| M-01 | Kimlik Doğrulama ve Yetkilendirme | Kullanıcı hesabı, giriş, rol ve güvenlik |
| M-02 | Kullanıcı ve Profil Yönetimi | Kullanıcı bilgileri, tercihler ve hesap ayarları |
| M-03 | Pet Yönetimi | Evcil hayvan profili, ilan ve detay yönetimi |
| M-04 | Sahiplendirme ve Başvuru | Sahiplendirme ilanı ve aday başvuru süreci |
| M-05 | Eşleştirme | Çiftleştirme/eşleşme profilleri ve istekler |
| M-06 | Mesajlaşma | Kullanıcılar arası gerçek zamanlı iletişim |
| M-07 | Veteriner ve Randevu | Veteriner bulma, detay ve randevu |
| M-08 | Aşı ve Sağlık Günlüğü | Aşı, kilo, ilaç ve sağlık kayıtları |
| M-09 | Pet Bakıcı ve Rezervasyon | Bakıcı bulma, rezervasyon ve hizmet takibi |
| M-10 | Kayıp/Bulunan Hayvan | Konum tabanlı kayıp/bulunan ilanları |
| M-11 | Sosyal Akış ve Etkinlik | Gönderi, yorum, etkinlik ve topluluk |
| M-12 | Mağaza, Sepet ve Sipariş | E-ticaret, ürün, sepet, sipariş |
| M-13 | Satıcı Paneli | Mağaza, ürün, sipariş ve kupon yönetimi |
| M-14 | Admin ve Moderasyon | Platform denetimi, rapor, kullanıcı yönetimi |
| M-15 | Bildirim ve Arka Plan İşleri | Push bildirim, hatırlatma ve zamanlanmış işler |

---

### 3. M-01 Kimlik Doğrulama ve Yetkilendirme

#### Amaç

Kullanıcıların sisteme güvenli şekilde kayıt olması, giriş yapması, oturumunun korunması ve rolüne göre yetkilendirilmesini sağlar.

#### Aktörler

- Ziyaretçi
- Kayıtlı kullanıcı
- Admin
- Satıcı
- Veteriner
- Pet bakıcısı

#### İşlevler

- Kayıt olma
- Giriş yapma
- Token üretme ve doğrulama
- Rol kontrolü
- Şifre sıfırlama
- Oturum süresi yönetimi

#### İş Kuralları

1. E-posta benzersiz olmalıdır.
2. Şifre düz metin saklanmamalıdır.
3. Admin kaynaklarına yalnızca admin rolü erişebilmelidir.
4. Satıcı paneline yalnızca onaylı satıcı erişebilmelidir.
5. Token geçersizse kullanıcı tekrar girişe yönlendirilmelidir.

#### Veri Girdileri

- E-posta
- Şifre
- Ad soyad
- Rol bilgisi
- Doğrulama kodu

#### Veri Çıktıları

- Access token
- Kullanıcı profili
- Rol bilgisi
- Hata mesajı

#### Hata Durumları

- Yanlış şifre
- Kayıtlı e-posta
- Geçersiz token
- Yetkisiz erişim
- Rate limit aşımı

#### İlgili Testler

- T-01, T-02, T-03, T-04, T-05

---

### 4. M-02 Kullanıcı ve Profil Yönetimi

#### Amaç

Kullanıcının kişisel profilini, iletişim bilgilerini, bildirim tercihlerini ve hesap ayarlarını yönetmesini sağlar.

#### Aktörler

- Kayıtlı kullanıcı
- Admin

#### İşlevler

- Profil görüntüleme
- Profil güncelleme
- Bildirim tercihlerini düzenleme
- Tema ve dil tercihi
- Kullanıcı engelleme veya şikayet etme

#### İş Kuralları

1. Kullanıcı yalnızca kendi profilini güncelleyebilir.
2. Admin gerekli durumlarda kullanıcı durumunu değiştirebilir.
3. Bildirim tercihleri kullanıcı hesabıyla ilişkili saklanmalıdır.
4. Dil ve tema tercihleri cihaz veya hesap bazında korunmalıdır.

#### Veri Girdileri

- Ad soyad
- Telefon
- Profil fotoğrafı
- Bildirim tercihleri
- Dil ve tema seçimi

#### Veri Çıktıları

- Güncel profil
- Tercih bilgileri
- İşlem sonucu

#### Hata Durumları

- Yetkisiz profil erişimi
- Geçersiz telefon formatı
- Fotoğraf yükleme hatası

#### İlgili Testler

- Profil güncelleme testi
- Bildirim tercihi testi
- Yetkisiz profil erişim testi

---

### 5. M-03 Pet Yönetimi

#### Amaç

Kullanıcının evcil hayvan profillerini oluşturması, güncellemesi ve ilgili ilan/hizmet süreçlerinde kullanmasını sağlar.

#### Aktörler

- Kayıtlı kullanıcı
- Admin

#### İşlevler

- Pet ekleme
- Pet düzenleme
- Pet detay görüntüleme
- Fotoğraf yükleme
- Konum bilgisi ekleme
- Pet sağlık kartına geçiş

#### İş Kuralları

1. Her pet bir kullanıcıya bağlı olmalıdır.
2. Pet silinirse ilişkili aktif ilan ve başvurular kontrol edilmelidir.
3. Tür, cinsiyet ve yaş gibi alanlar doğrulanmalıdır.
4. Fotoğraf boyutu ve türü kısıtlanmalıdır.

#### Veri Girdileri

- Pet adı
- Tür
- Cins
- Yaş
- Cinsiyet
- Fotoğraf
- Konum

#### Veri Çıktıları

- Pet listesi
- Pet detay sayfası
- Sağlık ve ilan bağlantıları

#### Hata Durumları

- Eksik zorunlu alan
- Geçersiz tür bilgisi
- Yetkisiz düzenleme
- Medya yükleme hatası

#### İlgili Testler

- T-06, T-07

---

### 6. M-04 Sahiplendirme ve Başvuru

#### Amaç

Kullanıcıların sahiplendirme ilanı açmasını ve diğer kullanıcıların bu ilanlara başvuru yapmasını sağlar.

#### Aktörler

- İlan sahibi
- Başvuran kullanıcı
- Admin

#### İşlevler

- Sahiplendirme ilanı oluşturma
- Başvuru gönderme
- Başvuru listeleme
- Başvuru kabul/red
- İlan durumunu güncelleme

#### İş Kuralları

1. Kullanıcı kendi ilanına başvuramaz.
2. Aynı kullanıcı aynı ilana birden fazla başvuru yapamaz.
3. İlan pasifse başvuru alınamaz.
4. Kabul edilen başvuru sonrası ilan kapatılabilir.

#### Veri Girdileri

- Pet seçimi
- İlan açıklaması
- Başvuru mesajı
- Başvuru durumu

#### Veri Çıktıları

- İlan listesi
- Başvuru listesi
- Bildirim
- Başvuru durumu

#### Hata Durumları

- İlan bulunamadı
- Başvuru tekrarı
- Yetkisiz başvuru durumu değiştirme

#### İlgili Testler

- T-08, T-09, T-10

---

### 7. M-05 Eşleştirme

#### Amaç

Evcil hayvanların çiftleştirme veya uygun eşleşme amacıyla profil bazlı görüntülenmesi ve istek gönderilmesini sağlar.

#### Aktörler

- Pet sahibi
- Eşleşme isteği alan kullanıcı

#### İşlevler

- Eşleşme profili görüntüleme
- Beğenme veya geçme
- Eşleşme isteği gönderme
- Gelen/giden istekleri listeleme
- İsteği kabul veya reddetme

#### İş Kuralları

1. Kullanıcı kendi petine istek gönderemez.
2. Pasif pet profilleri eşleştirmede görünmemelidir.
3. Aynı petler arasında tekrar eden istekler sınırlandırılmalıdır.
4. Engellenen kullanıcılar eşleştirme akışında görünmemelidir.

#### Veri Girdileri

- Pet profili
- Eşleşme tercihi
- Beğeni/geçme aksiyonu

#### Veri Çıktıları

- Önerilen profiller
- Eşleşme isteği durumu
- Bildirim

#### Hata Durumları

- Profil bulunamadı
- Tekrar eden istek
- Yetkisiz işlem

---

### 8. M-06 Mesajlaşma

#### Amaç

Kullanıcıların ilan, başvuru, randevu, bakım veya sipariş süreçleriyle ilişkili olarak gerçek zamanlı iletişim kurmasını sağlar.

#### Aktörler

- Kayıtlı kullanıcı
- Satıcı
- Bakıcı
- Veteriner

#### İşlevler

- Konuşma başlatma
- Mesaj gönderme
- Mesaj listeleme
- Socket odasına katılma
- Çevrim içi/çevrim dışı durum
- Push bildirim fallback

#### İş Kuralları

1. Kullanıcı yalnızca tarafı olduğu konuşmaya mesaj gönderebilir.
2. Engellenen kullanıcılar arasında mesajlaşma sınırlandırılmalıdır.
3. Mesaj veritabanına kaydedilmeden alıcıya başarılı sonucu gösterilmemelidir.
4. Alıcı çevrim dışıysa push bildirim tetiklenebilir.

#### Veri Girdileri

- Konuşma kimliği
- Mesaj içeriği
- Ek dosya
- Gönderen kullanıcı

#### Veri Çıktıları

- Mesaj listesi
- Okundu/iletildi durumu
- Bildirim

#### Hata Durumları

- Konuşma bulunamadı
- Yetkisiz konuşma erişimi
- Socket bağlantısı kopması
- Medya gönderim hatası

#### İlgili Diyagram

- `sequence_realtime_message`

---

### 9. M-07 Veteriner ve Randevu

#### Amaç

Kullanıcının konumuna yakın veterinerleri bulması, klinik detaylarını incelemesi ve randevu almasını sağlar.

#### Aktörler

- Kullanıcı
- Veteriner
- Admin

#### İşlevler

- Yakın veterinerleri listeleme
- Veteriner detay görüntüleme
- Müsait slot sorgulama
- Randevu oluşturma
- Randevu durumu güncelleme
- Veteriner yorumu

#### İş Kuralları

1. Geçmiş tarihe randevu oluşturulamaz.
2. Aynı slot için çakışan randevu alınamaz.
3. Randevu oluşturmak için kullanıcının pet profili olmalıdır.
4. Veteriner pasifse yeni randevu alınamaz.

#### Veri Girdileri

- Konum
- Veteriner kimliği
- Pet kimliği
- Tarih-saat
- Randevu notu

#### Veri Çıktıları

- Veteriner listesi
- Slot listesi
- Randevu durumu
- Bildirim

#### Hata Durumları

- Konum izni yok
- Slot dolu
- Veteriner bulunamadı
- Pet seçilmedi

#### İlgili Testler

- T-11, T-12, T-13

---

### 10. M-08 Aşı ve Sağlık Günlüğü

#### Amaç

Pet sağlık geçmişinin, aşı kayıtlarının, kilo değişimlerinin ve bakım notlarının merkezi olarak tutulmasını sağlar.

#### Aktörler

- Kullanıcı
- Veteriner

#### İşlevler

- Aşı kaydı ekleme
- Sonraki aşı tarihi belirleme
- Sağlık kaydı ekleme
- Kilo takibi
- Hatırlatma üretme

#### İş Kuralları

1. Sonraki aşı tarihi uygulama tarihinden önce olamaz.
2. Sağlık kayıtları ilgili pet ile ilişkilendirilmelidir.
3. Hatırlatma tercihi kapalıysa push gönderilmemelidir.
4. Kullanıcı başkasına ait pet sağlık kaydına erişemez.

#### Veri Girdileri

- Aşı adı
- Uygulama tarihi
- Sonraki tarih
- Kilo
- İlaç/not

#### Veri Çıktıları

- Aşı takvimi
- Sağlık geçmişi
- Grafiksel kilo değişimi
- Hatırlatma

#### Hata Durumları

- Geçersiz tarih
- Yetkisiz pet erişimi
- Eksik aşı adı

---

### 11. M-09 Pet Bakıcı ve Rezervasyon

#### Amaç

Kullanıcının güvenilir pet bakıcısı bulmasını, rezervasyon oluşturmasını ve hizmet durumunu takip etmesini sağlar.

#### Aktörler

- Kullanıcı
- Pet bakıcısı
- Admin

#### İşlevler

- Bakıcı listesi
- Bakıcı detay
- Bakıcı profili oluşturma
- Rezervasyon oluşturma
- Rezervasyon kabul/red
- Canlı hizmet durumu
- Bakım raporu

#### İş Kuralları

1. Geçmiş tarihli rezervasyon oluşturulamaz.
2. Başlangıç tarihi bitiş tarihinden sonra olamaz.
3. Bakıcı pasifse rezervasyon alınamaz.
4. Aktif hizmette durum değişiklikleri loglanmalıdır.

#### Veri Girdileri

- Bakıcı kimliği
- Pet kimliği
- Hizmet türü
- Tarih aralığı
- Hizmet notu

#### Veri Çıktıları

- Rezervasyon durumu
- Bakıcı bildirimi
- Canlı takip durumu
- Bakım raporu

#### Hata Durumları

- Tarih çakışması
- Bakıcı bulunamadı
- Yetkisiz durum güncelleme

---

### 12. M-10 Kayıp/Bulunan Hayvan

#### Amaç

Kayıp veya bulunan hayvan ilanlarının konum tabanlı olarak yayınlanmasını sağlar.

#### Aktörler

- Kullanıcı
- Admin

#### İşlevler

- Kayıp ilanı oluşturma
- Bulunan ilanı oluşturma
- Harita üzerinde görüntüleme
- Yakındaki ilanları listeleme
- İlanı çözüldü olarak işaretleme

#### İş Kuralları

1. İlan tipi kayıp veya bulundu olmalıdır.
2. Konum bilgisi yoksa yakınlık sıralaması yapılamaz.
3. Çözülen ilanlar arama sonuçlarında farklı gösterilmelidir.
4. Uygunsuz ilanlar admin tarafından kaldırılabilir.

#### Veri Girdileri

- İlan tipi
- Açıklama
- Fotoğraf
- Konum
- İletişim tercihi

#### Veri Çıktıları

- Harita marker'ları
- Yakın ilan listesi
- İlan durumu

#### Hata Durumları

- Konum alınamadı
- Eksik açıklama
- Fotoğraf yükleme hatası

---

### 13. M-11 Sosyal Akış ve Etkinlik

#### Amaç

Kullanıcıların pet odaklı sosyal gönderiler paylaşmasını, yorum yapmasını, etkinlik oluşturmasını ve toplulukla etkileşim kurmasını sağlar.

#### Aktörler

- Kullanıcı
- Admin

#### İşlevler

- Gönderi oluşturma
- Gönderi beğenme
- Yorum yapma
- Etkinlik oluşturma
- Etkinliğe katılma
- İçerik şikayeti

#### İş Kuralları

1. Uygunsuz içerikler şikayet edilebilir.
2. Kullanıcı aynı etkinliğe bir kez katılabilir.
3. Kontenjan doluysa katılım alınamaz.
4. Silinen gönderiler sosyal akışta görünmemelidir.

#### Veri Girdileri

- Gönderi metni
- Görsel
- Yorum
- Etkinlik tarihi
- Etkinlik konumu

#### Veri Çıktıları

- Sosyal akış
- Yorum listesi
- Etkinlik katılım bilgisi
- Şikayet kaydı

#### Hata Durumları

- İçerik boş
- Etkinlik tarihi geçmiş
- Kontenjan dolu

---

### 14. M-12 Mağaza, Sepet ve Sipariş

#### Amaç

Kullanıcıların evcil hayvan ürünlerini görüntülemesi, sepete eklemesi, kupon kullanması ve sipariş oluşturmasını sağlar.

#### Aktörler

- Kullanıcı
- Satıcı
- Admin

#### İşlevler

- Ürün listeleme
- Ürün detay
- Sepete ekleme
- Adres seçme
- Kupon uygulama
- Sipariş oluşturma
- Sipariş takip

#### İş Kuralları

1. Stok yoksa sipariş oluşturulamaz.
2. Kupon süresi dolmuşsa uygulanamaz.
3. Adres olmadan sipariş tamamlanamaz.
4. Sipariş durumları belirli sırayla ilerlemelidir.

#### Veri Girdileri

- Ürün kimliği
- Adet
- Kupon kodu
- Adres
- Sipariş notu

#### Veri Çıktıları

- Sepet özeti
- Toplam tutar
- Sipariş numarası
- Sipariş durumu

#### Hata Durumları

- Stok yetersiz
- Kupon geçersiz
- Adres eksik
- Ödeme/sipariş onay hatası

---

### 15. M-13 Satıcı Paneli

#### Amaç

Satıcıların mağaza profili, ürünleri, siparişleri, kuponları ve satış performansını yönetmesini sağlar.

#### Aktörler

- Satıcı
- Admin

#### İşlevler

- Satıcı başvurusu
- Mağaza profili düzenleme
- Ürün ekleme/düzenleme
- Sipariş listeleme
- Sipariş durumu güncelleme
- Kupon oluşturma
- Satış analitiği

#### İş Kuralları

1. Satıcı yalnızca kendi mağazasındaki ürünleri yönetebilir.
2. Ürün fiyatı ve stok negatif olamaz.
3. Sipariş durumu geriye dönük keyfi değiştirilememelidir.
4. Satıcı başvurusu admin onayına bağlı olabilir.

#### Veri Girdileri

- Mağaza adı
- Ürün bilgileri
- Fiyat/stok
- Kupon koşulları
- Sipariş durumu

#### Veri Çıktıları

- Satıcı dashboard
- Ürün listesi
- Sipariş listesi
- Kupon listesi

---

### 16. M-14 Admin ve Moderasyon

#### Amaç

Platformun güvenli, düzenli ve sürdürülebilir çalışması için kullanıcı, içerik, satıcı, veteriner ve şikayet süreçlerini yönetir.

#### Aktörler

- Admin

#### İşlevler

- Kullanıcı listeleme
- İçerik denetleme
- Şikayet inceleme
- Satıcı başvurusu değerlendirme
- Veteriner doğrulama
- Raporlama
- Audit log inceleme

#### İş Kuralları

1. Admin işlemleri audit log'a yazılmalıdır.
2. İçerik kaldırma kararı gerekçeli olmalıdır.
3. Kullanıcı kısıtlama işlemi geri alınabilir olmalıdır.
4. Kritik işlemler yalnızca yetkili admin tarafından yapılmalıdır.

#### Veri Girdileri

- Moderasyon kararı
- Kullanıcı durumu
- Şikayet notu
- Onay/red gerekçesi

#### Veri Çıktıları

- Moderasyon kuyruğu
- Audit log
- Raporlar
- Yönetim dashboard

---

### 17. M-15 Bildirim ve Arka Plan İşleri

#### Amaç

Mesaj, randevu, sipariş, aşı, rezervasyon ve sistem olaylarının kullanıcılara zamanında iletilmesini sağlar.

#### Aktörler

- Sistem
- Kullanıcı
- Firebase FCM

#### İşlevler

- Push bildirim gönderme
- Aşı hatırlatma
- Randevu hatırlatma
- Sipariş durum bildirimi
- Rezervasyon bildirimi
- Doğum günü veya ilan süresi hatırlatma

#### İş Kuralları

1. Kullanıcının bildirim tercihi dikkate alınmalıdır.
2. Başarısız bildirimler loglanmalıdır.
3. Aynı olay için tekrar eden bildirim gönderimi sınırlandırılmalıdır.
4. Arka plan işleri sunucu yükünü aşırı artırmamalıdır.

#### Veri Girdileri

- Olay tipi
- Kullanıcı cihaz token'ı
- Bildirim tercihi
- Zamanlanmış görev bilgisi

#### Veri Çıktıları

- Push bildirimi
- Bildirim logu
- Hatırlatma kaydı

---

### 18. Modül Önceliklendirme

| Modül | MVP Önceliği | Gerekçe |
|---|---|---|
| Kimlik doğrulama | Çok yüksek | Tüm sistemin giriş noktasıdır |
| Pet yönetimi | Çok yüksek | Platformun ana veri varlığıdır |
| Veteriner/randevu | Yüksek | Kullanıcı değeri yüksektir |
| Bakıcı/rezervasyon | Yüksek | Hizmet platformu karakterini güçlendirir |
| Mağaza/sipariş | Yüksek | Ticari modül sağlar |
| Mesajlaşma | Yüksek | Aktörler arası iletişim gerekir |
| Admin | Yüksek | Güvenlik ve moderasyon için zorunludur |
| Sosyal akış | Orta | Topluluk etkisi sağlar |
| Etkinlik | Orta | Yan değer üretir |
| Gelişmiş analitik | Düşük | MVP sonrası genişletilebilir |

---

### 19. Sonuç

Bu modül bazlı analiz, sistemin tek bir uygulama gibi değil, birbirine bağlı alt sistemlerden oluşan dağıtık bir platform olarak tasarlandığını gösterir. Her modülün aktörleri, iş kuralları ve hata durumları ayrı ele alındığında hem test planı hem de UML diyagramları daha tutarlı hale gelir.

# 13 Api Sozlesme Ve Endpoint Analizi

## Ek K: API Sözleşmesi ve Endpoint Analizi

### 1. Amaç

Bu bölüm, mobil uygulama, admin paneli ve satıcı panelinin backend ile nasıl haberleşeceğini açıklayan API sözleşmesi özetini içerir. API sözleşmesi, istemci ve sunucu ekiplerinin aynı iş kuralları ve veri formatları üzerinden çalışmasını sağlar.

---

### 2. API Tasarım İlkeleri

1. Endpoint'ler kaynak odaklı adlandırılmalıdır.
2. Korumalı endpoint'lerde JWT doğrulaması yapılmalıdır.
3. Hata cevapları standart formatta dönmelidir.
4. Liste endpoint'leri sayfalama ve filtreleme desteklemelidir.
5. Kritik işlemler sunucu tarafında yeniden doğrulanmalıdır.

---

### 3. Standart Cevap Formatı

Başarılı cevap:

```json
{
  "success": true,
  "data": {},
  "message": "İşlem başarılı"
}
```

Hatalı cevap:

```json
{
  "success": false,
  "message": "İşlem başarısız",
  "code": "validation_error"
}
```

---

### 4. Auth Endpoint'leri

| Method | Endpoint | Açıklama | Yetki |
|---|---|---|---|
| POST | `/api/auth/register` | Kullanıcı kaydı | Public |
| POST | `/api/auth/login` | Kullanıcı girişi | Public |
| GET | `/api/auth/me` | Oturum kullanıcısı | User |
| PATCH | `/api/auth/me` | Profil güncelleme | User |
| POST | `/api/auth/forgot-password` | Şifre sıfırlama | Public |

#### Örnek Login İsteği

```json
{
  "email": "user@example.com",
  "password": "secret"
}
```

#### İş Kuralları

- Hatalı giriş denemeleri sınırlandırılmalıdır.
- Şifre hashlenmiş olarak saklanmalıdır.
- Token süresi kontrol edilmelidir.

---

### 5. Pet ve İlan Endpoint'leri

| Method | Endpoint | Açıklama | Yetki |
|---|---|---|---|
| GET | `/api/pets` | Pet/ilan listesi | User |
| POST | `/api/pets` | Pet oluşturma | User |
| GET | `/api/pets/:id` | Pet detay | User |
| PATCH | `/api/pets/:id` | Pet güncelleme | Owner |
| DELETE | `/api/pets/:id` | Pet silme/pasifleştirme | Owner |
| GET | `/api/my-adverts` | Kullanıcının ilanları | User |

#### İş Kuralları

- Kullanıcı yalnızca kendi petini düzenleyebilir.
- Pet ile ilişkili aktif süreçler silmeden önce kontrol edilmelidir.

---

### 6. Sahiplendirme Endpoint'leri

| Method | Endpoint | Açıklama | Yetki |
|---|---|---|---|
| POST | `/api/adoption-applications` | Başvuru oluşturma | User |
| GET | `/api/adoption-applications/me` | Kullanıcının başvuruları | User |
| GET | `/api/adoption-applications/advert/:id` | İlan başvuruları | Owner |
| PATCH | `/api/adoption-applications/:id/status` | Kabul/red | Owner |

#### İş Kuralları

- Kullanıcı kendi ilanına başvuramaz.
- Aynı ilana tekrar başvuru yapılamaz.

---

### 7. Veteriner ve Randevu Endpoint'leri

| Method | Endpoint | Açıklama | Yetki |
|---|---|---|---|
| GET | `/api/veterinaries` | Veteriner listesi | User |
| GET | `/api/veterinaries/nearby` | Yakın veterinerler | User |
| GET | `/api/veterinaries/:id` | Veteriner detay | User |
| POST | `/api/appointments` | Randevu oluşturma | User |
| GET | `/api/appointments/me` | Kullanıcı randevuları | User |
| GET | `/api/appointments/vet/:id/slots` | Müsait slotlar | User |
| PATCH | `/api/appointments/:id/status` | Randevu durumu | Vet/Admin |

#### İş Kuralları

- Slot çakışması engellenmelidir.
- Geçmiş tarihe randevu alınmamalıdır.

---

### 8. Aşı ve Sağlık Endpoint'leri

| Method | Endpoint | Açıklama | Yetki |
|---|---|---|---|
| GET | `/api/vaccinations` | Aşı kayıtları | User |
| POST | `/api/vaccinations` | Aşı kaydı ekleme | User |
| PATCH | `/api/vaccinations/:id` | Aşı güncelleme | Owner |
| GET | `/api/health/:petId` | Sağlık kayıtları | Owner |
| POST | `/api/health` | Sağlık kaydı ekleme | Owner |

#### İş Kuralları

- Sağlık verisi sadece pet sahibi tarafından görüntülenebilmelidir.
- Hatırlatma tercihleri dikkate alınmalıdır.

---

### 9. Bakıcı Endpoint'leri

| Method | Endpoint | Açıklama | Yetki |
|---|---|---|---|
| GET | `/api/pet-sitters` | Bakıcı listesi | User |
| GET | `/api/pet-sitters/:id` | Bakıcı detay | User |
| POST | `/api/pet-sitters` | Bakıcı profili | User |
| POST | `/api/sitter-bookings` | Rezervasyon oluşturma | User |
| GET | `/api/sitter-bookings/me` | Kullanıcı rezervasyonları | User |
| PATCH | `/api/sitter-bookings/:id/status` | Durum güncelleme | Sitter/Owner |

#### İş Kuralları

- Tarih aralığı kontrol edilmelidir.
- Sadece ilgili bakıcı rezervasyon durumunu kabul/red yapabilmelidir.

---

### 10. Mesajlaşma Endpoint'leri

| Method | Endpoint | Açıklama | Yetki |
|---|---|---|---|
| GET | `/api/conversations` | Konuşma listesi | User |
| POST | `/api/conversations` | Konuşma oluşturma | User |
| GET | `/api/conversations/:id/messages` | Mesaj listesi | Participant |
| POST | `/api/conversations/:id/messages` | Mesaj gönderme | Participant |

#### Socket Olayları

| Olay | Açıklama |
|---|---|
| `join:conversation` | Konuşma odasına katılma |
| `message:new` | Yeni mesaj yayını |
| `leave:conversation` | Odadan ayrılma |

---

### 11. Mağaza ve Sipariş Endpoint'leri

| Method | Endpoint | Açıklama | Yetki |
|---|---|---|---|
| GET | `/api/stores` | Mağaza listesi | User |
| GET | `/api/products` | Ürün listesi | User |
| GET | `/api/products/:id` | Ürün detay | User |
| POST | `/api/cart` | Sepete ekleme | User |
| GET | `/api/cart` | Sepet görüntüleme | User |
| POST | `/api/orders` | Sipariş oluşturma | User |
| GET | `/api/orders/me` | Kullanıcı siparişleri | User |
| PATCH | `/api/orders/:id/status` | Sipariş durumu | Seller/Admin |

#### İş Kuralları

- Stok sunucu tarafında doğrulanmalıdır.
- Kupon kullanım limiti kontrol edilmelidir.
- Sipariş durumu state diyagramına uygun ilerlemelidir.

---

### 12. Admin Endpoint'leri

| Method | Endpoint | Açıklama | Yetki |
|---|---|---|---|
| GET | `/api/admin/users` | Kullanıcı listesi | Admin |
| GET | `/api/admin/reports` | Rapor listesi | Admin |
| PATCH | `/api/admin/users/:id/status` | Kullanıcı durumu | Admin |
| GET | `/api/admin/audit-logs` | Audit log | Admin |
| PATCH | `/api/admin/seller-applications/:id` | Satıcı başvurusu | Admin |

#### İş Kuralları

- Tüm admin işlemleri audit log'a yazılmalıdır.
- Admin dışı roller erişememelidir.

---

### 13. API Hata Kodları

| Kod | Anlamı |
|---|---|
| `validation_error` | Girdi doğrulama hatası |
| `unauthorized` | Giriş yapılmamış |
| `forbidden` | Yetki yok |
| `not_found` | Kayıt bulunamadı |
| `conflict` | Çakışan kayıt |
| `rate_limit` | İstek sınırı aşıldı |
| `internal_error` | Sunucu hatası |

---

### 14. Sonuç

API sözleşmesi, mobil ve web istemcilerin backend ile tutarlı haberleşmesini sağlar. Bu bölüm rapora eklendiğinde sistemin yalnızca arayüz veya veri modeliyle değil, servis sözleşmeleriyle de analiz edildiği gösterilmiş olur.

# 14 Detayli Veritabani Tasarimi

## Ek L: Detaylı Veritabanı Tasarımı

### 1. Amaç

Bu bölüm, sistemin veri modelini daha ayrıntılı açıklar. MongoDB belge tabanlı yapı kullanıldığı için klasik ilişkisel tablo mantığı yerine koleksiyon, belge, referans ve indeks yaklaşımı benimsenmiştir.

---

### 2. Veritabanı Tasarım İlkeleri

1. Her ana iş nesnesi ayrı koleksiyonla temsil edilmelidir.
2. Sık sorgulanan alanlarda indeks kullanılmalıdır.
3. Kullanıcı sahipliği gerektiren verilerde `ownerId`, `userId` veya benzeri referans tutulmalıdır.
4. Durum alanları kontrollü değerlerden oluşmalıdır.
5. Audit gerektiren işlemler loglanmalıdır.
6. Konum tabanlı veriler GeoJSON formatına uygun saklanmalıdır.

---

### 3. Koleksiyon Grupları

| Grup | Koleksiyonlar |
|---|---|
| Kullanıcı | users, addresses, auditlogs |
| Pet | pets, healthrecords, vaccinationrecords |
| İlan | adoptionapplications, matchrequests, interactions, favorites |
| Hizmet | veterinaries, appointments, petsitters, sitterbookings |
| Sosyal | posts, comments, events, eventattendances |
| Ticaret | stores, products, categories, cartitems, orders, coupons |
| İletişim | conversations, messages, supporttickets |
| Moderasyon | userreports, auditlogs |

---

### 4. Temel Koleksiyon Tanımları

#### 4.1 users

| Alan | Tip | Zorunlu | Açıklama |
|---|---|---|---|
| _id | ObjectId | Evet | Kullanıcı kimliği |
| name | String | Evet | Ad soyad |
| email | String | Evet | Benzersiz e-posta |
| passwordHash | String | Evet | Hashlenmiş şifre |
| role | String | Evet | user/admin/seller/vet |
| notificationPreferences | Object | Hayır | Bildirim tercihleri |
| createdAt | Date | Evet | Oluşturulma tarihi |

Önerilen indeksler:

- `email` unique
- `role`

#### 4.2 pets

| Alan | Tip | Zorunlu | Açıklama |
|---|---|---|---|
| _id | ObjectId | Evet | Pet kimliği |
| ownerId | ObjectId | Evet | Kullanıcı referansı |
| name | String | Evet | Pet adı |
| species | String | Evet | Tür |
| breed | String | Hayır | Irk |
| gender | String | Hayır | Cinsiyet |
| age | Number | Hayır | Yaş |
| photos | Array | Hayır | Fotoğraf URL'leri |
| location | GeoJSON | Hayır | Konum |
| status | String | Evet | Aktif/pasif |

Önerilen indeksler:

- `ownerId`
- `species`
- `location` 2dsphere

#### 4.3 adoptionapplications

| Alan | Tip | Zorunlu | Açıklama |
|---|---|---|---|
| _id | ObjectId | Evet | Başvuru kimliği |
| petId | ObjectId | Evet | İlgili pet |
| applicantId | ObjectId | Evet | Başvuran kullanıcı |
| ownerId | ObjectId | Evet | İlan sahibi |
| message | String | Hayır | Başvuru mesajı |
| status | String | Evet | pending/accepted/rejected |
| createdAt | Date | Evet | Başvuru tarihi |

Önerilen indeksler:

- `petId`
- `applicantId`
- `status`

#### 4.4 veterinaries

| Alan | Tip | Zorunlu | Açıklama |
|---|---|---|---|
| _id | ObjectId | Evet | Veteriner kimliği |
| clinicName | String | Evet | Klinik adı |
| address | String | Hayır | Adres |
| location | GeoJSON | Evet | Konum |
| services | Array | Hayır | Hizmet listesi |
| workingHours | Object | Hayır | Çalışma saatleri |
| rating | Number | Hayır | Ortalama puan |

Önerilen indeksler:

- `location` 2dsphere
- `clinicName`

#### 4.5 appointments

| Alan | Tip | Zorunlu | Açıklama |
|---|---|---|---|
| _id | ObjectId | Evet | Randevu kimliği |
| userId | ObjectId | Evet | Kullanıcı |
| petId | ObjectId | Evet | Pet |
| vetId | ObjectId | Evet | Veteriner |
| dateTime | Date | Evet | Randevu zamanı |
| status | String | Evet | pending/confirmed/completed/cancelled |
| note | String | Hayır | Kullanıcı notu |

Önerilen indeksler:

- `userId`
- `vetId, dateTime`
- `status`

#### 4.6 vaccinationrecords

| Alan | Tip | Zorunlu | Açıklama |
|---|---|---|---|
| _id | ObjectId | Evet | Kayıt kimliği |
| petId | ObjectId | Evet | Pet |
| vaccineName | String | Evet | Aşı adı |
| appliedDate | Date | Hayır | Uygulama tarihi |
| nextDueDate | Date | Hayır | Sonraki tarih |
| status | String | Evet | due/done |

Önerilen indeksler:

- `petId`
- `nextDueDate`

#### 4.7 petsitters

| Alan | Tip | Zorunlu | Açıklama |
|---|---|---|---|
| _id | ObjectId | Evet | Bakıcı kimliği |
| userId | ObjectId | Evet | Kullanıcı |
| serviceTypes | Array | Evet | Hizmet türleri |
| location | GeoJSON | Hayır | Konum |
| rating | Number | Hayır | Ortalama puan |
| active | Boolean | Evet | Aktiflik |

Önerilen indeksler:

- `userId`
- `location` 2dsphere
- `active`

#### 4.8 sitterbookings

| Alan | Tip | Zorunlu | Açıklama |
|---|---|---|---|
| _id | ObjectId | Evet | Rezervasyon kimliği |
| ownerId | ObjectId | Evet | Pet sahibi |
| sitterId | ObjectId | Evet | Bakıcı |
| petId | ObjectId | Evet | Pet |
| startDate | Date | Evet | Başlangıç |
| endDate | Date | Evet | Bitiş |
| status | String | Evet | pending/accepted/active/completed/cancelled |

Önerilen indeksler:

- `ownerId`
- `sitterId`
- `startDate, endDate`

#### 4.9 stores

| Alan | Tip | Zorunlu | Açıklama |
|---|---|---|---|
| _id | ObjectId | Evet | Mağaza kimliği |
| sellerId | ObjectId | Evet | Satıcı |
| name | String | Evet | Mağaza adı |
| description | String | Hayır | Açıklama |
| rating | Number | Hayır | Ortalama puan |
| active | Boolean | Evet | Aktiflik |

#### 4.10 products

| Alan | Tip | Zorunlu | Açıklama |
|---|---|---|---|
| _id | ObjectId | Evet | Ürün kimliği |
| storeId | ObjectId | Evet | Mağaza |
| categoryId | ObjectId | Hayır | Kategori |
| name | String | Evet | Ürün adı |
| price | Number | Evet | Fiyat |
| stock | Number | Evet | Stok |
| images | Array | Hayır | Görseller |
| active | Boolean | Evet | Yayın durumu |

Önerilen indeksler:

- `storeId`
- `categoryId`
- `price`
- `active`

#### 4.11 orders

| Alan | Tip | Zorunlu | Açıklama |
|---|---|---|---|
| _id | ObjectId | Evet | Sipariş kimliği |
| userId | ObjectId | Evet | Sipariş sahibi |
| orderNumber | String | Evet | Takip numarası |
| items | Array | Evet | Sipariş kalemleri |
| totalAmount | Number | Evet | Toplam tutar |
| addressId | ObjectId | Evet | Teslimat adresi |
| status | String | Evet | pending/confirmed/preparing/shipped/delivered |

Önerilen indeksler:

- `userId`
- `orderNumber` unique
- `status`

#### 4.12 conversations

| Alan | Tip | Zorunlu | Açıklama |
|---|---|---|---|
| _id | ObjectId | Evet | Konuşma kimliği |
| participants | Array | Evet | Katılımcılar |
| lastMessage | Object | Hayır | Son mesaj özeti |
| updatedAt | Date | Evet | Güncelleme zamanı |

#### 4.13 messages

| Alan | Tip | Zorunlu | Açıklama |
|---|---|---|---|
| _id | ObjectId | Evet | Mesaj kimliği |
| conversationId | ObjectId | Evet | Konuşma |
| senderId | ObjectId | Evet | Gönderen |
| content | String | Hayır | Mesaj içeriği |
| attachments | Array | Hayır | Ek dosyalar |
| createdAt | Date | Evet | Gönderim zamanı |

Önerilen indeksler:

- `conversationId, createdAt`
- `senderId`

#### 4.14 auditlogs

| Alan | Tip | Zorunlu | Açıklama |
|---|---|---|---|
| _id | ObjectId | Evet | Log kimliği |
| actorId | ObjectId | Evet | İşlemi yapan |
| action | String | Evet | İşlem tipi |
| targetType | String | Evet | Etkilenen nesne |
| targetId | ObjectId | Hayır | Etkilenen kayıt |
| createdAt | Date | Evet | Zaman |

---

### 5. Veri Güvenliği İlkeleri

1. Şifreler hashlenmiş saklanmalıdır.
2. Hassas alanlar loglara yazılmamalıdır.
3. Admin işlemleri audit log ile izlenmelidir.
4. Konum verileri yalnızca ihtiyaç duyulan süreçlerde kullanılmalıdır.
5. Kullanıcı silme veya veri talebi için prosedür tanımlanmalıdır.

---

### 6. Veri Bütünlüğü Kuralları

| Kural | Açıklama |
|---|---|
| Sahiplik kontrolü | Kullanıcı yalnızca kendi verisini düzenleyebilir |
| Durum geçişi | Randevu, sipariş ve rezervasyon durumları kontrollü ilerler |
| Referans kontrolü | Silinen kullanıcı/pet ilişkili kayıtları etkiler |
| Tekillik | E-posta ve sipariş numarası benzersizdir |
| Tarih mantığı | Başlangıç tarihi bitişten sonra olamaz |

---

### 7. Sonuç

Bu veritabanı tasarımı, sistemin çok modüllü yapısına uygun olacak biçimde koleksiyon tabanlı kurgulanmıştır. MongoDB esnekliği sayesinde modüller genişletilebilir; ancak veri bütünlüğü, yetkilendirme ve indeksleme kuralları doğru uygulanmadığında sistem güvenilirliği azalır. Bu nedenle veri modeli yalnızca teknik kayıt yapısı değil, iş kurallarının kalıcılığını sağlayan temel katman olarak değerlendirilmelidir.

# 10 Ekran Tasarimlari Ve Arayuz Akislari

## Ek H: Ekran Tasarımları ve Arayüz Akışları

### 1. Amaç

Bu bölüm, mobil uygulama, admin paneli ve satıcı panelinde yer alan temel ekranları yazılım mühendisliği bakışıyla açıklar. Her ekranın amacı, aktörü, giriş verisi, ürettiği çıktı ve hata durumları belirtilmiştir. Word raporuna ekran görüntüleri eklenecekse bu bölüm görsellerin alt açıklamalarına temel oluşturur.

---

### 2. Mobil Uygulama Ekranları

| Ekran | Aktör | Amaç |
|---|---|---|
| Splash | Tüm kullanıcılar | Oturum ve ilk açılış kontrolü |
| Onboarding | Yeni kullanıcı | Uygulamayı tanıtma |
| Giriş | Ziyaretçi | Kimlik doğrulama |
| Kayıt | Ziyaretçi | Yeni hesap oluşturma |
| Ana Sayfa | Kullanıcı | Pet, ilan ve hızlı modül erişimi |
| Pet Ekle | Kullanıcı | Pet profili oluşturma |
| Pet Detay | Kullanıcı | Pet bilgilerini ve aksiyonları görüntüleme |
| Sahiplendirme | Kullanıcı | İlanları listeleme ve başvuru |
| Eşleştirme | Kullanıcı | Swipe/match akışı |
| Mesajlar | Kullanıcı | Konuşma listesi |
| Sohbet | Kullanıcı | Gerçek zamanlı mesajlaşma |
| Veteriner Arama | Kullanıcı | Yakın veterinerleri bulma |
| Veteriner Detay | Kullanıcı | Klinik bilgisi ve randevu |
| Randevu Oluştur | Kullanıcı | Tarih/saat seçimi |
| Aşı Takvimi | Kullanıcı | Aşı kayıtları ve hatırlatmalar |
| Sağlık Günlüğü | Kullanıcı | Kilo, ilaç, not takibi |
| Bakıcı Listesi | Kullanıcı | Pet bakıcılarını görüntüleme |
| Bakıcı Detay | Kullanıcı | Bakıcı profili ve rezervasyon |
| Rezervasyon | Kullanıcı | Hizmet tarihi ve not girme |
| Mağaza | Kullanıcı | Ürünleri keşfetme |
| Ürün Detay | Kullanıcı | Ürün bilgisi ve sepete ekleme |
| Sepet | Kullanıcı | Ürünleri ve toplamı görme |
| Checkout | Kullanıcı | Adres, kupon ve sipariş onayı |
| Siparişlerim | Kullanıcı | Sipariş takibi |
| Kayıp/Bulunan | Kullanıcı | Kayıp ve bulunan ilanları |
| Sosyal Akış | Kullanıcı | Gönderi, yorum, beğeni |
| Etkinlikler | Kullanıcı | Etkinlik keşfi ve katılım |
| Ayarlar | Kullanıcı | Dil, tema, bildirim, hesap |

---

### 3. Mobil Ekran Detayları

#### 3.1 Giriş Ekranı

- Amaç: Kullanıcının e-posta ve şifre ile sisteme giriş yapmasını sağlamak.
- Giriş Verileri: E-posta, şifre.
- Çıktılar: Token, kullanıcı rolü, ana ekrana yönlendirme.
- Hata Durumları: Yanlış şifre, kayıtlı olmayan e-posta, rate limit, bağlantı hatası.
- Test Edilecek Noktalar: Boş alan kontrolü, hatalı şifre, başarılı giriş, token saklama.

#### 3.2 Kayıt Ekranı

- Amaç: Yeni kullanıcı hesabı oluşturmak.
- Giriş Verileri: Ad, soyad, e-posta, şifre.
- Çıktılar: Kullanıcı kaydı, giriş yönlendirmesi.
- Hata Durumları: Kayıtlı e-posta, zayıf şifre, eksik alan.
- Test Edilecek Noktalar: Benzersiz e-posta kontrolü, şifre politikası, başarılı kayıt.

#### 3.3 Pet Ekleme Ekranı

- Amaç: Kullanıcının pet profili oluşturmasını sağlamak.
- Giriş Verileri: Pet adı, tür, cinsiyet, yaş, fotoğraf, konum.
- Çıktılar: Pet kaydı ve pet detay ekranı.
- Hata Durumları: Eksik zorunlu alan, medya yükleme hatası.
- Test Edilecek Noktalar: Zorunlu alanlar, fotoğraf seçimi, yetkili kayıt.

#### 3.4 Veteriner Arama Ekranı

- Amaç: Kullanıcının konumuna göre veterinerleri listelemek.
- Giriş Verileri: Enlem-boylam, şehir, filtreler.
- Çıktılar: Veteriner listesi, harita marker'ları.
- Hata Durumları: Konum izni yok, sonuç bulunamadı, harita servisi hatası.
- Test Edilecek Noktalar: Konumlu arama, manuel arama, boş sonuç ekranı.

#### 3.5 Randevu Oluşturma Ekranı

- Amaç: Veteriner için uygun tarih ve saat seçilmesini sağlamak.
- Giriş Verileri: Veteriner, pet, tarih, saat, not.
- Çıktılar: Randevu kaydı, bildirim.
- Hata Durumları: Slot dolu, pet seçilmedi, geçmiş tarih.
- Test Edilecek Noktalar: Slot kontrolü, randevu oluşumu, çakışma engeli.

#### 3.6 Bakıcı Rezervasyon Ekranı

- Amaç: Pet bakıcısı için rezervasyon oluşturmak.
- Giriş Verileri: Bakıcı, hizmet türü, tarih aralığı, pet, not.
- Çıktılar: Rezervasyon kaydı, bakıcı bildirimi.
- Hata Durumları: Tarih çakışması, bakıcı pasif, geçersiz tarih.
- Test Edilecek Noktalar: Tarih doğrulama, durum oluşturma, bildirim.

#### 3.7 Sohbet Ekranı

- Amaç: Kullanıcılar arasında mesajlaşma sağlamak.
- Giriş Verileri: Mesaj içeriği, konuşma kimliği, ek medya.
- Çıktılar: Yeni mesaj, socket olayı, push bildirimi.
- Hata Durumları: Yetkisiz konuşma, bağlantı kopması, medya hatası.
- Test Edilecek Noktalar: Gerçek zamanlı iletim, çevrim dışı alıcı, yetki kontrolü.

#### 3.8 Checkout Ekranı

- Amaç: Sipariş onay sürecini tamamlamak.
- Giriş Verileri: Sepet, adres, kupon, not.
- Çıktılar: Sipariş numarası, sipariş durumu.
- Hata Durumları: Stok yetersiz, adres eksik, kupon geçersiz.
- Test Edilecek Noktalar: Stok kontrolü, kupon kontrolü, sipariş oluşturma.

---

### 4. Admin Panel Ekranları

| Ekran | Amaç |
|---|---|
| Admin Giriş | Yetkili giriş |
| Dashboard | Genel sistem özeti |
| Kullanıcılar | Kullanıcı listeleme ve durum yönetimi |
| Petler | Pet kayıtlarını inceleme |
| Gönderiler | Sosyal içerik denetimi |
| Raporlar | Şikayet ve kötüye kullanım yönetimi |
| Satıcı Başvuruları | Satıcı onay/red işlemleri |
| Veteriner Talepleri | Klinik doğrulama |
| Siparişler | Ticaret akışını izleme |
| Bakıcılar | Bakıcı profillerini inceleme |
| Audit Logs | Kritik admin işlemlerini izleme |
| Platform Ayarları | Sistem parametreleri |

#### 4.1 Admin Dashboard

- Amaç: Platformun genel durumunu tek ekranda göstermek.
- Giriş Verileri: Tarih aralığı, filtreler.
- Çıktılar: Kullanıcı sayısı, sipariş sayısı, rapor sayısı, bekleyen başvurular.
- Hata Durumları: Veri çekilemedi, yetkisiz erişim.
- Test Edilecek Noktalar: Rol kontrolü, metrik doğruluğu, boş veri durumu.

#### 4.2 Moderasyon Kuyruğu

- Amaç: Raporlanan içerikleri incelemek.
- Giriş Verileri: Rapor türü, içerik kimliği, admin kararı.
- Çıktılar: İçerik durumu, audit log.
- Hata Durumları: İçerik bulunamadı, karar yetkisi yok.
- Test Edilecek Noktalar: İçerik kaldırma, uyarı, log üretimi.

#### 4.3 Satıcı Başvuruları

- Amaç: Satıcı olmak isteyen kullanıcıları değerlendirmek.
- Giriş Verileri: Başvuru bilgileri, karar, gerekçe.
- Çıktılar: Onay/red durumu, kullanıcı rolü güncellemesi.
- Hata Durumları: Eksik belge, tekrar karar, yetkisiz işlem.
- Test Edilecek Noktalar: Rol güncellemesi, başvuru durumu, bildirim.

---

### 5. Satıcı Panel Ekranları

| Ekran | Amaç |
|---|---|
| Satıcı Giriş | Satıcı yetkili giriş |
| Satıcı Dashboard | Satış ve sipariş özeti |
| Mağaza Profili | Mağaza bilgisi düzenleme |
| Ürün Yönetimi | Ürün ekleme, güncelleme, pasifleştirme |
| Siparişler | Siparişleri listeleme ve durum güncelleme |
| Kuponlar | Kampanya ve kupon yönetimi |
| Yorumlar | Müşteri yorumlarını izleme |
| Analitik | Satış ve performans özeti |

#### 5.1 Ürün Yönetimi

- Amaç: Satıcının mağazasındaki ürünleri yönetmesini sağlamak.
- Giriş Verileri: Ürün adı, açıklama, fiyat, stok, kategori, görsel.
- Çıktılar: Ürün listesi, ürün durumu.
- Hata Durumları: Negatif stok, eksik fiyat, medya hatası.
- Test Edilecek Noktalar: Satıcı yetkisi, ürün ekleme, ürün güncelleme.

#### 5.2 Satıcı Siparişleri

- Amaç: Satıcının kendi mağazasına gelen siparişleri yönetmesi.
- Giriş Verileri: Sipariş durumu, kargo bilgisi, filtreler.
- Çıktılar: Sipariş listesi, durum güncellemesi, kullanıcı bildirimi.
- Hata Durumları: Başka satıcının siparişine erişim, geçersiz durum geçişi.
- Test Edilecek Noktalar: Yetki sınırı, durum geçişi, bildirim.

---

### 6. Ekran Akışları

#### 6.1 Randevu Akışı

1. Ana Sayfa
2. Veteriner Arama
3. Veteriner Detay
4. Randevu Oluştur
5. Randevularım
6. Randevu Detay

#### 6.2 Bakıcı Rezervasyon Akışı

1. Ana Sayfa
2. Bakıcı Listesi
3. Bakıcı Detay
4. Rezervasyon Formu
5. Rezervasyonlarım
6. Canlı Takip / Bakım Raporu

#### 6.3 Sipariş Akışı

1. Mağaza Ana Sayfa
2. Ürün Detay
3. Sepet
4. Adres Seçimi
5. Kupon ve Onay
6. Sipariş Detay
7. Sipariş Takip

#### 6.4 Sahiplendirme Akışı

1. Sahiplendirme Listesi
2. İlan Detay
3. Başvuru Formu
4. Başvurularım
5. Başvuru Durumu

---

### 7. Word Raporu İçin Ekran Görüntüsü Önerisi

100 sayfalık rapor hedefinde her ekranı görsel olarak koymak raporu ağırlaştırabilir. En doğru seçim, ana akışları temsil eden ekranlardan örnek vermektir:

- Giriş / kayıt
- Ana sayfa
- Pet detay
- Veteriner arama
- Randevu oluşturma
- Bakıcı detay
- Rezervasyon formu
- Mesajlaşma
- Mağaza
- Sepet / checkout
- Admin dashboard
- Satıcı ürün yönetimi

Bu 12 ekran görüntüsü, raporu hem görsel hem de yönetilebilir tutar.

# 11 Detayli Test Senaryolari

## Ek I: Genişletilmiş Test Senaryoları

### 1. Amaç

Bu bölüm, sistemin test kapsamını modül bazlı olarak genişletir. Önceki test planında temel senaryolar verilmişti; burada pozitif, negatif, güvenlik, entegrasyon ve kullanıcı kabul testleri daha ayrıntılı sunulmuştur.

---

### 2. Test Kategorileri

| Kategori | Açıklama |
|---|---|
| Pozitif test | Beklenen doğru kullanım |
| Negatif test | Hatalı veya eksik veri |
| Yetki testi | Rol ve erişim sınırları |
| Entegrasyon testi | Modüller arası veri akışı |
| Kullanılabilirlik testi | Kullanıcı görev tamamlama |
| Regresyon testi | Yeni değişiklik sonrası eski akışlar |
| Performans testi | Yanıt süresi ve yük davranışı |

---

### 3. Kimlik Doğrulama Testleri

| ID | Test | Beklenen Sonuç | Tür |
|---|---|---|---|
| AUTH-01 | Geçerli bilgilerle kayıt | Hesap oluşur | Pozitif |
| AUTH-02 | Kayıtlı e-posta ile kayıt | Hata döner | Negatif |
| AUTH-03 | Zayıf şifre ile kayıt | Sistem kabul etmez | Negatif |
| AUTH-04 | Geçerli bilgilerle giriş | Token üretilir | Pozitif |
| AUTH-05 | Yanlış şifre ile giriş | Hata mesajı gösterilir | Negatif |
| AUTH-06 | Token olmadan korumalı endpoint | 401 döner | Yetki |
| AUTH-07 | Standart kullanıcı admin endpoint ister | 403 döner | Yetki |
| AUTH-08 | Çok sayıda başarısız giriş | Rate limit devreye girer | Güvenlik |
| AUTH-09 | Süresi dolmuş token | Yeniden giriş istenir | Regresyon |
| AUTH-10 | Çıkış sonrası token kullanımı | Erişim engellenir | Güvenlik |

---

### 4. Pet ve İlan Testleri

| ID | Test | Beklenen Sonuç | Tür |
|---|---|---|---|
| PET-01 | Pet profili oluşturma | Pet kaydı oluşur | Pozitif |
| PET-02 | Eksik ad ile pet oluşturma | Hata verilir | Negatif |
| PET-03 | Geçersiz yaş girme | Hata verilir | Negatif |
| PET-04 | Pet fotoğrafı yükleme | Fotoğraf URL oluşur | Entegrasyon |
| PET-05 | Başkasının petini güncelleme | Erişim reddedilir | Yetki |
| PET-06 | Sahiplendirme ilanı açma | İlan yayınlanır | Pozitif |
| PET-07 | Eksik açıklama ile ilan | Kayıt engellenir | Negatif |
| PET-08 | Pasif ilanı görüntüleme | Duruma göre gizlenir | Regresyon |
| PET-09 | Favoriye ekleme | Favori kaydı oluşur | Pozitif |
| PET-10 | Aynı favoriyi tekrar ekleme | Tek kayıt korunur | Negatif |

---

### 5. Sahiplendirme Testleri

| ID | Test | Beklenen Sonuç | Tür |
|---|---|---|---|
| ADOPT-01 | İlan detayından başvuru | Başvuru oluşur | Pozitif |
| ADOPT-02 | Kendi ilanına başvuru | Sistem engeller | Negatif |
| ADOPT-03 | Aynı ilana ikinci başvuru | Tekrar engellenir | Negatif |
| ADOPT-04 | İlan sahibi başvuruyu kabul eder | Durum kabul olur | Pozitif |
| ADOPT-05 | İlan sahibi başvuruyu reddeder | Durum red olur | Pozitif |
| ADOPT-06 | Başvuru sonrası bildirim | Bildirim gider | Entegrasyon |
| ADOPT-07 | Pasif ilana başvuru | Başvuru alınmaz | Regresyon |
| ADOPT-08 | Başvuran başvurusunu görür | Liste doğru gelir | Kullanıcı kabul |

---

### 6. Veteriner ve Randevu Testleri

| ID | Test | Beklenen Sonuç | Tür |
|---|---|---|---|
| VET-01 | Konumla veteriner arama | Yakın klinikler listelenir | Pozitif |
| VET-02 | Konum izni reddi | Manuel arama sunulur | Negatif |
| VET-03 | Veteriner detay açma | Klinik bilgileri gelir | Pozitif |
| VET-04 | Boş slota randevu | Randevu oluşur | Pozitif |
| VET-05 | Dolu slota randevu | Sistem engeller | Negatif |
| VET-06 | Geçmiş tarihe randevu | Sistem engeller | Negatif |
| VET-07 | Pet seçmeden randevu | Sistem uyarır | Negatif |
| VET-08 | Randevu onay bildirimi | Kullanıcıya bildirim gider | Entegrasyon |
| VET-09 | Veteriner randevu durumunu günceller | Durum değişir | Pozitif |
| VET-10 | Yetkisiz randevu güncelleme | Erişim reddedilir | Yetki |

---

### 7. Aşı ve Sağlık Testleri

| ID | Test | Beklenen Sonuç | Tür |
|---|---|---|---|
| HEALTH-01 | Aşı kaydı ekleme | Kayıt oluşur | Pozitif |
| HEALTH-02 | Sonraki tarih geçmişte | Sistem engeller | Negatif |
| HEALTH-03 | Kilo kaydı ekleme | Sağlık kaydı oluşur | Pozitif |
| HEALTH-04 | Başkasının pet sağlık kaydı | Erişim reddedilir | Yetki |
| HEALTH-05 | Hatırlatma tercihi kapalı | Bildirim gönderilmez | Entegrasyon |
| HEALTH-06 | Aşı takvimini görüntüleme | Kayıtlar listelenir | Kullanıcı kabul |

---

### 8. Bakıcı Testleri

| ID | Test | Beklenen Sonuç | Tür |
|---|---|---|---|
| SITTER-01 | Bakıcı profili oluşturma | Profil oluşur | Pozitif |
| SITTER-02 | Eksik hizmet türü | Sistem uyarır | Negatif |
| SITTER-03 | Bakıcı listesi görüntüleme | Liste gelir | Pozitif |
| SITTER-04 | Rezervasyon oluşturma | Durum beklemede olur | Pozitif |
| SITTER-05 | Geçersiz tarih aralığı | Sistem engeller | Negatif |
| SITTER-06 | Çakışan rezervasyon | Sistem engeller | Negatif |
| SITTER-07 | Bakıcı kabul eder | Durum kabul olur | Pozitif |
| SITTER-08 | Bakıcı reddeder | Durum red olur | Pozitif |
| SITTER-09 | Hizmet başlatılır | Durum aktif olur | Entegrasyon |
| SITTER-10 | Hizmet tamamlanır | Durum tamamlandı olur | Pozitif |

---

### 9. Mesajlaşma Testleri

| ID | Test | Beklenen Sonuç | Tür |
|---|---|---|---|
| MSG-01 | Konuşma başlatma | Conversation oluşur | Pozitif |
| MSG-02 | Mesaj gönderme | Mesaj kaydedilir | Pozitif |
| MSG-03 | Alıcı çevrim içiyken mesaj | Socket ile gelir | Entegrasyon |
| MSG-04 | Alıcı çevrim dışıyken mesaj | Push bildirimi gider | Entegrasyon |
| MSG-05 | Yetkisiz konuşmaya erişim | Sistem engeller | Yetki |
| MSG-06 | Boş mesaj gönderme | Sistem uyarır | Negatif |
| MSG-07 | Medya mesajı | Dosya yüklenir | Entegrasyon |
| MSG-08 | Engellenen kullanıcıya mesaj | Sistem engeller | Güvenlik |

---

### 10. Mağaza ve Sipariş Testleri

| ID | Test | Beklenen Sonuç | Tür |
|---|---|---|---|
| STORE-01 | Ürün listeleme | Ürünler gelir | Pozitif |
| STORE-02 | Filtreleme | Sonuçlar filtrelenir | Pozitif |
| STORE-03 | Sepete ürün ekleme | Sepet güncellenir | Pozitif |
| STORE-04 | Stoktan fazla adet | Sistem engeller | Negatif |
| STORE-05 | Kupon uygulama | Tutar güncellenir | Pozitif |
| STORE-06 | Süresi dolmuş kupon | Hata verilir | Negatif |
| STORE-07 | Adres olmadan sipariş | Sistem engeller | Negatif |
| STORE-08 | Sipariş oluşturma | Sipariş numarası oluşur | Pozitif |
| STORE-09 | Sipariş durumu takip | Güncel durum görünür | Kullanıcı kabul |
| STORE-10 | Satıcı başka mağaza siparişi görür | Erişim reddedilir | Yetki |

---

### 11. Admin ve Satıcı Panel Testleri

| ID | Test | Beklenen Sonuç | Tür |
|---|---|---|---|
| PANEL-01 | Admin giriş | Dashboard açılır | Pozitif |
| PANEL-02 | Standart kullanıcı admin paneli | Erişim reddedilir | Yetki |
| PANEL-03 | Raporlanan içerik listeleme | Liste gelir | Pozitif |
| PANEL-04 | İçerik kaldırma | İçerik pasif olur | Pozitif |
| PANEL-05 | Admin işlemi loglanır | Audit kaydı oluşur | Entegrasyon |
| PANEL-06 | Satıcı ürün ekler | Ürün oluşur | Pozitif |
| PANEL-07 | Negatif fiyat girilir | Sistem engeller | Negatif |
| PANEL-08 | Satıcı sipariş durumu günceller | Durum değişir | Pozitif |
| PANEL-09 | Satıcı başvuru durumu izler | Güncel durum görünür | Kullanıcı kabul |
| PANEL-10 | Admin satıcı başvurusunu onaylar | Rol güncellenir | Entegrasyon |

---

### 12. Performans ve Regresyon Testleri

| ID | Test | Beklenen Sonuç |
|---|---|---|
| PERF-01 | Ana sayfa liste yükleme | Kabul edilebilir sürede yüklenir |
| PERF-02 | Yakın veteriner sorgusu | Konum indeksleriyle hızlı döner |
| PERF-03 | Mesaj listesi açma | Sayfalama ile yüklenir |
| PERF-04 | Ürün listesi filtreleme | Gecikme makul kalır |
| REG-01 | Tema değişimi sonrası ekranlar | Layout bozulmaz |
| REG-02 | Dil değişimi sonrası metinler | Doğru dil görünür |
| REG-03 | Oturum süresi dolduğunda işlem | Girişe yönlendirilir |
| REG-04 | API hata verdiğinde UI | Anlaşılır hata gösterir |

---

### 13. Kullanıcı Kabul Testleri

| ID | Kullanıcı Görevi | Başarı Kriteri |
|---|---|---|
| UAT-01 | Kullanıcı kayıt olup giriş yapar | Ana sayfaya ulaşır |
| UAT-02 | Kullanıcı pet profili oluşturur | Pet listesinde görünür |
| UAT-03 | Kullanıcı veteriner randevusu alır | Randevu listesinde görünür |
| UAT-04 | Kullanıcı bakıcı rezervasyonu yapar | Beklemede durum oluşur |
| UAT-05 | Kullanıcı ürün siparişi verir | Sipariş numarası alır |
| UAT-06 | Satıcı ürün ekler | Ürün mağazada görünür |
| UAT-07 | Admin raporlu içeriği kaldırır | İçerik pasifleşir |
| UAT-08 | Kullanıcı mesaj gönderir | Alıcı mesajı alır |

---

### 14. Test Kapsam Özeti

Bu genişletilmiş test setinde 90'a yakın test maddesi tanımlanmıştır. Testlerin amacı yalnızca doğru çalışan senaryoları doğrulamak değil; güvenlik, yetki, veri doğruluğu, hata mesajları ve kullanıcı kabul akışlarını da kapsamaktır.

# 03 Test Risk Plan Ekleri

## Ek B: Test, Risk, Planlama ve Proje Yönetimi Ekleri

### 1. Amaç

Bu ek doküman, ana raporun yönetimsel ve kalite boyutunu güçlendirmek amacıyla hazırlanmıştır. Yazılım mühendisliği proje raporlarında yalnızca neyin yapılacağı değil, bunun nasıl test edileceği, hangi risklerin yönetileceği, işin nasıl planlanacağı ve başarı ölçümünün nasıl yapılacağı da gösterilmelidir. Bu nedenle bu dokümanda aşağıdaki başlıklar yer almaktadır:

- İş kırılım yapısı
- Zaman planı
- Sprint bazlı ilerleme önerisi
- RACI matrisi
- Risk yönetimi
- Test stratejisi
- Örnek test senaryoları
- Kullanıcı hikâyeleri ve backlog
- Kalite ölçütleri
- Değişiklik yönetimi

---

### 2. İş Kırılım Yapısı (WBS)

#### 2.1 Seviye 1

1. Proje Başlatma
2. Analiz ve Gereksinim Yönetimi
3. Mimari ve Tasarım
4. Mobil Uygulama Geliştirme
5. Backend Geliştirme
6. Web Paneller Geliştirme
7. Test ve Kalite Güvence
8. Dağıtım ve Operasyon
9. Dokümantasyon ve Teslim

#### 2.2 Seviye 2 Ayrıntısı

| WBS Kodu | İş Paketi | Açıklama |
|---|---|---|
| 1.1 | Proje konusu netleştirme | Alan seçimi, kapsam belirleme |
| 1.2 | Paydaş tanımlama | Aktörlerin ve rollerin belirlenmesi |
| 2.1 | Gereksinim toplama | İşlevsel ve işlevsel olmayan gereksinimler |
| 2.2 | Use case hazırlama | Senaryo ve sözleşmeler |
| 2.3 | İş kuralları tanımı | Alan kısıtları ve kurallar |
| 3.1 | Mimari tasarım | Dağıtım, katman ve bileşen yapısı |
| 3.2 | Veri tasarımı | Varlıklar, ilişkiler, indeksler |
| 3.3 | Arayüz tasarımı | Mobil ve panel ekran akışları |
| 4.1 | Kimlik ve profil modülü | Mobil istemci çekirdek akışları |
| 4.2 | Veteriner modülü | Arama, detay, randevu |
| 4.3 | Bakıcı modülü | Profil, rezervasyon, durum takibi |
| 4.4 | Mağaza modülü | Ürün, sepet, sipariş |
| 4.5 | Sosyal modüller | Mesaj, gönderi, etkinlik |
| 5.1 | Auth API | Giriş, token, yetkilendirme |
| 5.2 | Pet ve ilan API | Pet CRUD, başvuru akışları |
| 5.3 | Hizmet API'leri | Randevu, aşı, bakıcı |
| 5.4 | Ticaret API'leri | Sipariş, kupon, ürün |
| 6.1 | Admin paneli | Moderasyon ve operasyon |
| 6.2 | Satıcı paneli | Ürün ve sipariş yönetimi |
| 7.1 | Birim test | Servis ve kontrol seviyeleri |
| 7.2 | Entegrasyon test | API ve modül etkileşimi |
| 7.3 | Kabul testi | İş senaryosu bazlı test |
| 8.1 | Deploy hazırlığı | Ortam değişkenleri, sunucu |
| 8.2 | İzleme | Log, bildirim, hata takibi |
| 9.1 | Final raporu | Word teslim dosyası |
| 9.2 | Ekler ve diyagramlar | UML, test tabloları, ekranlar |

---

### 3. Zaman Planı

#### 3.1 Önerilen Faz Planı

| Faz | Süre | Çıktı |
|---|---|---|
| Faz 1 | 1 hafta | Problem, kapsam, paydaş analizi |
| Faz 2 | 1 hafta | Gereksinim listesi, use case, iş kuralları |
| Faz 3 | 1 hafta | Mimari, veri modeli, diyagramlar |
| Faz 4 | 2 hafta | Ana modüllerin gerçeklenmesi/kanıtlanması |
| Faz 5 | 1 hafta | Test, hata düzeltme, kalite kontrol |
| Faz 6 | 1 hafta | Son rapor, ekler, teslim paketi |

#### 3.2 Sprint Tabanlı Planlama

| Sprint | Hedef |
|---|---|
| Sprint 1 | Auth, profil ve pet modülleri |
| Sprint 2 | Sahiplendirme ve eşleştirme |
| Sprint 3 | Mesajlaşma ve sosyal modüller |
| Sprint 4 | Veteriner, aşı ve sağlık |
| Sprint 5 | Bakıcı rezervasyonu ve canlı süreçler |
| Sprint 6 | Mağaza, sipariş, admin, seller ve kalite |

#### 3.3 Kilometre Taşları

1. Gereksinimlerin dondurulması
2. Temel mimarinin onaylanması
3. Çekirdek modüllerin tamamlanması
4. Çok modüllü entegrasyonun görülmesi
5. Test ve düzeltme
6. Rapor ve teslim

---

### 4. RACI Matrisi

| İş Alanı | Proje Yöneticisi | Analist | Backend | Mobil | Web Panel | DB/DevOps | Test Uzmanı |
|---|---|---|---|---|---|---|---|
| Kapsam belirleme | A | R | C | C | C | C | C |
| Gereksinim yazımı | A | R | C | C | C | C | C |
| UML modelleme | C | R | C | C | C | C | C |
| API tasarımı | C | C | R | C | C | C | C |
| Mobil ekranlar | C | C | C | R | C | C | C |
| Admin/seller panel | C | C | C | C | R | C | C |
| Veritabanı tasarımı | C | C | C | C | C | R | C |
| Test planı | C | C | C | C | C | C | R |
| Dağıtım | C | C | C | C | C | R | C |

`R`: Responsible, `A`: Accountable, `C`: Consulted

---

### 5. Risk Yönetimi

#### 5.1 Risk Tanımlama Yaklaşımı

Dağıtık sistemlerde riskler yalnızca kod hataları ile sınırlı değildir. Aşağıdaki alanlar birlikte değerlendirilmelidir:

- Teknik riskler
- Operasyonel riskler
- Güvenlik riskleri
- Takvim riskleri
- Kapsam sürünmesi
- Kullanılabilirlik riskleri

#### 5.2 Risk Matrisi

| Risk Kodu | Risk Tanımı | Olasılık | Etki | Önlem |
|---|---|---|---|---|
| R-01 | Gereksinimlerin sık değişmesi | Orta | Yüksek | Kapsam dondurma ve değişiklik yönetimi |
| R-02 | Modüller arası entegrasyon hataları | Yüksek | Yüksek | Erken entegrasyon ve API sözleşmeleri |
| R-03 | Yetkilendirme açığı | Orta | Çok Yüksek | Rol bazlı erişim ve güvenlik testleri |
| R-04 | Veritabanı performans sorunu | Orta | Yüksek | İndeksleme ve sorgu incelemesi |
| R-05 | Konum servislerinde hata | Orta | Orta | Manuel konum fallback |
| R-06 | Bildirimlerin ulaşmaması | Orta | Orta | Retry ve kullanıcı içi durum ekranları |
| R-07 | Socket bağlantı kopmaları | Yüksek | Orta | Yeniden bağlanma ve offline fallback |
| R-08 | Medya yükleme problemleri | Orta | Orta | Dosya boyutu ve tür doğrulaması |
| R-09 | Takvim çakışma hataları | Orta | Yüksek | Çift taraflı uygunluk doğrulaması |
| R-10 | Stok ve sipariş tutarsızlığı | Orta | Yüksek | İşlem sırası ve sunucu tarafı doğrulama |
| R-11 | Uygunsuz içerik yayını | Orta | Yüksek | Moderasyon kuyruğu ve raporlama |
| R-12 | Kullanıcı verisi sızıntısı | Düşük | Çok Yüksek | Şifreleme, log denetimi, erişim sınırı |
| R-13 | Sunucu kesintisi | Düşük | Yüksek | Sağlık kontrolü ve yedekleme planı |
| R-14 | Kapsamın aşırı büyümesi | Yüksek | Orta | Önceliklendirme ve fazlama |
| R-15 | Teslim öncesi dokümantasyon eksikliği | Orta | Yüksek | Belge üretimini erken başlatma |

#### 5.3 En Kritik Riskler

Bu proje özelinde en kritik riskler:

1. Yetkilendirme ve güvenlik açıkları
2. Randevu/rezervasyon çakışmaları
3. Çok modüllü yapının entegrasyon karmaşıklığı
4. Dokümantasyonun uygulama kapsamını yeterince yansıtamaması

---

### 6. Test Stratejisi

#### 6.1 Test Seviyeleri

1. Birim test
2. Entegrasyon test
3. Sistem testi
4. Kullanıcı kabul testi
5. Regresyon testi

#### 6.2 Test Kapsamı

- Kimlik doğrulama
- Yetkilendirme
- Pet ve ilan yönetimi
- Randevu ve takvim süreçleri
- Aşı ve sağlık kayıtları
- Bakıcı rezervasyonları
- Mesajlaşma
- Sipariş ve stok
- Moderasyon

#### 6.3 Test Ortamı

- Geliştirme ortamı
- Test veritabanı
- Örnek kullanıcı rolleri
- Gerçek cihaz ve emülatör
- Panel için masaüstü tarayıcı

#### 6.4 Test Veri Kümeleri

- Standart kullanıcı hesabı
- Admin hesabı
- Satıcı hesabı
- Veteriner hesabı
- Bakıcı hesabı
- Farklı türde pet kayıtları
- Stoklu/stoksuz ürünler
- Gelecek ve geçmiş tarihli rezervasyon örnekleri

---

### 7. Örnek Test Senaryoları

#### 7.1 Kimlik ve Erişim Testleri

| Test ID | Senaryo | Beklenen Sonuç |
|---|---|---|
| T-01 | Geçerli bilgilerle kayıt olma | Kullanıcı hesabı oluşturulur |
| T-02 | Aynı e-posta ile ikinci kayıt | Sistem hata verir |
| T-03 | Geçerli bilgilerle giriş | Token üretilir |
| T-04 | Yanlış parola ile giriş | Hata mesajı gösterilir |
| T-05 | Yetkisiz kullanıcı admin endpoint'ine erişir | 401/403 döner |

#### 7.2 Pet ve İlan Testleri

| Test ID | Senaryo | Beklenen Sonuç |
|---|---|---|
| T-06 | Zorunlu alanlarla pet ekleme | Pet kaydı oluşur |
| T-07 | Fotoğrafsız pet oluşturma | Kurala göre kabul veya uyarı |
| T-08 | Sahiplendirme ilanı oluşturma | İlan kaydedilir |
| T-09 | Kendi ilanına başvurma | Sistem engeller |
| T-10 | Aynı ilana iki kez başvurma | İkinci başvuru reddedilir |

#### 7.3 Veteriner ve Sağlık Testleri

| Test ID | Senaryo | Beklenen Sonuç |
|---|---|---|
| T-11 | Konumla veteriner arama | Yakın sonuçlar listelenir |
| T-12 | Boş slot için randevu alma | Randevu oluşturulur |
| T-13 | Dolu slot için randevu alma | Sistem yeni slot ister |
| T-14 | Aşı kaydı ekleme | Kayıt oluşur |
| T-15 | Geçersiz aşı tarihi girme | Sistem hatayı gösterir |

#### 7.4 Bakıcı Testleri

| Test ID | Senaryo | Beklenen Sonuç |
|---|---|---|
| T-16 | Bakıcı profili oluşturma | Profil kaydedilir |
| T-17 | Uygun tarihe rezervasyon oluşturma | Rezervasyon oluşur |
| T-18 | Çakışan tarihe rezervasyon | Sistem engeller |
| T-19 | Bakıcı rezervasyonu kabul eder | Durum güncellenir |
| T-20 | Aktif hizmette durum takibi | İlgili olaylar görünür |

#### 7.5 Mesajlaşma ve Etkileşim Testleri

| Test ID | Senaryo | Beklenen Sonuç |
|---|---|---|
| T-21 | Konuşma içinden mesaj gönderme | Mesaj kaydedilir ve iletilir |
| T-22 | Yetkisiz konuşmaya mesaj gönderme | Sistem engeller |
| T-23 | Alıcı çevrimdışı iken mesaj | Mesaj kaydedilir, bildirim atılır |
| T-24 | Gönderi beğenme | Sayaç artar |
| T-25 | Kullanıcıyı engelleme sonrası etkileşim | Kurallara göre kısıtlama uygulanır |

#### 7.6 Mağaza ve Sipariş Testleri

| Test ID | Senaryo | Beklenen Sonuç |
|---|---|---|
| T-26 | Ürünü sepete ekleme | Sepet güncellenir |
| T-27 | Yetersiz stokla sipariş verme | Sistem reddeder |
| T-28 | Geçerli kupon uygulama | Tutar güncellenir |
| T-29 | Geçersiz kupon uygulama | Hata gösterilir |
| T-30 | Sipariş oluşturma | Sipariş numarası oluşur |

#### 7.7 Admin ve Moderasyon Testleri

| Test ID | Senaryo | Beklenen Sonuç |
|---|---|---|
| T-31 | Admin moderasyon kuyruğunu açar | Veriler listelenir |
| T-32 | Raporlu içeriği kaldırma | İçerik pasif olur |
| T-33 | Kullanıcıyı kısıtlama | Hesap işlem sınırı alır |
| T-34 | Admin işlemi loglanır | Audit kaydı oluşur |
| T-35 | Admin dışı kullanıcı moderasyon endpoint'ine gider | Erişim reddedilir |

#### 7.8 Regresyon ve Kullanılabilirlik Testleri

| Test ID | Senaryo | Beklenen Sonuç |
|---|---|---|
| T-36 | Tema değişimi sonrası ana ekran | Arayüz bozulmaz |
| T-37 | Dil değişimi sonrası kritik ekranlar | Metinler doğru görünür |
| T-38 | Ağ zayıfken liste ekranları | Boş/hata durumları anlaşılırdır |
| T-39 | Bildirimden ekran açma | Kullanıcı doğru modüle gider |
| T-40 | Oturum süresi dolmuş halde işlem | Kullanıcı yeniden girişe yönlendirilir |

---

### 8. Kullanıcı Hikâyeleri ve Backlog

#### 8.1 Örnek Kullanıcı Hikâyeleri

| Hikâye ID | Kullanıcı Hikâyesi | Öncelik |
|---|---|---|
| US-01 | Bir kullanıcı olarak hesap açmak istiyorum ki uygulamayı kişisel verilerimle kullanabileyim | Must |
| US-02 | Bir kullanıcı olarak pet profili oluşturmak istiyorum ki hayvanıma ait kayıtlar sistemde tutulsun | Must |
| US-03 | Bir kullanıcı olarak sahiplendirme ilanı vermek istiyorum ki hayvanıma yuva bulabileyim | Must |
| US-04 | Bir kullanıcı olarak veterinerleri yakınlığa göre görmek istiyorum ki bana en uygun kliniği seçebileyim | Must |
| US-05 | Bir kullanıcı olarak randevu almak istiyorum ki kliniğe gitmeden planlama yapabileyim | Must |
| US-06 | Bir kullanıcı olarak aşı tarihimi kaydetmek istiyorum ki unutmayayım | Should |
| US-07 | Bir kullanıcı olarak bakıcı bulmak istiyorum ki seyahat dönemimde yardım alabileyim | Must |
| US-08 | Bir kullanıcı olarak bakıcı rezervasyonumu takip etmek istiyorum ki süreçten haberdar olayım | Should |
| US-09 | Bir kullanıcı olarak diğer kullanıcılarla mesajlaşmak istiyorum ki ayrıntıları konuşabileyim | Must |
| US-10 | Bir kullanıcı olarak ürün satın almak istiyorum ki ihtiyaçlarımı uygulamadan karşılayabileyim | Must |
| US-11 | Bir satıcı olarak ürün eklemek istiyorum ki mağazamda satış yapabileyim | Must |
| US-12 | Bir admin olarak raporlanan içeriği görmek istiyorum ki platformu güvenli tutabileyim | Must |
| US-13 | Bir kullanıcı olarak kayıp ilanı vermek istiyorum ki hayvanımı daha hızlı bulabileyim | Should |
| US-14 | Bir kullanıcı olarak etkinliğe katılmak istiyorum ki toplulukla etkileşim kurabileyim | Could |
| US-15 | Bir kullanıcı olarak bildirim tercihimi yönetmek istiyorum ki istemediğim bildirimleri kapatabileyim | Should |

#### 8.2 Modül Bazlı Backlog

##### Auth ve Profil
- E-posta/parola ile kayıt
- Güvenli giriş
- Şifre sıfırlama
- Profil düzenleme
- Bildirim tercihleri

##### Veteriner ve Sağlık
- Yakın veteriner arama
- Veteriner detay
- Müsait slot sorgulama
- Randevu oluşturma
- Aşı takvimi
- Sağlık günlüğü

##### Bakıcı
- Bakıcı profili
- Hizmet türleri
- Rezervasyon oluşturma
- Durum takibi
- Geri bildirim/puanlama

##### Mağaza
- Ürün listeleme
- Filtreleme
- Sepet
- Kupon
- Sipariş oluşturma
- Sipariş izleme

---

### 9. Kalite Ölçütleri

#### 9.1 İşlevsel Kalite

- Kritik kullanım senaryolarının başarıyla tamamlanması
- İş kurallarının doğru uygulanması
- Yetkisiz işlem yapılamaması

#### 9.2 Kullanılabilirlik

- Kullanıcının temel görevleri az adımda tamamlaması
- Form ve hata mesajlarının anlaşılır olması
- Mobil cihazlarda akıcı deneyim

#### 9.3 Güvenilirlik

- Aynı işlemin tekrarında tutarlı sonuç üretme
- Çökme veya veri kaybı yaşanmaması
- Ağ dalgalanmalarında kontrollü davranış

#### 9.4 Performans

- Liste ve detay ekranlarında kabul edilebilir yanıt
- Bildirim ve mesaj gecikmesinin düşük olması

#### 9.5 Sürdürülebilirlik

- Yeni modüllerin mevcut yapıyı bozmadan eklenebilmesi
- Kod ve dokümantasyon ayrışmasının net olması

---

### 10. Değişiklik Yönetimi

#### 10.1 Değişiklik Türleri

- Yeni özellik talebi
- Mevcut iş kuralı değişikliği
- Güvenlik iyileştirmesi
- Performans iyileştirmesi
- Kullanıcı deneyimi düzeltmesi

#### 10.2 Değişiklik Süreci

1. Talep oluşturulur.
2. Etki analizi yapılır.
3. Öncelik belirlenir.
4. Backlog'a alınır.
5. İlgili sprint veya sürüme planlanır.
6. Test ve dokümantasyon güncellenir.

---

### 11. Başarı Ölçütleri

Projeyi başarıya götüren ölçütler aşağıdaki gibi tanımlanabilir:

- Kullanıcı uygulamada temel işlemleri tamamlayabiliyor olmalı
- Sistem internet üzerinden erişilebilir olmalı
- Farklı aktör rolleri anlamlı şekilde ayrışmalı
- En az birden fazla dağıtık bileşen birlikte çalışmalı
- Veritabanı ağırlıklı süreçler başarıyla yönetilmeli
- Mobil uygulama raporun merkezinde yer almalı
- Gereksinim, use case, tasarım ve test arasında izlenebilirlik kurulmuş olmalı

---

### 12. Son Değerlendirme

Bu ek doküman, projenin yalnızca fikir ve arayüz düzeyinde değil; planlama, kalite güvence, risk yönetimi ve sürdürülebilirlik açısından da düşünüldüğünü göstermektedir. Yazılım mühendisliği projelerinde yüksek notu belirleyen şey çoğu zaman yalnızca kod miktarı değildir. Gereksinimlerin, testlerin, risklerin ve iş planının mühendislik disiplini ile ifade edilmesi projeyi üst seviyeye taşır.

Bu nedenle ana rapor ile birlikte bu ek dosya kullanıldığında, proje teslimi daha olgun, daha detaylı ve değerlendirici açısından daha savunulabilir hale gelmektedir.

# 12 Genisletilmis Risk Yonetimi

## Ek J: Genişletilmiş Risk Yönetimi

### 1. Amaç

Bu bölüm, projenin teknik, operasyonel, güvenlik, veri, kullanıcı deneyimi ve bakım risklerini ayrıntılı olarak ele alır. Amaç yalnızca riskleri listelemek değil; her risk için etki, olasılık, önlem ve izleme göstergesi belirlemektir.

---

### 2. Risk Sınıfları

| Risk Sınıfı | Açıklama |
|---|---|
| Teknik risk | Mimari, kod, entegrasyon ve performans sorunları |
| Güvenlik riski | Yetkisiz erişim, veri sızıntısı, kötüye kullanım |
| Veri riski | Veri kaybı, tutarsızlık, yanlış ilişki |
| Operasyonel risk | Deploy, bakım, yedekleme ve izleme problemleri |
| Kullanıcı riski | Kullanılabilirlik ve kullanıcı hataları |
| Proje yönetimi riski | Takvim, kapsam, kaynak ve maliyet sapmaları |

---

### 3. Risk Matrisi

| ID | Risk | Sınıf | Olasılık | Etki | Önlem |
|---|---|---|---|---|---|
| R-01 | Gereksinimlerin sürekli değişmesi | Proje | Orta | Yüksek | Değişiklik yönetimi |
| R-02 | Kapsamın aşırı büyümesi | Proje | Yüksek | Yüksek | MVP önceliklendirme |
| R-03 | Backend ve mobil API uyumsuzluğu | Teknik | Orta | Yüksek | API sözleşmesi |
| R-04 | Socket bağlantı kopmaları | Teknik | Yüksek | Orta | Reconnect ve push fallback |
| R-05 | MongoDB sorgularında yavaşlama | Teknik | Orta | Yüksek | İndeksleme |
| R-06 | Konum servisinin hata vermesi | Teknik | Orta | Orta | Manuel konum seçimi |
| R-07 | Bildirimlerin ulaşmaması | Teknik | Orta | Orta | Bildirim logu ve retry |
| R-08 | Dosya yükleme güvenlik açığı | Güvenlik | Orta | Yüksek | Tür/boyut doğrulama |
| R-09 | Yetkisiz admin erişimi | Güvenlik | Düşük | Çok yüksek | Rol bazlı erişim |
| R-10 | Kullanıcı şifresinin sızması | Güvenlik | Düşük | Çok yüksek | Hashleme ve gizli log politikası |
| R-11 | Başkasının pet verisine erişim | Güvenlik | Orta | Yüksek | Sahiplik kontrolü |
| R-12 | Sipariş stok tutarsızlığı | Veri | Orta | Yüksek | Sunucu tarafı stok kontrolü |
| R-13 | Randevu slot çakışması | Veri | Orta | Yüksek | Atomik slot doğrulama |
| R-14 | Bakıcı rezervasyon çakışması | Veri | Orta | Yüksek | Tarih aralığı kontrolü |
| R-15 | Yanlış bildirim gönderimi | Veri | Düşük | Orta | Olay-kullanıcı eşleştirme testi |
| R-16 | Veritabanı yedeğinin alınmaması | Operasyon | Düşük | Çok yüksek | Otomatik yedekleme |
| R-17 | Deploy sonrası servis çalışmaması | Operasyon | Orta | Yüksek | Health check |
| R-18 | Ortam değişkeni hatası | Operasyon | Orta | Yüksek | Ortam kontrol listesi |
| R-19 | Kullanıcı konum izni vermez | Kullanıcı | Yüksek | Orta | Manuel konum akışı |
| R-20 | Çok karmaşık arayüz | Kullanıcı | Orta | Orta | Kullanılabilirlik testi |
| R-21 | Satıcının yanlış stok girmesi | Kullanıcı | Orta | Orta | Form doğrulama |
| R-22 | Adminin hatalı moderasyon kararı | Operasyon | Düşük | Yüksek | Gerekçe ve audit log |
| R-23 | Test kapsamının yetersiz kalması | Kalite | Orta | Yüksek | Traceability matrisi |
| R-24 | Mobil cihazlar arası uyumsuzluk | Teknik | Orta | Orta | Farklı ekran testleri |
| R-25 | Dış servis kota aşımı | Operasyon | Düşük | Orta | Kota izleme |
| R-26 | Push token geçersizliği | Teknik | Orta | Orta | Token yenileme |
| R-27 | Medya depolama maliyet artışı | Operasyon | Orta | Orta | Görsel sıkıştırma |
| R-28 | Kullanıcı verisi silme talebi | Hukuki | Düşük | Yüksek | Veri silme prosedürü |
| R-29 | Şikayet sürecinin kötüye kullanılması | Güvenlik | Orta | Orta | Rapor güven skoru |
| R-30 | Çoklu rol karmaşası | Teknik | Orta | Yüksek | Rol matrisi ve test |

---

### 4. Risk Önceliklendirme

En kritik ilk 5 risk:

1. Yetkisiz admin erişimi
2. Kullanıcı verisi sızıntısı
3. Randevu ve rezervasyon çakışmaları
4. API ve istemci uyumsuzluğu
5. Veritabanı yedekleme eksikliği

Bu risklerin ortak özelliği, oluşmaları halinde yalnızca tek ekranı değil sistem güvenilirliğini doğrudan etkilemeleridir.

---

### 5. Risk İzleme Göstergeleri

| Gösterge | İzlenen Risk |
|---|---|
| 401/403 hata sayısı | Yetkisiz erişim |
| 5xx hata oranı | Sunucu kararlılığı |
| Ortalama API yanıt süresi | Performans |
| Başarısız bildirim oranı | Bildirim altyapısı |
| Tekrarlanan randevu hataları | Slot çakışması |
| Sipariş iptal oranı | Stok ve operasyon |
| Şikayet sayısı | Moderasyon ihtiyacı |
| Crash oranı | Mobil kararlılık |

---

### 6. Risk Azaltma Stratejisi

1. Kritik iş kuralları istemciye bırakılmamalı, sunucu tarafında uygulanmalıdır.
2. Her rol için ayrı yetki testi yapılmalıdır.
3. Randevu, rezervasyon ve sipariş gibi durumlu süreçlerde state diyagramları referans alınmalıdır.
4. Dış servis entegrasyonlarında fallback senaryosu bulunmalıdır.
5. Admin işlemleri audit log ile izlenebilir olmalıdır.
6. Yedekleme ve geri yükleme planı raporda ve operasyon prosedüründe yer almalıdır.

---

### 7. Sonuç

Bu risk yönetimi yaklaşımı, projenin yalnızca geliştirilebilir değil, sürdürülebilir ve denetlenebilir bir sistem olarak ele alındığını gösterir. Özellikle dağıtık sistemlerde risk yönetimi, test planı ve mimari tasarım kadar önemlidir.

# 06 Maliyet Kestirimi Ve Kaynak Planlama

## Ek D: Maliyet Kestirimi, Kaynak Planlama ve İş-Zaman Planı

### 1. Amaç

Bu bölüm, Evcil Hayvan Hizmet, Sosyal Ağ ve E-Ticaret Platformu projesinin planlama aşamasında ele alınması gereken maliyet, kaynak, süre ve iş gücü değerlendirmelerini sunar. Önceki örnek raporlarda görülen COCOMO, işlev noktası, ekip yapısı ve iş-zaman planı yaklaşımı bu projeye uyarlanmıştır.

Buradaki sayısal değerler akademik proje varsayımıdır. Amaç, gerçek ticari ihale bedeli çıkarmak değil; yazılım mühendisliği planlama mantığını göstermek ve projenin büyüklüğünü ölçülebilir hale getirmektir.

---

### 2. Proje Büyüklüğünün Değerlendirilmesi

Bu proje klasik tek modüllü bir otomasyon değildir. Mobil istemci, backend API, gerçek zamanlı mesajlaşma, admin paneli, satıcı paneli, bulut veritabanı ve dış servis entegrasyonları birlikte çalışmaktadır. Bu nedenle proje karmaşıklığı orta-yüksek seviyede kabul edilmiştir.

#### 2.1 Ana Modül Sayısı

| Modül | Açıklama |
|---|---|
| Kimlik doğrulama | Kayıt, giriş, token, rol kontrolü |
| Pet yönetimi | Pet profili, ilan, favori |
| Sahiplendirme | İlan ve başvuru akışları |
| Eşleştirme | Çiftleştirme ve match istekleri |
| Mesajlaşma | REST + Socket.io tabanlı iletişim |
| Veteriner | Yakın veteriner arama, detay, yorum |
| Randevu | Slot, randevu, durum yönetimi |
| Aşı ve sağlık | Aşı takvimi, sağlık günlüğü |
| Pet bakıcı | Bakıcı profili, rezervasyon, canlı takip |
| Kayıp/bulunan | Konum tabanlı kayıp ilanları |
| Sosyal akış | Gönderi, beğeni, yorum |
| Etkinlik | Etkinlik oluşturma ve katılım |
| Mağaza | Ürün, kategori, sepet, sipariş |
| Satıcı paneli | Ürün, sipariş, kupon, mağaza yönetimi |
| Admin paneli | Kullanıcı, içerik, rapor, başvuru denetimi |

Bu yapı, projenin ders ödevi için oldukça kapsamlı olduğunu ve maliyet/süre planının tek ekranlı bir uygulamadan farklı ele alınması gerektiğini göstermektedir.

---

### 3. İşlev Noktası Yaklaşımı

İşlev noktası yöntemi, yazılımın büyüklüğünü kod satırına bağımlı kalmadan değerlendirmek için kullanılır. Bu projede aşağıdaki varsayımsal sayımlar yapılmıştır:

| Ölçüm Parametresi | Sayı | Karmaşıklık | Ağırlık | Katkı |
|---|---:|---|---:|---:|
| Dış Girdiler | 95 | Ortalama | 4 | 380 |
| Dış Çıktılar | 45 | Ortalama | 5 | 225 |
| Dış Sorgular | 60 | Ortalama | 4 | 240 |
| İç Mantıksal Dosyalar | 40 | Ortalama | 10 | 400 |
| Dış Arayüz Dosyaları | 6 | Ortalama | 7 | 42 |
| Toplam | 246 |  |  | 1287 |

Ayarlanmamış işlev noktası sayısı:

```text
AIN = 1287
```

#### 3.1 Teknik Karmaşıklık Faktörü

Teknik karmaşıklık; dağıtık çalışma, performans, çevrim içi veri girişi, güvenlik, tekrar kullanılabilirlik ve dış servis entegrasyonları dikkate alınarak değerlendirilmiştir.

| Teknik Faktör | Puan |
|---|---:|
| Veri iletişimi gereksinimi | 5 |
| Dağıtık işlem yapısı | 5 |
| Performans hassasiyeti | 4 |
| Çevrim içi veri girişi | 5 |
| Ana verilerin çevrim içi güncellenmesi | 5 |
| Karmaşık sorgular ve filtreleme | 4 |
| Yeniden kullanılabilir bileşenler | 3 |
| Kurulum ve geçiş kolaylığı | 3 |
| Kullanım kolaylığı | 4 |
| Güvenlik gereksinimi | 5 |
| Bildirim ve gerçek zamanlı iletişim | 4 |
| Çoklu rol ve yetki yapısı | 4 |
| Mobil ve web istemci çeşitliliği | 4 |
| Bakım ve genişletilebilirlik | 4 |
| Toplam Teknik Faktör | 59 |

Ayarlama katsayısı:

```text
VAF = 0.65 + (0.01 x 59)
VAF = 1.24
```

Ayarlanmış işlev noktası:

```text
FP = 1287 x 1.24
FP = 1595.88 ≈ 1596
```

#### 3.2 Yorum

Bu değer, projenin akademik bir mikro proje olmadığını gösterir. Tam ticari kapsamda değerlendirildiğinde proje orta-yüksek büyüklükte bir platformdur. Ancak ders tesliminde kodlama yapılmayacağı ve modelleme/dokümantasyon esas olduğu için bu büyüklük raporda kapsamlı analiz avantajı sağlar.

---

### 4. COCOMO Yaklaşımı

COCOMO modeli, yazılım geliştirme eforunu tahmin etmek için kullanılır. Bu proje dağıtık, çok modüllü ve farklı istemciler içeren bir sistem olduğu için "yarı gömülü / semi-detached" karaktere yakın kabul edilmiştir. Ancak akademik rapor kapsamında iki ayrı değerlendirme yapılmıştır:

1. Tam ticari ürün kapsamı
2. Ders projesi ve modelleme kapsamı

#### 4.1 Tam Ticari Ürün Varsayımı

İşlev noktası ve mevcut modül yoğunluğu dikkate alınarak yaklaşık kod satırı karşılığı:

```text
Tahmini LOC = 60.000
KLOC = 60
```

Semi-detached COCOMO katsayıları:

```text
Effort = 3.0 x KLOC^1.12
Effort = 3.0 x 60^1.12
Effort ≈ 294 kişi-ay
```

Tahmini geliştirme süresi:

```text
Duration = 2.5 x Effort^0.35
Duration ≈ 18 ay
```

Ortalama ekip büyüklüğü:

```text
Team Size = Effort / Duration
Team Size ≈ 16 kişi
```

Bu değer, uygulamanın tüm modülleriyle ticari üretim kalitesinde hazırlanması halinde büyük ekip ve uzun süre gerektireceğini gösterir.

#### 4.2 Ders Projesi ve Analiz Kapsamı Varsayımı

Bu final ödevi kapsamında kodlama yapılmayacağı için iş gücü ağırlığı analiz, modelleme, dokümantasyon, diyagram ve test planına kayar. Bu nedenle akademik iş gücü daha düşük hesaplanır:

| İş Paketi | Tahmini Kişi-Gün |
|---|---:|
| Problem ve kapsam analizi | 5 |
| Gereksinim analizi | 7 |
| Use case ve sözleşmeler | 8 |
| UML ve mimari modelleme | 8 |
| Veri sözlüğü ve veri tasarımı | 6 |
| Test, risk ve plan dokümanları | 6 |
| Rapor düzenleme ve Word teslimi | 8 |
| Toplam | 48 kişi-gün |

Akademik modelde tek öğrenci çalışması için bu süre, yoğunluk durumuna göre 3-5 haftalık çalışma aralığına denk gelir.

---

### 5. Kaynak Planı

#### 5.1 İnsan Kaynakları

Ödev bireysel teslim edilecek olsa da proje organizasyonu ders şartına uygun şekilde en az 6 personel içerecek biçimde modellenmiştir.

| Rol | Sorumluluk | Tahmini Katkı |
|---|---|---:|
| Proje Yöneticisi | Plan, kapsam, koordinasyon | %12 |
| İş/Sistem Analisti | Gereksinim, use case, iş kuralları | %16 |
| Backend Geliştirici | API, güvenlik, socket, servisler | %18 |
| Mobil Geliştirici | Flutter ekranları ve mobil akışlar | %18 |
| Web Panel Geliştiricisi | Admin ve satıcı paneli | %12 |
| Veritabanı ve DevOps Uzmanı | DB, deploy, izleme, yedekleme | %12 |
| Test ve Kalite Uzmanı | Test planı, kabul kriterleri | %12 |

#### 5.2 Donanım Kaynakları

| Kaynak | Kullanım Amacı |
|---|---|
| Geliştirici bilgisayarı | Kod, test, dokümantasyon |
| Android test cihazı | Mobil uygulama testleri |
| Android emülatör | Farklı ekran testleri |
| Bulut uygulama sunucusu | Backend yayınlama |
| Bulut veritabanı | MongoDB Atlas veri saklama |
| Dosya depolama alanı | Görsel ve medya dosyaları |

#### 5.3 Yazılım Kaynakları

| Yazılım / Araç | Amaç |
|---|---|
| Flutter SDK | Mobil uygulama geliştirme |
| Dart | Mobil programlama dili |
| Node.js | Backend çalışma ortamı |
| Express.js | REST API geliştirme |
| MongoDB Atlas | Bulut veritabanı |
| Mongoose | ODM ve veri modeli |
| Socket.io | Gerçek zamanlı iletişim |
| Firebase FCM | Bildirim altyapısı |
| React / Vite | Web panel geliştirme |
| Git / GitHub | Sürüm kontrolü |
| Postman / Swagger | API test ve dokümantasyon |
| PlantUML / Mermaid | Diyagram ve grafik hazırlama |

---

### 6. Maliyet Varsayımı

Bu bölümde ticari ekip ile 6 aylık prototip ve raporlama dönemi varsayılmıştır. Rakamlar akademik örnekleme içindir.

| Kalem | Aylık Tahmini Maliyet | Süre | Toplam |
|---|---:|---:|---:|
| Proje yöneticisi | 60.000 TL | 6 ay | 360.000 TL |
| Analist | 55.000 TL | 5 ay | 275.000 TL |
| Backend geliştirici | 70.000 TL | 6 ay | 420.000 TL |
| Mobil geliştirici | 70.000 TL | 6 ay | 420.000 TL |
| Web panel geliştirici | 60.000 TL | 4 ay | 240.000 TL |
| DB/DevOps uzmanı | 65.000 TL | 4 ay | 260.000 TL |
| Test uzmanı | 50.000 TL | 3 ay | 150.000 TL |
| Bulut servisleri | 10.000 TL | 6 ay | 60.000 TL |
| Test cihazları ve araçlar | 75.000 TL | 1 kez | 75.000 TL |
| Dokümantasyon ve eğitim | 40.000 TL | 1 kez | 40.000 TL |
| Toplam |  |  | 2.300.000 TL |

#### 6.1 Maliyet Dağılımı Yorumu

En büyük maliyet kalemi insan kaynağıdır. Bunun nedeni sistemin birden fazla uzmanlık alanına ihtiyaç duymasıdır. Backend, mobil uygulama, panel, veritabanı, test ve operasyon süreçleri farklı yetkinlikler gerektirir. Bulut maliyetleri erken aşamada insan kaynağına göre düşük kalsa da kullanıcı sayısı, medya kullanımı ve bildirim hacmi arttıkça büyüyebilir.

---

### 7. İş-Zaman Planı

#### 7.1 Faz Bazlı Plan

| Faz | Tarih Aralığı | Süre | Çıktı |
|---|---|---:|---|
| Planlama | 02.04.2026 - 07.04.2026 | 6 gün | Kapsam, ekip, yöntem |
| Analiz | 08.04.2026 - 16.04.2026 | 9 gün | Gereksinimler, aktörler |
| Mantıksal Model | 17.04.2026 - 25.04.2026 | 9 gün | Use case, veri modeli |
| Tasarım | 26.04.2026 - 03.05.2026 | 8 gün | Mimari, sınıf, sequence |
| Test ve Risk Planı | 04.05.2026 - 08.05.2026 | 5 gün | Test, risk, kabul kriterleri |
| Raporlama | 09.05.2026 - 12.05.2026 | 4 gün | Word raporu, ekler |
| Teslim Kontrolü | 13.05.2026 | 1 gün | Son teslim |

#### 7.2 Kritik Yol

Kritik yol aşağıdaki sırayı izler:

1. Kapsam belirleme
2. Gereksinim analizi
3. Use case ve iş kuralları
4. Veri modeli
5. Mimari tasarım
6. Test ve risk planı
7. Rapor düzenleme

Bu sırada özellikle gereksinim analizi tamamlanmadan doğru UML ve test planı üretilemez. Bu nedenle analiz aşaması projenin en kritik aşamasıdır.

---

### 8. İş Paketleri ve Teslim Çıktıları

| İş Paketi | Teslim Çıktısı |
|---|---|
| Proje tanımı | Problem, amaç, kapsam |
| Gereksinim analizi | FR/NFR listesi |
| Use case | Use case diyagramı ve sözleşmeleri |
| Veri modeli | Veri sözlüğü, ER/MongoDB view diyagramı |
| Mimari model | Deployment ve component diyagramları |
| Dinamik model | Sequence, activity ve state diyagramları |
| Test planı | Test senaryoları ve kabul ölçütleri |
| Risk planı | Risk matrisi |
| Maliyet planı | FP/COCOMO ve maliyet tablosu |
| Teslim raporu | Word formatlı final dokümanı |

---

### 9. Grafik Olarak Kullanılacak Veriler

Bu bölümdeki tablolar aşağıdaki grafiklere dönüştürülmelidir:

- Rol bazlı iş gücü dağılımı
- Maliyet kalemleri dağılımı
- Faz bazlı süre dağılımı
- Modül kapsam yoğunluğu

Bu grafikler için kaynak dosyalar ayrıca `charts` klasöründe hazırlanmıştır.

# 07 Kurulum Egitim Bakim Ve Operasyon Plani

## Ek E: Kurulum, Eğitim, Bakım ve Operasyon Planı

### 1. Amaç

Bu bölüm, sistemin geliştirme ve analiz aşamasından sonra nasıl kurulacağını, kimlere nasıl eğitim verileceğini, bakım sürecinin nasıl yürütüleceğini ve operasyonel devamlılığın nasıl sağlanacağını açıklar. Önceki proje raporlarında yer alan eğitim ve bakım planı yaklaşımı bu projeye uyarlanmıştır.

---

### 2. Kurulum Planı

#### 2.1 Kurulum Ortamları

Sistem üç ana ortam üzerinden ele alınmalıdır:

| Ortam | Amaç |
|---|---|
| Geliştirme ortamı | Kodlama, lokal test ve hata ayıklama |
| Test ortamı | Entegrasyon, kullanıcı kabul ve regresyon testleri |
| Canlı ortam | Son kullanıcıların eriştiği üretim sistemi |

#### 2.2 Backend Kurulumu

Backend kurulumu için gereken adımlar:

1. Node.js ortamı hazırlanır.
2. Ortam değişkenleri tanımlanır.
3. MongoDB Atlas bağlantısı doğrulanır.
4. JWT ve güvenlik anahtarları oluşturulur.
5. Upload dizini veya medya depolama servisi hazırlanır.
6. Firebase veya bildirim servisi bağlantısı tanımlanır.
7. API sağlık kontrolü yapılır.

#### 2.3 Mobil Uygulama Kurulumu

Mobil uygulama kurulumu için gereken adımlar:

1. Flutter SDK hazırlanır.
2. API base URL değeri doğru ortama göre ayarlanır.
3. Android build ayarları kontrol edilir.
4. Firebase yapılandırması doğrulanır.
5. Debug veya release APK alınır.
6. Gerçek cihaz üzerinde giriş, listeleme ve bildirim test edilir.

#### 2.4 Web Panel Kurulumu

Admin ve satıcı panelleri için:

1. Bağımlılıklar kurulur.
2. API URL yapılandırması yapılır.
3. Yetkili kullanıcı hesapları oluşturulur.
4. Panelde kullanıcı, ürün, sipariş ve rapor ekranları test edilir.

#### 2.5 Veritabanı Kurulumu

Veritabanı tarafında:

1. MongoDB Atlas cluster hazırlanır.
2. Kullanıcı ve bağlantı izinleri tanımlanır.
3. Koleksiyonlar uygulama tarafından oluşturulur.
4. Gerekli indeksler kontrol edilir.
5. Test verileri eklenir.
6. Yedekleme politikası belirlenir.

---

### 3. Eğitim Planı

#### 3.1 Eğitim Verilecek Gruplar

| Grup | Eğitim İçeriği |
|---|---|
| Son kullanıcı | Kayıt, pet ekleme, ilan, randevu, sipariş |
| Veteriner | Klinik profili, randevu, sağlık kayıtları |
| Pet bakıcısı | Profil, rezervasyon, hizmet süreci |
| Satıcı | Mağaza, ürün, sipariş, kupon |
| Admin | Kullanıcı, içerik, rapor, moderasyon |
| Teknik ekip | Deploy, log, yedekleme, hata analizi |

#### 3.2 Eğitim Yöntemi

Eğitim üç biçimde verilebilir:

1. Kısa kullanım kılavuzu
2. Ekran görüntülü adım adım doküman
3. Uygulamalı demo oturumu

#### 3.3 Eğitim Süresi

| Eğitim | Süre |
|---|---:|
| Son kullanıcı eğitimi | 1 saat |
| Satıcı eğitimi | 2 saat |
| Admin eğitimi | 3 saat |
| Teknik ekip eğitimi | 4 saat |

#### 3.4 Eğitim Başarı Ölçütleri

- Kullanıcı kendi hesabını açabilmeli
- Kullanıcı pet profili oluşturabilmeli
- Kullanıcı randevu veya rezervasyon oluşturabilmeli
- Satıcı ürün ekleyebilmeli
- Admin raporlanan içeriği inceleyebilmeli
- Teknik ekip sağlık kontrolü ve log takibi yapabilmeli

---

### 4. Bakım Planı

#### 4.1 Bakım Türleri

| Bakım Türü | Açıklama |
|---|---|
| Düzeltici bakım | Hataların giderilmesi |
| Uyarlayıcı bakım | Yeni işletim sistemi, API veya servis değişikliklerine uyum |
| İyileştirici bakım | Performans ve kullanıcı deneyimi geliştirmeleri |
| Önleyici bakım | Hata oluşmadan risklerin azaltılması |

#### 4.2 Bakım Süreci

1. Hata veya talep kaydı açılır.
2. Öncelik ve etki analizi yapılır.
3. Sorumlu kişi atanır.
4. Çözüm geliştirilir.
5. Test ortamında doğrulanır.
6. Canlı ortama kontrollü aktarılır.
7. Değişiklik kayıt altına alınır.

#### 4.3 Bakım Öncelik Seviyeleri

| Seviye | Açıklama | Müdahale Süresi |
|---|---|---:|
| Kritik | Sistem kullanılamıyor veya güvenlik açığı var | 4 saat |
| Yüksek | Temel işlem yapılamıyor | 1 iş günü |
| Orta | Alternatif yol var ama kullanıcı etkileniyor | 3 iş günü |
| Düşük | Kozmetik veya iyileştirme talebi | Planlı sürüm |

---

### 5. Operasyon Planı

#### 5.1 İzlenecek Göstergeler

| Gösterge | Neden Önemli |
|---|---|
| API yanıt süresi | Performans takibi |
| 5xx hata oranı | Sunucu kararlılığı |
| Başarısız giriş sayısı | Güvenlik takibi |
| Socket bağlantı sayısı | Gerçek zamanlı iletişim yükü |
| Bildirim başarı oranı | FCM verimliliği |
| Sipariş tamamlama oranı | Ticari akış sağlığı |
| Randevu iptal oranı | Hizmet kalitesi |

#### 5.2 Loglama

Loglanması gereken olaylar:

- Giriş denemeleri
- Rol ve yetki değişiklikleri
- Admin işlemleri
- Sipariş durum değişiklikleri
- Randevu durum değişiklikleri
- Rezervasyon durum değişiklikleri
- Kritik API hataları

#### 5.3 Yedekleme Planı

| Veri | Yedekleme Sıklığı |
|---|---|
| Kullanıcı ve pet verileri | Günlük |
| Sipariş ve ödeme benzeri kayıtlar | Günlük |
| Mesaj ve konuşmalar | Günlük |
| Dosya yüklemeleri | Haftalık |
| Konfigürasyonlar | Her değişiklikte |

#### 5.4 Felaket Kurtarma

Sistem kesintisi veya veri kaybı durumunda:

1. Sorunun kapsamı belirlenir.
2. Son sağlıklı yedek tespit edilir.
3. Veri geri yükleme işlemi yapılır.
4. API sağlık kontrolü çalıştırılır.
5. Admin ve teknik ekip bilgilendirilir.
6. Olay sonrası kök neden analizi yapılır.

---

### 6. Entegrasyon Planı

#### 6.1 Entegre Edilecek Servisler

| Servis | Amaç |
|---|---|
| MongoDB Atlas | Merkezi veri saklama |
| Firebase FCM | Bildirim gönderimi |
| Google Places | Veteriner/konum arama |
| Socket.io | Anlık mesajlaşma ve olay yayını |
| Upload servisi | Görsel ve medya yönetimi |

#### 6.2 Entegrasyon Riskleri

- Dış servis erişim hatası
- API anahtarının geçersiz olması
- Kota sınırı
- Ağ gecikmesi
- Yanlış ortam değişkeni

#### 6.3 Entegrasyon Testleri

| Test | Beklenen Sonuç |
|---|---|
| MongoDB bağlantı testi | API veri okuyup yazabilmeli |
| FCM test bildirimi | Cihaza bildirim düşmeli |
| Google Places araması | Konuma göre sonuç gelmeli |
| Socket bağlantısı | Kullanıcı çevrim içi görünmeli |
| Upload testi | Görsel yüklenip URL dönmeli |

---

### 7. Güvenlik Operasyonu

#### 7.1 Periyodik Kontroller

- Yetkisiz erişim logları incelenir.
- Admin hesapları kontrol edilir.
- Ortam değişkenleri ve anahtarlar yenilenir.
- Rate limit kayıtları değerlendirilir.
- Şüpheli kullanıcı davranışları raporlanır.

#### 7.2 Kullanıcı Verisi Koruma

Kullanıcı verilerinin korunması için:

- Gereksiz veri toplanmamalıdır.
- Hassas veri loglara yazılmamalıdır.
- Silme ve hesap kapatma talepleri süreçle yönetilmelidir.
- Erişim rolleri düzenli gözden geçirilmelidir.

---

### 8. Sürümleme ve Yayın Planı

| Sürüm | İçerik |
|---|---|
| v0.1 | Temel auth, pet ve ilan modeli |
| v0.2 | Mesajlaşma ve sahiplendirme |
| v0.3 | Veteriner ve randevu |
| v0.4 | Bakıcı ve rezervasyon |
| v0.5 | Mağaza ve sipariş |
| v0.6 | Admin/satıcı paneli |
| v1.0 | Test edilmiş bütünleşik MVP |

#### 8.1 Yayın Öncesi Kontrol Listesi

- API health endpoint çalışıyor
- Mobil uygulama giriş yapabiliyor
- Randevu ve sipariş akışları test edildi
- Admin panel erişimi kontrol edildi
- Veritabanı bağlantısı doğrulandı
- Bildirim testi yapıldı
- Rollback planı hazır

---

### 9. Sonuç

Kurulum, eğitim, bakım ve operasyon planı; projenin yalnızca analiz edilen bir fikir değil, gerçek dünyada sürdürülebilir biçimde çalışabilecek bir yazılım sistemi olarak düşünüldüğünü gösterir. Özellikle dağıtık sistemlerde kurulum ve bakım adımlarının raporda bulunması, yazılım mühendisliği bakışını güçlendirir.

# 08 Grafikler Ve Diyagramlar Kullanim Rehberi

## Ek F: Grafikler ve Diyagramlar Kullanım Rehberi

### 1. Amaç

Bu rehber, final raporuna eklenecek grafik ve diyagramların hangi bölümde kullanılacağını açıklar. Eski örnek raporlarda güçlü görülen tablo, grafik, ER/veri modeli, use case ve iş akışı yaklaşımı bu projeye uyarlanmıştır.

---

### 2. Rapor İçine Eklenecek Grafikler

#### 2.1 Maliyet Dağılımı Grafiği

Kaynak dosya:

- `charts/maliyet_dagilimi_pie.mmd`

Kullanılacağı bölüm:

- `06_MALIYET_KESTIRIMI_VE_KAYNAK_PLANLAMA.md`
- "Maliyet Varsayımı" başlığından sonra

Grafiğin amacı:

- Projede maliyetin büyük kısmının insan kaynağından geldiğini göstermek
- Bulut, cihaz ve dokümantasyon giderlerinin toplam içindeki oranını görselleştirmek

#### 2.2 Rol Bazlı İş Gücü Dağılımı Grafiği

Kaynak dosya:

- `charts/rol_bazli_isgucu_pie.mmd`

Kullanılacağı bölüm:

- Kaynak planı
- Proje ekibi ve roller

Grafiğin amacı:

- Backend, mobil, analiz, test ve operasyon rollerinin projedeki ağırlığını göstermek

#### 2.3 Faz Bazlı Süre Dağılımı Grafiği

Kaynak dosya:

- `charts/faz_sureleri_xy.mmd`

Kullanılacağı bölüm:

- İş-zaman planı

Grafiğin amacı:

- Planlama, analiz, tasarım, test ve raporlama fazlarının sürelerini görselleştirmek

#### 2.4 Modül Kapsam Yoğunluğu Grafiği

Kaynak dosya:

- `charts/modul_kapsam_yogunlugu_xy.mmd`

Kullanılacağı bölüm:

- Proje kapsamı
- Sistem genel tanımı

Grafiğin amacı:

- Hangi modüllerin daha yoğun gereksinim ve iş kuralı içerdiğini göstermek

#### 2.5 Gantt Grafiği

Kaynak dosya:

- `charts/proje_gantt.mmd`

Kullanılacağı bölüm:

- Ayrıntılı proje planı

Grafiğin amacı:

- Teslim tarihine kadar planlanan fazları zaman çizelgesi üzerinde göstermek

---

### 3. Rapor İçine Eklenecek UML ve Sistem Diyagramları

#### 3.1 Use Case Diyagramı

Kaynak dosya:

- `use_case_diagram.puml`

Kullanılacağı bölüm:

- Kullanım senaryoları
- Aktör analizi

#### 3.2 Bağlam Diyagramı

Kaynak dosya:

- `context_diagram.puml`

Kullanılacağı bölüm:

- Sistem genel tanımı
- Mimari bakış

Bu diyagram, sistemi dış aktörler ve dış servislerle birlikte tek bakışta gösterir.

#### 3.3 Veri Akış Diyagramı

Kaynak dosya:

- `data_flow_level0.puml`

Kullanılacağı bölüm:

- Sistem çözümleme
- Mantıksal model

Bu diyagram; kimlik, pet, hizmet, ticaret, mesaj ve admin süreçleri arasındaki veri akışlarını gösterir.

#### 3.4 Deployment Diyagramı

Kaynak dosya:

- `deployment_diagram.puml`

Kullanılacağı bölüm:

- Mimari tasarım
- Dağıtık sistem açıklaması

#### 3.5 Component Diyagramı

Kaynak dosya:

- `component_diagram.puml`

Kullanılacağı bölüm:

- Genel tasarım
- Ortak alt sistemler

#### 3.6 Sınıf Diyagramı

Kaynak dosya:

- `class_diagram.puml`

Kullanılacağı bölüm:

- Nesneye dayalı tasarım
- Analiz ve tasarım sınıfları

#### 3.7 MongoDB Görünüm / Veri Modeli Diyagramı

Kaynak dosya:

- `mongodb_view_diagram.puml`

Kullanılacağı bölüm:

- Veri tasarımı
- Veri sözlüğü

Bu diyagram, eski örneklerdeki `ER Diagram` veya `Database Diagram` bölümlerinin MongoDB tabanlı karşılığıdır.

#### 3.8 Sequence Diyagramları

Kaynak dosyalar:

- `sequence_vet_appointment.puml`
- `sequence_order_flow.puml`
- `sequence_realtime_message.puml`

Kullanılacağı bölüm:

- Tasarım etkileşim diyagramları

Bu diyagramlar sırasıyla veteriner randevusu, sipariş oluşturma ve gerçek zamanlı mesajlaşma akışlarını gösterir.

#### 3.9 Activity Diyagramları

Kaynak dosyalar:

- `activity_sitter_booking.puml`
- `activity_order_flow.puml`

Kullanılacağı bölüm:

- İş akışları
- Kullanım senaryosu detayları

#### 3.10 State Diyagramları

Kaynak dosyalar:

- `state_appointment.puml`
- `state_order.puml`
- `state_sitter_booking.puml`

Kullanılacağı bölüm:

- Durum yönetimi
- İş kuralları

Bu diyagramlar sistemdeki durum bazlı nesnelerin yaşam döngüsünü gösterir. Özellikle randevu, sipariş ve bakıcı rezervasyonu gibi süreçlerde değerlidir.

---

### 4. Word İçin Önerilen Şekil Sırası

1. Şekil 1: Sistem Bağlam Diyagramı
2. Şekil 2: Use Case Diyagramı
3. Şekil 3: Veri Akış Diyagramı
4. Şekil 4: Deployment Diyagramı
5. Şekil 5: Component Diyagramı
6. Şekil 6: Sınıf Diyagramı
7. Şekil 7: MongoDB Veri Modeli Diyagramı
8. Şekil 8: Veteriner Randevusu Sequence Diyagramı
9. Şekil 9: Sipariş Sequence Diyagramı
10. Şekil 10: Mesajlaşma Sequence Diyagramı
11. Şekil 11: Bakıcı Rezervasyonu Activity Diyagramı
12. Şekil 12: Sipariş Activity Diyagramı
13. Şekil 13: Randevu Durum Diyagramı
14. Şekil 14: Sipariş Durum Diyagramı
15. Şekil 15: Bakıcı Rezervasyonu Durum Diyagramı
16. Şekil 16: Maliyet Dağılımı Grafiği
17. Şekil 17: Rol Bazlı İş Gücü Dağılımı
18. Şekil 18: Faz Bazlı Süre Grafiği
19. Şekil 19: Modül Kapsam Yoğunluğu Grafiği
20. Şekil 20: Gantt İş-Zaman Planı

---

### 5. Render Notu

PlantUML dosyaları `.puml`, Mermaid grafikleri `.mmd` uzantılıdır. Word'e eklemek için bu dosyalar görsele çevrilmelidir. Kullanılabilecek araçlar:

- PlantUML eklentisi
- Mermaid Live Editor
- VS Code PlantUML / Mermaid preview eklentileri
- draw.io import desteği

Görsele çevrildikten sonra her diyagramın altına kısa açıklama eklenmelidir. Diyagramların açıklamasız bırakılması rapor kalitesini düşürür.
