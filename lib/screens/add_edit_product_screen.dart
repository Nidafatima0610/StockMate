import 'package:flutter/material.dart';

import '../models/product.dart';

/// Screen for adding a new product or editing an existing product.
///
/// Designed to match the StockMate premium purple dashboard visual identity.
/// In Week 1 Day 1, form inputs and navigation are interactive while persistence
/// will be connected in subsequent milestones.
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
  }

  @override
  void dispose() {
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
    // Validate all form fields; if invalid, activate inline validation feedback
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

    // Create or update the product model with a clean, readable ID
    final idSuffix = name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
    final cleanId = idSuffix.length > 8 ? idSuffix.substring(0, 8) : idSuffix;
    final product = Product(
      id: widget.product?.id ?? 'prod-$cleanId',
      name: name,
      price: price,
      quantity: quantity,
      category: category,
    );

    // Return the new/updated product back to the inventory screen
    Navigator.pop(context, product);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7FC),
      appBar: AppBar(
        titleSpacing: 0,
        leading: IconButton(
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
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 16.0),
          child: Form(
            key: _formKey,
            autovalidateMode: _autovalidateMode,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Contextual Hero Banner
                _buildHeroBanner(),
                const SizedBox(height: 18),

                // Form card container
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF161324).withValues(alpha: 0.04),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                    border: Border.all(
                      color: const Color(0xFFEAEAEE),
                      width: 1.2,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Expanded(
                            child: Row(
                              children: [
                                Icon(
                                  Icons.feed_outlined,
                                  size: 18,
                                  color: Color(0xFF5B2EBC),
                                ),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Product Information',
                                    style: TextStyle(
                                      fontSize: 15.5,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF161324),
                                      letterSpacing: -0.2,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF3F2F8),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'Catalog Details',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF6B687E),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),

                      // Product Name field
                      _buildTextField(
                        fieldKey: const Key('product_name_field'),
                        controller: _nameController,
                        label: 'Product Name',
                        hint: 'e.g., Wireless Ergonomic Mouse',
                        icon: Icons.inventory_2_outlined,
                        validator: _validateName,
                      ),
                      const SizedBox(height: 16),

                      // Category field (Optional)
                      _buildTextField(
                        fieldKey: const Key('product_category_field'),
                        controller: _categoryController,
                        label: 'Category',
                        hint: 'e.g., Electronics, Accessories, Office',
                        icon: Icons.category_outlined,
                      ),
                      const SizedBox(height: 16),

                      // Price field
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
                      const SizedBox(height: 16),

                      // Quantity field
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
                  ),
                ),
                const SizedBox(height: 16),

                // Compact, attractive low-stock rule informational panel
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 13,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3EFFF),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: const Color(0xFFE5DCFD),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.shield_outlined,
                          color: Color(0xFF5B2EBC),
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Automatic Stock Tracking Rule',
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF5B2EBC),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Quantities ≤ ${widget.lowStockThreshold} display an amber Low Stock badge. Products with 0 units display a red Out of Stock badge.',
                              style: const TextStyle(
                                fontSize: 11.5,
                                color: Color(0xFF5B5875),
                                height: 1.35,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),

                // Primary Save / Update button
                ElevatedButton(
                  key: const Key('save_product_button'),
                  onPressed: _handleSave,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5B2EBC),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(13),
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
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _isEditing ? 'Update Product' : 'Save Product',
                        style: const TextStyle(
                          fontSize: 15.5,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 0.1,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                // Secondary Cancel button
                OutlinedButton(
                  key: const Key('cancel_product_button'),
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF5B2EBC),
                    side: const BorderSide(
                      color: Color(0xFFD4C8FA),
                      width: 1.2,
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(13),
                    ),
                  ),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(
                      fontSize: 14.5,
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
    );
  }

  /// Informational hero banner distinguishing Add vs Edit workflows.
  Widget _buildHeroBanner() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEAEAEE), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF161324).withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFF3EFFF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              _isEditing ? Icons.edit_note_rounded : Icons.add_business_rounded,
              color: const Color(0xFF5B2EBC),
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isEditing ? 'Update Inventory Item' : 'New Inventory Item',
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF161324),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _isEditing
                      ? 'Modify product specifications, pricing, and recorded stock counts.'
                      : 'Register a new item into your small business inventory catalog.',
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: Color(0xFF6B687E),
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
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
