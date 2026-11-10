/// Sensorli tugmalar va klaviatura holati. Ikkalasi bir vaqtda ishlaydi.
class Input {
  bool tLeft = false, tRight = false, tJump = false;
  bool kLeft = false, kRight = false, kJump = false;
  bool _jumpQ = false, _attackQ = false, _slideQ = false;

  bool get left => tLeft || kLeft;
  bool get right => tRight || kRight;
  bool get jumpHeld => tJump || kJump;

  void pressJump({required bool touch}) {
    if (!jumpHeld) _jumpQ = true;
    if (touch) {
      tJump = true;
    } else {
      kJump = true;
    }
  }

  void releaseJump({required bool touch}) {
    if (touch) {
      tJump = false;
    } else {
      kJump = false;
    }
  }

  void pressAttack() => _attackQ = true;
  void pressSlide() => _slideQ = true;

  bool consumeJump() {
    final q = _jumpQ;
    _jumpQ = false;
    return q;
  }

  bool consumeAttack() {
    final q = _attackQ;
    _attackQ = false;
    return q;
  }

  bool consumeSlide() {
    final q = _slideQ;
    _slideQ = false;
    return q;
  }

  void clear() {
    tLeft = tRight = tJump = false;
    kLeft = kRight = kJump = false;
    _jumpQ = _attackQ = _slideQ = false;
  }
}
