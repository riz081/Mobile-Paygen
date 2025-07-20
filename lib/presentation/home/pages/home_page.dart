import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_jago_pos_app/core/components/spaces.dart';
import 'package:flutter_jago_pos_app/core/constants/colors.dart';
import 'package:flutter_jago_pos_app/core/constants/variables.dart';
import 'package:flutter_jago_pos_app/core/extensions/build_context_ext.dart';
import 'package:flutter_jago_pos_app/core/extensions/int_ext.dart';
import 'package:flutter_jago_pos_app/core/extensions/string_ext.dart';
import 'package:flutter_jago_pos_app/data/datasources/auth_local_datasource.dart';
import 'package:flutter_jago_pos_app/data/models/requests/business_setting_request_model.dart';
import 'package:flutter_jago_pos_app/presentation/auth/bloc/account/account_bloc.dart';
import 'package:flutter_jago_pos_app/presentation/home/bloc/checkout/checkout_bloc.dart';
import 'package:flutter_jago_pos_app/presentation/home/models/product_model.dart';
import 'package:flutter_jago_pos_app/presentation/home/pages/checkout_page.dart';
import 'package:flutter_jago_pos_app/presentation/home/widgets/drawer_widget.dart';
import 'package:flutter_jago_pos_app/presentation/items/bloc/category/category_bloc.dart';
import 'package:flutter_jago_pos_app/presentation/items/bloc/product/product_bloc.dart';
import 'package:flutter_jago_pos_app/presentation/items/pages/category_page.dart';
import 'package:flutter_jago_pos_app/presentation/scanner/blocs/get_qrcode/get_qrcode_bloc.dart';
import 'package:flutter_jago_pos_app/presentation/scanner/pages/scanner_page.dart';
import 'package:flutter_jago_pos_app/presentation/tax_discount/bloc/business_setting/business_setting_bloc.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';
import 'package:collection/collection.dart';


class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _animation;
  OverlayEntry? _overlayEntry;

  final GlobalKey cartKey = GlobalKey();
  bool _isAnimating = false;
  double totalPayment = 0;

  int? selectedCategory;

  @override
  void initState() {
    super.initState();
    context.read<ProductBloc>().add(ProductEvent.getProducts());
    context.read<AccountBloc>().add(const AccountEvent.getAccount());
    context.read<CategoryBloc>().add(const CategoryEvent.getCategories());
    context.read<BusinessSettingBloc>().add(const BusinessSettingEvent.getBusinessSetting());

    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));

    AuthLocalDatasource().getPrinter().then((value) async {
      if (value != null) {
        await PrintBluetoothThermal.connect(macPrinterAddress: value.macAddress ?? "");
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _startAnimation(BuildContext context, GlobalKey buttonKey, Widget image) {
    if (_isAnimating) return;

    final RenderBox buttonBox = buttonKey.currentContext!.findRenderObject() as RenderBox;
    final RenderBox cartBox = cartKey.currentContext!.findRenderObject() as RenderBox;
    final Offset buttonPosition = buttonBox.localToGlobal(Offset.zero);
    final Offset cartPosition = cartBox.localToGlobal(Offset.zero);

    _animation = Tween<Offset>(
      begin: buttonPosition,
      end: cartPosition,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _overlayEntry = _createFloatingIcon(buttonPosition, image);
    Overlay.of(context).insert(_overlayEntry!);

    setState(() => _isAnimating = true);

    _controller.forward().then((_) {
      _overlayEntry?.remove();
      setState(() {
        _isAnimating = false;
        _controller.reset();
      });
    });
  }

  OverlayEntry _createFloatingIcon(Offset startPosition, Widget image) {
    return OverlayEntry(
      builder: (context) => AnimatedBuilder(
        animation: _controller,
        builder: (_, child) {
          final offset = Offset(_animation.value.dx, _animation.value.dy);
          return Positioned(top: offset.dy, left: offset.dx, child: image);
        },
      ),
    );
  }

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: DrawerWidget(),
      appBar: AppBar(
        title: const Text('Penjualan', style: TextStyle(color: AppColors.white, fontSize: 18, fontWeight: FontWeight.w700)),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.menu, color: AppColors.white),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        actions: [
          BlocListener<GetQrcodeBloc, GetQrcodeState>(
            listener: (context, state) {
              state.maybeWhen(
                orElse: () {},
                success: (value) {
                  context.read<ProductBloc>().add(ProductEvent.getProductByBarcode(value));
                },
              );
            },
            child: GestureDetector(
              onTap: () {
                context.read<GetQrcodeBloc>().add(const GetQrcodeEvent.started());
                context.push(const ScannerPage());
              },
              child: Image.asset('assets/images/barcode.png', color: AppColors.white, height: 28),
            ),
          ),
          const SpaceWidth(16),
        ],
      ),
      body: Column(
        children: [
          InkWell(
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const CheckoutPage()));
            },
            child: Container(
              key: cartKey,
              height: 80,
              width: double.infinity,
              margin: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
              decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(10)),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('BAYAR', style: TextStyle(color: AppColors.white, fontSize: 18, fontWeight: FontWeight.w700)),
                  BlocBuilder<CheckoutBloc, CheckoutState>(
                    builder: (context, state) {
                      return state.maybeWhen(
                        orElse: () => const Text('0 (0 item)', style: TextStyle(color: AppColors.white)),
                        success: (orders, promo, tax, subtotal, total, qty) {
                          return Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(total.currencyFormatRp, style: const TextStyle(color: AppColors.white, fontSize: 20, fontWeight: FontWeight.w700)),
                              const SpaceWidth(10),
                              Text('($qty item)', style: const TextStyle(color: AppColors.white, fontSize: 16, fontWeight: FontWeight.w700)),
                            ],
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4, offset: const Offset(0, 2))],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Image.asset('assets/icons/search-status.png', color: AppColors.primary),
                    const SizedBox(width: 16),
                    Container(height: 28, width: 1, color: Colors.grey.shade300),
                    const SizedBox(width: 8),
                    BlocBuilder<CategoryBloc, CategoryState>(
                      builder: (context, state) {
                        return state.maybeWhen(
                          orElse: () => const Text('Semua Kategori', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                          success: (data) {
                            return SizedBox(
                              width: 240,
                              child: DropdownButton(
                                icon: const SizedBox.shrink(),
                                borderRadius: BorderRadius.circular(8),
                                value: selectedCategory,
                                items: data.data!.map((e) => DropdownMenuItem(value: e.id, child: Text(e.name ?? ''))).toList(),
                                onChanged: (value) {
                                  setState(() => selectedCategory = value);
                                  context.read<ProductBloc>().add(ProductEvent.getProductsByCategory(value!));
                                },
                                hint: const Text('Semua Kategori', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SpaceHeight(8),
          Expanded(
            child: BlocBuilder<AccountBloc, AccountState>(
              builder: (context, accountState) {
                final outletData = accountState.maybeWhen(
                  orElse: () => null,
                  loaded: (_, outlet) => outlet,
                );
                return BlocBuilder<BusinessSettingBloc, BusinessSettingState>(
                  builder: (context, settingState) {
                    final taxs = settingState.maybeWhen(
                      orElse: () => [],
                      loaded: (data) => data.where((e) => e.chargeType == 'tax').toList(),
                    );
                    return BlocBuilder<ProductBloc, ProductState>(
                      builder: (context, productState) {
                        return productState.maybeWhen(
                          orElse: () => const Center(child: CircularProgressIndicator()),
                          loading: () => const Center(child: CircularProgressIndicator()),
                          success: (products) {
                            if (products.isEmpty) {
                              return Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Center(child: Text("No Items")),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.primary,
                                      minimumSize: const Size(200, 50),
                                    ),
                                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CategoryPage())),
                                    child: const Text("Tambahkan Kategori", style: TextStyle(color: AppColors.white)),
                                  ),
                                ],
                              );
                            }

                            return ListView.separated(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              itemBuilder: (context, index) {
                                final product = products[index];
                                final stock = product.stocks?.firstWhereOrNull(
                                  (e) => e.outletId == outletData?.id,
                                );
                                GlobalKey buttonKey = GlobalKey();
                                return InkWell(
                                  key: buttonKey,
                                  onTap: () async {
                                    if (stock == null || stock.quantity == null || stock.quantity! <= 0) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text("Stok Habis"), backgroundColor: AppColors.red),
                                      );
                                      return;
                                    }
                                    _startAnimation(
                                      context,
                                      buttonKey,
                                      Container(
                                        width: 50,
                                        height: 50,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(10),
                                          color: changeStringtoColor(product.color ?? ""),
                                        ),
                                      ),
                                    );
                                    await Future.delayed(const Duration(milliseconds: 700));
                                    context.read<CheckoutBloc>().add(
                                          CheckoutEvent.addToCart(product: product, businessSetting: taxs.cast<BusinessSettingRequestModel>()),
                                        );
                                  },
                                  child: Card(
                                    color: Colors.white,
                                    child: ListTile(
                                      leading: product.image != null
                                          ? ClipRRect(
                                              borderRadius: BorderRadius.circular(10),
                                              child: Image.network(
                                                product.image!.startsWith('http')
                                                    ? product.image!
                                                    : product.image!.startsWith('/storage')
                                                        ? '${Variables.baseUrl}${product.image!}'
                                                        : '${Variables.imageBaseUrl}${product.image!}',
                                                width: 50,
                                                height: 50,
                                                fit: BoxFit.cover,
                                                errorBuilder: (context, error, stackTrace) => Icon(Icons.broken_image),
                                              ),
                                            )
                                          : Container(
                                              width: 50,
                                              height: 50,
                                              decoration: BoxDecoration(
                                                borderRadius: BorderRadius.circular(10),
                                                color: changeStringtoColor(product.color ?? ""),
                                              ),
                                            ),
                                      title: Text(product.name ?? "", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                                      subtitle: Text(
                                        "Stock: ${stock?.quantity ?? 0}",
                                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w400),
                                      ),
                                      trailing: Text(product.price!.currencyFormatRpV3, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                                    ),
                                  ),
                                );
                              },
                              itemCount: products.length,
                              separatorBuilder: (_, __) => const SpaceHeight(4),
                            );
                          },
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
