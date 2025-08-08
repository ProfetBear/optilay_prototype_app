import 'package:flutter/material.dart';
import 'package:optilay_prototype_app/utils/constants/sizes.dart';

class OptionCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final VoidCallback onTap;
  final Color color;

  const OptionCard({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
    required this.onTap,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      splashColor: color.withOpacity(0.2),
      borderRadius: BorderRadius.circular(MySizes.borderRadiusMd),
      child: Container(
        padding: const EdgeInsets.all(MySizes.padding),
        decoration: BoxDecoration(
          border: Border.all(color: color.withOpacity(0.4)),
          borderRadius: BorderRadius.circular(MySizes.padding),
          color: Theme.of(context).cardColor,
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 6,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: color.withOpacity(0.1),
              child: Icon(icon, color: color, size: MySizes.iconLg),
              radius: 28,
            ),
            const SizedBox(width: MySizes.spacing),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: MySizes.fontSizeLg,
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: MySizes.md),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: MySizes.fontSizeMd,
                      color: Theme.of(context).textTheme.bodySmall?.color,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
