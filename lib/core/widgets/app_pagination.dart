import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class AppPagination extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final ValueChanged<int> onPageChange;

  const AppPagination({
    super.key,
    required this.currentPage,
    required this.totalPages,
    required this.onPageChange,
  });

  @override
  Widget build(BuildContext context) {
    if (totalPages <= 1) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Botón Anterior
          IconButton(
            onPressed: currentPage > 1 ? () => onPageChange(currentPage - 1) : null,
            icon: const Icon(Icons.chevron_left_rounded),
            color: Colors.white,
            disabledColor: const Color(0xFF3F3F46),
            style: IconButton.styleFrom(
              backgroundColor: const Color(0xFF1E1609),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: const BorderSide(color: Color(0xFF382510)),
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Números de Página
          Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(totalPages, (index) {
              final pageNumber = index + 1;
              final isActive = pageNumber == currentPage;

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: InkWell(
                  onTap: () => onPageChange(pageNumber),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: isActive ? AppColors.primary : const Color(0xFF1E1609),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isActive ? AppColors.primary : const Color(0xFF382510),
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '$pageNumber',
                      style: TextStyle(
                        color: isActive ? Colors.white : const Color(0xFFA1A1AA),
                        fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(width: 8),

          // Botón Siguiente
          IconButton(
            onPressed: currentPage < totalPages ? () => onPageChange(currentPage + 1) : null,
            icon: const Icon(Icons.chevron_right_rounded),
            color: Colors.white,
            disabledColor: const Color(0xFF3F3F46),
            style: IconButton.styleFrom(
              backgroundColor: const Color(0xFF1E1609),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: const BorderSide(color: Color(0xFF382510)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}