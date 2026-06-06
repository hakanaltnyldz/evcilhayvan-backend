import 'package:evcilhayvan_mobil2/router/app_router.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('store browse routes remain available to guests', () {
    expect(isGuestBrowsableRoute('/store'), isTrue);
    expect(isGuestBrowsableRoute('/store-new'), isTrue);
    expect(isGuestBrowsableRoute('/store-new/product/abc'), isTrue);
    expect(isGuestBrowsableRoute('/product/abc'), isTrue);
    expect(isGuestBrowsableRoute('/seller/dashboard'), isFalse);
  });
}
