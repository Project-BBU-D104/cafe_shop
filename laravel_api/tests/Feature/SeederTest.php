<?php

namespace Tests\Feature;

use App\Models\Category;
use App\Models\Ingredient;
use App\Models\InventoryMovement;
use App\Models\Product;
use App\Models\ProductIngredient;
use App\Models\StaffProfile;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class SeederTest extends TestCase
{
    use RefreshDatabase;

    public function test_seeder_populates_catalog_staff_and_stock_and_is_idempotent(): void
    {
        $this->seed();
        $this->seed();

        $this->assertSame(3, User::count());
        $this->assertSame(3, StaffProfile::count());
        $this->assertSame(4, Category::count());
        $this->assertSame(10, Product::count());
        $this->assertSame(13, Ingredient::count());

        // 13 opening stock-in + 1 waste + 1 adjustment, seeded once only.
        $this->assertSame(15, InventoryMovement::count());

        $milk = Ingredient::where('name', 'Milk')->firstOrFail();
        $this->assertSame('19500.000', $milk->current_stock); // 20000 in - 500 waste

        $ice = Ingredient::where('name', 'Ice')->firstOrFail();
        $this->assertSame('14000.000', $ice->current_stock); // 15000 in - 1000 adjustment

        $hotLatte = Product::where('name', 'Latte')->firstOrFail()
            ->variants()->where('name', 'Hot')->firstOrFail();
        $this->assertSame(3, ProductIngredient::where('product_variant_id', $hotLatte->id)->count());
    }
}
