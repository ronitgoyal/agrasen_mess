import 'package:flutter/material.dart';

class AppBreakpoints {
  AppBreakpoints._();

  static const double mobile = 600;
  static const double tablet = 900;
  static const double large = 1200;
}

class ResponsiveLayout {
  ResponsiveLayout._();

  static bool isMobile(BuildContext context) {
    return MediaQuery.sizeOf(context).width < AppBreakpoints.mobile;
  }

  static bool isTablet(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;

    return width >= AppBreakpoints.mobile && width < AppBreakpoints.tablet;
  }

  static bool isLargeScreen(BuildContext context) {
    return MediaQuery.sizeOf(context).width >= AppBreakpoints.tablet;
  }

  static int gridColumns(
    double width, {
    int mobile = 2,
    int tablet = 3,
    int large = 4,
  }) {
    if (width >= AppBreakpoints.tablet) {
      return large;
    }

    if (width >= AppBreakpoints.mobile) {
      return tablet;
    }

    return mobile;
  }

  static double horizontalPadding(double width) {
    if (width >= AppBreakpoints.large) {
      return 32;
    }

    if (width >= AppBreakpoints.mobile) {
      return 24;
    }

    return 16;
  }
}

class ResponsiveContent extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  final EdgeInsetsGeometry? padding;
  final Alignment alignment;

  const ResponsiveContent({
    super.key,
    required this.child,
    this.maxWidth = 1100,
    this.padding,
    this.alignment = Alignment.topCenter,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;

    final defaultPadding = ResponsiveLayout.horizontalPadding(width);

    return Align(
      alignment: alignment,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(
          padding: padding ?? EdgeInsets.symmetric(horizontal: defaultPadding),
          child: child,
        ),
      ),
    );
  }
}

class ResponsiveGrid extends StatelessWidget {
  final List<Widget> children;
  final int mobileColumns;
  final int tabletColumns;
  final int largeColumns;
  final double spacing;
  final double mobileAspectRatio;
  final double tabletAspectRatio;
  final double largeAspectRatio;

  const ResponsiveGrid({
    super.key,
    required this.children,
    this.mobileColumns = 2,
    this.tabletColumns = 3,
    this.largeColumns = 4,
    this.spacing = 14,
    this.mobileAspectRatio = 1.05,
    this.tabletAspectRatio = 1.15,
    this.largeAspectRatio = 1.2,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        final columns = ResponsiveLayout.gridColumns(
          width,
          mobile: mobileColumns,
          tablet: tabletColumns,
          large: largeColumns,
        );

        final aspectRatio = width >= AppBreakpoints.tablet
            ? largeAspectRatio
            : width >= AppBreakpoints.mobile
            ? tabletAspectRatio
            : mobileAspectRatio;

        return GridView.count(
          crossAxisCount: columns,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: spacing,
          mainAxisSpacing: spacing,
          childAspectRatio: aspectRatio,
          children: children,
        );
      },
    );
  }
}
