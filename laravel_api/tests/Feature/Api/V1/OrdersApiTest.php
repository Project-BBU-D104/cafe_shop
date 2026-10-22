<?php

namespace Tests\Feature\Api\V1;

use App\Enums\UserRole;
use App\Models\Category;
use App\Models\Ingredient;
use App\Models\Order;
use App\Models\Product;
use App\Models\ProductVariant;
use App\Models\Shop;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class OrdersApiTest extends TestCase
{
    use RefreshDatabase;

    public function test_order_routes_require_authentication(): void
    {
        $this->getJson('/api/v1/orders')->assertUnauthorized();
        $this->postJson('/api/v1/orders', [])->assertUnauthorized();
        $this->getJson('/api/v1/orders/1')->assertUnauthorized();
        $this->patchJson('/api/v1/orders/1/status', [])->assertUnauthorized();
        $this->postJson('/api/v1/orders/1/pay', [])->assertUnauthorized();
        $this->postJson('/api/v1/orders/1/cancel', [])->assertUnauthorized();
    }

    public function test_cashiers_can_create_orders(): void
    {
        $shop = $this->authenticate(UserRole::Cashier);
        $variant = $this->createVariant($shop);

        $this->postJson('/api/v1/orders', $this->payload($variant))->assertCreated();
    }

    public function test_create_calculates_totals_server_side_and_snapshots_items(): void
    {
        $shop = $this->authenticate();
        $variant = $this->createVariant($shop, '12.50', 'Latte');

        $this->postJson('/api/v1/orders', $this->payload($variant, 2, ['discount_amount' => '5.00']))
            ->assertCreated()
            ->assertJsonPath('data.status', 'pending')
            ->assertJsonPath('data.payment_status', 'unpaid')
            ->assertJsonPath('data.subtotal', '25.00')
            ->assertJsonPath('data.discount_amount', '5.00')
            ->assertJsonPath('data.tax_amount', '2.00')
            ->assertJsonPath('data.total_amount', '22.00')
            ->assertJsonPath('data.items.0.product_name', 'Coffee Latte')
            ->assertJsonPath('data.items.0.variant_name', 'Latte')
            ->assertJsonPath('data.items.0.quantity', 2)
            ->assertJsonPath('data.items.0.unit_price', '12.50')
            ->assertJsonPath('data.items.0.line_total', '25.00');

        $this->assertDatabaseHas('order_items', [
            'product_variant_id' => $variant->id,
            'quantity' => 2,
            'line_total' => '25.00',
        ]);
        $this->assertDatabaseHas('order_status_histories', [
            'from_status' => null,
            'to_status' => 'pending',
            'user_id' => auth()->id(),
        ]);
    }

    public function test_create_clamps_the_discount_to_the_subtotal(): void
    {
        $shop = $this->authenticate();
        $variant = $this->createVariant($shop);

        $this->postJson('/api/v1/orders', $this->payload($variant, 1, ['discount_amount' => '999.00']))
            ->assertCreated()
            ->assertJsonPath('data.discount_amount', '12.50')
            ->assertJsonPath('data.tax_amount', '0.00')
            ->assertJsonPath('data.total_amount', '0.00');
    }

    public function test_create_merges_duplicate_variant_lines(): void
    {
        $shop = $this->authenticate();
        $variant = $this->createVariant($shop);

        $this->postJson('/api/v1/orders', [
            'type' => 'takeaway',
            'items' => [
                ['product_variant_id' => $variant->id, 'quantity' => 1],
                ['product_variant_id' => $variant->id, 'quantity' => 2],
            ],
        ])
            ->assertCreated()
            ->assertJsonCount(1, 'data.items')
            ->assertJsonPath('data.items.0.quantity', 3)
            ->assertJsonPath('data.subtotal', '37.50');
    }

    public function test_create_rejects_unavailable_or_foreign_variants(): void
    {
        $shop = $this->authenticate();
        $unavailable = $this->createVariant($shop, '5.00', 'Sold Out', false);
        $otherShop = $this->createShop('OTHER');
        $foreign = $this->createVariant($otherShop, '5.00', 'Foreign');

        $this->postJson('/api/v1/orders', $this->payload($unavailable))
            ->assertUnprocessable()
            ->assertJsonPath('message', 'One or more product variants are unavailable.');

        $this->postJson('/api/v1/orders', $this->payload($foreign))
            ->assertUnprocessable()
            ->assertJsonPath('message', 'One or more product variants are unavailable.');
    }

    public function test_create_validates_the_payload(): void
    {
        $this->authenticate();

        $this->postJson('/api/v1/orders', [])
            ->assertUnprocessable()
            ->assertJsonValidationErrors(['type', 'items']);

        $this->postJson('/api/v1/orders', [
            'type' => 'dine_in',
            'items' => [['product_variant_id' => 1, 'quantity' => 0]],
        ])->assertUnprocessable()->assertJsonValidationErrors('items.0.quantity');
    }

    public function test_completing_an_order_deducts_recipe_ingredients(): void
    {
        $shop = $this->authenticate();
        $variant = $this->createVariant($shop);
        $ingredient = $this->createRecipe($variant, '10.000', '0.020');

        $orderId = $this->postJson('/api/v1/orders', $this->payload($variant, 2))
            ->assertCreated()
            ->json('data.id');

        $this->patchJson("/api/v1/orders/{$orderId}/status", ['status' => 'preparing'])
            ->assertOk()
            ->assertJsonPath('data.status', 'preparing');

        $this->patchJson("/api/v1/orders/{$orderId}/status", ['status' => 'completed'])
            ->assertOk()
            ->assertJsonPath('data.status', 'completed')
            ->assertJsonPath('data.completed_at', fn ($value) => $value !== null);

        $this->assertDatabaseHas('ingredients', ['id' => $ingredient->id, 'current_stock' => '9.960']);
        $this->assertDatabaseHas('inventory_movements', [
            'ingredient_id' => $ingredient->id,
            'type' => 'order_consumption',
            'quantity' => '0.040',
            'reference_type' => 'order',
            'reference_id' => $orderId,
        ]);
        $this->assertDatabaseCount('order_status_histories', 3);
    }

    public function test_completing_an_order_survives_a_soft_deleted_ingredient(): void
    {
        $shop = $this->authenticate();
        $variant = $this->createVariant($shop);
        $ingredient = $this->createRecipe($variant, '10.000', '0.020');
        $ingredient->delete();

        $orderId = $this->createOrder($variant);

        $this->patchJson("/api/v1/orders/{$orderId}/status", ['status' => 'preparing'])->assertOk();
        $this->patchJson("/api/v1/orders/{$orderId}/status", ['status' => 'completed'])->assertOk();

        $this->assertSame('9.980', Ingredient::withTrashed()->findOrFail($ingredient->id)->current_stock);
        $this->assertDatabaseHas('inventory_movements', [
            'ingredient_id' => $ingredient->id,
            'type' => 'order_consumption',
        ]);
    }

    public function test_invalid_status_transitions_are_rejected(): void
    {
        $shop = $this->authenticate();
        $variant = $this->createVariant($shop);
        $orderId = $this->createOrder($variant);

        $this->patchJson("/api/v1/orders/{$orderId}/status", ['status' => 'completed'])->assertStatus(409);

        $this->postJson("/api/v1/orders/{$orderId}/cancel")->assertOk();

        $this->patchJson("/api/v1/orders/{$orderId}/status", ['status' => 'preparing'])->assertStatus(409);
        $this->postJson("/api/v1/orders/{$orderId}/cancel")->assertStatus(409);

        $second = $this->createOrder($variant);
        $this->patchJson("/api/v1/orders/{$second}/status", ['status' => 'preparing'])->assertOk();
        $this->patchJson("/api/v1/orders/{$second}/status", ['status' => 'completed'])->assertOk();
        $this->postJson("/api/v1/orders/{$second}/cancel")->assertStatus(409);
    }

    public function test_cancelling_an_order_never_deducts_stock(): void
    {
        $shop = $this->authenticate();
        $variant = $this->createVariant($shop);
        $ingredient = $this->createRecipe($variant, '10.000', '0.020');
        $orderId = $this->createOrder($variant);

        $this->postJson("/api/v1/orders/{$orderId}/cancel", ['note' => 'Customer left'])
            ->assertOk()
            ->assertJsonPath('data.status', 'cancelled')
            ->assertJsonPath('data.cancelled_at', fn ($value) => $value !== null);

        $this->assertDatabaseHas('ingredients', ['id' => $ingredient->id, 'current_stock' => '10.000']);
        $this->assertDatabaseCount('inventory_movements', 0);
    }

    public function test_pay_records_a_payment_and_caches_the_order_summary(): void
    {
        $shop = $this->authenticate();
        $variant = $this->createVariant($shop);
        $orderId = $this->createOrder($variant, 1);

        $this->postJson("/api/v1/orders/{$orderId}/pay", [
            'method' => 'cash',
            'transaction_reference' => 'TX-1',
        ])
            ->assertCreated()
            ->assertJsonPath('data.method', 'cash')
            ->assertJsonPath('data.status', 'paid')
            ->assertJsonPath('data.amount', '13.75')
            ->assertJsonPath('data.transaction_reference', 'TX-1');

        $order = Order::findOrFail($orderId);
        $this->assertSame('paid', $order->payment_status->value);
        $this->assertSame('cash', $order->payment_method->value);
        $this->assertNotNull($order->paid_at);
        $this->assertDatabaseHas('payments', ['order_id' => $orderId, 'amount' => '13.75', 'status' => 'paid']);
    }

    public function test_cancelling_a_paid_order_is_rejected(): void
    {
        $shop = $this->authenticate();
        $orderId = $this->createOrder($this->createVariant($shop));

        $this->postJson("/api/v1/orders/{$orderId}/pay", ['method' => 'cash'])->assertCreated();

        $this->postJson("/api/v1/orders/{$orderId}/cancel")
            ->assertStatus(409)
            ->assertJsonPath('message', 'A paid order cannot be cancelled.');
    }

    public function test_tax_rounds_half_up_at_the_half_cent(): void
    {
        $shop = $this->authenticate();
        $variant = $this->createVariant($shop, '12.35');

        $this->postJson('/api/v1/orders', $this->payload($variant))
            ->assertCreated()
            ->assertJsonPath('data.tax_amount', '1.24')
            ->assertJsonPath('data.total_amount', '13.59');
    }

    public function test_pay_rejects_double_payment_and_cancelled_orders(): void
    {
        $shop = $this->authenticate();
        $variant = $this->createVariant($shop);
        $orderId = $this->createOrder($variant);

        $this->postJson("/api/v1/orders/{$orderId}/pay", ['method' => 'cash'])->assertCreated();
        $this->postJson("/api/v1/orders/{$orderId}/pay", ['method' => 'cash'])->assertStatus(409);

        $cancelled = $this->createOrder($variant);
        $this->postJson("/api/v1/orders/{$cancelled}/cancel")->assertOk();
        $this->postJson("/api/v1/orders/{$cancelled}/pay", ['method' => 'cash'])->assertStatus(409);
    }

    public function test_orders_are_scoped_to_the_acting_shop(): void
    {
        $this->authenticate();
        $foreignId = $this->createForeignOrder($this->createShop('OTHER'))->id;

        $this->getJson("/api/v1/orders/{$foreignId}")->assertNotFound();
        $this->patchJson("/api/v1/orders/{$foreignId}/status", ['status' => 'preparing'])->assertNotFound();
        $this->postJson("/api/v1/orders/{$foreignId}/pay", ['method' => 'cash'])->assertNotFound();
        $this->postJson("/api/v1/orders/{$foreignId}/cancel")->assertNotFound();
    }

    public function test_index_date_filters_use_the_shop_timezone(): void
    {
        $shop = $this->authenticate(UserRole::Admin, 'Asia/Phnom_Penh');
        $orderId = $this->createOrder($this->createVariant($shop));

        // 03:00 on Oct 22 in Phnom Penh is 20:00 on Oct 21 UTC.
        Order::whereKey($orderId)->update(['created_at' => '2026-10-21 20:00:00']);

        $this->getJson('/api/v1/orders?from=2026-10-22&to=2026-10-22')
            ->assertOk()
            ->assertJsonCount(1, 'data');

        $this->getJson('/api/v1/orders?from=2026-10-21&to=2026-10-21')
            ->assertOk()
            ->assertJsonCount(0, 'data');
    }

    public function test_index_rejects_invalid_filters(): void
    {
        $this->authenticate();

        $this->getJson('/api/v1/orders?from=not-a-date')
            ->assertUnprocessable()
            ->assertJsonValidationErrors('from');

        $this->getJson('/api/v1/orders?status=nope')
            ->assertUnprocessable()
            ->assertJsonValidationErrors('status');
    }

    public function test_index_lists_only_the_acting_shops_orders_and_filters_by_status(): void
    {
        $shop = $this->authenticate();
        $variant = $this->createVariant($shop);
        $first = $this->createOrder($variant);
        $this->createOrder($variant);
        $this->patchJson("/api/v1/orders/{$first}/status", ['status' => 'preparing'])->assertOk();

        $this->createForeignOrder($this->createShop('OTHER'));

        $this->getJson('/api/v1/orders')->assertOk()->assertJsonCount(2, 'data');
        $this->getJson('/api/v1/orders?status=preparing')
            ->assertOk()
            ->assertJsonCount(1, 'data')
            ->assertJsonPath('data.0.id', $first);
    }

    public function test_non_numeric_order_ids_are_not_found(): void
    {
        $this->authenticate();

        $this->getJson('/api/v1/orders/abc')->assertNotFound();
        $this->patchJson('/api/v1/orders/abc/status', ['status' => 'preparing'])->assertNotFound();
        $this->postJson('/api/v1/orders/abc/pay', ['method' => 'cash'])->assertNotFound();
        $this->postJson('/api/v1/orders/abc/cancel')->assertNotFound();
    }

    public function test_order_routes_expose_no_generic_update_or_delete(): void
    {
        $shop = $this->authenticate();
        $orderId = $this->createOrder($this->createVariant($shop));

        $this->putJson("/api/v1/orders/{$orderId}", [])->assertMethodNotAllowed();
        $this->patchJson("/api/v1/orders/{$orderId}", [])->assertMethodNotAllowed();
        $this->deleteJson("/api/v1/orders/{$orderId}")->assertMethodNotAllowed();
    }

    private function authenticate(UserRole $role = UserRole::Admin, string $timezone = 'UTC'): Shop
    {
        $shop = $this->createShop(fake()->unique()->lexify('??????'), $timezone);

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

    private function createShop(string $code, string $timezone = 'UTC'): Shop
    {
        return Shop::create([
            'name' => 'Coffee Shop',
            'code' => $code,
            'tax_rate' => '10.00',
            'timezone' => $timezone,
        ]);
    }

    private function createVariant(Shop $shop, string $price = '12.50', string $name = 'Latte', bool $available = true): ProductVariant
    {
        $category = Category::create(['shop_id' => $shop->id, 'name' => fake()->unique()->word()]);
        $product = Product::create([
            'shop_id' => $shop->id,
            'category_id' => $category->id,
            'name' => 'Coffee '.$name,
        ]);

        return $product->variants()->create([
            'name' => $name,
            'price' => $price,
            'is_default' => true,
            'is_available' => $available,
        ]);
    }

    private function createRecipe(ProductVariant $variant, string $stock, string $quantity): Ingredient
    {
        $ingredient = Ingredient::create([
            'shop_id' => $variant->product->shop_id,
            'name' => fake()->unique()->word(),
            'unit' => 'kg',
            'current_stock' => $stock,
            'minimum_stock' => '1.000',
            'cost_per_unit' => '2.5000',
        ]);

        $variant->ingredients()->attach($ingredient->id, ['quantity' => $quantity, 'unit' => 'kg']);

        return $ingredient;
    }

    /**
     * @param  array<string, mixed>  $overrides
     * @return array<string, mixed>
     */
    private function payload(ProductVariant $variant, int $quantity = 1, array $overrides = []): array
    {
        return [
            'type' => 'takeaway',
            'items' => [['product_variant_id' => $variant->id, 'quantity' => $quantity]],
            ...$overrides,
        ];
    }

    private function createOrder(ProductVariant $variant, int $quantity = 1): int
    {
        return $this->postJson('/api/v1/orders', $this->payload($variant, $quantity))
            ->assertCreated()
            ->json('data.id');
    }

    private function createForeignOrder(Shop $shop): Order
    {
        return Order::create([
            'shop_id' => $shop->id,
            'order_number' => 'BB-'.fake()->unique()->numerify('################'),
            'type' => 'takeaway',
            'status' => 'pending',
            'payment_status' => 'unpaid',
            'subtotal' => '5.00',
            'total_amount' => '5.00',
        ]);
    }
}
