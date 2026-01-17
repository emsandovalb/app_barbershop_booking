import 'package:flutter/material.dart';
import '../theme/colors.dart';

class PaginationBar extends StatelessWidget {
  final int current;
  final int last;
  final ValueChanged<int> onSelect;
  const PaginationBar({super.key, required this.current, required this.last, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    if (last <= 1) return const SizedBox.shrink();
    final items = _buildItems(current, last);
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        _arrowButton(Icons.chevron_left, current > 1 ? () => onSelect(current - 1) : null),
        const SizedBox(width: 8),
        ...items.map((item) {
          if (item is String) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(item, style: const TextStyle(color: Colors.white70)),
            );
          }
          final isActive = item == current;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => onSelect(item as int),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: isActive ? AppColors.primary.withOpacity(.2) : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$item',
                  style: TextStyle(
                    color: isActive ? AppColors.primary : Colors.white,
                    fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
            ),
          );
        }),
        const SizedBox(width: 8),
        _arrowButton(Icons.chevron_right, current < last ? () => onSelect(current + 1) : null),
      ],
    );
  }

  Widget _arrowButton(IconData icon, VoidCallback? onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: Colors.transparent,
          border: Border.all(color: Colors.white24),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: onTap == null ? Colors.white30 : Colors.white, size: 20),
      ),
    );
  }

  List<dynamic> _buildItems(int current, int last) {
    if (last <= 5) {
      return List<int>.generate(last, (index) => index + 1);
    }
    final items = <dynamic>[1];
    void add(int value) {
      if (value > 1 && value < last && !items.contains(value)) {
        items.add(value);
      }
    }
    if (current > 3) items.add('...');
    for (var page = current - 1; page <= current + 1; page++) {
      add(page);
    }
    if (current < last - 2) items.add('...');
    items.add(last);
    return items;
  }
}
