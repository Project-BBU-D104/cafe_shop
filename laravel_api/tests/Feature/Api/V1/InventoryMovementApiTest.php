<?php

namespace Tests\Feature\Api\V1;

use App\Enums\StockMovementType;
use App\Enums\UserRole;
use App\Models\Ingredient;
use App\Models\InventoryMovement;
use App\Models\Shop;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Schema;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class InventoryMovementApiTest extends TestCase
{
    use RefreshDatabase;

    public function test_inventory_movement_routes_require_authentication(): void
    {
        $this->getJson('/api/v1/inventory/movements')->assertUnauthorized();
        $this->postJson('/api/v1/ingredients/1/movements', [])->assertUnauthorized();
    }

    public function test_cashiers_cannot_record_or_list_inventory_movements(): void
    {
        $this->authenticate(UserRole::Cashier);

        $this->getJson('/api/v1/inventory/movements')->assertForbidden();
        $this->postJson('/api/v1/ingredients/1/movements', ['type' => 'stock_in', 'quantity' => '1.000'])->assertForbidden();
    }

    public function test_store_rejects_an_unknown_movement_type(): void
    {
        $shop = $this->authenticate();
        $ingredient = $this->createIngredient($shop);

        $this->postJson("/api/v1/ingredients/{$ingredient->id}/movements", [
            'type' => 'stock_transfer',
            'quantity' => '1.000',
        ])->assertUnprocessable()->assertJsonValidationErrors('type');
    }

    public function test_store_rejects_missing_or_invalid_quantities(): void
    {
        $shop = $this->authenticate();
        $ingredient = $this->createIngredient($shop);

        foreach ([
            ['type' => 'stock_in'],
            ['type' => 'stock_in', 'quantity' => '0'],
            ['type' => 'stock_in', 'quantity' => '0.000'],
            ['type' => 'stock_in', 'quantity' => '-5.000'],
            ['type' => 'stock_in', 'quantity' => '1.2345'],
            ['type' => 'stock_in', 'quantity' => '1000000000'],
        ] as $payload) {
            $this->postJson("/api/v1/ingredients/{$ingredient->id}/movements", $payload)
                ->assertUnprocessable()->assertJsonValidationErrors('quantity');
        }
    }

    public function test_store_rejects_a_zero_adjustment(): void
    {
        $shop = $this->authenticate();
        $ingredient = $this->createIngredient($shop);

        foreach (['0', '0.000'] as $quantity) {
            $this->postJson("/api/v1/ingredients/{$ingredient->id}/movements", [
                'type' => 'adjustment',
                'quantity' => $quantity,
            ])->assertUnprocessable()->assertJsonValidationErrors('quantity');
        }
    }

    public function test_store_rejects_out_of_range_adjustment_quantities(): void
    {
        $shop = $this->authenticate();
        $ingredient = $this->createIngredient($shop);

        foreach (['-2.1234', '-1000000000.000', '1.2345', '1e3'] as $quantity) {
            $this->postJson("/api/v1/ingredients/{$ingredient->id}/movements", [
                'type' => 'adjustment',
                'quantity' => $quantity,
            ])->assertUnprocessable()->assertJsonValidationErrors('quantity');
        }
    }

    public function test_store_rejects_an_invalid_unit_cost(): void
    {
        $shop = $this->authenticate();
        $ingredient = $this->createIngredient($shop);

        foreach (['-1.0000', '1.23456'] as $unitCost) {
            $this->postJson("/api/v1/ingredients/{$ingredient->id}/movements", [
                'type' => 'stock_in',
                'quantity' => '1.000',
                'unit_cost' => $unitCost,
            ])->assertUnprocessable()->assertJsonValidationErrors('unit_cost');
        }
    }

    public function test_store_records_a_stock_in_movement_and_increases_stock(): void
    {
        $shop = $this->authenticate();
        $ingredient = $this->createIngredient($shop);

        $this->postJson("/api/v1/ingredients/{$ingredient->id}/movements", [
            'type' => 'stock_in',
            'quantity' => '3.500',
        ])
            ->assertCreated()
            ->assertJsonPath('data.type', 'stock_in')
            ->assertJsonPath('data.quantity', '3.500')
            ->assertJsonPath('data.unit_cost', '2.5000')
            ->assertJsonPath('data.user_id', auth()->id())
            ->assertJsonPath('data.ingredient.name', 'Coffee Beans');

        $this->assertDatabaseHas('ingredients', ['id' => $ingredient->id, 'current_stock' => '13.500']);
        $this->assertDatabaseHas('inventory_movements', [
            'shop_id' => $shop->id,
            'ingredient_id' => $ingredient->id,
            'type' => 'stock_in',
            'quantity' => '3.500',
            'unit_cost' => '2.5000',
        ]);
    }

    public function test_store_unit_cost_override_wins_over_the_ingredient_snapshot(): void
    {
        $shop = $this->authenticate();
        $ingredient = $this->createIngredient($shop);

        $this->postJson("/api/v1/ingredients/{$ingredient->id}/movements", [
            'type' => 'stock_in',
            'quantity' => '1.000',
            'unit_cost' => '3.1000',
        ])->assertCreated()->assertJsonPath('data.unit_cost', '3.1000');

        $this->assertDatabaseHas('inventory_movements', ['unit_cost' => '3.1000']);
        $this->assertDatabaseHas('ingredients', ['id' => $ingredient->id, 'cost_per_unit' => '2.5000']);
    }

    public function test_store_persists_reference_fields_and_notes(): void
    {
        $shop = $this->authenticate();
        $ingredient = $this->createIngredient($shop);

        $this->postJson("/api/v1/ingredients/{$ingredient->id}/movements", [
            'type' => 'stock_in',
            'quantity' => '1.000',
            'reference_type' => 'order',
            'reference_id' => 42,
            'notes' => 'Restock delivery',
        ])
            ->assertCreated()
            ->assertJsonPath('data.reference_type', 'order')
            ->assertJsonPath('data.reference_id', 42)
            ->assertJsonPath('data.notes', 'Restock delivery');
    }

    public function test_movements_table_has_no_updated_at_column(): void
    {
        $this->assertTrue(Schema::hasTable('inventory_movements'));
        $this->assertFalse(Schema::hasColumn('inventory_movements', 'updated_at'));
    }

    public function test_store_applies_negative_deltas_for_consumption_types(): void
    {
        $shop = $this->authenticate();

        foreach ([
            ['stock_out', '8.000', '2.000', 'Beans A'],
            ['waste', '9.500', '0.500', 'Beans B'],
            ['order_consumption', '8.750', '1.250', 'Beans C'],
        ] as [$type, $expectedStock, $quantity, $name]) {
            $ingredient = $this->createIngredient($shop, '10.000', name: $name);

            $this->postJson("/api/v1/ingredients/{$ingredient->id}/movements", [
                'type' => $type,
                'quantity' => $quantity,
            ])->assertCreated();

            $this->assertDatabaseHas('ingredients', ['id' => $ingredient->id, 'current_stock' => $expectedStock]);
            $this->assertDatabaseHas('inventory_movements', ['ingredient_id' => $ingredient->id, 'type' => $type, 'quantity' => $quantity]);
        }
    }

    public function test_store_applies_signed_adjustments_in_both_directions(): void
    {
        $shop = $this->authenticate();
        $ingredient = $this->createIngredient($shop, '10.000');

        $this->postJson("/api/v1/ingredients/{$ingredient->id}/movements", [
            'type' => 'adjustment',
            'quantity' => '-4.000',
        ])->assertCreated();
        $this->assertDatabaseHas('ingredients', ['id' => $ingredient->id, 'current_stock' => '6.000']);
        $this->assertDatabaseHas('inventory_movements', ['type' => 'adjustment', 'quantity' => '-4.000']);

        $this->postJson("/api/v1/ingredients/{$ingredient->id}/movements", [
            'type' => 'adjustment',
            'quantity' => '2.500',
        ])->assertCreated();
        $this->assertDatabaseHas('ingredients', ['id' => $ingredient->id, 'current_stock' => '8.500']);
    }

    public function test_store_allows_stock_to_go_negative(): void
    {
        $shop = $this->authenticate();
        $ingredient = $this->createIngredient($shop, '10.000');

        $this->postJson("/api/v1/ingredients/{$ingredient->id}/movements", [
            'type' => 'stock_out',
            'quantity' => '15.000',
        ])->assertCreated();

        $this->assertDatabaseHas('ingredients', ['id' => $ingredient->id, 'current_stock' => '-5.000']);
    }

    public function test_store_rejects_movements_that_would_overflow_the_stock_column(): void
    {
        $shop = $this->authenticate();
        $high = $this->createIngredient($shop, '999999999.000');
        $low = $this->createIngredient($shop, '-999999999.000', name: 'Low Beans');

        $this->postJson("/api/v1/ingredients/{$high->id}/movements", ['type' => 'stock_in', 'quantity' => '1.000'])
            ->assertUnprocessable()->assertJsonValidationErrors('quantity');
        $this->postJson("/api/v1/ingredients/{$low->id}/movements", ['type' => 'stock_out', 'quantity' => '1.000'])
            ->assertUnprocessable()->assertJsonValidationErrors('quantity');

        $this->assertDatabaseHas('ingredients', ['id' => $high->id, 'current_stock' => '999999999.000']);
        $this->assertDatabaseHas('ingredients', ['id' => $low->id, 'current_stock' => '-999999999.000']);
        $this->assertDatabaseCount('inventory_movements', 0);
    }

    public function test_store_returns_not_found_for_a_non_numeric_ingredient_id(): void
    {
        $this->authenticate();

        $this->postJson('/api/v1/ingredients/abc/movements', [
            'type' => 'stock_in',
            'quantity' => '1.000',
        ])->assertNotFound();
    }

    public function test_store_returns_not_found_for_an_ingredient_from_another_shop(): void
    {
        $this->authenticate();
        $otherShop = Shop::create(['name' => 'Other Shop', 'code' => 'OTHER']);
        $foreign = Ingredient::create(['shop_id' => $otherShop->id, 'name' => 'Foreign', 'unit' => 'kg']);

        $this->postJson("/api/v1/ingredients/{$foreign->id}/movements", [
            'type' => 'stock_in',
            'quantity' => '1.000',
        ])->assertNotFound();

        $this->postJson('/api/v1/ingredients/999999/movements', [
            'type' => 'stock_in',
            'quantity' => '1.000',
        ])->assertNotFound();
    }

    public function test_index_lists_only_the_acting_shops_movements_newest_first(): void
    {
        $shop = $this->authenticate();
        $ingredient = $this->createIngredient($shop);
        $otherShop = Shop::create(['name' => 'Other Shop', 'code' => 'OTHER']);
        $foreign = Ingredient::create(['shop_id' => $otherShop->id, 'name' => 'Foreign', 'unit' => 'kg']);

        $this->postJson("/api/v1/ingredients/{$ingredient->id}/movements", ['type' => 'stock_in', 'quantity' => '1.000'])->assertCreated();
        $this->postJson("/api/v1/ingredients/{$ingredient->id}/movements", ['type' => 'stock_out', 'quantity' => '0.500'])->assertCreated();

        InventoryMovement::create([
            'shop_id' => $otherShop->id,
            'ingredient_id' => $foreign->id,
            'user_id' => auth()->id(),
            'type' => StockMovementType::StockIn,
            'quantity' => '99.000',
        ]);

        $this->getJson('/api/v1/inventory/movements')
            ->assertOk()
            ->assertJsonCount(2, 'data')
            ->assertJsonPath('data.0.type', 'stock_out')
            ->assertJsonPath('data.1.type', 'stock_in');
    }

    public function test_index_filters_by_ingredient(): void
    {
        $shop = $this->authenticate();
        $beans = $this->createIngredient($shop);
        $milk = Ingredient::create(['shop_id' => $shop->id, 'name' => 'Milk', 'unit' => 'L']);

        $this->postJson("/api/v1/ingredients/{$beans->id}/movements", ['type' => 'stock_in', 'quantity' => '1.000'])->assertCreated();
        $this->postJson("/api/v1/ingredients/{$milk->id}/movements", ['type' => 'stock_in', 'quantity' => '2.000'])->assertCreated();

        $this->getJson("/api/v1/inventory/movements?ingredient_id={$milk->id}")
            ->assertOk()
            ->assertJsonCount(1, 'data')
            ->assertJsonPath('data.0.ingredient_id', $milk->id);
    }

    public function test_movement_routes_expose_no_update_or_delete_endpoints(): void
    {
        $this->authenticate();

        $this->putJson('/api/v1/inventory/movements', [])->assertMethodNotAllowed();
        $this->patchJson('/api/v1/inventory/movements', [])->assertMethodNotAllowed();
        $this->deleteJson('/api/v1/inventory/movements', [])->assertMethodNotAllowed();
        $this->getJson('/api/v1/inventory/movements/1')->assertNotFound();
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

    private function createIngredient(Shop $shop, string $stock = '10.000', string $cost = '2.5000', string $name = 'Coffee Beans'): Ingredient
    {
        return Ingredient::create([
            'shop_id' => $shop->id,
            'name' => $name,
            'unit' => 'kg',
            'current_stock' => $stock,
            'minimum_stock' => '1.000',
            'cost_per_unit' => $cost,
        ]);
    }
}
