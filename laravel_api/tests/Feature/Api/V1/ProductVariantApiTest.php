<?php

namespace Tests\Feature\Api\V1;

use App\Enums\UserRole;
use App\Models\Category;
use App\Models\Product;
use App\Models\ProductVariant;
use App\Models\Shop;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class ProductVariantApiTest extends TestCase
{
    use RefreshDatabase;

    private Shop $shop;

    protected function setUp(): void
    {
        parent::setUp();

        $this->shop = Shop::create(['name' => 'Coffee Shop', 'code' => 'MAIN']);

        Sanctum::actingAs(User::create([
            'shop_id' => $this->shop->id,
            'name' => 'Shop User',
            'email' => 'user@example.com',
            'password' => 'password',
            'role' => UserRole::Admin,
            'is_active' => true,
        ]));
    }

    public function test_index_lists_variants_for_a_product(): void
    {
        $product = $this->createProduct();
        ProductVariant::create(['product_id' => $product->id, 'name' => 'Regular', 'price' => '3.50']);
        ProductVariant::create(['product_id' => $product->id, 'name' => 'Large', 'price' => '4.50']);

        $this->getJson("/api/v1/products/{$product->id}/variants")
            ->assertOk()
            ->assertJsonCount(2, 'data')
            ->assertJsonFragment(['name' => 'Regular'])
            ->assertJsonFragment(['name' => 'Large']);
    }

    public function test_store_creates_a_variant(): void
    {
        $product = $this->createProduct();

        $this->postJson("/api/v1/products/{$product->id}/variants", [
            'name' => 'Large',
            'price' => '4.50',
            'is_default' => false,
            'is_available' => true,
        ])
            ->assertCreated()
            ->assertJsonPath('data.product_id', $product->id)
            ->assertJsonPath('data.price', '4.50');

        $this->assertDatabaseHas('product_variants', [
            'product_id' => $product->id,
            'name' => 'Large',
            'price' => '4.50',
        ]);
    }

    public function test_store_rejects_duplicate_variant_name_for_the_same_product(): void
    {
        $product = $this->createProduct();
        ProductVariant::create(['product_id' => $product->id, 'name' => 'Regular', 'price' => '3.50']);

        $this->postJson("/api/v1/products/{$product->id}/variants", [
            'name' => 'Regular',
            'price' => '4.50',
        ])->assertUnprocessable();
    }

    public function test_update_and_delete_variant(): void
    {
        $product = $this->createProduct();
        $variant = ProductVariant::create(['product_id' => $product->id, 'name' => 'Regular', 'price' => '3.50']);

        $this->putJson("/api/v1/products/{$product->id}/variants/{$variant->id}", [
            'name' => 'Large',
            'price' => '4.50',
        ])->assertOk()->assertJsonPath('data.name', 'Large');

        $this->deleteJson("/api/v1/products/{$product->id}/variants/{$variant->id}")
            ->assertNoContent();

        $this->assertDatabaseMissing('product_variants', ['id' => $variant->id]);
    }

    public function test_variant_from_another_shop_is_not_accessible(): void
    {
        $otherShop = Shop::create(['name' => 'Second Shop', 'code' => 'SECOND']);
        $otherCategory = Category::create(['shop_id' => $otherShop->id, 'name' => 'Drinks']);
        $otherProduct = Product::create([
            'shop_id' => $otherShop->id,
            'category_id' => $otherCategory->id,
            'name' => 'Other Product',
        ]);
        $variant = ProductVariant::create([
            'product_id' => $otherProduct->id,
            'name' => 'Regular',
            'price' => '3.50',
        ]);

        $this->getJson("/api/v1/products/{$otherProduct->id}/variants")->assertNotFound();
        $this->getJson("/api/v1/products/{$otherProduct->id}/variants/{$variant->id}")->assertNotFound();
    }

    public function test_all_variant_routes_require_authentication(): void
    {
        $this->app['auth']->forgetGuards();
        $product = $this->createProduct();

        $this->getJson("/api/v1/products/{$product->id}/variants")->assertUnauthorized();
        $this->postJson("/api/v1/products/{$product->id}/variants", [])->assertUnauthorized();
    }

    private function createProduct(): Product
    {
        $category = Category::create(['shop_id' => $this->shop->id, 'name' => 'Drinks']);

        return Product::create([
            'shop_id' => $this->shop->id,
            'category_id' => $category->id,
            'name' => 'Latte',
        ]);
    }
}
