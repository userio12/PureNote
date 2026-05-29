import 'package:flutter/material.dart';
import 'package:purenote/core/database/database.dart';

class LabelChip extends StatelessWidget {
  final Label label;
  final bool selected;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const LabelChip({
    super.key,
    required this.label,
    this.selected = false,
    this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final chipColor = label.color != null ? Color(label.color!) : null;
    return InputChip(
      label: Text(label.name),
      selected: selected,
      onPressed: onTap,
      onDeleted: onDelete,
      deleteIconColor: chipColor?.withValues(alpha: 0.7),
      selectedColor: chipColor?.withValues(alpha: 0.2),
      side: chipColor != null ? BorderSide(color: chipColor.withValues(alpha: 0.5)) : null,
    );
  }
}
