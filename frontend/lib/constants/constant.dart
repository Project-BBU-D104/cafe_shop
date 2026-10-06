// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';

final MaterialColor primarySwatch = Colors.pink;
final Color appColor = Colors.pink;
final Color titleColor = Colors.white;

final MaterialColor primaryColor =
    createMaterialColor(HexColor.fromHex("#007bff"));
final MaterialColor secondaryColor =
    createMaterialColor(HexColor.fromHex("#f3f3f3"));
final MaterialColor successColor =
    createMaterialColor(HexColor.fromHex("#28a745"));
final MaterialColor dangerColor =
    createMaterialColor(HexColor.fromHex("#CA0B00"));
final MaterialColor warningColor =
    createMaterialColor(HexColor.fromHex("#ffc107"));
final MaterialColor infoColor =
    createMaterialColor(HexColor.fromHex("#17a2b8"));
final MaterialColor lightColor =
    createMaterialColor(HexColor.fromHex("#f5f5f5"));
final MaterialColor darkColor =
    createMaterialColor(HexColor.fromHex("#000000"));

final MaterialColor whiteColor =
    createMaterialColor(HexColor.fromHex("#ffffff"));

final MaterialColor mutedColor =
    createMaterialColor(HexColor.fromHex("#6c757d"));

final Color placeholderColor = Colors.grey.shade300;
final Color bgOpacity = primarySwatch.shade100.withAlpha(100);
final Color bgBorderColor = primarySwatch.shade100;
final Border bgBorder = Border.all(
  width: 0.5,
  color: bgBorderColor,
);

Color primaryColorLight(BuildContext context) {
  return Theme.of(context).colorScheme.primary;
}

Color textColor(BuildContext context) {
  return Theme.of(context).colorScheme.onSurface;
}

Color subtitleColor(BuildContext context) {
  return Theme.of(context).hintColor;
}

Color backgroundColor(BuildContext context) {
  return Theme.of(context).scaffoldBackgroundColor;
}

Color iconColor(BuildContext context) {
  return Theme.of(context).iconTheme.color!;
}

final Color skeletonizerContainerColor = Colors.grey.shade300;

final double circularRadius = 8.0;
final EdgeInsets padding = EdgeInsets.all(8.0);
final EdgeInsets margin = EdgeInsets.all(8.0);
final String backgroundPath = "assets/images/background.png";
final String bannerPath = "assets/images/banner.jpg";
final String logoNoBackgroundPath = "assets/images/logo_no_background.png";
final String emptyPath = "assets/images/empty.png";
final String langEnPath = "assets/images/lang_en.png";
final String langKmPath = "assets/images/lang_km.png";

///get material hexcolor
MaterialColor createMaterialColor(Color color) {
  List<double> strengths = <double>[.05];
  final swatch = <int, Color>{};
  final int r = color.red, g = color.green, b = color.blue;
  for (int i = 1; i < 10; i++) {
    strengths.add(0.1 * i);
  }

  for (var strength in strengths) {
    final double ds = 0.5 - strength;
    swatch[(strength * 1000).round()] = Color.fromRGBO(
      r + ((ds < 0 ? r : (255 - r)) * ds).round(),
      g + ((ds < 0 ? g : (255 - g)) * ds).round(),
      b + ((ds < 0 ? b : (255 - b)) * ds).round(),
      1,
    );
  }

  return MaterialColor(color.value, swatch);
}

/// get hex color
extension HexColor on Color {
  static Color fromHex(String? hexString) {
    if ((hexString ?? "") != "") {
      try {
        final buffer = StringBuffer();
        if (hexString?.length == 6 || hexString?.length == 7) {
          buffer.write('ff');
        }
        buffer.write(hexString?.replaceFirst('#', ''));
        return Color(int.parse(buffer.toString(), radix: 16));
      } on Exception catch (_) {
        return Colors.transparent;
      }
    } else {
      return Colors.transparent;
    }
  }

  String toHex({bool leadingHashSign = true}) => '${leadingHashSign ? '#' : ''}'
      '${alpha.toRadixString(16).padLeft(2, '0')}'
      '${red.toRadixString(16).padLeft(2, '0')}'
      '${green.toRadixString(16).padLeft(2, '0')}'
      '${blue.toRadixString(16).padLeft(2, '0')}';
}
