# Privacy Policy — Salah First

**Effective date:** 19 September 2026
*(Türkçe metin aşağıdadır.)*

## The short version

Salah First collects nothing. There is no account, no server, and no analytics.
The app contains no network client at all — it cannot send data anywhere, and it
works in airplane mode.

## What the app stores, and where

Everything below stays on your device, inside the app's own storage. None of it
is transmitted, backed up to us, or shared with anyone.

| What | Why | Kept for |
|---|---|---|
| Your location (latitude/longitude) | To calculate prayer times on the device | Until you change or remove it |
| The apps you chose to block | So they can be blocked at prayer times | Until you change the selection |
| Which prayers you marked complete or skipped | To show today's and this week's counts | At most 120 days, then deleted automatically |
| Your settings (calculation method, window length, notifications) | To run the app as you configured it | Until you change them |

### About your location

Location is used only to compute prayer times, and only on your device.

Coordinates are rounded to three decimal places — roughly 100 metres — which is
far more precision than prayer times require and far less than is needed to
identify a home address.

The app does **not** perform reverse geocoding. Turning a coordinate into a place
name would mean sending that coordinate to a third-party service, so the app
does not do it. If you prefer not to share your location at all, you can pick a
city from a list that ships inside the app.

### About the apps you block

App selection happens inside Apple's own `FamilyActivityPicker`, which runs in a
separate process controlled by iOS. Salah First receives only opaque tokens that
the system can interpret and we cannot. The app never learns which apps are
installed on your device, or which ones you selected.

## What the app does not do

- No account, sign-in, email address or phone number
- No servers, no network requests, no cloud sync
- No analytics, crash reporting, advertising identifiers or trackers
- No third-party SDKs beyond one offline prayer-time calculation library
  ([adhan-swift](https://github.com/batoulapps/adhan-swift), MIT licensed, which
  performs arithmetic and makes no network calls)
- No ads, subscriptions, in-app purchases or donations
- Nothing is sold, shared or disclosed, because nothing is collected

## Notifications

Prayer-time notifications are scheduled locally on your device from times the
device itself calculated. There is no push infrastructure behind this app.

## Children

The app is rated 4+ and collects no data from anyone, including children.

## Deleting your data

Settings → **Delete all data** removes your selections, settings and prayer
history from the device immediately. Deleting the app removes everything as well.

## Changes to this policy

If this policy ever changes, the new version will be published here with a new
effective date. Because the app has no way to contact you, material changes will
also be noted in the App Store release notes.

## Contact

Questions or concerns: open an issue at
<https://github.com/ichbrt/SalahFirst/issues>

The full source code is public, so every claim above can be verified by reading
it.

---

# Gizlilik Politikası — Salah First

**Yürürlük tarihi:** 19 Eylül 2026

## Kısa özet

Salah First hiçbir veri toplamaz. Hesap yok, sunucu yok, analitik yok.
Uygulamanın içinde ağ istemcisi bile bulunmuyor — hiçbir yere veri gönderemez ve
uçak modunda çalışır.

## Uygulama neyi, nerede saklıyor

Aşağıdakilerin tamamı cihazınızda, uygulamanın kendi alanında kalır. Hiçbiri
iletilmez, bize yedeklenmez, kimseyle paylaşılmaz.

| Ne | Niçin | Ne kadar |
|---|---|---|
| Konumunuz (enlem/boylam) | Namaz vakitlerini cihazda hesaplamak için | Siz değiştirene veya silene kadar |
| Engellemeyi seçtiğiniz uygulamalar | Namaz vakitlerinde engellenebilmesi için | Seçimi değiştirene kadar |
| Tamamladığınız veya geçtiğiniz vakitler | Bugünün ve bu haftanın sayısını göstermek için | En fazla 120 gün, sonra kendiliğinden silinir |
| Ayarlarınız (hesaplama yöntemi, pencere süresi, bildirimler) | Uygulamayı sizin belirlediğiniz gibi çalıştırmak için | Siz değiştirene kadar |

### Konumunuz hakkında

Konum yalnızca namaz vakitlerini hesaplamak için, yalnızca cihazınızda
kullanılır.

Koordinatlar üç ondalık basamağa yuvarlanır — yaklaşık 100 metre. Bu, namaz
vakitlerinin gerektirdiğinden çok daha fazla, bir ev adresini belirlemek için
gerekenden çok daha az hassasiyettir.

Uygulama **ters coğrafi kodlama yapmaz.** Bir koordinatı yer adına çevirmek, o
koordinatı üçüncü taraf bir servise göndermek anlamına gelirdi; uygulama bunu
yapmaz. Konumunuzu hiç paylaşmak istemiyorsanız, uygulamanın içinde gelen
listeden bir şehir seçebilirsiniz.

### Engellediğiniz uygulamalar hakkında

Uygulama seçimi, iOS'un kontrol ettiği ayrı bir süreçte çalışan Apple'ın kendi
`FamilyActivityPicker` ekranında yapılır. Salah First yalnızca sistemin
yorumlayabildiği, bizim yorumlayamadığımız anlamsız kimlikler (token) alır.
Uygulama, cihazınızda hangi uygulamaların kurulu olduğunu veya hangilerini
seçtiğinizi asla öğrenmez.

## Uygulamanın yapmadıkları

- Hesap, giriş, e-posta adresi veya telefon numarası yok
- Sunucu yok, ağ isteği yok, bulut eşitleme yok
- Analitik, çökme raporlama, reklam kimliği veya takip aracı yok
- Çevrimdışı çalışan tek bir namaz vakti hesaplama kütüphanesi dışında üçüncü
  taraf SDK yok ([adhan-swift](https://github.com/batoulapps/adhan-swift), MIT
  lisanslı; yalnızca aritmetik yapar, ağa çıkmaz)
- Reklam, abonelik, uygulama içi satın alma veya bağış yok
- Hiçbir şey satılmaz, paylaşılmaz, ifşa edilmez — çünkü hiçbir şey toplanmaz

## Bildirimler

Namaz vakti bildirimleri, cihazın kendi hesapladığı vakitlerden yola çıkarak
cihazınızda yerel olarak planlanır. Bu uygulamanın arkasında bir push altyapısı
yoktur.

## Çocuklar

Uygulama 4+ yaş sınıfındadır ve çocuklar dahil hiç kimseden veri toplamaz.

## Verilerinizi silmek

Ayarlar → **Tüm verileri sil**, seçimlerinizi, ayarlarınızı ve namaz geçmişinizi
cihazdan anında kaldırır. Uygulamayı silmek de her şeyi kaldırır.

## Bu politikadaki değişiklikler

Bu politika değişirse, yeni sürüm burada yeni bir yürürlük tarihiyle
yayımlanacaktır. Uygulamanın sizinle iletişim kurma yolu olmadığı için, önemli
değişiklikler App Store sürüm notlarında da belirtilecektir.

## İletişim

Soru veya endişeleriniz için:
<https://github.com/ichbrt/SalahFirst/issues>

Kaynak kodun tamamı açıktır; yukarıdaki her iddia kodu okuyarak doğrulanabilir.
