<?php

namespace Tests\Feature\Api\V1;

use App\Models\Category;
use App\Models\Shop;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class CategoryTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();

        Shop::create(['name' => 'Coffee Shop', 'code' => 'MAIN']);
    }

    public function test_store_assigns_the_single_shop(): void
    {
        $this->postJson('/api/v1/categories', ['name' => 'Latte Art'])
            ->assertCreated();

        $this->assertDatabaseHas('categories', ['name' => 'Latte Art', 'shop_id' => 1]);
    }

    public function test_duplicate_name_is_rejected_but_reusable_after_delete(): void
    {
        $this->postJson('/api/v1/categories', ['name' => 'Latte Art'])->assertCreated();
        $this->postJson('/api/v1/categories', ['name' => 'Latte Art'])->assertUnprocessable();

        $id = Category::query()->where('name', 'Latte Art')->value('id');
        $this->deleteJson("/api/v1/categories/{$id}")->assertNoContent();

        $this->postJson('/api/v1/categories', ['name' => 'Latte Art'])->assertCreated();
    }

    public function test_index_filters_inactive_by_default(): void
    {
        Category::create(['shop_id' => 1, 'name' => 'Active', 'is_active' => true]);
        Category::create(['shop_id' => 1, 'name' => 'Hidden', 'is_active' => false]);

        $this->getJson('/api/v1/categories')->assertOk()->assertJsonCount(1, 'data')->assertJsonPath('data.0.name', 'Active');

        $this->getJson('/api/v1/categories?include_inactive=1')->assertOk()->assertJsonCount(2, 'data');
    }

    public function test_show_returns_404_for_missing_category(): void
    {
        $this->getJson('/api/v1/categories/999')->assertNotFound();
    }

    public function test_update_rejects_name_taken_by_another_category(): void
    {
        Category::create(['shop_id' => 1, 'name' => 'Espresso']);
        $other = Category::create(['shop_id' => 1, 'name' => 'Mocha']);

        $this->putJson("/api/v1/categories/{$other->id}", ['name' => 'Espresso'])->assertUnprocessable();

        $this->putJson("/api/v1/categories/{$other->id}", ['name' => 'Mocha Drinks'])->assertOk()
            ->assertJsonPath('data.name', 'Mocha Drinks');
    }
}
