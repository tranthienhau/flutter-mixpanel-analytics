import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/analytics/analytics_provider.dart';
import 'cart_controller.dart';

class Product {
  const Product({
    required this.id,
    required this.name,
    required this.category,
    required this.price,
  });
  final String id;
  final String name;
  final String category;
  final double price;
}

const _catalog = [
  Product(id: 'p1', name: 'Daily Streak Hoodie', category: 'apparel', price: 49.0),
  Product(id: 'p2', name: 'Quest Master Mug', category: 'home', price: 14.0),
  Product(id: 'p3', name: 'Level Up Sneakers', category: 'apparel', price: 120.0),
  Product(id: 'p4', name: 'XP Boost Snack Pack', category: 'food', price: 9.0),
];

class ProductListScreen extends ConsumerWidget {
  const ProductListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(cartControllerProvider);
    final analytics = ref.read(analyticsServiceProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Shop'),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Center(child: Text('${cart.count} items')),
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: _catalog.length,
        itemBuilder: (context, index) {
          final product = _catalog[index];
          return ListTile(
            title: Text(product.name),
            subtitle: Text('\$${product.price.toStringAsFixed(2)}'),
            trailing: ElevatedButton(
              child: const Text('Add'),
              onPressed: () => ref.read(cartControllerProvider.notifier).addItem(
                    productId: product.id,
                    name: product.name,
                    price: product.price,
                  ),
            ),
            onTap: () => analytics.trackProductViewed(
              productId: product.id,
              productName: product.name,
              category: product.category,
              price: product.price,
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          ref.read(cartControllerProvider.notifier).startCheckout();
          await ref
              .read(cartControllerProvider.notifier)
              .completePurchase(paymentMethod: 'apple_pay');
        },
        label: const Text('Checkout'),
      ),
    );
  }
}
