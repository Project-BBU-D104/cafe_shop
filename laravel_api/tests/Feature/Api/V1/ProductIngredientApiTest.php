<?php

namespace Tests\Feature\Api\V1;

use App\Enums\UserRole;
use App\Models\Category;
use App\Models\Ingredient;
use App\Models\Product;
use App\Models\ProductVariant;
use App\Models\Shop;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class ProductIngredientApiTest extends TestCase
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

    public function test_index_lists_recipe_ingredients(): void
    {
        $variant = $this->createVariant();
        $milk = $this->createIngredient('Milk', 'ml');
        $this->addIngredient($variant, $milk, '150.000');

        $this->getJson("/api/v1/variants/{$variant->id}/ingredients")
            ->assertOk()
            ->assertJsonCount(1, 'data')
            ->assertJsonPath('data.0.quantity', '150.000')
            ->assertJsonPath('data.0.unit', 'ml')
            ->assertJsonPath('data.0.ingredient.name', 'Milk');
    }

    public function test_store_adds_a_recipe_ingredient_pinned_to_the_ingredient_unit(): void
    {
        $variant = $this->createVariant();
        $beans = $this->createIngredient('Coffee Beans', 'g');

        $this->postJson("/api/v1/variants/{$variant->id}/ingredients", [
            'ingredient_id' => $beans->id,
            'quantity' => '18.000',
        ])
            ->assertCreated()
            ->assertJsonPath('data.quantity', '18.000')
            ->assertJsonPath('data.unit', 'g')
            ->assertJsonPath('data.ingredient.name', 'Coffee Beans');

        $this->assertDatabaseHas('product_ingredients', [
            'product_variant_id' => $variant->id,
            'ingredient_id' => $beans->id,
            'quantity' => '18.000',
            'unit' => 'g',
        ]);
    }

    public function test_store_rejects_a_unit_that_differs_from_the_ingredient_unit(): void
    {
        $variant = $this->createVariant();
        $beans = $this->createIngredient('Coffee Beans', 'g');

        $this->postJson("/api/v1/variants/{$variant->id}/ingredients", [
            'ingredient_id' => $beans->id,
            'quantity' => '18.000',
            'unit' => 'kg',
        ])->assertUnprocessable()->assertJsonValidationErrors('unit');
    }

    public function test_store_rejects_a_duplicate_ingredient_for_the_same_variant(): void
    {
        $variant = $this->createVariant();
        $milk = $this->createIngredient('Milk', 'ml');
        $this->addIngredient($variant, $milk, '150.000');

        $this->postJson("/api/v1/variants/{$variant->id}/ingredients", [
            'ingredient_id' => $milk->id,
            'quantity' => '100.000',
        ])->assertUnprocessable()->assertJsonValidationErrors('ingredient_id');
    }

    public function test_store_rejects_an_ingredient_from_another_shop(): void
    {
        $variant = $this->createVariant();
        $otherShop = Shop::create(['name' => 'Other Shop', 'code' => 'OTHER']);
        $foreign = Ingredient::create(['shop_id' => $otherShop->id, 'name' => 'Foreign', 'unit' => 'ml']);

        $this->postJson("/api/v1/variants/{$variant->id}/ingredients", [
            'ingredient_id' => $foreign->id,
            'quantity' => '10.000',
        ])->assertUnprocessable()->assertJsonValidationErrors('ingredient_id');
    }

    public function test_update_changes_the_quantity_without_touching_the_unit(): void
    {
        $variant = $this->createVariant();
        $milk = $this->createIngredient('Milk', 'ml');
        $this->addIngredient($variant, $milk, '150.000');

        $this->patchJson("/api/v1/variants/{$variant->id}/ingredients/{$milk->id}", [
            'quantity' => '200.000',
        ])
            ->assertOk()
            ->assertJsonPath('data.quantity', '200.000')
            ->assertJsonPath('data.unit', 'ml');

        $this->assertDatabaseHas('product_ingredients', [
            'product_variant_id' => $variant->id,
            'ingredient_id' => $milk->id,
            'quantity' => '200.000',
            'unit' => 'ml',
        ]);
    }

    public function test_update_accepts_an_echoed_ingredient_id_and_updates_the_quantity(): void
    {
        $variant = $this->createVariant();
        $milk = $this->createIngredient('Milk', 'ml');
        $this->addIngredient($variant, $milk, '150.000');

        $this->patchJson("/api/v1/variants/{$variant->id}/ingredients/{$milk->id}", [
            'ingredient_id' => $milk->id,
            'quantity' => '200.000',
        ])
            ->assertOk()
            ->assertJsonPath('data.quantity', '200.000');
    }

    public function test_destroy_removes_the_recipe_ingredient(): void
    {
        $variant = $this->createVariant();
        $milk = $this->createIngredient('Milk', 'ml');
        $this->addIngredient($variant, $milk, '150.000');

        $this->deleteJson("/api/v1/variants/{$variant->id}/ingredients/{$milk->id}")
            ->assertNoContent();

        $this->assertDatabaseMissing('product_ingredients', [
            'product_variant_id' => $variant->id,
            'ingredient_id' => $milk->id,
        ]);
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
        $otherVariant = ProductVariant::create([
            'product_id' => $otherProduct->id,
            'name' => 'Regular',
            'price' => '3.50',
        ]);

        $this->getJson("/api/v1/variants/{$otherVariant->id}/ingredients")->assertNotFound();
        $this->postJson("/api/v1/variants/{$otherVariant->id}/ingredients", [
            'ingredient_id' => $this->createIngredient('Milk', 'ml')->id,
            'quantity' => '10.000',
        ])->assertNotFound();
    }

    public function test_recipe_routes_require_authentication(): void
    {
        $this->app['auth']->forgetGuards();
        $variant = $this->createVariant();
        $milk = $this->createIngredient('Milk', 'ml');

        $this->getJson("/api/v1/variants/{$variant->id}/ingredients")->assertUnauthorized();
        $this->postJson("/api/v1/variants/{$variant->id}/ingredients", [])->assertUnauthorized();
        $this->patchJson("/api/v1/variants/{$variant->id}/ingredients/{$milk->id}", ['quantity' => '10.000'])
            ->assertUnauthorized();
        $this->deleteJson("/api/v1/variants/{$variant->id}/ingredients/{$milk->id}")->assertUnauthorized();
    }

    public function test_update_and_destroy_reject_a_variant_from_another_shop(): void
    {
        $otherVariant = $this->createVariantInAnotherShop();
        $milk = $this->createIngredient('Milk', 'ml');

        $this->patchJson("/api/v1/variants/{$otherVariant->id}/ingredients/{$milk->id}", [
            'quantity' => '10.000',
        ])->assertNotFound();

        $this->deleteJson("/api/v1/variants/{$otherVariant->id}/ingredients/{$milk->id}")
            ->assertNotFound();
    }

    public function test_update_and_destroy_return_not_found_for_a_missing_recipe_row(): void
    {
        $variant = $this->createVariant();
        $milk = $this->createIngredient('Milk', 'ml');

        $this->patchJson("/api/v1/variants/{$variant->id}/ingredients/{$milk->id}", [
            'quantity' => '10.000',
        ])->assertNotFound();

        $this->deleteJson("/api/v1/variants/{$variant->id}/ingredients/{$milk->id}")
            ->assertNotFound();
    }

    public function test_store_rejects_out_of_range_and_over_precise_quantities(): void
    {
        $variant = $this->createVariant();
        $milk = $this->createIngredient('Milk', 'ml');

        foreach (['0', '1.2345', '1000000000'] as $quantity) {
            $this->postJson("/api/v1/variants/{$variant->id}/ingredients", [
                'ingredient_id' => $milk->id,
                'quantity' => $quantity,
            ])->assertUnprocessable()->assertJsonValidationErrors('quantity');
        }
    }

    private function createVariantInAnotherShop(): ProductVariant
    {
        $shop = Shop::create(['name' => 'Second Shop', 'code' => 'SECOND']);
        $category = Category::create(['shop_id' => $shop->id, 'name' => 'Drinks']);
        $product = Product::create([
            'shop_id' => $shop->id,
            'category_id' => $category->id,
            'name' => 'Other Product',
        ]);

        return ProductVariant::create(['product_id' => $product->id, 'name' => 'Regular', 'price' => '3.50']);
    }

    private function createVariant(): ProductVariant
    {
        $category = Category::create(['shop_id' => $this->shop->id, 'name' => 'Drinks']);
        $product = Product::create([
            'shop_id' => $this->shop->id,
            'category_id' => $category->id,
            'name' => 'Latte',
        ]);

        return ProductVariant::create(['product_id' => $product->id, 'name' => 'Regular', 'price' => '3.50']);
    }

    private function createIngredient(string $name, string $unit): Ingredient
    {
        return Ingredient::create(['shop_id' => $this->shop->id, 'name' => $name, 'unit' => $unit]);
    }

    private function addIngredient(ProductVariant $variant, Ingredient $ingredient, string $quantity): void
    {
        $variant->ingredients()->attach($ingredient->id, ['quantity' => $quantity, 'unit' => $ingredient->unit]);
    }
}
