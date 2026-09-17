# App Store: riskler ve hazırlık

Reddedilme ihtimali olan noktaları önem sırasına göre yazdım. İlk ikisi gerçek
risk, gerisi büyük ölçüde hazır.

---

## 1. 🔴 Entitlement onayı — tek gerçek blokaj

Family Controls (Distribution) entitlement'ı onaylanmadan **TestFlight'a bile**
yükleme yapamazsın. Bu bir App Store review konusu değil, ondan önceki bir
kapı. Detaylar ve başvuru metni: [`APPLE_SETUP.md`](APPLE_SETUP.md).

**Öneri: bunu bugün başlat.** Geliştirmenin geri kalanı beklerken ilerleyebilir.

---

## 2. 🟠 Review uzmanı özelliği göremeyebilir

Bu, bu tür uygulamalarda en sık karşılaşılan pratik sorun. Reviewer'ın
engellemeyi görebilmesi için:

1. Ekran Süresi iznini vermesi,
2. en az bir uygulama seçmesi,
3. **bir namaz vaktinin gelmesini beklemesi** gerekiyor.

Üçüncüsü saatler sürebilir. Reviewer özelliği çalışırken göremezse "özellik
çalışmıyor" veya "inceleyemedik" gerekçesiyle reddedebilir.

### İki seçeneğin var

**A) App Review Notes'a net bir test yolu yaz** (kapsam değişmez).
App Store Connect › Uygulama sürümü › App Review Information › Notes alanına
aşağıdakini olduğu gibi koyabilirsin:

> Salah First temporarily blocks user-selected apps during prayer times, using
> FamilyControls / DeviceActivity / ManagedSettings. The user selects the apps
> themselves via Apple's FamilyActivityPicker; the app never learns which apps
> are installed.
>
> To see blocking in action without waiting for a prayer time:
>
> 1. Open the app and complete the short setup (grant Screen Time permission,
>    then pick one app to block — for example Safari).
> 2. On the home screen, note the time shown next to the next prayer.
> 3. In iOS Settings › General › Date & Time, turn off "Set Automatically" and
>    set the clock to two minutes before that time.
> 4. Reopen Salah First once, then close it. (This re-registers the schedule
>    after the time change.)
> 5. Wait until the prayer time passes, then open the app you selected. It will
>    be replaced by a Salah First screen.
> 6. Tap "I have prayed" on that screen, or in the Salah First app, to unblock.
>
> The user is never locked in: the shield has a dismiss button, the app has a
> "Skip this one" option, and blocking can be turned off entirely in Settings.
>
> There is no account, no server and no analytics. The app makes no network
> requests.

**B) "Şimdi Odaklan" (manuel odak modu) özelliğini ekle.**
Kullanıcı 15/20/30 dakikalık bir engelleme başlatır. Reviewer tek dokunuşla
özelliği görür ve risk büyük ölçüde ortadan kalkar.

Bunu MVP dışında bıraktın, ben de eklemedim — mimari hazır (`ActivityID`
içinde `manualFocus` durumu zaten var, zamanlayıcıda da 5 slot boş bırakıldı),
eklemek yaklaşık yarım günlük iş. **Tavsiyem: A ile başla, ilk sürüm reddedilirse
B'yi ekle.**

---

## 3. 🟡 Metadata ve konumlandırma

- **Kategori:** Health & Fitness veya Productivity. *Lifestyle* seçme — bu bir
  dijital iyi oluş aracı, dini içerik uygulaması değil. Konumlandırma
  entitlement gerekçenle de tutarlı olmalı.
- **Açıklamada ibadet doğrulama iması olmasın.** Uygulama namaz kılındığını
  doğrulamıyor, doğruladığını ima eden bir cümle hem yanlış olur hem Guideline
  2.3 (Accurate Metadata) kapsamına girer.
- **Ekran görüntülerinde gerçek uygulama isimleri/logoları gösterme.** Kalkan
  ekranının görselinde "Instagram" yazan bir kare, marka kullanımı açısından
  gereksiz risk. Genel bir metin kullan.

## 4. 🟡 Arka plan modu

`UIBackgroundModes: fetch` tanımlı. Bu, zamanlamayı uzatan günlük
`BGAppRefreshTask` için gerekli ve gerçekten kullanılıyor — ağdan içerik
çekilmiyor. Sorulursa açıklaması: *"Used only to extend the locally computed
prayer-time schedule; no network requests are made."*

Bu özelliği tamamen çıkarmak da bir seçenek: diğer üç katman (extension'ın
kendini yeniden kurması, uygulamanın öne gelmesi, bildirimler) zaten çalışıyor.
Ama o zaman uygulamayı 14 günden uzun süre hiç açmayan kullanıcıda engelleme
sessizce durur.

---

## ✅ Hazır olanlar

| Konu | Durum |
|---|---|
| Privacy manifest | `PrivacyInfo.xcprivacy` — tracking yok, veri toplama yok, `UserDefaults` gerekçeleri (`CA92.1`, `1C8F.1`) beyan edildi |
| App Privacy beyanı | "Data Not Collected" seçilebilir; kodda karşılığı var |
| İzin açıklamaları | Konum izni iki dilde, `InfoPlist.strings` içinde |
| İzin akışı | Ekran Süresi izni istenmeden **önce** neden gerektiği anlatılıyor (Guideline 5.1.1) |
| Hesap silme (5.1.1(v)) | Hesap yok, geçerli değil. Yine de Ayarlar'da "Tüm verileri sil" var |
| Uygulama ikonu | 1024×1024, alpha kanalı yok |
| Üçüncü taraf SDK | Sadece adhan-swift (MIT, saf hesaplama, ağ yok) — privacy manifest gerektirmiyor |
| Dark mode | Destekleniyor |
| Dynamic Type | Tüm metinler sistem text style'ları kullanıyor |
| VoiceOver | Ana ekran, vakit listesi ve namaz penceresi için etiketler var |
| Kullanıcı kilitlenmesi | Üç ayrı çıkış yolu: kalkanda kapat, uygulamada "bu sefer geç", Ayarlar'da engellemeyi kapat |

---

## Gözden kaçırılmaması gereken bir davranış

Kullanıcı iOS Ayarlar'dan Ekran Süresi iznini geri çekerse uygulama bunu fark
eder, tüm `DeviceActivity` kayıtlarını durdurur ve engellemeyi kapatır
(`ScreenTimeService.handleTransition`). Bu hem doğru davranış hem de reviewer'ın
test edebileceği bir senaryo — kilitli kalmış bir cihaz bırakmıyoruz.
