<?php

namespace Database\Seeders;

use App\Enums\UserRole;
use App\Models\Shop;
use App\Models\User;
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

        User::firstOrCreate(
            ['email' => 'owner@example.com'],
            [
                'shop_id' => $shop->id,
                'name' => 'Shop Owner',
                'password' => 'password123',
                'role' => UserRole::Owner,
                'is_active' => true,
            ]
        );

        User::firstOrCreate(
            ['email' => 'cashier@example.com'],
            [
                'shop_id' => $shop->id,
                'name' => 'Default Cashier',
                'password' => 'password123',
                'role' => UserRole::Cashier,
                'is_active' => true,
            ]
        );
    }
}
