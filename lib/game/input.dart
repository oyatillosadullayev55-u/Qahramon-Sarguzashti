/// Sensorli tugmalar va klaviatura holati. Ikkalasi bir vaqtda ishlaydi.
class Input {
  bool tLeft = false, tRight = false, tJump = false;
  bool kLeft = false, kRight = false, kJump = false;
  bool _queued = false;

  bool get left => tLeft || kLeft;
  bool get right => tRight || kRight;
  bool get jumpHeld => tJump || kJump;

  void pressJump({required bool touch}) {
    if (!jumpHeld) _queued = true;
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

  /// Sakrash bosilganda bir marta true qaytaradi.
  bool consumeJump() {
    final q = _queued;
    _queued = false;
    return q;
  }

  void clear() {
    tLeft = tRight = tJump = false;
    kLeft = kRight = kJump = false;
    _queued = false;
  }
}
