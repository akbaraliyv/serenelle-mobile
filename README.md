# Serenelle Direct — 120Hz Native Android Chat Application

Instagram Direct formatidagi 14,170 ta xabardan iborat, 0 millisekund kechikish va 120Hz silliqlikda ishlaydigan Flutter Native mobil ilovasi.

---

## ⚡ Nega Mobil Brauzer Qotadi, Native Ilova Esa 120Hz Uchadi?

1. **DOM Cheklovi Yo'q:** Veb-brauzerlar (WebKit/Chrome) ekranda 10,000+ element aylanganda DOM daraxtini qayta hisoblab xotira to'lib qoladi va bo'shliqlar (blank spots) chiqaradi. Flutter esa Impeller dvigateli orqali bevosita GPU (Vulkan/OpenGL) ga chizadi.
2. **Pre-Indexed SQLite + FTS5:** Barcha 14,170 ta xabar `assets/database/chat.db` SQLite fayliga oldindan indekslab qo'yilgan. Ilova ochilganda JSON o'qishga 1 millisekund ham vaqt sarflanmaydi.
3. **ScrollablePositionedList:** Ekranda faqat ko'rinib turgan 15-20 ta xabar RAM'da ushlanadi. Barmog'ingiz bilan qanchalik qattiq aylantirmang, 120 FPS inertial physics bilan ishlaydi.

---

## 📂 Loyiha Tuzilmasi

```
serenelle-mobile-app/
├── assets/
│   ├── database/
│   │   └── chat.db             # 14,170 ta xabar + FTS5 to'liq qidiruv bazasi (3.57 MB)
│   └── media/
│       ├── audio/              # Ovozli xabarlar
│       └── photos/             # Rasmlar
├── lib/
│   ├── main.dart               # Ilova boshlang'ich nuqtasi (OLED qora mavzu)
│   ├── models/
│   │   └── chat_message.dart   # ChatMessage, DateMeta, SearchResultItem modellari
│   ├── services/
│   │   └── database_service.dart # SQLite & FTS5 qidiruv xizmati
│   ├── screens/
│   │   └── chat_screen.dart    # 120Hz chat ekrani, jump dock (Eng Tepaga / Eng Pastga)
│   └── widgets/
│       ├── chat_bubble.dart    # Instagram Direct OLED pufakchalar, 3D reaksiyalar
│       ├── audio_player_bubble.dart # Waveform audio pleyer
│       ├── search_bottom_sheet.dart # Bir zumda FTS5 qidiruv
│       ├── date_filter_modal.dart   # 95 kunlik taqvim filtri
│       └── image_viewer.dart   # Rasmni kattalashtirib ko'rish (zoom)
├── .github/workflows/
│   └── build-apk.yml           # Bulutda avtomatik bepul APK yig'uvchi GitHub Actions
└── pubspec.yaml                # Flutter konfiguratsiyasi va kutubxonalar
```

---

## 🚀 APK Faylini Yig'ish (Build Qilish) Yo'riqnomasi

Ikkita oson yo'l mavjud:

### 1-USUL: Bulutda Bepul APK Yig'ish (Kompyuteringizga hech narsa o'rnatmasdan — Tavsiya etiladi!)

Sizning kompyuteringizga 20 GB Android Studio, Gradle va Java o'rnatish shart emas. GitHub Actions bulut serverlari ilovani 3 daqiqada yig'ib beradi:

1. Ushbu loyihani GitHub repozitoriyangizga push qiling (`git push origin main`).
2. GitHub sahifangizda **Actions** bo'limiga o'ting.
3. **Build Android Release APK** workflow avtomatik tarzda ishga tushadi.
4. 3-4 daqiqadan so'ng jarayon tugaydi va **Artifacts** bo'limida tayyor `serenelle-direct-apk` yuklab olish uchun chiqadi.
5. Telefoningizga yuklab olib, o'rnating!

---

### 2-USUL: Kompyuterda Mahalliy Build Qilish

Agar kompyuteringizda Flutter o'rnatilgan bo'lsa:

1. Kutubxonalarni yuklang:
   ```bash
   flutter pub get
   ```

2. Ilovani telefoningizda yoki simulyatorda sinab ko'rish:
   ```bash
   flutter run
   ```

3. Tayyor Android APK faylini chiqarish:
   ```bash
   flutter build apk --release
   ```
   Chiqadigan tayyor fayl manzili:
   `build/app/outputs/flutter-apk/app-release.apk`
