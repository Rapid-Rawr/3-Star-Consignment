import 'package:flutter/material.dart';

import '../utils/app_colors.dart';

/// Stepper Signature 3-Star Consignment.
///
/// - [quantity]    : Nilai Kuantitas
/// - [maxQuantity] : Batas Atas Kuantitas (null = tanpa batas)
/// - [onDecrement] : Dipanggil saat tombol − ditekan
/// - [onIncrement] : Dipanggil saat tombol + ditekan
/// - [onChanged]   : Dipanggil saat user mengetik nilai secara langsung
class QuantityStepper extends StatefulWidget {
  final int quantity;
  final int? maxQuantity;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;
  final ValueChanged<int>? onChanged;

  const QuantityStepper({
    super.key,
    required this.quantity,
    this.maxQuantity,
    required this.onDecrement,
    required this.onIncrement,
    this.onChanged,
  });

  @override
  State<QuantityStepper> createState() => _QuantityStepperState();
}

class _QuantityStepperState extends State<QuantityStepper> {
  late TextEditingController _ctrl;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.quantity.toString());
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus) _handleSubmitted(_ctrl.text);
    });
  }

  @override
  void didUpdateWidget(covariant QuantityStepper old) {
    super.didUpdateWidget(old);
    if (old.quantity != widget.quantity &&
        _ctrl.text != widget.quantity.toString()) {
      _ctrl.text = widget.quantity.toString();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _handleSubmitted(String val) {
    final qty = int.tryParse(val);
    if (qty != null && qty > 0) {
      final clamped = widget.maxQuantity != null
          ? qty.clamp(1, widget.maxQuantity!)
          : qty;
      widget.onChanged?.call(clamped);
    } else {
      _ctrl.text = widget.quantity.toString();
    }
  }

  bool get _isAtMax =>
      widget.maxQuantity != null && widget.quantity >= widget.maxQuantity!;

  @override
  Widget build(BuildContext context) {
    final Color iconColor = context.isDark
        ? const Color(0xFF80CBC4)
        : const Color(0xFF2E7D32);

    return Container(
      height: 32,
      decoration: BoxDecoration(
        color: context.isDark
            ? const Color(0xFF1A3A2A)
            : const Color(0xFFE6F4EA),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Decrement / Delete button
          InkWell(
            onTap: widget.onDecrement,
            borderRadius: const BorderRadius.horizontal(
              left: Radius.circular(20),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Icon(
                widget.quantity <= 1 ? Icons.delete_outline : Icons.remove,
                size: 18,
                color: widget.quantity <= 1 ? Colors.red.shade400 : iconColor,
              ),
            ),
          ),
          // Direct text input
          SizedBox(
            width: 36,
            child: TextField(
              controller: _ctrl,
              focusNode: _focusNode,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: context.isDark ? Colors.white : const Color(0xFF1D1B20),
              ),
              decoration: const InputDecoration(
                isDense: true,
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
              onSubmitted: _handleSubmitted,
              onTapOutside: (_) => _focusNode.unfocus(),
            ),
          ),
          // Increment button
          InkWell(
            onTap: _isAtMax ? null : widget.onIncrement,
            borderRadius: const BorderRadius.horizontal(
              right: Radius.circular(20),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Icon(
                Icons.add,
                size: 18,
                color: _isAtMax ? iconColor.withValues(alpha: 0.3) : iconColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
