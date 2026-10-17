import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/controllers/product_variant_controller.dart';
import 'package:get/get.dart';

void main() {
  setUpAll(() {
    // ApiService reads API_URL from dotenv at construction time.
    dotenv.testLoad(fileInput: 'API_URL=http://127.0.0.1:8000/api/v1');
  });

  test('onSearchVariant filters by name and shows all variants when cleared', () {
    final ctr = ProductVariantController();

    ctr.variantsList.assignAll([
      {'name': 'Regular'},
      {'name': 'Large Iced Latte'},
      {'name': 'Espresso'},
    ]);

    ctr.onSearchVariant('latte');
    expect(
      ctr.searchVariantList.map((v) => v['name']).toList(),
      ['Large Iced Latte'],
    );

    ctr.onSearchVariant('  ');
    expect(ctr.searchVariantList.length, 3);
  });
}
