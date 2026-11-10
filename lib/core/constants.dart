/// O'yin dunyosining barcha asosiy konstantalari (virtual birliklarda).
/// Ekran balandligi doim 360 birlik deb olinadi va qurilmaga moslab kattalashtiriladi.
class G {
  G._();

  static const double viewH = 360;
  static const double gravity = 1400;
  static const double groundY = 300;

  static const double heroW = 26;
  static const double heroH = 58;
  static const double jumpV = 620;
  static const double superJumpV = 780;
  static const double runSpeed = 190;
  static const double boltSpeed = 270;

  static const int levelCount = 5;
  static const int maxLives = 5;
  static const int startLives = 3;
}
