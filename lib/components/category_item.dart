import 'package:flutter/material.dart';
import 'package:new_furniture_app_fixed/utils/app_theme.dart';
import 'package:new_furniture_app_fixed/models/category_model.dart';

class CategoryItem extends StatelessWidget {
  final String name;
  final String? imageUrl;
  final VoidCallback onTap;
  final bool isSelected;

  const CategoryItem({
    super.key,
    required this.name,
    this.imageUrl,
    required this.onTap,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color:
              isSelected
                  ? AppTheme.primaryColor
                  : AppTheme.accentColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(AppTheme.borderRadius_l),
        ),
        child: Text(
          name,
          style: AppTheme.bodySmall.copyWith(
            color: isSelected ? Colors.white : AppTheme.textSecondaryColor,
          ),
        ),
      ),
    );
  }
}
