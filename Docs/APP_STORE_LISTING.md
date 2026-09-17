# App Store Connect — hazır metinler

Buradaki her şeyi kopyalayıp yapıştırabilirsin. Sağdaki karakter sınırları Apple'ın limitleri.

---

## Temel bilgiler

| Alan | Değer |
|---|---|
| Bundle ID | `com.salahfirst.app` |
| SKU | `salahfirst-ios-001` |
| Birincil dil | Türkçe |
| Birincil kategori | **Health & Fitness** |
| İkincil kategori | Productivity |
| Fiyat | Free |
| Uygulama içi satın alma | Yok |
| Yaş sınırı | 4+ |

> **Kategori neden Lifestyle değil:** Family Controls entitlement talebinde uygulamayı "dijital iyi oluş aracı" olarak tanımladın. App Store kategorisinin bu gerekçeyle tutarlı olması gerekiyor. Lifestyle/Reference seçmek, review sırasında "bu neden Screen Time yetkisi istiyor" sorusunu davet eder.

---

## Türkçe

**Uygulama adı** (30 karakter)
```
Salah First: Önce Namaz
```

**Alt başlık** (30 karakter)
```
Namaz vaktinde kısa bir ara
```

**Anahtar kelimeler** (100 karakter, virgülle, boşluksuz)
```
namaz,vakit,ezan,odak,ekran süresi,dikkat,engelle,sosyal medya,diyanet,kıble yok,scroll,mola
```

**Tanıtım metni** (170 karakter — istediğin zaman güncelleyebilirsin, review gerektirmez)
```
Namaz vakti geldiğinde seni oyalayan uygulamalara kısa bir ara ver. Ücretsiz, reklamsız, hesapsız. Hiçbir veri toplamıyor.
```

**Açıklama** (4000 karakter)
```
Önce namaz. Sonra scroll.

Salah First, namaz vakti geldiğinde senin seçtiğin uygulamaları kısa bir süre kilitler. Namazını tamamladığını söylediğinde açar.

Bu bir denetim aracı değil. Namaz kılıp kılmadığını kontrol etmez, kontrol edemez ve etmeye çalışmaz. Kendine verdiğin sözü telefonun üzerinden uygulamana yardım eder — o kadar.

NASIL ÇALIŞIR

• Ara vermek istediğin uygulamaları sen seçersin
• Namaz vakti girdiğinde bu uygulamalar kilitlenir
• "Namazımı tamamladım" dediğinde açılır
• İstersen pencere süresi dolunca kendiliğinden de açılır

NAMAZ VAKİTLERİ

• Cihazında hesaplanır, internet gerekmez
• 12 hesaplama yöntemi; Türkiye için Diyanet varsayılan
• İkindi vaktini iki seçenekten seçebilirsin, ikisinin de saatini görerek
• Konum izni vermek istemezsen 200 şehirden birini seçebilirsin

SENİ SIKIŞTIRMAZ

Kilitli ekranda "Kapat" var, uygulamada "Bu sefer geç" var, Ayarlar'da engellemeyi tamamen kapatabilirsin. Üç ayrı çıkış yolu. Hiçbiri seni utandırmaz.

Streak baskısı yok. "Başarısız oldun" yazmaz. Sadece bugün kaç vakit tamamladığını gösterir.

GİZLİLİK

• Hesap yok. E-posta, telefon numarası, giriş yok.
• Sunucu yok. Uygulamanın içinde ağ istemcisi bile yok — uçak modunda çalışır.
• Konumun yalnızca vakit hesabı için, yalnızca cihazında kullanılır.
• Hangi uygulamaları seçtiğini biz göremiyoruz. Seçimi Apple'ın kendi ekranı yapıyor.
• Namaz geçmişin cihazında kalır, en fazla 120 gün.
• Reklam yok, abonelik yok, uygulama içi satın alma yok, bağış yok, takip aracı yok.

Uygulamanın kaynak kodu açıktır: github.com/ichbrt/SalahFirst

GEREKSİNİM

Uygulama engelleme için Apple'ın Ekran Süresi iznine ihtiyaç duyar. Bu izin yalnızca senin seçtiğin uygulamaları kısıtlamayı sağlar; hangi uygulamaları kullandığını görmez.
```

**Destek URL'si**
```
https://github.com/ichbrt/SalahFirst
```

**Gizlilik politikası URL'si**
```
https://github.com/ichbrt/SalahFirst#privacy
```

---

## English

**App name** (30)
```
Salah First: Pray First
```

**Subtitle** (30)
```
A short pause at prayer time
```

**Keywords** (100)
```
prayer,salah,namaz,focus,screen time,block apps,distraction,adhan,islam,mindful,scroll,break
```

**Promotional text** (170)
```
Take a short break from the apps that pull you in when it is time to pray. Free, no ads, no account. Collects nothing.
```

**Description** (4000)
```
Pray first. Scroll later.

Salah First locks the apps you choose for a short while when a prayer time arrives, and unlocks them when you say you have prayed.

It is not a supervisor. It does not check whether you prayed, it cannot, and it does not try. It helps you keep a promise you made to yourself — that is all.

HOW IT WORKS

• You choose which apps to take a break from
• They lock when a prayer time begins
• They unlock when you tap "I have prayed"
• Or on their own, when the window ends

PRAYER TIMES

• Calculated on your device. No internet needed.
• 12 calculation methods, chosen from your region by default
• Asr can be set either way, with both clock times shown side by side
• Rather not share your location? Pick from 200 bundled cities.

IT NEVER TRAPS YOU

The lock screen has a dismiss button, the app has "Skip this one", and Settings can turn blocking off entirely. Three ways out. None of them shame you.

No streak pressure. It never says you failed. It shows how many prayers you completed today, and nothing more.

PRIVACY

• No account. No email, no phone number, no sign-in.
• No server. There is no network client in the app at all — it works in airplane mode.
• Your location is used only to calculate prayer times, only on your device.
• We cannot see which apps you chose. Apple's own picker makes the selection.
• Your prayer history stays on your device, for at most 120 days.
• No ads, no subscription, no in-app purchases, no donations, no trackers.

The source code is open: github.com/ichbrt/SalahFirst

REQUIREMENT

App blocking needs Apple's Screen Time permission. It only allows restricting the apps you pick; it does not reveal which apps you use.
```

---

## App Review Information — Notes

Bu alan kritik. Review uzmanı özelliği vakit beklemeden test edemezse "çalışmıyor" diye reddedebilir.

```
Salah First temporarily blocks user-selected apps during prayer times, using
FamilyControls, DeviceActivity and ManagedSettings. The user selects the apps
themselves via Apple's FamilyActivityPicker; the app never learns which apps are
installed.

To see blocking in action without waiting for a prayer time:

1. Open the app and complete the short setup (grant Screen Time permission,
   then pick one app to block — for example Safari).
2. Go to Settings inside the app and set "Window length" to 15 minutes.
3. On the home screen, note the time shown next to the next prayer.
4. In iOS Settings > General > Date & Time, turn off "Set Automatically" and set
   the clock to two minutes before that time.
5. Reopen Salah First once, then close it. This re-registers the schedule after
   the time change.
6. Wait until the prayer time passes, then open the app you selected. It will be
   replaced by a Salah First screen.
7. Tap "I have prayed" on that screen, or in the Salah First app, to unblock.

The user is never locked in: the shield has a dismiss button, the app has a
"Skip this one" option, and blocking can be turned off entirely in Settings.

There is no account, no server and no analytics. The app makes no network
requests. Prayer times are computed on device with the adhan-swift library
(MIT). The source is public at github.com/ichbrt/SalahFirst.
```

---

## Beyanlar — bunları SEN dolduracaksın

Bunlar Apple'a yaptığın hukuki beyanlar, senin adına doldurulamaz. Doğru cevaplar kod tabanına göre şöyle:

| Soru | Doğru cevap | Neden |
|---|---|---|
| **App Privacy** | "Data Not Collected" | Uygulama gerçekten hiçbir veri toplamıyor; `PrivacyInfo.xcprivacy` de bunu beyan ediyor |
| **Export compliance** — şifreleme kullanıyor mu? | **Hayır** | `Info.plist`'te `ITSAppUsesNonExemptEncryption = false` zaten var |
| **Content rights** — üçüncü taraf içerik var mı? | **Hayır** | Tüm içerik özgün; tek bağımlılık MIT lisanslı bir hesaplama kütüphanesi |
| **Advertising identifier (IDFA)** | **Hayır** | Reklam yok, IDFA'ya hiç dokunulmuyor |
| **Yaş sınırı anketi** | Hepsine "Yok/None" | Uygunsuz içerik, şiddet, kumar, kullanıcı içeriği — hiçbiri yok. Sonuç 4+ çıkar |

---

## Ekran görüntüleri

`Docs/appstore/` içinde hazır, hepsi 1320×2868 (iPhone 6.9", zorunlu boyut):

| Dosya | Ne gösteriyor |
|---|---|
| `01-home-light.png` | Ana ekran, açık tema |
| `01-home-dark.png` | Ana ekran, koyu tema |
| `02-window-light.png` | Namaz penceresi ekranı |
| `03-settings-light.png` | Ayarlar |
| `04-shield-dark.png` | Engellenen uygulama yerine çıkan ekran |

> ⚠️ `04-shield-dark.png` bir **render**, cihaz ekran görüntüsü değil — kalkan simülatörde yakalanamıyor. Extension'ın ürettiği gerçek renk, sembol ve yerleşimden çizildi. Gerçek cihazdan alabilirsen onunla değiştir; App Store ekran görüntülerinin uygulamayı doğru temsil etmesi gerekiyor.
