import 'package:flutter/material.dart';

/// Model untuk satu filter chip
class FilterChipOption<T> {
  final String label;
  final T? value; // null = "All"

  const FilterChipOption({required this.label, required this.value});
}

/// Widget reusable: search bar + horizontal filter chips dengan gradient selected
///
/// Contoh penggunaan:
/// ```dart
/// SearchFilterBar<String>(
///   searchController: _searchController,
///   searchFocusNode: _searchFocusNode,
///   hintText: 'Cari...',
///   onSearchChanged: (q) => setState(() => controller.setSearchQuery(q)),
///   filters: const [
///     FilterChipOption(label: 'All', value: null),
///     FilterChipOption(label: 'Manager', value: 'Manager'),
///   ],
///   selectedFilter: controller.selectedRoleFilter,
///   onFilterSelected: (val) => setState(() => controller.setRoleFilter(val)),
/// )
/// ```
class SearchFilterBar<T> extends StatelessWidget {
  final TextEditingController searchController;
  final FocusNode searchFocusNode;
  final String hintText;
  final ValueChanged<String> onSearchChanged;
  final List<FilterChipOption<T>> filters;
  final T? selectedFilter;
  final ValueChanged<T?> onFilterSelected;

  const SearchFilterBar({
    super.key,
    required this.searchController,
    required this.searchFocusNode,
    required this.hintText,
    required this.onSearchChanged,
    required this.filters,
    required this.selectedFilter,
    required this.onFilterSelected,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    final Color fillColor = isDark
        ? const Color(0xFF2C2A30)
        : const Color(0xFFF5F5F5);
    final Color filterIconColor = isDark
        ? Colors.white60
        : const Color(0xFF49454F);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: TextField(
            controller: searchController,
            focusNode: searchFocusNode,
            decoration: InputDecoration(
              hintText: hintText,
              prefixIcon: const Icon(Icons.search),
              suffixIcon: searchController.text.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        searchController.clear();
                        onSearchChanged('');
                      },
                    ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              filled: true,
              fillColor: fillColor,
            ),
            onChanged: onSearchChanged,
          ),
        ),
        if (filters.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Row(
              children: [
                Icon(Icons.filter_list, size: 20, color: filterIconColor),
                const SizedBox(width: 8),
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: filters.map((chip) {
                        final isSelected = selectedFilter == chip.value;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: _AppFilterChip(
                            label: chip.label,
                            isSelected: isSelected,
                            isDark: isDark,
                            onTap: () => onFilterSelected(
                              isSelected ? null : chip.value,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _AppFilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final bool isDark;
  final VoidCallback onTap;

  const _AppFilterChip({
    required this.label,
    required this.isSelected,
    required this.isDark,
    required this.onTap,
  });

  static const List<Color> _lightGradient = [
    Color(0xFF67636D),
    Color(0xFF1D1B20),
  ];
  static const List<Color> _darkGradient = [
    Color(0xFFA3A3A3),
    Color(0xFFFFFFFF),
  ];

  @override
  Widget build(BuildContext context) {
    if (isSelected) {
      final gradient = isDark ? _darkGradient : _lightGradient;
      final textColor = isDark ? const Color(0xFF1D1B20) : Colors.white;

      return Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomLeft,
                end: Alignment.topRight,
                colors: gradient,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check, size: 16, color: textColor),
                const SizedBox(width: 4),
                Text(
                  label,
                  style: TextStyle(
                    color: textColor,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final unselectedColor = isDark ? Colors.white70 : const Color(0xFF49454F);
    final unselectedBg = isDark
        ? const Color(0xFF2C2A30)
        : const Color(0xFFECECEC);

    return Material(
      color: unselectedBg,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          child: Text(
            label,
            style: TextStyle(
              color: unselectedColor,
              fontFamily: 'Poppins',
              fontWeight: FontWeight.normal,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }
}
