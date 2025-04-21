import 'package:flutter/material.dart';

class CommonListTiles extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final EdgeInsetsGeometry? contentPadding;
  final EdgeInsetsGeometry? margin;
  final double? elevation;
  final TextStyle? titleStyle;
  final TextStyle? subtitleStyle;
  final ShapeBorder? shape;
  final double? tileHeight;
  final bool? dense;
  final bool? enabled;
  final Color? selectedColor;
  final bool? selected;

  const CommonListTiles({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.onTap,
    this.backgroundColor,
    this.contentPadding,
    this.margin,
    this.elevation,
    this.titleStyle,
    this.subtitleStyle,
    this.shape,
    this.tileHeight,
    this.dense,
    this.enabled,
    this.selectedColor,
    this.selected,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        side: BorderSide(
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
          width: 1,
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: SizedBox(
        height: tileHeight,
        child: ListTile(
          contentPadding: contentPadding ??
              const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: leading,
          title: Text(
            title,
            style: titleStyle ??
                const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
          ),
          subtitle: subtitle != null
              ? Text(
                  subtitle!,
                  style: subtitleStyle ??
                      const TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                )
              : null,
          trailing: trailing,
          onTap: onTap,
          dense: dense,
          enabled: enabled ?? true,
          selected: selected ?? false,
          selectedColor: selectedColor,
        ),
      ),
    );
  }
}
