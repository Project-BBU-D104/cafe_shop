<?php

namespace Tests\Feature\Api\V1;

use App\Enums\UserRole;
use App\Models\Ingredient;
use App\Models\Shop;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class IngredientsApiTest extends TestCase
{
    use RefreshDatabase;

    public function test_ingredient_routes_require_authentication(): void
    {
        $this->getJson('/api/v1/ingredients')->assertUnauthorized();
        $this->postJson('/api/v1/ingredients', [])->assertUnauthorized();
    }

    public function test_store_assigns_the_users_shop_and_persists_decimal_values(): void
    {
        $shop = $this->authenticate();

        $this->postJson('/api/v1/ingredients', [
            'name' => 'Coffee Beans',
            'unit' => 'kg',
            'current_stock' => '12.345',
            'minimum_stock' => '2.500',
            'cost_per_unit' => '8.1234',
            'shop_id' => 999,
        ])
            ->assertCreated()
            ->assertJsonPath('data.current_stock', '12.345')
            ->assertJsonPath('data.cost_per_unit', '8.1234')
            ->assertJsonPath('data.is_low_stock', false);

        $this->assertDatabaseHas('ingredients', [
            'shop_id' => $shop->id,
            'name' => 'Coffee Beans',
            'current_stock' => '12.345',
            'minimum_stock' => '2.500',
            'cost_per_unit' => '8.1234',
        ]);
        $this->assertDatabaseMissing('ingredients', ['shop_id' => 999]);
    }

    public function test_store_rejects_duplicate_names_in_the_same_shop(): void
    {
        $shop = $this->authenticate();
        Ingredient::create(['shop_id' => $shop->id, 'name' => 'Milk', 'unit' => 'L']);

        $this->postJson('/api/v1/ingredients', ['name' => 'Milk', 'unit' => 'L'])
            ->assertUnprocessable()
            ->assertJsonValidationErrors('name');
    }

    public function test_index_scopes_results_and_can_filter_low_stock(): void
    {
        $shop = $this->authenticate();
        $otherShop = Shop::create(['name' => 'Other Shop', 'code' => 'OTHER']);
        Ingredient::create([
            'shop_id' => $shop->id,
            'name' => 'Low Stock',
            'unit' => 'kg',
            'current_stock' => '1.000',
            'minimum_stock' => '2.000',
        ]);
        Ingredient::create([
            'shop_id' => $shop->id,
            'name' => 'Enough Stock',
            'unit' => 'kg',
            'current_stock' => '5.000',
            'minimum_stock' => '2.000',
        ]);
        Ingredient::create([
            'shop_id' => $otherShop->id,
            'name' => 'Other Shop Item',
            'unit' => 'kg',
        ]);

        $this->getJson('/api/v1/ingredients?low_stock=1')
            ->assertOk()
            ->assertJsonCount(1, 'data')
            ->assertJsonPath('data.0.name', 'Low Stock')
            ->assertJsonPath('data.0.is_low_stock', true);
    }

    public function test_cashiers_can_read_and_create_ingredients(): void
    {
        $shop = $this->authenticate(UserRole::Cashier);

        $this->getJson('/api/v1/ingredients')->assertOk();
        $this->postJson('/api/v1/ingredients', ['name' => 'Milk', 'unit' => 'L'])->assertCreated();

        $this->assertDatabaseHas('ingredients', ['shop_id' => $shop->id, 'name' => 'Milk']);
    }

    public function test_store_rejects_stock_values_with_excess_precision(): void
    {
        $this->authenticate();

        $this->postJson('/api/v1/ingredients', [
            'name' => 'Coffee Beans',
            'unit' => 'kg',
            'current_stock' => '1.2345',
        ])->assertUnprocessable()->assertJsonValidationErrors('current_stock');
    }

    private function authenticate(UserRole $role = UserRole::Admin): Shop
    {
        $shop = Shop::create(['name' => 'Coffee Shop', 'code' => fake()->unique()->lexify('??????')]);

        Sanctum::actingAs(User::create([
            'shop_id' => $shop->id,
            'name' => 'Shop User',
            'email' => fake()->unique()->safeEmail(),
            'password' => 'password',
            'role' => $role,
            'is_active' => true,
        ]));

        return $shop;
    }
}
