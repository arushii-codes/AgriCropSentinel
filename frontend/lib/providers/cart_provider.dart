import 'package:flutter/foundation.dart';

class CartItem {
  final String id;
  final String name;
  final double price;
  int quantity;
  final String imagePath;

  CartItem({
    required this.id,
    required this.name,
    required this.price,
    required this.quantity,
    required this.imagePath,
  });
}

class CartProvider with ChangeNotifier {
  final Map<String, CartItem> _items = {};

  Map<String, CartItem> get items {
    return {..._items};
  }

  int get itemCount {
    return _items.length;
  }

  double get totalAmount {
    var total = 0.0;
    _items.forEach((key, cartItem) {
      total += cartItem.price * cartItem.quantity;
    });
    return total;
  }

  void addItem(String productId, double price, String name, String imagePath) {
    if (_items.containsKey(productId)) {
      // if item is already in the cart, just increase quantity
      _items.update(
        productId,
        (existingCartItem) => CartItem(
          id: existingCartItem.id,
          name: existingCartItem.name,
          price: existingCartItem.price,
          imagePath: existingCartItem.imagePath,
          quantity: existingCartItem.quantity + 1,
        ),
      );
    } else {
      // add a new item to the cart
      _items.putIfAbsent(
        productId,
        () => CartItem(
          id: DateTime.now().toString(),
          name: name,
          price: price,
          imagePath: imagePath,
          quantity: 1,
        ),
      );
    }
    // This is crucial! It tells any listening widgets to rebuild.
    notifyListeners();
  }

  void removeItem(String productId) {
    _items.remove(productId);
    notifyListeners();
  }

  void updateQuantity(String productId, int newQuantity) {
    if (_items.containsKey(productId)) {
      if (newQuantity > 0) {
        _items.update(
          productId,
          (existing) => CartItem(
            id: existing.id,
            name: existing.name,
            price: existing.price,
            quantity: newQuantity,
            imagePath: existing.imagePath,
          ),
        );
      } else {
        // If quantity is 0 or less, remove the item
        _items.remove(productId);
      }
      notifyListeners();
    }
  }

  void clear() {
    _items.clear();
    notifyListeners();
  }
}
