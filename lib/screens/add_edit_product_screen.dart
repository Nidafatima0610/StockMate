import 'package:flutter/material.dart';

import '../models/product.dart';
import '../theme/app_theme.dart';

/// Screen for adding a new product or editing an existing product.
///
/// Redesigned with an executive single-card layout that groups form fields into
/// clear visual sections (Product Details, Categorization, Pricing & Stock Control),
/// provides quick-selection chips, live batch valuation preview, and responsive sizing.
class AddEditProductScreen extends StatefulWidget {
  final Product? product;
  final int lowStockThreshold;

  const AddEditProductScreen({
    super.key,
    this.product,
    this.lowStockThreshold = kDefaultLowStockThreshold,
  });

  @override
  State<AddEditProductScreen> createState() => _AddEditProductScreenState();
}

class _AddEditProductScreenState extends State<AddEditProductScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _categoryController;
  late final TextEditingController _priceController;
  late final TextEditingController _quantityController;

  bool get _isEditing => widget.product != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.product?.name ?? '');
    _categoryController = TextEditingController(
      text: widget.product?.category ?? '',
    );
    _priceController = TextEditingController(
      text: widget.product != null
          ? widget.product!.price.toStringAsFixed(2)
          : '',
    );
    _quantityController = TextEditingController(
      text: widget.product != null ? widget.product!.quantity.toString() : '',
    );

    _priceController.addListener(_onValuesChanged);
    _quantityController.addListener(_onValuesChanged);
    _categoryController.addListener(_onValuesChanged);
  }

  void _onValuesChanged() {
    setState(() {});
  }

  @override
  void dispose() {
    _priceController.removeListener(_onValuesChanged);
    _quantityController.removeListener(_onValuesChanged);
    _categoryController.removeListener(_onValuesChanged);
    _nameController.dispose();
    _categoryController.dispose();
    _priceController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  AutovalidateMode _autovalidateMode = AutovalidateMode.disabled;

  String? _validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Product name cannot be empty';
    }
    return null;
  }

  String? _validatePrice(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Price cannot be empty';
    }
    final price = double.tryParse(value.trim());
    if (price == null || price <= 0) {
      return 'Price must be a valid number greater than zero';
    }
    return null;
  }

  String? _validateQuantity(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Quantity cannot be empty';
    }
    final quantity = int.tryParse(value.trim());
    if (quantity == null || quantity < 0) {
      return 'Quantity must be a valid whole number (0 or greater)';
    }
    return null;
  }

  void _handleSave() {
    if (!_formKey.currentState!.validate()) {
      setState(() {
        _autovalidateMode = AutovalidateMode.onUserInteraction;
      });
      return;
    }

    final name = _nameController.text.trim();
    final rawCategory = _categoryController.text.trim();
    final category = rawCategory.isEmpty ? 'General' : rawCategory;
    final price = double.parse(_priceController.text.trim());
    final quantity = int.parse(_quantityController.text.trim());

    final idSuffix = name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
    final cleanId = idSuffix.length > 8 ? idSuffix.substring(0, 8) : idSuffix;
    final product = Product(
      id: widget.product?.id ?? 'prod-$cleanId',
      name: name,
      price: price,
      quantity: quantity,
      category: category,
    );

    Navigator.pop(context, product);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7FC),
      appBar: AppBar(
        titleSpacing: 0,
        leading: IconButton(
          key: const Key('add_edit_back_button'),
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
            size: 18,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _isEditing ? 'Edit Product' : 'Add New Product',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18.5,
            color: Colors.white,
            letterSpacing: -0.2,
          ),
        ),
        backgroundColor: const Color(0xFF5B2EBC),
        elevation: 0,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 14),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.25),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _isEditing
                      ? Icons.edit_note_rounded
                      : Icons.add_circle_outline_rounded,
                  size: 14,
                  color: Colors.white,
                ),
                const SizedBox(width: 4),
                Text(
                  _isEditing ? 'EDITING' : 'NEW ITEM',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 12.0,
              ),
              child: Form(
                key: _formKey,
                autovalidateMode: _autovalidateMode,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Contextual Hero Banner
                    _buildHeroBanner(),
                    const SizedBox(height: 12),

                    // Main Product Card
                    _buildMainFormCard(),
                    const SizedBox(height: 14),

                    // Primary Save / Update Button
                    ElevatedButton(
                      key: const Key('save_product_button'),
                      onPressed: _handleSave,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF5B2EBC),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                        shadowColor: const Color(0xFF5B2EBC)
                            .withValues(alpha: 0.35),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.check_rounded,
                            color: Colors.white,
                            size: 19,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _isEditing ? 'Update Product' : 'Save Product',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 0.1,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Secondary Cancel Button
                    OutlinedButton(
                      key: const Key('cancel_product_button'),
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF5B2EBC),
                        side: const BorderSide(
                          color: Color(0xFFD4C8FA),
                          width: 1.1,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF5B2EBC),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Informational Hero Banner with SKU, mode, and workflow advice.
  Widget _buildHeroBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border, width: 1.1),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF5B2EBC), Color(0xFF431C9A)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              _isEditing ? Icons.edit_note_rounded : Icons.add_business_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        _isEditing
                            ? 'Update Inventory Item'
                            : 'New Inventory Item',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF161324),
                          letterSpacing: -0.1,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (_isEditing && widget.product != null) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3EFFF),
                          borderRadius: BorderRadius.circular(5),
                          border: Border.all(
                            color: const Color(0xFFD4C8FA),
                            width: 0.8,
                          ),
                        ),
                        child: Text(
                          '#${widget.product!.id}',
                          style: const TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF5B2EBC),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 1),
                Text(
                  _isEditing
                      ? 'Modify product specifications, unit pricing, and recorded stock counts.'
                      : 'Register a new item into your small business inventory catalog.',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF6B687E),
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Master Executive Form Card containing organized sections: Identity, Category & Chips, Pricing & Stock.
  Widget _buildMainFormCard() {
    final parsedPrice = double.tryParse(_priceController.text.trim()) ?? 0.0;
    final parsedQty = int.tryParse(_quantityController.text.trim()) ?? 0;
    final batchValuation = parsedPrice * parsedQty;

    final bool isDepleted = parsedQty == 0;
    final bool isLowStock =
        parsedQty > 0 && parsedQty <= widget.lowStockThreshold;

    final Color statusColor;
    final Color statusBg;
    final String statusLabel;
    final IconData statusIcon;

    if (isDepleted) {
      statusColor = const Color(0xFFC02626);
      statusBg = const Color(0xFFFEECEB);
      statusLabel = 'Out of Stock (0 units)';
      statusIcon = Icons.remove_circle_outline_rounded;
    } else if (isLowStock) {
      statusColor = const Color(0xFFD97706);
      statusBg = const Color(0xFFFFFBEB);
      statusLabel = 'Low Stock (≤ ${widget.lowStockThreshold} units)';
      statusIcon = Icons.warning_amber_rounded;
    } else {
      statusColor = const Color(0xFF0F764C);
      statusBg = const Color(0xFFE6F7F0);
      statusLabel = 'Optimal Level (> ${widget.lowStockThreshold} units)';
      statusIcon = Icons.check_circle_outline_rounded;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border, width: 1.1),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section 1 Header: Product Identity
          _buildCardSectionHeader(
            icon: Icons.badge_outlined,
            title: 'Product Information',
            badgeText: 'Required',
            badgeBg: const Color(0xFFF3EFFF),
            badgeColor: const Color(0xFF5B2EBC),
          ),
          const SizedBox(height: 12),

          // Product Name
          _buildTextField(
            fieldKey: const Key('product_name_field'),
            controller: _nameController,
            label: 'Product Name',
            hint: 'e.g., Wireless Ergonomic Mouse',
            icon: Icons.inventory_2_outlined,
            validator: _validateName,
          ),
          const SizedBox(height: 12),

          // Category Field
          _buildTextField(
            fieldKey: const Key('product_category_field'),
            controller: _categoryController,
            label: 'Category',
            hint: 'e.g., Electronics, Accessories, Office',
            icon: Icons.category_outlined,
          ),
          const SizedBox(height: 8),

          // Category Quick-Select Chips
          Wrap(
            spacing: 6,
            runSpacing: 5,
            children:
                [
                  '+ Electronics',
                  '+ Accessories',
                  '+ Office',
                  '+ Peripherals',
                  '+ General',
                ].map((suggestion) {
                  final catName = suggestion.replaceAll('+', '').trim();
                  final isSelected =
                      _categoryController.text.trim().toLowerCase() ==
                      catName.toLowerCase();
                  return InkWell(
                    borderRadius: BorderRadius.circular(7),
                    onTap: () {
                      setState(() {
                        _categoryController.text = catName;
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3.5,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFF5B2EBC)
                            : const Color(0xFFF3EFFF),
                        borderRadius: BorderRadius.circular(7),
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFF5B2EBC)
                              : const Color(0xFFE5DCFD),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isSelected) ...[
                            const Icon(
                              Icons.check_rounded,
                              size: 11,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 3),
                          ],
                          Text(
                            suggestion,
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.bold,
                              color: isSelected
                                  ? Colors.white
                                  : const Color(0xFF5B2EBC),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, thickness: 0.9, color: Color(0xFFEAEAEE)),
          const SizedBox(height: 14),

          // Section 2 Header: Pricing & Stock Control
          _buildCardSectionHeader(
            icon: Icons.monetization_on_outlined,
            title: 'Pricing & Stock Level',
            badgeText: 'Live Sync',
            badgeBg: const Color(0xFFF3F2F8),
            badgeColor: const Color(0xFF6B687E),
          ),
          const SizedBox(height: 12),

          // Responsive Price and Quantity fields
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth >= 380) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _buildTextField(
                        fieldKey: const Key('product_price_field'),
                        controller: _priceController,
                        label: 'Price (\$)',
                        hint: 'e.g., 29.99',
                        icon: Icons.attach_money_rounded,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        validator: _validatePrice,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildTextField(
                        fieldKey: const Key('product_quantity_field'),
                        controller: _quantityController,
                        label: 'Quantity in Stock',
                        hint: 'e.g., 25',
                        icon: Icons.numbers_rounded,
                        keyboardType: TextInputType.number,
                        validator: _validateQuantity,
                      ),
                    ),
                  ],
                );
              } else {
                return Column(
                  children: [
                    _buildTextField(
                      fieldKey: const Key('product_price_field'),
                      controller: _priceController,
                      label: 'Price (\$)',
                      hint: 'e.g., 29.99',
                      icon: Icons.attach_money_rounded,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      validator: _validatePrice,
                    ),
                    const SizedBox(height: 12),
                    _buildTextField(
                      fieldKey: const Key('product_quantity_field'),
                      controller: _quantityController,
                      label: 'Quantity in Stock',
                      hint: 'e.g., 25',
                      icon: Icons.numbers_rounded,
                      keyboardType: TextInputType.number,
                      validator: _validateQuantity,
                    ),
                  ],
                );
              }
            },
          ),
          const SizedBox(height: 12),

          // Compact Live Catalog Preview Pill Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF9F9FC),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFEAEAEE), width: 1),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 2.5,
                    ),
                    decoration: BoxDecoration(
                      color: statusBg,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(statusIcon, size: 11, color: statusColor),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            statusLabel,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: statusColor,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Batch: ',
                      style: TextStyle(
                        fontSize: 11,
                        color: Color(0xFF6B687E),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      '\$${batchValuation.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF5B2EBC),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Reusable Card Section Header
  Widget _buildCardSectionHeader({
    required IconData icon,
    required String title,
    required String badgeText,
    required Color badgeBg,
    required Color badgeColor,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3EFFF),
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Icon(icon, size: 16, color: const Color(0xFF5B2EBC)),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF161324),
                    letterSpacing: -0.1,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
          decoration: BoxDecoration(
            color: badgeBg,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            badgeText,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: badgeColor,
            ),
          ),
        ),
      ],
    );
  }

  /// Consistent, accessible form field component.
  Widget _buildTextField({
    Key? fieldKey,
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: Color(0xFF38354D),
            letterSpacing: 0.1,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          key: fieldKey,
          controller: controller,
          keyboardType: keyboardType,
          validator: validator,
          style: const TextStyle(
            fontSize: 14.5,
            color: Color(0xFF161324),
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(
              fontSize: 13.5,
              color: Color(0xFFB5B3C2),
              fontWeight: FontWeight.normal,
            ),
            prefixIcon: Icon(icon, color: const Color(0xFF5B2EBC), size: 19),
            filled: true,
            fillColor: const Color(0xFFFAFAFD),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(11),
              borderSide: const BorderSide(color: Color(0xFFE5E5EB)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(11),
              borderSide: const BorderSide(color: Color(0xFFE5E5EB)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(11),
              borderSide: const BorderSide(
                color: Color(0xFF5B2EBC),
                width: 1.6,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(11),
              borderSide: const BorderSide(
                color: Color(0xFFD32F2F),
                width: 1.2,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(11),
              borderSide: const BorderSide(
                color: Color(0xFFD32F2F),
                width: 1.6,
              ),
            ),
            errorStyle: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Color(0xFFD32F2F),
            ),
          ),
        ),
      ],
    );
  }
}
