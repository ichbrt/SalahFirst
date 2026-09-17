# Apple tarafında yapman gerekenler

Bu listedeki her şey **senin** Apple Developer hesabında yapılacak; kod tarafı hazır.
Sırayla ilerle.

---

## 0. Önce şunu başlat — en uzun süren adım bu

**Family Controls (Distribution) entitlement talebi.**

Geliştirme entitlement'ı Xcode'da capability'yi ekler eklemez çalışır; kendi
cihazında hemen test edebilirsin. Ancak **TestFlight'a veya App Store'a hiçbir
build yükleyemezsin** — Apple ayrı bir dağıtım talebini onaylayana kadar.

- Form: <https://developer.apple.com/contact/request/family-controls-distribution>
- Süre: geliştiricilerin bildirdiği aralık birkaç iş gününden birkaç haftaya kadar
  değişiyor; Apple'ın taahhüt ettiği bir süre yok.
- Talebi **her bundle ID için ayrı ayrı** yapman gerekiyor — ana uygulama ve üç
  extension:

  ```
  com.salahfirst.app
  com.salahfirst.app.Monitor
  com.salahfirst.app.ShieldConfiguration
  com.salahfirst.app.ShieldAction
  ```

**Formda ne yazmalısın.** Apple'ın aradığı şey, uygulamanın çekirdek amacının
gerçekten ekran süresi / dijital iyi oluş olması ve bu yetkinin kullanım verisi
toplamak veya profilleme için kullanılmaması. Salah First bu kriterlere birebir
uyuyor; şu noktaları açıkça yaz:

- Uygulama, kullanıcının **kendi** cihazındaki, **kendi seçtiği** uygulamaları,
  **kendi belirlediği** zaman aralıklarında geçici olarak kısıtlar.
- Yetişkin bireysel kullanım (`.individual`), ebeveyn denetimi (`.child`) değil.
- Hiçbir kullanım verisi toplanmıyor, hiçbir sunucuya gönderilmiyor; uygulamanın
  ağ istemcisi yok.
- Ücretsiz, reklamsız, aboneliksiz.
- Kullanıcı her an çıkabilir: hem kalkan ekranında hem uygulama içinde bir
  "geç" seçeneği var, ayrıca Ayarlar'dan engellemeyi tamamen kapatabilir.

---

## 1. Identifier'ları oluştur

Developer portal › Certificates, Identifiers & Profiles › Identifiers.

Dört App ID oluştur ve her birinde **Family Controls** ile **App Groups**
capability'lerini işaretle:

| Identifier | Tür |
|---|---|
| `com.salahfirst.app` | App |
| `com.salahfirst.app.Monitor` | App (extension) |
| `com.salahfirst.app.ShieldConfiguration` | App (extension) |
| `com.salahfirst.app.ShieldAction` | App (extension) |

> Kendi ters-domain'ini kullanmak istersen `project.yml` içindeki
> `APP_BUNDLE_ID` ve `APP_GROUP_ID` değerlerini değiştirmen yeterli — başka
> hiçbir dosyaya dokunman gerekmez.

## 2. App Group oluştur

Identifiers › App Groups › `group.com.salahfirst.app`

Yukarıdaki **dört identifier'ın hepsine** bu grubu ekle. Biri eksik kalırsa o
extension paylaşılan durumu okuyamaz ve engelleme sessizce çalışmaz.

## 3. Team ID'yi projeye yaz

`project.yml` içinde:

```yaml
DEVELOPMENT_TEAM: "XXXXXXXXXX"   # 10 karakterlik Team ID'n
```

Sonra `xcodegen generate` çalıştır.

## 4. Xcode'da imzalama

Xcode'da dört target'ın her biri için Signing & Capabilities sekmesinde:

- Team'i seç
- "Automatically manage signing" açık olsun
- **Family Controls** ve **App Groups** capability'lerinin göründüğünü doğrula
  (`.entitlements` dosyalarında zaten tanımlı, Xcode bunları okuyacak)

## 5. App Store Connect

- Yeni uygulama kaydı: bundle ID `com.salahfirst.app`
- Kategori önerisi: **Health & Fitness** veya **Productivity**
  (*Lifestyle* değil — bu bir dijital iyi oluş aracı, dini içerik uygulaması değil)
- Yaş sınırı: 4+
- **App Privacy** bölümünde "Data Not Collected" seç. Uygulama gerçekten hiçbir
  şey toplamıyor; `PrivacyInfo.xcprivacy` de bunu beyan ediyor.
- Fiyat: Free
- Uygulama içi satın alma: yok

---

## Test etmeden önce bilmen gerekenler

**Simülatörde engelleme çalışmaz.** Screen Time API'leri simülatörde
uygulanmamıştır; yetkilendirme her zaman başarısız olur. Uygulamanın geri kalanı
normal çalışır ve izin ekranında bunu açıkça söyler. Engellemeyi mutlaka gerçek
bir iPhone'da test et.

**Test ederken pencere süresini 15 dakikaya al** (Ayarlar › Pencere süresi).
Apple 15 dakikadan kısa aralığa izin vermiyor, bu yüzden daha hızlı test
edemezsin. Bir vaktin gelmesini beklemek istemezsen cihazın saatini bir sonraki
vaktin birkaç dakika öncesine alabilirsin — ama bunu yaptıktan sonra uygulamayı
açıp kapatarak zamanlamanın yeniden kurulmasını sağla.

**Yetkilendirmeyi iptal edersen** (iOS Ayarlar › Ekran Süresi), uygulama bunu
fark edip tüm zamanlamaları durdurur ve engellemeyi kapatır.
