# T.C.
# KONYA TEKNİK ÜNİVERSİTESİ
# BİLGİSAYAR MÜHENDİSLİĞİ
# BİLGİSAYAR MÜHENDİSLİĞİ UYGULAMASI – 2
# (BİTİRME PROJESİ-2) ARA RAPOR FORMU

**Öğrencinin Adı-Soyadı:** [Ad Soyad]  
**Numarası:** [Numara]  
**Danışmanı Adı Soyadı:** [Danışman Adı Soyadı]  
**Sınav Tarihi:** [Tarih]  
**Projenin Konusu:** Flutter tabanlı evcil hayvan sahiplendirme, eşleştirme ve hizmet platformunun geliştirilmesi

## DÖNEM İÇİ YAPILAN ÇALIŞMALARIN ÖZETİ

Bu dönem çalışmanın ana amacı, önceki dönemde temeli atılan mobil uygulamayı daha geniş kapsamlı, daha kararlı ve gerçek kullanıcılarla test edilebilir bir yapıya taşımaktır. Önceki aşamada projede sahiplendirme ve eşleştirme ilanları, temel mesajlaşma yapısı, profil düzenleme ekranları, mağaza tarafında ürün görüntüleme ve sipariş oluşturma gibi ana modüller bulunmaktaydı. Ancak arayüz tarafında renk ve bileşen tutarsızlıkları, bazı hata akışlarında yetersiz geri bildirimler ve sistemin büyük ölçüde yerel geliştirme ortamına bağlı olması gibi önemli sınırlılıklar vardı. Bu dönem yapılan çalışmalar, yalnızca yeni ekranlar eklemekten ibaret kalmamış; aynı zamanda projeyi teknik altyapı, kullanıcı deneyimi ve canlı kullanım açısından daha olgun bir düzeye taşımıştır.

Bu dönemin en önemli çıktılarından biri veteriner modülünün projeye eklenmesidir. Veteriner modülü ile kullanıcıların yakın veterinerleri görebilmesi, veteriner detay sayfasını inceleyebilmesi, uygun slotlara göre randevu oluşturabilmesi ve randevu durumunu takip edebilmesi mümkün hale gelmiştir. Böylece proje, yalnızca ilanların bulunduğu bir mobil uygulama olmaktan çıkarılmış; evcil hayvan sahiplerinin günlük yaşamda doğrudan kullanabileceği bir yardımcı sisteme dönüştürülmüştür. Teknik açıdan bu modül, konum tabanlı sorgulama, randevu yönetimi ve kullanıcı-veteriner etkileşimi gibi birden fazla alt problemi aynı çatı altında çözmeyi gerektirmiştir.

Veteriner modülüyle bağlantılı olarak konum temelli arama mantığı da güçlendirilmiştir. Yakındaki veterinerler ekranında kullanıcı konumuna göre daha anlamlı sonuçlar üretilmesi hedeflenmiştir. Mobil uygulama özelinde “yakınlık” kavramı çok kritiktir; çünkü kullanıcı veteriner ararken yalnızca bir liste görmek değil, gerçekten bulunduğu noktaya uygun sonuçlara ulaşmak ister. Bu nedenle konum bilgisinin doğru alınması, sunucu tarafında coğrafi filtreleme uygulanması ve sonuçların mantıklı biçimde sıralanması proje için önemli bir kazanım olmuştur.

Bu dönemin ikinci büyük başlığı evcil hayvan bakıcısı modülüdür. Bu modül ile sistem, sahiplendirme ve eşleştirme temelli bir sosyal platform olmanın ötesine geçerek hizmet odaklı bir yapıya dönüşmüştür. Bakıcı modülünde bakıcı profil oluşturma, hizmet türlerini tanımlama, hangi hayvan türleriyle çalışıldığını belirtme, konum ekleme, yakın bakıcıların listelenmesi, bakıcı detay sayfasının görüntülenmesi ve rezervasyon oluşturulması gibi temel akışlar geliştirilmiştir. Bunun yanında rezervasyonların kabul edilmesi, reddedilmesi, iptal edilmesi ve tamamlanması gibi iş süreçleri de sistem içinde ele alınmıştır.

Bakıcı modülünün önemli bir tarafı da yalnızca statik profil ekranlarından ibaret olmamasıdır. Rezervasyon sonrasında canlı konum güncellemeleri, yürüyüş başlangıç ve bitiş olayları, bakım raporları ve durum değişikliği bildirimleri gibi gelişmiş akışlar da sisteme dahil edilmiştir. Böylece kullanıcı, hizmeti talep ettikten sonra süreci uygulama üzerinden takip edebilmekte, bakıcı da yaptığı işlemleri sistem üzerinde görünür hale getirebilmektedir. Bu yapı hem kullanıcı güvenini artırmakta hem de yazılım mühendisliği açısından gerçek zamanlı veri akışını destekleyen daha ileri bir mimari gerektirmektedir.

Bu dönem ayrıca uygulamanın arayüzü baştan sona yeniden ele alınmıştır. Önceki sürümde bazı ekranlarda yazı rengi, arka plan, buton stili ve kart tasarımlarında birbirinden kopuk kararlar bulunmaktaydı. Yeni düzenleme ile birlikte uygulamanın ana renk dili yeşil tonları etrafında birleştirilmiş, bileşenler tek bir tema mantığı altında yeniden düzenlenmiştir. Bu güncelleme yalnızca görsel bir güzelleştirme değildir. Okunabilirlik artmış, kullanıcıların önemli eylem butonlarını fark etmesi kolaylaşmış ve ekranlar arası bütünlük sağlanmıştır. Özellikle aynı uygulama içinde ilanlar, mağaza, veteriner, bakıcı ve profil gibi farklı modüller bulunduğu için ortak bir tasarım dili oluşturulması çok önemliydi.

Arayüz geliştirmelerinin önemli bir parçası olarak karanlık mod desteği eklenmiştir. Kullanıcı artık uygulamayı açık veya koyu tema ile kullanabilmektedir. Tema tercihi kalıcı olarak saklanmakta ve uygulama yeniden açıldığında korunmaktadır. Teknik açıdan bu özellik; AppBar, kartlar, giriş alanları, butonlar, sekmeler ve alt gezinme yapısının iki farklı tema senaryosuna göre tutarlı davranmasını gerektirmiştir. Son kullanıcı açısından ise bu geliştirme uygulamayı daha modern ve kişiselleştirilebilir hale getirmiştir.

Bir diğer önemli geliştirme çok dilli kullanım desteğidir. Uygulamaya Türkçe ve İngilizce dil seçeneği eklenmiş, metinler merkezi yerelleştirme dosyaları üzerinden yönetilir hale getirilmiştir. Bu yaklaşım, projeyi yalnızca yerel kullanım için hazırlanan tek dilli bir uygulama olmaktan çıkarıp ölçeklenebilir bir yapıya taşımıştır. Teknik olarak metinlerin sabit kod içinden ayrıştırılması, dil seçiminin saklanması ve tüm ekranların yerelleştirme mekanizmasına uyumlu hale getirilmesi bu sürecin temel parçaları olmuştur.

Mağaza tarafında bu dönemde admin paneli ve satıcı paneli kapsam dışında tutulmakla birlikte, son kullanıcı deneyimini iyileştiren önemli güncellemeler yapılmıştır. Ürün listeleme ekranında arama, sıralama ve filtreleme tarafı daha işlevsel hale getirilmiştir. Böylece kullanıcılar ürünleri yalnızca düz bir liste halinde görmek yerine belirli ölçütlere göre daha hızlı bulabilmektedir. Ürün sayısı arttıkça filtreleme ve sıralama özelliklerinin önemi daha da arttığından, bu geliştirme mağaza modülünün büyüyebilirliği açısından kritik bir adımdır.

Bu dönem yapılan en büyük teknik sıçrama ise canlı sunucuya geçiştir. Önceki durumda uygulama büyük ölçüde yerel backend ve yerel veri tabanı ile çalışmaktaydı. Bu durum, çok kullanıcılı testleri ve gerçek cihaz senaryolarını kısıtlıyordu. Bu dönem backend canlı ortama taşınmış, mobil uygulama bu sunucu üzerinden veri alacak şekilde yapılandırılmış ve APK alınarak gerçek cihazlarda kullanım mümkün hale getirilmiştir. Böylece proje yalnızca geliştirici bilgisayarında çalışan bir prototip olmaktan çıkıp, birden fazla kişi tarafından test edilebilen bir sisteme dönüşmüştür.

Canlı backend geçişi ile birlikte veri tabanı da yerel MongoDB kurulumundan MongoDB Atlas altyapısına taşınmıştır. Atlas kullanımı sayesinde veriler bulutta merkezi biçimde tutulmaya başlanmış, farklı cihazlardan aynı veri kümesine erişim mümkün hale gelmiştir. Bu değişim, çok kullanıcılı test senaryolarında büyük kolaylık sağlamış ve uygulamayı gerçek kullanım koşullarına yaklaştırmıştır. Ayrıca veri tabanının geliştirici bilgisayarına bağımlı olmaktan çıkarılması, sistemin sürdürülebilirliği açısından da önemli bir adımdır.

Bu dönemde yalnızca yeni modüller eklenmemiş, mevcut modüller üzerinde de çok sayıda hata düzeltmesi yapılmıştır. Mesajlaşma, mağaza akışı, sepet davranışı, konum bazlı sonuçlar, sohbet ekranları, filtreleme mantıkları ve bakıcı rezervasyon akışları üzerinde iyileştirmeler uygulanmıştır. Yazılım projelerinde yeni özellik eklemek kadar mevcut özellikleri kararlı hale getirmek de önemlidir. Bu açıdan değerlendirildiğinde bu dönem, hem işlev genişletme hem de kalite artırma dönemi olarak tanımlanabilir.

Sonuç olarak bu dönem sonunda proje, önceki sürüme göre çok daha kapsamlı bir hale gelmiştir. Uygulama artık sahiplendirme ve eşleştirme modüllerinin yanında veteriner ve bakıcı hizmetlerini içeren, Türkçe ve İngilizce dil desteği bulunan, açık ve koyu tema ile çalışabilen, daha tutarlı bir arayüze sahip, mağaza tarafında daha kullanışlı filtreleme araçları sunan, canlı sunucu ve bulut veri tabanı üzerinden çalışan bir mobil platform düzeyine ulaşmıştır.

## KAYNAK ARAŞTIRMASI

Bu dönem kaynak araştırması, projede kullanılan teknolojilerin seçimi ve doğru uygulanması amacıyla yapılmıştır. Uygulama; mobil istemci, sunucu tarafı, bulut veri tabanı, gerçek zamanlı iletişim, bildirim ve hata izleme gibi farklı alanları aynı anda kapsadığı için araştırma süreci de çok yönlü ilerlemiştir. Amaç yalnızca hangi teknolojiyi kullanacağımıza karar vermek değil, bu teknolojilerin proje gereksinimlerine nasıl uyarlanacağını anlamaktır.

Mobil istemci tarafında Flutter yaklaşımı incelenmiştir. Flutter’ın tek kod tabanından mobil arayüz üretmesi, tema sistemi ile ortak tasarım dilini desteklemesi ve yerelleştirme altyapısının güçlü olması proje için önemli avantajlar sunmuştur. Özellikle bu dönemde eklenen karanlık mod ve Türkçe-İngilizce dil desteği, Flutter’ın resmi dokümantasyonundaki tema ve internationalization yaklaşımlarından yararlanılarak şekillendirilmiştir (Flutter Documentation, 2026a; Flutter Documentation, 2026b).

Canlı uygulamalarda hata takibi ve kullanıcıya bildirim iletimi büyük önem taşır. Bu nedenle Firebase ekosistemi değerlendirilmiştir. Firebase Crashlytics ile uygulama hatalarının merkezi biçimde izlenmesi, Firebase Cloud Messaging ile ise önemli olayların cihazlara bildirim olarak iletilmesi hedeflenmiştir. Mesajlar, rezervasyon güncellemeleri ve hatırlatma akışları açısından bu servislerin projeye önemli katkı sağladığı görülmüştür (Firebase Documentation, 2026a; Firebase Documentation, 2026b; Firebase Documentation, 2026c).

Sunucu tarafında Node.js ve Express tabanlı REST API yaklaşımı benimsenmiştir. Bu mimarinin seçilme nedeni, mobil istemci ile hızlı veri alışverişi kurabilmesi ve modüler bir backend yapısı oluşturmaya elverişli olmasıdır. Bunun yanında gerçek zamanlı iletişim ihtiyacı için Socket.IO araştırılmış ve özellikle mesajlaşma, rezervasyon değişiklikleri ve canlı konum güncellemeleri açısından uygun bir çözüm olduğu görülmüştür (Socket.IO Documentation, 2026).

Veri tabanı tarafında ise MongoDB Atlas öne çıkmıştır. Yerel veri tabanından bulut veri tabanına geçişle birlikte verilerin çok cihazlı kullanım senaryolarına açılması, merkezi olarak saklanması ve canlı backend ile birlikte çalışması mümkün hale gelmiştir. Atlas’ın yönetilen bulut veri tabanı yaklaşımı, bu proje için hem operasyonel kolaylık hem de çok kullanıcılı test kabiliyeti sağlamıştır (MongoDB, 2026a; MongoDB, 2026b).

Canlıya alma sürecinde Render incelenmiştir. Render’ın Git tabanlı dağıtım modeli, çevre değişkenleri ile çalışma mantığı ve web servis barındırma yaklaşımı, backend tarafının sürdürülebilir biçimde canlıda çalışmasını kolaylaştırmıştır (Render Documentation, 2026a; Render Documentation, 2026b). Bu araştırma sayesinde proje yalnızca geliştirme bilgisayarında çalışan bir yapı olmaktan çıkıp dış dünyaya açık bir servis haline getirilmiştir.

Kaynak araştırmasının kullanıcı deneyimi boyutu da önemlidir. Tema tutarlılığı, okunabilirlik, filtreleme, çoklu dil desteği ve görev akışlarının açıklığı gibi konular doğrudan kullanıcı memnuniyetini etkilemektedir. Bu nedenle arayüz güncellemeleri yalnızca görsel tercih olarak değil, kullanılabilirlik iyileştirmesi olarak değerlendirilmiştir.

## PROJEDE KULLANILAN MATERYAL VE METOTLAR

Proje istemci ve sunucu tarafı birlikte çalışan çok katmanlı bir yapı ile geliştirilmiştir. Mobil istemci tarafında Flutter ve Dart kullanılmıştır. Durum yönetimi için Riverpod, ağ iletişimi için Dio, yerel tercihlerin saklanması için SharedPreferences ve bildirim/hata takibi için Firebase servisleri tercih edilmiştir. Tema ve dil seçiminin kalıcı hale getirilmesi, kullanıcı oturumunun korunması ve ekranlar arası veri akışının düzenli biçimde sürdürülmesi bu yapı üzerinden sağlanmıştır.

Sunucu tarafında Node.js ve Express tabanlı bir backend mimarisi kullanılmıştır. Route, controller ve model ayrımı ile ilerlenmiş; böylece ilanlar, mesajlaşma, veteriner, bakıcı, mağaza ve sipariş gibi modüller birbirinden ayrıştırılmıştır. Veri modelleri Mongoose ile tanımlanmış ve MongoDB Atlas üzerinde saklanmıştır. Bu yaklaşım, proje büyüdükçe yeni modüllerin mevcut yapıyı bozmadan eklenmesini kolaylaştırmaktadır.

Gerçek zamanlı iletişim gereken alanlarda Socket.IO kullanılmıştır. Mesajlaşma sistemi, yeni rezervasyon olayları, rezervasyon durum değişiklikleri ve bazı canlı güncellemeler bu katman üzerinden desteklenmektedir. Böylece kullanıcıların bazı ekranlarda sürekli yenileme yapmasına gerek kalmadan olay temelli veri aktarımı mümkün olmuştur.

Konum bazlı işlemler için cihazdan alınan enlem-boylam bilgisi değerlendirilmiştir. Yakındaki veterinerler ve yakın bakıcılar gibi ekranlarda mobil cihazdan alınan konum bilgisi backend’e gönderilmekte, backend tarafında coğrafi filtreleme ile anlamlı sonuçlar üretilmektedir. Bu yöntem, özellikle gerçek kullanım senaryosunda kullanıcıya daha ilgili sonuçlar göstermektedir.

Arayüz geliştirme yöntemi olarak ortak tema tanımı ve bileşen standardizasyonu benimsenmiştir. Uygulama genelinde yeşil tonlu yeni bir tasarım dili oluşturulmuş, açık/koyu tema desteği tek merkezden yönetilecek şekilde kurgulanmıştır. Dil desteği için yerelleştirme dosyaları kullanılmış ve Türkçe-İngilizce içerikler aynı altyapı üzerinden sunulmuştur.

Geliştirme sürecinde iteratif yöntem tercih edilmiştir. Önce mevcut çalışan çekirdek akışlar korunmuş, ardından veteriner ve bakıcı gibi yeni modüller eklenmiş, sonrasında arayüz ve stabilite düzenlemeleri yapılmıştır. Canlı backend’e geçiş, APK derleme ve gerçek cihaz testleri de bu iteratif yaklaşımın parçası olarak ele alınmıştır.

Kullanılan başlıca materyaller aşağıdadır:

- Flutter ve Dart
- Riverpod
- Dio
- SharedPreferences
- Firebase Cloud Messaging
- Firebase Crashlytics
- Node.js ve Express.js
- MongoDB Atlas ve Mongoose
- Socket.IO
- Render
- Git ve GitHub
- Android Studio, Flutter SDK ve ADB

## DÖNEM SONU HEDEFLERİNİN DEĞERLENDİRİLMESİ

Bu dönem sonunda belirlenen hedeflerin büyük kısmı gerçekleştirilmiştir. En önemli kazanım, projenin çekirdek ilan ve mesajlaşma yapısının üzerine gerçek hayatta karşılığı olan iki güçlü modülün, yani veteriner ve bakıcı sistemlerinin eklenmesidir. Bu modüller projenin kapsamını genişletmiş ve uygulamayı daha işlevsel hale getirmiştir.

Kullanıcı deneyimi açısından da hedefler büyük ölçüde karşılanmıştır. Açık ve koyu tema desteği, Türkçe ve İngilizce dil seçeneği, yeşil temalı daha tutarlı arayüz, hata mesajlarının daha anlaşılır sunulması ve mağaza filtreleme-sıralama geliştirmeleri uygulamanın genel kalite algısını yükseltmiştir.

Altyapı tarafında ise canlı backend ortamına geçilmesi ve MongoDB Atlas kullanımına başlanması dönem içindeki en stratejik başarıdır. Bu sayede uygulama yalnızca yerel ortamda çalışan bir demo olmaktan çıkmış, birden fazla cihazda denenebilen bir sisteme dönüşmüştür. APK alınıp gerçek cihazlarda test yapılabilmesi, proje çıktısının değerini artırmıştır.

Bununla birlikte ilerleyen aşamada geliştirilebilecek alanlar da vardır. İlan filtreleme sistemine şehir/ülke gibi metinsel konum bilgileri eklenebilir. Bakıcı modülünde fiyat aralığı, minimum puan, müsaitlik ve hizmet süresi bazlı filtreler geliştirilebilir. Veteriner modülünde daha gelişmiş takvim yönetimi ve sağlık geçmişi ekranları eklenebilir. Ayrıca otomatik test kapsamının genişletilmesi ve performans ölçümlerinin artırılması sistemin daha da sağlamlaşmasına katkı sağlayacaktır.

Genel olarak değerlendirildiğinde bu dönem, projenin önceki aşamasına kıyasla en büyük ilerlemenin yaşandığı geliştirme dönemi olmuştur. Proje hem teknik mimari hem de kullanıcı deneyimi açısından daha güçlü, daha anlaşılır ve daha gerçekçi bir seviyeye taşınmıştır.

## KAYNAKLAR

1. Flutter Documentation, 2026a; “Use Themes to Share Colors and Font Styles”, https://docs.flutter.dev/cookbook/design/themes, erişim tarihi: 09.04.2026
2. Flutter Documentation, 2026b; “Internationalizing Flutter Apps”, https://docs.flutter.dev/ui/internationalization, erişim tarihi: 09.04.2026
3. Firebase Documentation, 2026a; “Get Started with Crashlytics for Flutter”, https://firebase.google.com/docs/crashlytics/flutter/get-started, erişim tarihi: 09.04.2026
4. Firebase Documentation, 2026b; “Firebase Cloud Messaging”, https://firebase.google.com/docs/cloud-messaging, erişim tarihi: 09.04.2026
5. Firebase Documentation, 2026c; “Get Started with Firebase Cloud Messaging in Flutter Apps”, https://firebase.google.com/docs/cloud-messaging/flutter/client, erişim tarihi: 09.04.2026
6. MongoDB, 2026a; “MongoDB Atlas”, https://www.mongodb.com/atlas, erişim tarihi: 09.04.2026
7. MongoDB, 2026b; “What is MongoDB Atlas?”, https://www.mongodb.com/docs/atlas/index/, erişim tarihi: 09.04.2026
8. Render Documentation, 2026a; “Web Services”, https://render.com/docs/web-services, erişim tarihi: 09.04.2026
9. Render Documentation, 2026b; “Deploying on Render”, https://render.com/docs/deploys/, erişim tarihi: 09.04.2026
10. Socket.IO Documentation, 2026; “Socket.IO”, https://socket.io/, erişim tarihi: 09.04.2026
