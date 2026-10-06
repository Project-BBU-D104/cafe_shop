<?php

namespace Tests\Feature\Api\V1;

use App\Enums\UserRole;
use App\Models\Category;
use App\Models\Shop;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class CategoryTest extends TestCase
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

    public function test_all_category_routes_require_authentication(): void
    {
        $this->app['auth']->forgetGuards();

        $this->getJson('/api/v1/categories')->assertUnauthorized();
        $this->postJson('/api/v1/categories', ['name' => 'Latte Art'])->assertUnauthorized();
        $this->getJson('/api/v1/categories/1')->assertUnauthorized();
        $this->putJson('/api/v1/categories/1', ['name' => 'Latte'])->assertUnauthorized();
        $this->deleteJson('/api/v1/categories/1')->assertUnauthorized();
    }

    public function test_store_assigns_the_authenticated_users_shop(): void
    {
        $this->postJson('/api/v1/categories', ['name' => 'Latte Art'])->assertCreated();

        $this->assertDatabaseHas('categories', ['name' => 'Latte Art', 'shop_id' => $this->shop->id]);
    }

    public function test_duplicate_name_is_rejected_but_reusable_after_delete(): void
    {
        $this->postJson('/api/v1/categories', ['name' => 'Latte Art'])->assertCreated();
        $this->postJson('/api/v1/categories', ['name' => 'Latte Art'])->assertUnprocessable();

        $id = Category::query()->where('name', 'Latte Art')->value('id');
        $this->deleteJson("/api/v1/categories/{$id}")->assertNoContent();

        $this->postJson('/api/v1/categories', ['name' => 'Latte Art'])->assertCreated();
    }

    public function test_index_filters_inactive_and_other_shops_categories(): void
    {
        $otherShop = Shop::create(['name' => 'Second Shop', 'code' => 'SECOND']);
        Category::create(['shop_id' => $this->shop->id, 'name' => 'Active', 'is_active' => true]);
        Category::create(['shop_id' => $this->shop->id, 'name' => 'Hidden', 'is_active' => false]);
        Category::create(['shop_id' => $otherShop->id, 'name' => 'Other shop category']);

        $this->getJson('/api/v1/categories')
            ->assertOk()
            ->assertJsonCount(1, 'data')
            ->assertJsonPath('data.0.name', 'Active');

        $this->getJson('/api/v1/categories?include_inactive=1')
            ->assertOk()
            ->assertJsonCount(2, 'data');
    }

    public function test_show_returns_404_for_missing_or_other_shop_category(): void
    {
        $otherShop = Shop::create(['name' => 'Second Shop', 'code' => 'SECOND']);
        $category = Category::create(['shop_id' => $otherShop->id, 'name' => 'Other shop category']);

        $this->getJson('/api/v1/categories/999')->assertNotFound();
        $this->getJson("/api/v1/categories/{$category->id}")->assertNotFound();
    }

    public function test_user_cannot_update_or_delete_another_shops_category(): void
    {
        $otherShop = Shop::create(['name' => 'Second Shop', 'code' => 'SECOND']);
        $category = Category::create(['shop_id' => $otherShop->id, 'name' => 'Other shop category']);

        $this->putJson("/api/v1/categories/{$category->id}", ['name' => 'Changed'])->assertNotFound();
        $this->deleteJson("/api/v1/categories/{$category->id}")->assertNotFound();

        $this->assertDatabaseHas('categories', ['id' => $category->id, 'name' => 'Other shop category']);
    }

    public function test_update_rejects_name_taken_in_same_shop(): void
    {
        Category::create(['shop_id' => $this->shop->id, 'name' => 'Espresso']);
        $category = Category::create(['shop_id' => $this->shop->id, 'name' => 'Mocha']);

        $this->putJson("/api/v1/categories/{$category->id}", ['name' => 'Espresso'])->assertUnprocessable();

        $this->putJson("/api/v1/categories/{$category->id}", ['name' => 'Mocha Drinks'])
            ->assertOk()
            ->assertJsonPath('data.name', 'Mocha Drinks');
    }
}
