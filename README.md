# Super Adventure — Flutter platformer (2-versiya)

Birinchi versiyaning ("Sarguzasht") yangi dizaynli davomi: yangi qahramon (plash va jangovar pozalar),
yangi UI (logo, PLAY tugmasi, sozlamalar, rekordlar, statistika) va yangi o'yin imkoniyatlari.
Paketlar: `audioplayers` (ovoz), `shared_preferences` (saqlash).

## Ishga tushirish
```bash
flutter create --platforms=android,windows,web .
flutter pub get
flutter run
```
> Bu v1 dan alohida loyiha (`super_adventure`). Eskisini almashtirmaydi.

## Tezlik haqida
Debug rejimida (`flutter run`) o'yin ancha sekin ishlaydi. Haqiqiy tezlikni ko'rish uchun:
```bash
flutter run --release
```

## Boshqaruv
- **Telefon:** ◀ ▶ (yurish), katta to'q sariq tugma (sakrash), qizil ⚡ (hujum), binafsha ⏬ (sirpanish).
- **Kompyuter:** ← → / A D yurish, Space / ↑ / W sakrash, J yoki X hujum, S yoki ↓ sirpanish, Esc / P pauza.

## Yangi imkoniyatlar (v2)
- **Hujum:** qilich zarbasi oldingi dushmanlarni yo'q qiladi (bosdan ham, yonidan ham).
- **Sirpanish:** past tushib sirpanadi: arvohlar tepadan o'tib ketadi, slime/toshbaqani urib yuboradi.
- **Qalqon** 🛡: bitta zarbani qaytaradi. **Kalit** 🔑 + **sandiq**: kalitni olib darajaning oxiridagi sandiqni oching (+15 ball, +3 olmos).
- **Tikanlar** (sakrab o'ting) va **muz** bloklar (sirpanchiq).
- Pozalar: Idle, Run, Jump, Attack, Hurt, Die, Slide, Celebrate.
- 5-darajada final boss; daraja oxirida 1–3 yulduz.
- Hamyon (tanga/olmos), rekordlar, statistika, sozlamalar (musiqa / ovoz / tebranish) telefonda saqlanadi.

## Tuzilma
```
lib/core/      konstantalar, rasm/ovoz yuklash, progress
lib/game/      fizika (game_world), level generator, painter, input, modellar
lib/screens/   menyu, daraja tanlash, o'yin ekrani (HUD, pauza, g'alaba, yutqazish)
lib/widgets/   tugmalar, hisoblagichlar, sozlamalar/rekordlar/statistika oynalari
assets/images  yangi sheet'dan qirqilgan sprite'lar
assets/sounds  sintezlangan effektlar va musiqa
```
Qiyinlik: `lib/game/level_builder.dart`, fizika: `lib/core/constants.dart`.
