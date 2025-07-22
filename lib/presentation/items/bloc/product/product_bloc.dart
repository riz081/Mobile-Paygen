import 'dart:io';

import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_jago_pos_app/presentation/items/models/product_model.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:flutter_jago_pos_app/data/datasources/product_remote_datasource.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../data/models/responses/product_response_model.dart';

part 'product_bloc.freezed.dart';
part 'product_event.dart';
part 'product_state.dart';

class ProductBloc extends Bloc<ProductEvent, ProductState> {
  final ProductRemoteDataSource productRemoteDataSource;
  List<Product> products = [];
  ProductBloc(
    this.productRemoteDataSource,
  ) : super(_Initial()) {
    on<_AddProduct>((event, emit) async {
      emit(ProductState.loading());
      final result = await productRemoteDataSource.addProduct(
        event.product,
      );
      result.fold(
        (l) => emit(_Error(l)),
        (r) => add(_GetProducts()),
      );
    });

    on<_AddProductWithImage>((event, emit) async {
      emit(ProductState.loading());
      final result = await productRemoteDataSource.addProductWithImage(
        event.product,
        event.image,
      );
      result.fold(
        (l) => emit(_Error(l)),
        (r) => add(_GetProducts()),
      );
    });

    on<_EditProduct>((event, emit) async {
      emit(ProductState.loading());
      debugPrint('Editing product with ID: ${event.id}');
      debugPrint('Product data: ${event.product.toString()}');
      
      final result = await productRemoteDataSource.editProduct(
        event.product,
        event.id,
      );
      
      result.fold(
        (l) {
          debugPrint('Edit product failed: $l');
          emit(_Error(l));
        },
        (r) {
          debugPrint('Edit product success');
          add(_GetProducts());
        },
      );
    });

    on<_EditProductWithImage>((event, emit) async {
      emit(ProductState.loading());
      try {
        debugPrint('Editing product with image, ID: ${event.id}');
        
        // Verify image exists
        final imageFile = File(event.image.path);
        if (!await imageFile.exists()) {
          throw Exception('File gambar tidak ditemukan');
        }

        // Verify image size
        final fileSize = await imageFile.length();
        if (fileSize > 5 * 1024 * 1024) { // 5MB
          throw Exception('Ukuran gambar masih terlalu besar setelah kompresi');
        }

        final result = await productRemoteDataSource.editProductWithImage(
          event.product,
          event.image,
          event.id,
        );
        
        result.fold(
          (l) {
            debugPrint('Edit product with image failed: $l');
            emit(_Error(l));
          },
          (r) {
            debugPrint('Edit product with image success');
            add(_GetProducts());
          },
        );
      } catch (e) {
        debugPrint('Error in editProductWithImage: $e');
        emit(_Error(e.toString()));
      }
    });

    on<_GetProducts>((event, emit) async {
      emit(ProductState.loading());
      final result = await productRemoteDataSource.getProducts();
      result.fold(
        (l) => emit(_Error(l)),
        (r) {
          products = r.data ?? [];
          emit(_Success(r.data ?? []));
        },
      );
    });

    on<_SearchProduct>((event, emit) async {
      final searchResult = products
          .where((element) =>
              element.name!.toLowerCase().contains(event.query.toLowerCase()))
          .toList();

      emit(_Success(searchResult));
    });

    on<_UpdateStock>((event, emit) async {
      emit(ProductState.loading());
      final result = await productRemoteDataSource.updateStock(
        event.stock,
        event.type,
        event.note,
        event.id,
      );
      result.fold(
        (l) => emit(_Error(l)),
        (r) => add(_GetProducts()),
      );
    });

    on<_GetProductsByCategory>((event, emit) async {
      emit(ProductState.loading());
      final result = products
          .where((element) => element.categoryId! == event.categoryId)
          .toList();
      emit(_Success(result));
    });

    on<_GetProductByBarcode>((event, emit) async {
      emit(ProductState.loading());
      final result = products
          .where((element) => element.barcode == event.barcode)
          .toList();
      emit(_Success(result));
    });
  }
}
