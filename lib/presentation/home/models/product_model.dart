import '../../../data/models/responses/transaction_response_model.dart';

class ProductModel {
  final int id;
  final String name;
  String? description;
  final double price;
  final String image;

  ProductModel({
    required this.id,
    required this.name,
    this.description,
    required this.price,
    required this.image,
  });
}

class ProductQtyModel {
  final ProductModel product;
  int qty;

  ProductQtyModel({
    required this.product,
    this.qty = 1,
  });
}

class TransactionGroup {
  final String date;
  final List<Transaction> items;

  TransactionGroup({required this.date, required this.items});
}