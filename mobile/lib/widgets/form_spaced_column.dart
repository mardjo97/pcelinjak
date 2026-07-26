import 'package:flutter/material.dart';

/// Vertikalni razmak između outline polja (labela inače „ulazi” u susedno polje).
const kFormFieldGap = 20.0;

/// Kolona sa ujednačenim razmakom između polja — za dijaloge i forme.
class FormSpacedColumn extends StatelessWidget {
  const FormSpacedColumn({
    super.key,
    required this.children,
    this.gap = kFormFieldGap,
    this.crossAxisAlignment = CrossAxisAlignment.stretch,
  });

  final List<Widget> children;
  final double gap;
  final CrossAxisAlignment crossAxisAlignment;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: crossAxisAlignment,
      children: [
        for (var i = 0; i < children.length; i++) ...[
          if (i > 0) SizedBox(height: gap),
          children[i],
        ],
      ],
    );
  }
}
