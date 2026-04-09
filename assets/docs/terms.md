# GİZLİLİK POLİTİKASI (PRIVACY POLICY)

**Son Güncelleme Tarihi:** 09 Nisan 2026

[cite_start]Bu Gizlilik Politikası, AuraNet ("biz", "uygulama" veya "AuraNet") Ev Ağı Güvenlik ve Analiz Uygulaması'nı kullandığınızda bilgilerinizi nasıl topladığımızı, kullandığımızı, koruduğumuzu ve paylaştığımızı açıklamaktadır[cite: 2]. [cite_start]Uygulamamızın temel amacı ev ağlarınızı güvende tutmanıza yardımcı olmaktır[cite: 3]. Uygulamayı kullanarak bu politikada belirtilen uygulamaları kabul etmiş olursunuz.

### 1. Toplanan Veriler ve Kullanım Amaçları

AuraNet, size ağ güvenliği hizmetleri sunabilmek için minimum düzeyde veri toplama prensibiyle çalışır:

* [cite_start]**Kimlik ve Hesap Bilgileri:** Uygulamayı kullanabilmek için kayıt zorunludur[cite: 123]. [cite_start]Adınız, soyadınız, e-posta adresiniz ve şifreniz (veya Google ile Giriş bilgileriniz) hesabınızı oluşturmak ve yönetmek amacıyla Firebase Authentication üzerinden güvenle toplanır[cite: 84, 144, 145].
* [cite_start]**Konum İzinleri (Sadece Yerel İşlem):** Android 10 ve üzeri sürümlerde ağdaki cihazların MAC adreslerini okuyabilmek için teknik bir zorunluluk olarak "Kesin Konum" (ACCESS_FINE_LOCATION) ve "Yaklaşık Konum" (ACCESS_COARSE_LOCATION) izinleri talep edilmektedir[cite: 116, 117]. [cite_start]**Konum veriniz SADECE tarama sırasında lokal olarak kullanılır ve kesinlikle sunucularımıza gönderilmez veya kaydedilmez[cite: 497].**
* [cite_start]**Ağ ve Cihaz Bilgileri:** Uygulama, bağlı olduğunuz ağın durumunu analiz etmek için cihazınızın WiFi durumu, internet erişimi ve ağ bilgilerini işler[cite: 454, 455, 456, 457, 458].
* [cite_start]**MAC Adresleri ve Cihaz Tespiti:** Ağınıza bağlı cihazları tespit edebilmek için cihazların MAC adresleri okunur[cite: 467, 468]. [cite_start]Bu adresler, üretici bilgisini almak amacıyla güvenli bir şekilde `api.macvendors.com` servisine iletilir, ancak tarafımızca hiçbir şekilde loglanmaz veya sunucularımızda saklanmaz[cite: 104, 497].

### 2. Yerel Saklanan Veriler (Sizin Cihazınızda Kalanlar)

Gizliliğinize maksimum düzeyde önem veriyoruz. [cite_start]Aşağıdaki veriler cihazınızda yerel veri tabanında (Hive) saklanır ve hiçbir zaman Firebase (Firestore) sunucularımıza yazılmaz[cite: 81, 497]:
* [cite_start]Cihazlara verdiğiniz özel isimler[cite: 497].
* [cite_start]Cihazlar için eklediğiniz notlar ve seçtiğiniz emojiler[cite: 497].

### 3. Üçüncü Taraf Servisler ve Veri Paylaşımı

Uygulamamızın çalışabilmesi için verilerinizi anonim veya şifrelenmiş olarak bazı altyapı sağlayıcılarıyla paylaşmaktayız:
* [cite_start]**Firebase (Google Inc.):** Kullanıcı kimlik doğrulaması (Auth), profil verileri (premium durumu, tarama istatistikleri) (Firestore) ve anlık bildirimler (FCM) için kullanılır[cite: 84, 85].
* [cite_start]**RevenueCat:** Abonelik işlemlerinin ve ödemelerin (Google Play Billing) yönetilmesi için kullanılır[cite: 88, 93].
* [cite_start]**MacVendors API:** MAC adreslerinden (örn. Apple, TP-Link, Hikvision) cihaz tipini ve üreticisini belirlemek için kullanılır[cite: 188, 189, 190, 191, 192].

### 4. Veri Silme ve Hesabın İptali

[cite_start]Kullanıcılar uygulama içerisindeki Profil ekranından "Hesabı Sil" butonunu kullanarak hesaplarını diledikleri zaman silebilirler[cite: 372]. [cite_start]Hesabınızı sildiğinizde, Firestore sunucularımızda bulunan size ait tüm veriler (profiliniz, premium durumunuz, genel tarama geçmişiniz) kalıcı olarak silinir[cite: 497].

---

# KULLANIM KOŞULLARI (TERMS OF SERVICE)

**Son Güncelleme Tarihi:** 09 Nisan 2026

Lütfen AuraNet uygulamasını kullanmadan önce bu koşulları dikkatlice okuyunuz. Uygulamaya kayıt olarak ve kullanarak bu şartları yasal olarak kabul etmiş sayılırsınız.

### 1. Hizmetin Amacı ve Yasal Sorumluluk Reddi

* [cite_start]**Bilgi Amaçlı Kullanım:** AuraNet, kullanıcıların ev ağlarını analiz etmeleri ve güvenlik açıklarını (açık portlar, zayıf şifreler, şüpheli cihazlar vb.) tespit etmeleri için tasarlanmış bilgi amaçlı bir ağ güvenlik aracıdır[cite: 632]. Uygulama, ağınızın %100 güvenli olacağını garanti etmez.
* [cite_start]**Kullanıcı Sorumluluğu:** Uygulamanın kullanımından doğacak her türlü yasal sorumluluk tamamen kullanıcıya aittir[cite: 632].
* [cite_start]**Yetkisiz Ağ Taraması Yasaktır:** Tüm ağ tarama işlemleri SADECE kullanıcının aktif olarak bağlı olduğu ağlarda yapılmalıdır[cite: 629]. [cite_start]Uygulama, başka ağları uzaktan tarayacak şekilde tasarlanmamıştır ve bu teknik olarak da imkânsızdır[cite: 630]. Ancak kullanıcının bulunduğu fiziksel ortamdaki izinsiz bir WiFi ağına bağlanıp tarama yapmasından AuraNet sorumlu tutulamaz.

### 2. Üyelik Tipleri ve Özellik Sınırları

AuraNet iki farklı kullanım planı sunar:

* [cite_start]**Ücretsiz (Free) Kullanıcı:** En fazla 10 cihazı listeleyebilir ve en yaygın 20 portu tarayabilir[cite: 123]. [cite_start]Son 3 tarama geçmişine erişebilir ve temel hız testi ile güvenlik skorunu görüntüleyebilir[cite: 123, 124, 125].
* [cite_start]**Premium Kullanıcı:** Sınırsız cihaz görüntüleme, tam port taraması (1-65535 arası), DNS sızıntı testi, ARP Spoofing (Ortadaki Adam Saldırısı) tespiti, Router şifre zafiyet uyarısı, PDF rapor oluşturma ve yeni cihaz anlık bildirimi gibi tüm gelişmiş özelliklere erişebilir[cite: 10, 11, 12, 13, 127, 128].

### 3. Abonelik, Ödemeler ve İptal Koşulları

* [cite_start]**Abonelik Planları:** Premium özelliklere erişim için Aylık (79 TL/ay) veya Yıllık (599 TL/yıl) abonelik planlarından biri seçilmelidir[cite: 375, 376]. [cite_start]Yıllık plan 7 günlük ücretsiz deneme süresi içerebilir[cite: 135].
* [cite_start]**Ödeme Altyapısı:** Tüm satın alım işlemleri Google Play Store hesaplarınız üzerinden RevenueCat altyapısı kullanılarak faturalandırılır[cite: 93].
* **Otomatik Yenileme ve İptal:** Abonelikler, mevcut dönemin bitiminden en az 24 saat önce iptal edilmediği sürece otomatik olarak yenilenir. [cite_start]Kullanıcılar aboneliklerini doğrudan Google Play Store veya uygulama içindeki "Aboneliği Yönet" butonu üzerinden iptal edebilirler[cite: 364].

### 4. Hizmetin Kötüye Kullanımı

Kullanıcılar uygulamayı yasadışı faaliyetlerde bulunmak, başkalarının ağlarına (örn. kafe, şirket, komşu ağları) izinsiz sızma testleri yapmak veya ARP tablolarını manipüle etmek amacıyla kullanamazlar. Aksi takdirde kullanıcının hesabı Firebase üzerinden sonlandırılabilir.

### 5. Acil Durumlar

[cite_start]Uygulamanın şüpheli cihaz tespit etmesi veya yüksek güvenlik riski göstermesi durumunda, fiziksel güvenliğinizi tehdit eden olağanüstü durumlarda uygulamaya güvenmek yerine her zaman öncelikli olarak yerel güvenlik güçlerini (112) aramanız tavsiye edilir[cite: 633].

### 6. Değişiklikler

AuraNet, bu Gizlilik Politikası ve Kullanım Koşulları belgelerinde dilediği zaman değişiklik yapma hakkını saklı tutar. Önemli değişiklikler uygulama içi bildirim veya e-posta yoluyla kullanıcılara duyurulacaktır.
