import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../core/analytics/analytics_provider.dart';

class CartItem {
  CartItem({
    required this.productId,
    required this.name,
    required this.price,
    required this.quantity,
  });

  final String productId;
  final String name;
  final double price;
  int quantity;
}

class CartState {
  CartState({this.items = const []});
  final List<CartItem> items;

  double get total => items.fold(0, (sum, i) => sum + i.price * i.quantity);
  int get count => items.fold(0, (sum, i) => sum + i.quantity);
}

class CartController extends StateNotifier<CartState> {
  CartController(this._ref) : super(CartState());

  final Ref _ref;
  final _uuid = const Uuid();

  void addItem({
    required String productId,
    required String name,
    required double price,
  }) {
    final existing = state.items.firstWhere(
      (i) => i.productId == productId,
      orElse: () => CartItem(productId: '', name: '', price: 0, quantity: 0),
    );

    final updated = [...state.items];
    if (existing.productId.isEmpty) {
      updated.add(CartItem(
        productId: productId,
        name: name,
        price: price,
        quantity: 1,
      ));
    } else {
      existing.quantity += 1;
    }
    state = CartState(items: updated);

    _ref.read(analyticsServiceProvider).trackAddToCart(
          productId: productId,
          quantity: 1,
          price: price,
        );
  }

  void startCheckout() {
    _ref.read(analyticsServiceProvider).trackCheckoutStarted(
          cartValue: state.total,
          itemCount: state.count,
        );
  }

  Future<void> completePurchase({required String paymentMethod}) async {
    final analytics = _ref.read(analyticsServiceProvider);
    final orderId = _uuid.v4();

    analytics.trackPurchaseCompleted(
      orderId: orderId,
      cartValue: state.total,
      itemCount: state.count,
      paymentMethod: paymentMethod,
    );

    state = CartState();
  }
}

final cartControllerProvider =
    StateNotifierProvider<CartController, CartState>((ref) {
  return CartController(ref);
});
