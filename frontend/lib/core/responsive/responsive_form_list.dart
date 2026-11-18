import 'package:flutter/material.dart';

class ResponsiveFormList extends StatelessWidget {
  final List<Widget> children;
  final double maxWidth;
  final EdgeInsetsGeometry padding;
  final ScrollController? controller;

  const ResponsiveFormList({
    super.key,
    required this.children,
    this.maxWidth = 620,
    this.padding = const EdgeInsets.all(20),
    this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;

        final horizontalOuterPadding = screenWidth >= 700 ? 24.0 : 0.0;

        return Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: maxWidth + horizontalOuterPadding * 2,
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: horizontalOuterPadding),
              child: ListView(
                controller: controller,
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: padding,
                children: children,
              ),
            ),
          ),
        );
      },
    );
  }
}
