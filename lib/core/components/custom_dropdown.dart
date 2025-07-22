import 'package:flutter/material.dart';
import 'spaces.dart';

class CustomDropdown<T> extends StatelessWidget {
  final T? value;
  final List<T> items;
  final String label;
  final Function(T? value)? onChanged;
  final String Function(T item)? itemToString;

  const CustomDropdown({
    super.key,
    required this.value,
    required this.items,
    required this.label,
    this.onChanged,
    this.itemToString,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SpaceHeight(12.0),
        DropdownButtonFormField<T>(
          value: value,
          onChanged: onChanged,
          items: items
              .map((T item) => DropdownMenuItem<T>(
                    value: item,
                    child: Text(
                        itemToString != null ? itemToString!(item) : item.toString()),
                  ))
              .toList()
              // Ensure unique values
              .where((item) => item.value != null)
              .toSet()
              .toList(),
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16.0),
              borderSide: const BorderSide(color: Colors.grey),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16.0),
              borderSide: const BorderSide(color: Colors.grey),
            ),
          ),
          validator: (value) => value == null ? 'Pilih $label' : null,
        ),
      ],
    );
  }
}