/// O'yin dunyosining barcha asosiy konstantalari (virtual birliklarda).
/// Ekran balandligi doim 360 birlik deb olinadi va qurilmaga moslab kattalashtiriladi.
class G {
  G._();

  static const double viewH = 360;
  static const double gravity = 1500;
  static const double groundY = 300;

  static const double heroW = 26;
  static const double heroH = 58;
  static const double jumpV = 590;
  static const double superJumpV = 740;
  static const double runSpeed = 170;
  static const double boltSpeed = 250;

  static const int levelCount = 5;
  static const int maxLives = 5;
  static const int startLives = 3;
}
