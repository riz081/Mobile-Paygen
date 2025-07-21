import 'package:flutter/material.dart';
import 'package:flutter_jago_pos_app/core/constants/colors.dart';
import 'package:flutter_jago_pos_app/core/constants/variables.dart';
import 'package:flutter_jago_pos_app/core/extensions/string_ext.dart';

import 'package:flutter_jago_pos_app/data/models/responses/product_response_model.dart';
import 'package:flutter_jago_pos_app/presentation/items/pages/product/edit_product_page.dart';

class DetailProductPage extends StatefulWidget {
  final Product data;
  const DetailProductPage({
    super.key,
    required this.data,
  });

  @override
  State<DetailProductPage> createState() => _DetailProductPageState();
}

class _DetailProductPageState extends State<DetailProductPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Product',
            style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700)),
        centerTitle: true,
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          widget.data.image != null
              ? Container(
                  width: double.infinity,
                  height: 200, // Tinggi yang lebih proporsional
                  margin: const EdgeInsets.only(bottom: 16),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(
                      // Fix: Gunakan logika yang sama seperti di HomePage
                      widget.data.image!.startsWith('http')
                          ? widget.data.image!
                          : widget.data.image!.startsWith('/storage')
                              ? '${Variables.baseUrl}${widget.data.image!}'
                              : '${Variables.imageBaseUrl}${widget.data.image!}',
                      width: double.infinity,
                      height: 200,
                      fit: BoxFit.contain, // Ubah ke contain agar tidak terpotong
                      // Tambahkan error handling
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: double.infinity,
                          height: 200,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            color: Colors.grey[300],
                          ),
                          child: const Icon(
                            Icons.broken_image,
                            size: 50,
                            color: Colors.grey,
                          ),
                        );
                      },
                      // Tambahkan loading indicator
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          width: double.infinity,
                          height: 200,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            color: Colors.grey[200],
                          ),
                          child: const Center(
                            child: CircularProgressIndicator(),
                          ),
                        );
                      },
                    ),
                  ),
                )
              : Container(
                  width: double.infinity,
                  height: 200,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: changeStringtoColor(widget.data.color ?? ''),
                  ),
                  child: const Icon(
                    Icons.image,
                    size: 80,
                    color: Colors.white,
                  ),
                ),
          ListTile(
            title: const Text('Nama Product'),
            subtitle: Text(widget.data.name ?? ''),
          ),
          //category
          ListTile(
            title: const Text('Kategori Product'),
            subtitle: Text(widget.data.category?.name ?? ''),
          ),
          ListTile(
            title: const Text('Harga Jual Product'),
            subtitle: Text(widget.data.price!.currencyFormatRpV3),
          ),

          ListTile(
            title: const Text('Harga Dasar Product'),
            subtitle: Text(widget.data.cost!.currencyFormatRpV3),
          ),
          SizedBox(height: 16),
          //edit button
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EditProductPage(data: widget.data),
                ),
              );
            },
            child: const Text('Edit Product'),
          ),
        ],
      ),
    );
  }
}