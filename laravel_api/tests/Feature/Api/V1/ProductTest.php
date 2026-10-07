<?php

namespace Tests\Feature\Api\V1;

use App\Enums\UserRole;
use App\Models\Category;
use App\Models\Product;
use App\Models\Shop;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class ProductTest extends TestCase
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

    public function test_all_product_routes_require_authentication(): void
    {
        $this->app['auth']->forgetGuards();

        $this->getJson('/api/v1/products')->assertUnauthorized();
        $this->postJson('/api/v1/products', ['name' => 'Latte'])->assertUnauthorized();
        $this->getJson('/api/v1/products/1')->assertUnauthorized();
        $this->putJson('/api/v1/products/1', ['name' => 'Latte'])->assertUnauthorized();
        $this->deleteJson('/api/v1/products/1')->assertUnauthorized();
    }

    public function test_store_assigns_the_authenticated_users_shop(): void
    {
        $category = Category::create(['shop_id' => $this->shop->id, 'name' => 'Drinks']);

        $this->postJson('/api/v1/products', ['category_id' => $category->id, 'name' => 'Latte'])
            ->assertCreated();

        $this->assertDatabaseHas('products', ['name' => 'Latte', 'shop_id' => $this->shop->id]);
    }

    public function test_duplicate_name_is_rejected_but_reusable_after_delete(): void
    {
        $category = Category::create(['shop_id' => $this->shop->id, 'name' => 'Drinks']);

        $this->postJson('/api/v1/products', ['category_id' => $category->id, 'name' => 'Latte'])->assertCreated();
        $this->postJson('/api/v1/products', ['category_id' => $category->id, 'name' => 'Latte'])->assertUnprocessable();

        $id = Product::query()->where('name', 'Latte')->value('id');
        $this->deleteJson("/api/v1/products/{$id}")->assertNoContent();

        $this->postJson('/api/v1/products', ['category_id' => $category->id, 'name' => 'Latte'])->assertCreated();
    }

    public function test_index_filters_unavailable_and_other_shops_products(): void
    {
        $otherShop = Shop::create(['name' => 'Second Shop', 'code' => 'SECOND']);
        $category = Category::create(['shop_id' => $this->shop->id, 'name' => 'Drinks']);
        $otherCategory = Category::create(['shop_id' => $otherShop->id, 'name' => 'Other Drinks']);

        Product::create(['shop_id' => $this->shop->id, 'category_id' => $category->id, 'name' => 'Available', 'is_available' => true]);
        Product::create(['shop_id' => $this->shop->id, 'category_id' => $category->id, 'name' => 'Unavailable', 'is_available' => false]);
        Product::create(['shop_id' => $otherShop->id, 'category_id' => $otherCategory->id, 'name' => 'Other shop product']);

        $this->getJson('/api/v1/products')
            ->assertOk()
            ->assertJsonCount(1, 'data')
            ->assertJsonPath('data.0.name', 'Available');

        $this->getJson('/api/v1/products?include_unavailable=1')
            ->assertOk()
            ->assertJsonCount(2, 'data');
    }

    public function test_show_returns_404_for_missing_or_other_shop_product(): void
    {
        $otherShop = Shop::create(['name' => 'Second Shop', 'code' => 'SECOND']);
        $otherCategory = Category::create(['shop_id' => $otherShop->id, 'name' => 'Other Drinks']);
        $product = Product::create(['shop_id' => $otherShop->id, 'category_id' => $otherCategory->id, 'name' => 'Other shop product']);

        $this->getJson('/api/v1/products/999')->assertNotFound();
        $this->getJson("/api/v1/products/{$product->id}")->assertNotFound();
    }

    public function test_user_cannot_update_or_delete_another_shops_product(): void
    {
        $otherShop = Shop::create(['name' => 'Second Shop', 'code' => 'SECOND']);
        $otherCategory = Category::create(['shop_id' => $otherShop->id, 'name' => 'Other Drinks']);
        $product = Product::create(['shop_id' => $otherShop->id, 'category_id' => $otherCategory->id, 'name' => 'Other shop product']);

        $this->putJson("/api/v1/products/{$product->id}", ['name' => 'Changed'])->assertNotFound();
        $this->deleteJson("/api/v1/products/{$product->id}")->assertNotFound();

        $this->assertDatabaseHas('products', ['id' => $product->id, 'name' => 'Other shop product']);
    }

    public function test_update_rejects_name_taken_in_same_shop_and_category(): void
    {
        $category = Category::create(['shop_id' => $this->shop->id, 'name' => 'Drinks']);
        Product::create(['shop_id' => $this->shop->id, 'category_id' => $category->id, 'name' => 'Espresso']);
        $product = Product::create(['shop_id' => $this->shop->id, 'category_id' => $category->id, 'name' => 'Mocha']);

        $this->putJson("/api/v1/products/{$product->id}", ['name' => 'Espresso'])->assertUnprocessable();

        $this->putJson("/api/v1/products/{$product->id}", ['name' => 'Mocha Frappuccino'])
            ->assertOk()
            ->assertJsonPath('data.name', 'Mocha Frappuccino');
    }
}
