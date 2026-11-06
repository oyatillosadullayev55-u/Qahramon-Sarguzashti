# Sarguzasht — Flutter platformer o'yini

Paketlar: `audioplayers` (ovoz) va `shared_preferences` (saqlash). Barcha rasmlar siz yuborgan sheet'dan
qirqib olingan: `assets/images/`.

## Ishga tushirish

```bash
# 1) Bo'sh papkada platforma fayllarini yaratish (android/windows/web ...)
flutter create --platforms=android,windows,web .

# 2) Paketlarni olish va yurgizish
flutter pub get
flutter run
```

> `flutter create .` mavjud `lib/`, `pubspec.yaml` va `assets/` ni o'zgartirmaydi.

## Boshqaruv
- **Telefon:** chapda ◀ ▶ tugmalari, o'ngda katta sakrash tugmasi (bir vaqtda ishlaydi).
- **Kompyuter:** ← → yoki A D, sakrash: Space / ↑ / W, pauza: Esc yoki P.

## O'yin qoidalari
- Tanga (+1), yulduz (+3), olmos (+5) yig'ing. Yurak — qo'shimcha jon (max 5).
- Slime va toshbaqa ustiga sakrab tushsangiz yo'qoladi. Arvoh va bomba — faqat aylanib o'ting.
- "?" blokni pastdan urib sovg'a oling: tanga, yurak, 🧲 magnit, ⚡ tezlik, 🧪 super sakrash (8 soniya).
- Oxiridagi yo'l ko'rsatkichiga yeting. Yig'ilgan ball va olingan zarbaga qarab 1–3 yulduz beriladi.
- 5-darajada final boss: katta toshbaqa (5 jon). Uni yengmaguncha daraja tugamaydi.
- 5 ta daraja (kun / tun / o'rmon fonlari), keyingilari qiyinroq.

## Tuzilma
```
lib/
  main.dart                  ilova kirish nuqtasi
  core/                      konstantalar, rasm yuklash, progress
  game/                      fizika (game_world), level generator, painter, input, modellar
  screens/                   menyu, daraja tanlash, o'yin ekrani (HUD, pauza, g'alaba, yutqazish)
  widgets/                   umumiy tugmalar va matn
assets/images/               sheet'dan qirqilgan sprite'lar (fon olib tashlangan)
```

## Sozlash joylari
- Qiyinlik: `lib/game/level_builder.dart` (`enemyProb`, bo'shliq kengligi, daraja uzunligi).
- Fizika: `lib/core/constants.dart` (gravitatsiya, sakrash, tezlik).
- Progress va ovoz sozlamasi telefonda saqlanadi (`core/progress.dart`).
- Ovozlar `assets/sounds/*.wav` — o'zingiznikiga almashtirsangiz bo'ladi (nomlari bir xil bo'lsin).
