<?php

namespace Tests\Feature\Api\V1;

use App\Enums\UserRole;
use App\Models\Shift;
use App\Models\Shop;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class ShiftApiTest extends TestCase
{
    use RefreshDatabase;

    public function test_guest_cannot_access_shifts_current(): void
    {
        $this->getJson('/api/v1/shifts/current')->assertUnauthorized();
    }

    public function test_owner_is_forbidden_from_shifts_current(): void
    {
        $this->authenticate(UserRole::Owner);

        $this->getJson('/api/v1/shifts/current')->assertForbidden();
    }

    public function test_cashier_can_fetch_their_own_open_shift(): void
    {
        $user = $this->authenticate(UserRole::Cashier);
        $shift = $this->createShift($user, openingCash: '100.00');

        $this->getJson('/api/v1/shifts/current')
            ->assertOk()
            ->assertJsonPath('data.id', $shift->id)
            ->assertJsonPath('data.opening_cash', '100.00')
            ->assertJsonPath('data.ended_at', null);
    }

    public function test_current_returns_null_data_when_the_user_has_no_open_shift(): void
    {
        $this->authenticate(UserRole::Cashier);

        $this->getJson('/api/v1/shifts/current')
            ->assertOk()
            ->assertJsonPath('data', null);
    }

    public function test_current_returns_null_when_the_users_shift_is_already_closed(): void
    {
        $user = $this->authenticate(UserRole::Cashier);
        $this->createShift($user, endedAt: now());

        $this->getJson('/api/v1/shifts/current')
            ->assertOk()
            ->assertJsonPath('data', null);
    }

    public function test_cashier_does_not_see_another_users_open_shift(): void
    {
        $user = $this->authenticate(UserRole::Cashier);
        $other = User::create([
            'shop_id' => $user->shop_id,
            'name' => 'Other Cashier',
            'email' => fake()->unique()->safeEmail(),
            'password' => 'password',
            'role' => UserRole::Cashier,
            'is_active' => true,
        ]);
        $this->createShift($other);

        $this->getJson('/api/v1/shifts/current')
            ->assertOk()
            ->assertJsonPath('data', null);
    }

    private function authenticate(UserRole $role = UserRole::Cashier): User
    {
        $shop = Shop::create(['name' => 'Coffee Shop', 'code' => fake()->unique()->lexify('??????')]);

        $user = User::create([
            'shop_id' => $shop->id,
            'name' => 'Shop User',
            'email' => fake()->unique()->safeEmail(),
            'password' => 'password',
            'role' => $role,
            'is_active' => true,
        ]);

        Sanctum::actingAs($user);

        return $user;
    }

    private function createShift(User $user, string $openingCash = '50.00', ?\DateTimeInterface $endedAt = null): Shift
    {
        return Shift::create([
            'shop_id' => $user->shop_id,
            'user_id' => $user->id,
            'started_at' => now()->subHours(2),
            'ended_at' => $endedAt,
            'opening_cash' => $openingCash,
            'closing_cash' => $endedAt ? '80.00' : null,
        ]);
    }
}
