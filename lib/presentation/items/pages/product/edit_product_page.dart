import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_jago_pos_app/core/components/custom_dropdown.dart';
import 'package:flutter_jago_pos_app/core/components/spaces.dart';
import 'package:flutter_jago_pos_app/core/constants/colors.dart';
import 'package:flutter_jago_pos_app/core/constants/variables.dart';
import 'package:flutter_jago_pos_app/core/extensions/build_context_ext.dart';
import 'package:flutter_jago_pos_app/core/extensions/string_ext.dart';
import 'package:flutter_jago_pos_app/core/utils/image_utils.dart';
import 'package:flutter_jago_pos_app/data/datasources/auth_local_datasource.dart';
import 'package:flutter_jago_pos_app/data/models/responses/category_response_model.dart';
import 'package:flutter_jago_pos_app/data/models/responses/product_response_model.dart';
import 'package:flutter_jago_pos_app/presentation/items/bloc/category/category_bloc.dart';
import 'package:flutter_jago_pos_app/presentation/items/bloc/product/product_bloc.dart';
import 'package:image_picker/image_picker.dart';

import '../../models/product_model.dart';

class EditProductPage extends StatefulWidget {
  final Product data;
  const EditProductPage({
    super.key,
    required this.data,
  });

  @override
  State<EditProductPage> createState() => _EditProductPageState();
}

class _EditProductPageState extends State<EditProductPage> {
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _stockController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _barcodeController = TextEditingController();
  final _costController = TextEditingController();
  final _businessIdController = TextEditingController();

  Category? _selectedCategoryData;

  List<Color> _colors = [
    Colors.red,
    Colors.blue,
    Colors.green,
    Colors.yellow,
    Colors.purple,
    Colors.orange,
    Colors.pink,
    Colors.teal
  ];

  Color _selectedColor = Colors.red;
  final _formKey = GlobalKey<FormState>();
  XFile? _image;
  bool _isImage = false;
  bool _isLoading = false;

  @override
  void initState() {
    _initializeForm();
    context.read<CategoryBloc>().add(CategoryEvent.getCategories());
    super.initState();
  }

  void _initializeForm() {
    _nameController.text = widget.data.name ?? '';
    _priceController.text = widget.data.price!.currencyFormatRpV3;
    _stockController.text = widget.data.stock.toString();
    _descriptionController.text = widget.data.description ?? '';
    _barcodeController.text = widget.data.barcode ?? '';
    _costController.text = widget.data.cost!.currencyFormatRpV3;
    _businessIdController.text = widget.data.businessId.toString();
    _selectedCategoryData = widget.data.category;
    _selectedColor = changeStringtoColor(widget.data.color ?? '');
    if (widget.data.image != null) {
      _isImage = true;
    }
  }

  Future<void> _getImage() async {
    final image = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (image != null) {
      final file = File(image.path);
      final sizeInBytes = await file.length();
      final sizeInMB = sizeInBytes / (1024 * 1024);

      if (sizeInMB > 5) {
        if (mounted) {
          context.showSnackBar('Ukuran gambar melebihi 5MB', Colors.red);
        }
        return;
      }

      setState(() {
        _image = image;
      });
    }
  }

  Future<void> _takePicture() async {
    final image = await ImagePicker().pickImage(source: ImageSource.camera);
    if (image != null) {
      final file = File(image.path);
      final sizeInBytes = await file.length();
      final sizeInMB = sizeInBytes / (1024 * 1024);

      if (sizeInMB > 5) {
        if (mounted) {
          context.showSnackBar('Ukuran gambar melebihi 5MB', Colors.red);
        }
        return;
      }

      setState(() {
        _image = image;
      });
    }
  }

  void changeColor(Color color) {
    setState(() {
      _selectedColor = color;
    });
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      debugPrint('Form validation failed');
      return;
    }

    if (_selectedCategoryData == null || _selectedCategoryData!.id == 0) {
      debugPrint('No category selected');
      context.showSnackBar('Pilih kategori terlebih dahulu', Colors.red);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final authData = await AuthLocalDatasource().getUserData();
      final outletData = await AuthLocalDatasource().getOutletData();

      // Validate and process image if needed
      File? imageFile;
      if (_isImage && _image != null) {
        debugPrint('Processing image...');
        final originalFile = File(_image!.path);
        final fileSize = await originalFile.length();
        final fileSizeMB = fileSize / (1024 * 1024);

        if (fileSizeMB > 5) {
          debugPrint('Compressing image (original size: ${fileSizeMB.toStringAsFixed(2)}MB)');
          imageFile = await ImageUtils.compressImage(originalFile);
          
          if (imageFile == null) {
            throw Exception('Gagal mengkompres gambar');
          }

          final compressedSize = await imageFile.length();
          final compressedSizeMB = compressedSize / (1024 * 1024);
          debugPrint('Compressed image size: ${compressedSizeMB.toStringAsFixed(2)}MB');
        } else {
          imageFile = originalFile;
          debugPrint('Image size OK (${fileSizeMB.toStringAsFixed(2)}MB)');
        }
      }

      final data = ProductModel(
        name: _nameController.text,
        categoryId: _selectedCategoryData!.id!,
        price: _priceController.text.toIntegerFromText.toDouble(),
        cost: _costController.text.toIntegerFromText.toDouble(),
        stock: int.parse(_stockController.text),
        color: getColorString(_selectedColor),
        barcode: _barcodeController.text,
        businessId: authData!.data!.businessId!,
        description: _descriptionController.text,
        outletId: outletData.id!,
      );

      if (_isImage && imageFile != null) {
        debugPrint('Attempting to update product with processed image');
        context.read<ProductBloc>().add(
              ProductEvent.editProductWithImage(data, XFile(imageFile.path), widget.data.id!),
            );
      } else {
        debugPrint('Attempting to update product without image');
        context.read<ProductBloc>().add(
              ProductEvent.editProduct(data, widget.data.id!),
            );
      }
    } catch (e) {
      debugPrint('Error in _submitForm: $e');
      if (mounted) {
        context.showSnackBar('Terjadi kesalahan: $e', Colors.red);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ProductBloc, ProductState>(
      listener: (context, state) {
        state.maybeWhen(
          orElse: () {},
          success: (message) {
            debugPrint('Product update success: $message');
            Navigator.of(context)
              ..pop()
              ..pop();
            context.showSnackBar('Produk berhasil diperbarui', AppColors.primary);
          },
          error: (message) {
            debugPrint('Product update error: $message');
            
            String errorMessage = 'Gagal mengupdate produk';
            if (message.contains('File gambar tidak ditemukan')) {
              errorMessage = 'File gambar tidak ditemukan';
            } else if (message.contains('Ukuran gambar masih terlalu besar')) {
              errorMessage = 'Ukuran gambar terlalu besar (maks 5MB)';
            } else if (message.contains('Failed')) {
              errorMessage = 'Gagal menyimpan ke server';
            }
            
            context.showSnackBar(errorMessage, Colors.red);
          },
        );
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Edit Product',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          centerTitle: true,
          leading: IconButton(
            onPressed: () {
              Navigator.pop(context);
            },
            icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          ),
        ),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nama Produk',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Nama produk tidak boleh kosong';
                  }
                  return null;
                },
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 16),
              BlocBuilder<CategoryBloc, CategoryState>(
                builder: (context, state) {
                  return state.maybeWhen(
                    orElse: () => const Center(child: CircularProgressIndicator()),
                    success: (data) {
                      final categories = data.data ?? [];
                      
                      // Remove duplicates by id
                      final uniqueCategories = categories.fold<Map<int, Category>>(
                        {},
                        (map, category) {
                          if (category.id != null) {
                            map[category.id!] = category;
                          }
                          return map;
                        },
                      ).values.toList();

                      // Set initial selection if not set or invalid
                      if (_selectedCategoryData == null ||
                          !uniqueCategories.any((c) => c.id == _selectedCategoryData?.id)) {
                        _selectedCategoryData = widget.data.category ??
                            (uniqueCategories.isNotEmpty ? uniqueCategories.first : null);
                      }

                      return CustomDropdown<Category>(
                        value: _selectedCategoryData,
                        items: uniqueCategories,
                        label: 'Kategori',
                        itemToString: (item) => item.name ?? 'Unknown',
                        onChanged: (value) {
                          setState(() {
                            _selectedCategoryData = value;
                          });
                        },
                      );
                    },
                  );
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(
                  labelText: 'Harga Jual',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Harga jual tidak boleh kosong';
                  }
                  if (value.toIntegerFromText <= 0) {
                    return 'Harga jual harus lebih dari 0';
                  }
                  return null;
                },
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _costController,
                decoration: const InputDecoration(
                  labelText: 'Harga Modal',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Harga modal tidak boleh kosong';
                  }
                  if (value.toIntegerFromText <= 0) {
                    return 'Harga modal harus lebih dari 0';
                  }
                  return null;
                },
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _stockController,
                decoration: const InputDecoration(
                  labelText: 'Stok',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Stok tidak boleh kosong';
                  }
                  if (int.tryParse(value) == null) {
                    return 'Stok harus berupa angka';
                  }
                  return null;
                },
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _barcodeController,
                decoration: const InputDecoration(
                  labelText: 'Barcode',
                ),
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Deskripsi',
                ),
                maxLines: 3,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 16),
              const Text('Tampilan di POS'),
              const SizedBox(height: 8),
              RadioListTile<bool>(
                value: false,
                groupValue: _isImage,
                onChanged: (value) {
                  setState(() {
                    _isImage = value!;
                  });
                },
                title: const Text('Warna'),
              ),
              RadioListTile<bool>(
                value: true,
                groupValue: _isImage,
                onChanged: (value) {
                  setState(() {
                    _isImage = value!;
                  });
                },
                title: const Text('Gambar'),
              ),
              const SizedBox(height: 16),
              if (!_isImage)
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _colors
                      .map((color) => GestureDetector(
                            onTap: () => changeColor(color),
                            child: _selectedColor == color
                                ? Container(
                                    width: 50,
                                    height: 50,
                                    decoration: BoxDecoration(
                                      color: color,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: Colors.grey,
                                        width: 4,
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.check,
                                      color: Colors.white,
                                    ),
                                  )
                                : Container(
                                    width: 50,
                                    height: 50,
                                    decoration: BoxDecoration(
                                      color: color,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: Colors.grey.shade300,
                                      ),
                                    ),
                                  ),
                          ))
                      .toList(),
                ),
              if (_isImage)
                Row(
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: _image != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.file(
                                File(_image!.path),
                                fit: BoxFit.cover,
                              ),
                            )
                          : widget.data.image != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: Image.network(
                                    widget.data.image!.startsWith('http')
                                        ? widget.data.image!
                                        : widget.data.image!.startsWith('/storage')
                                            ? '${Variables.baseUrl}${widget.data.image!}'
                                            : '${Variables.imageBaseUrl}${widget.data.image!}',
                                    width: 100,
                                    height: 100,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      print('Error loading image: $error');
                                      return Container(
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(10),
                                          color: Colors.grey[300],
                                        ),
                                        child: const Icon(
                                          Icons.broken_image,
                                          size: 30,
                                          color: Colors.grey,
                                        ),
                                      );
                                    },
                                    loadingBuilder:
                                        (context, child, loadingProgress) {
                                      if (loadingProgress == null) return child;
                                      return Container(
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(10),
                                          color: Colors.grey[200],
                                        ),
                                        child: const Center(
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                )
                              : const Icon(
                                  Icons.image,
                                  color: Colors.white,
                                  size: 50,
                                ),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(200, 40),
                          ),
                          onPressed: _getImage,
                          child: const Row(
                            children: [
                              Icon(Icons.folder),
                              SpaceWidth(8),
                              Text('Pilih Gambar'),
                            ],
                          ),
                        ),
                        OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(200, 40),
                          ),
                          onPressed: _takePicture,
                          child: const Row(
                            children: [
                              Icon(Icons.camera_alt),
                              SpaceWidth(8),
                              Text('Ambil Foto'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              const SizedBox(height: 24),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  backgroundColor: AppColors.primary,
                ),
                onPressed: _isLoading ? null : _submitForm,
                child: _isLoading
                    ? const CircularProgressIndicator(
                        color: Colors.white,
                      )
                    : const Text(
                        'Simpan Perubahan',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    _descriptionController.dispose();
    _barcodeController.dispose();
    _costController.dispose();
    _businessIdController.dispose();
    super.dispose();
  }
}