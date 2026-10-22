import 'package:flutter/material.dart';

const String categoryManagementFontFamily = 'NotoSansKhmer';

class CategoryManagementTheme extends StatelessWidget {
  const CategoryManagementTheme({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme.apply(
      fontFamily: categoryManagementFontFamily,
    );
    final primaryTextTheme = theme.primaryTextTheme.apply(
      fontFamily: categoryManagementFontFamily,
    );

    return Theme(
      data: theme.copyWith(
        textTheme: textTheme,
        primaryTextTheme: primaryTextTheme,
      ),
      child: child,
    );
  }
}
