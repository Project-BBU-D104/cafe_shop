<?php

namespace Database\Seeders;

use App\Enums\StockMovementType;
use App\Enums\UserRole;
use App\Models\Category;
use App\Models\Ingredient;
use App\Models\InventoryMovement;
use App\Models\Product;
use App\Models\ProductIngredient;
use App\Models\ProductVariant;
use App\Models\Shop;
use App\Models\StaffProfile;
use App\Models\User;
use App\Services\InventoryService;
use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;

class DatabaseSeeder extends Seeder
{
    use WithoutModelEvents;

    /**
     * Seed the application's database.
     */
    public function run(): void
    {
        $shop = Shop::firstOrCreate(
            ['code' => 'MAIN'],
            [
                'name' => 'Coffee Shop Main',
                'currency' => 'USD',
                'timezone' => 'Asia/Phnom_Penh',
                'is_active' => true,
            ]
        );

        $owner = User::firstOrCreate(
            ['email' => 'owner@example.com'],
            [
                'shop_id' => $shop->id,
                'name' => 'Shop Owner',
                'password' => 'password123',
                'role' => UserRole::Owner,
                'is_active' => true,
            ]
        );

        $manager = User::firstOrCreate(
            ['email' => 'manager@example.com'],
            [
                'shop_id' => $shop->id,
                'name' => 'Shop Manager',
                'password' => 'password123',
                'role' => UserRole::Manager,
                'is_active' => true,
            ]
        );

        $cashier = User::firstOrCreate(
            ['email' => 'cashier@example.com'],
            [
                'shop_id' => $shop->id,
                'name' => 'Default Cashier',
                'password' => 'password123',
                'role' => UserRole::Cashier,
                'is_active' => true,
            ]
        );

        foreach ([[$owner, 'EMP-001', 3.00], [$manager, 'EMP-002', 2.50], [$cashier, 'EMP-003', 1.75]] as $i => [$user, $code, $rate]) {
            StaffProfile::firstOrCreate(
                ['user_id' => $user->id],
                ['employee_code' => $code, 'hire_date' => now()->subMonths(6 - $i), 'hourly_rate' => $rate],
            );
        }

        $ingredientData = [
            // name => [unit, minimum_stock, cost_per_unit, opening stock-in qty]
            'Coffee Beans' => ['g', 1000, 0.02, 5000],
            'Milk' => ['ml', 2000, 0.003, 20000],
            'Sugar' => ['g', 500, 0.001, 5000],
            'Ice' => ['g', 2000, 0.0005, 15000],
            'Matcha Powder' => ['g', 200, 0.05, 1000],
            'Chocolate Powder' => ['g', 300, 0.01, 1500],
            'Caramel Syrup' => ['ml', 200, 0.008, 800],
            'Tea Leaves' => ['g', 100, 0.01, 500],
            'Lemon' => ['pcs', 10, 0.15, 60],
            'Croissant' => ['pcs', 5, 1.2, 24],
            'Blueberry Muffin' => ['pcs', 5, 1.1, 18],
            'Cup 12oz' => ['pcs', 50, 0.05, 300],
            'Cup 16oz' => ['pcs', 50, 0.07, 300],
        ];

        $ingredients = [];
        foreach ($ingredientData as $name => [$unit, $minStock, $cost]) {
            $ingredients[$name] = Ingredient::firstOrCreate(
                ['shop_id' => $shop->id, 'name' => $name],
                ['unit' => $unit, 'current_stock' => 0, 'minimum_stock' => $minStock, 'cost_per_unit' => $cost, 'is_active' => true],
            );
        }

        $catalog = [
            'Coffee' => [
                'Espresso' => ['Rich double-shot base drink', [
                    'Single' => [1.75, true, ['Coffee Beans' => 9, 'Cup 12oz' => 1]],
                    'Doppio' => [2.50, false, ['Coffee Beans' => 18, 'Cup 12oz' => 1]],
                ]],
                'Latte' => ['Espresso with steamed milk', [
                    'Hot' => [2.50, true, ['Coffee Beans' => 18, 'Milk' => 200, 'Cup 12oz' => 1]],
                    'Iced' => [2.75, false, ['Coffee Beans' => 18, 'Milk' => 150, 'Ice' => 150, 'Cup 16oz' => 1]],
                ]],
                'Cappuccino' => ['Espresso with milk foam', [
                    'Hot' => [2.50, true, ['Coffee Beans' => 18, 'Milk' => 150, 'Cup 12oz' => 1]],
                    'Iced' => [2.75, false, ['Coffee Beans' => 18, 'Milk' => 120, 'Ice' => 150, 'Cup 16oz' => 1]],
                ]],
                'Americano' => ['Espresso with hot water', [
                    'Hot' => [2.00, true, ['Coffee Beans' => 18, 'Cup 12oz' => 1]],
                    'Iced' => [2.25, false, ['Coffee Beans' => 18, 'Ice' => 150, 'Cup 16oz' => 1]],
                ]],
            ],
            'Tea' => [
                'Matcha Latte' => ['Ceremonial-grade matcha with milk', [
                    'Hot' => [3.00, true, ['Matcha Powder' => 8, 'Milk' => 200, 'Sugar' => 10, 'Cup 12oz' => 1]],
                    'Iced' => [3.25, false, ['Matcha Powder' => 8, 'Milk' => 150, 'Sugar' => 10, 'Ice' => 150, 'Cup 16oz' => 1]],
                ]],
                'Lemon Tea' => ['Fresh brewed tea with lemon', [
                    'Hot' => [2.25, true, ['Tea Leaves' => 5, 'Sugar' => 15, 'Cup 12oz' => 1]],
                    'Iced' => [2.50, false, ['Tea Leaves' => 5, 'Sugar' => 20, 'Lemon' => 1, 'Ice' => 150, 'Cup 16oz' => 1]],
                ]],
            ],
            'Frappe' => [
                'Caramel Frappe' => ['Blended iced coffee with caramel', [
                    'Regular' => [3.50, true, ['Coffee Beans' => 18, 'Milk' => 150, 'Ice' => 200, 'Caramel Syrup' => 20, 'Cup 16oz' => 1]],
                ]],
                'Chocolate Frappe' => ['Blended iced chocolate', [
                    'Regular' => [3.50, true, ['Chocolate Powder' => 30, 'Milk' => 150, 'Ice' => 200, 'Cup 16oz' => 1]],
                ]],
            ],
            'Bakery' => [
                'Butter Croissant' => ['Baked fresh every morning', [
                    'Regular' => [1.75, true, ['Croissant' => 1]],
                ]],
                'Blueberry Muffin' => ['Soft muffin with blueberries', [
                    'Regular' => [1.65, true, ['Blueberry Muffin' => 1]],
                ]],
            ],
        ];

        $categoryOrder = 0;
        foreach ($catalog as $categoryName => $products) {
            $category = Category::firstOrCreate(
                ['shop_id' => $shop->id, 'name' => $categoryName],
                ['sort_order' => $categoryOrder++, 'is_active' => true],
            );

            $productOrder = 0;
            foreach ($products as $productName => [$description, $variants]) {
                $product = Product::firstOrCreate(
                    ['shop_id' => $shop->id, 'category_id' => $category->id, 'name' => $productName],
                    ['description' => $description, 'is_available' => true, 'sort_order' => $productOrder++],
                );

                foreach ($variants as $variantName => [$price, $isDefault, $recipe]) {
                    $variant = ProductVariant::firstOrCreate(
                        ['product_id' => $product->id, 'name' => $variantName],
                        ['price' => $price, 'is_default' => $isDefault, 'is_available' => true],
                    );

                    foreach ($recipe as $ingredientName => $quantity) {
                        $ingredient = $ingredients[$ingredientName];
                        ProductIngredient::firstOrCreate(
                            ['product_variant_id' => $variant->id, 'ingredient_id' => $ingredient->id],
                            ['quantity' => $quantity, 'unit' => $ingredient->unit],
                        );
                    }
                }
            }
        }

        // shortcut: stock movements only seed on an empty history; wipe and reseed to regenerate.
        if (InventoryMovement::where('shop_id', $shop->id)->doesntExist()) {
            $inventory = app(InventoryService::class);

            foreach ($ingredientData as $name => [, , , $openingQty]) {
                $inventory->record($owner, $ingredients[$name], [
                    'type' => StockMovementType::StockIn->value,
                    'quantity' => (string) $openingQty,
                    'notes' => 'Opening stock',
                ]);
            }

            $inventory->record($manager, $ingredients['Milk'], [
                'type' => StockMovementType::Waste->value,
                'quantity' => '500',
                'notes' => 'Spoiled milk discarded',
            ]);
            $inventory->record($owner, $ingredients['Ice'], [
                'type' => StockMovementType::Adjustment->value,
                'quantity' => '-1000',
                'notes' => 'Count correction after stocktake',
            ]);
        }
    }
}
