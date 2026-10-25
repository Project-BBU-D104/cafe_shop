<?php

namespace Tests\Feature\Api\V1;

use App\Enums\UserRole;
use App\Models\Shop;
use App\Models\StaffProfile;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class StaffApiTest extends TestCase
{
    use RefreshDatabase;

    public function test_staff_routes_require_authentication(): void
    {
        $this->getJson('/api/v1/staff')->assertUnauthorized();
        $this->postJson('/api/v1/staff', [])->assertUnauthorized();
    }

    public function test_cashiers_cannot_manage_staff(): void
    {
        $this->authenticate(UserRole::Cashier);

        $this->getJson('/api/v1/staff')->assertForbidden();
    }

    public function test_staff_can_view_only_their_own_profile(): void
    {
        $shop = $this->authenticate(UserRole::Cashier);
        $user = auth()->user();
        StaffProfile::create(['user_id' => $user->id, 'employee_code' => 'EMP-001']);
        $otherUser = User::factory()->create(['shop_id' => $shop->id]);
        StaffProfile::create(['user_id' => $otherUser->id, 'employee_code' => 'EMP-002']);

        $this->getJson('/api/v1/staff/me')
            ->assertOk()
            ->assertJsonPath('data.id', $user->id)
            ->assertJsonPath('data.staff_profile.employee_code', 'EMP-001')
            ->assertJsonMissing(['employee_code' => 'EMP-002']);
    }

    public function test_staff_without_a_profile_gets_not_found_from_self_endpoint(): void
    {
        $this->authenticate(UserRole::Cashier);

        $this->getJson('/api/v1/staff/me')->assertNotFound();
    }

    public function test_store_creates_a_profile_for_an_existing_user_in_the_current_shop(): void
    {
        $shop = $this->authenticate();
        $staff = User::factory()->create(['shop_id' => $shop->id, 'role' => UserRole::Cashier]);

        $this->postJson('/api/v1/staff', [
            'user_id' => $staff->id,
            'employee_code' => 'EMP-001',
            'hire_date' => '2026-01-15',
            'hourly_rate' => '8.50',
            'emergency_contact' => '012345678',
        ])
            ->assertCreated()
            ->assertJsonPath('data.id', $staff->id)
            ->assertJsonPath('data.staff_profile.employee_code', 'EMP-001');

        $this->assertDatabaseHas('staff_profiles', [
            'user_id' => $staff->id,
            'employee_code' => 'EMP-001',
            'hourly_rate' => '8.50',
        ]);
    }

    public function test_store_rejects_a_user_from_another_shop(): void
    {
        $this->authenticate();
        $otherShop = Shop::create(['name' => 'Other Shop', 'code' => 'OTHER']);
        $foreignUser = User::factory()->create(['shop_id' => $otherShop->id]);

        $this->postJson('/api/v1/staff', [
            'user_id' => $foreignUser->id,
            'employee_code' => 'EMP-404',
        ])->assertNotFound();

        $this->assertDatabaseMissing('staff_profiles', ['user_id' => $foreignUser->id]);
    }

    public function test_store_rejects_duplicate_employee_codes_and_duplicate_profiles(): void
    {
        $shop = $this->authenticate();
        $staff = User::factory()->create(['shop_id' => $shop->id]);
        StaffProfile::create(['user_id' => $staff->id, 'employee_code' => 'EMP-001']);

        $other = User::factory()->create(['shop_id' => $shop->id]);

        $this->postJson('/api/v1/staff', ['user_id' => $other->id, 'employee_code' => 'EMP-001'])
            ->assertUnprocessable()
            ->assertJsonValidationErrors('employee_code');

        $this->postJson('/api/v1/staff', ['user_id' => $staff->id, 'employee_code' => 'EMP-002'])
            ->assertUnprocessable()
            ->assertJsonValidationErrors('user_id');
    }

    public function test_index_lists_only_current_shop_users_with_their_profiles(): void
    {
        $shop = $this->authenticate();
        $withProfile = User::factory()->create(['shop_id' => $shop->id, 'name' => 'Has Profile']);
        StaffProfile::create(['user_id' => $withProfile->id, 'employee_code' => 'EMP-001']);
        User::factory()->create(['shop_id' => $shop->id, 'name' => 'No Profile']);
        User::factory()->create(['shop_id' => $shop->id, 'name' => 'Inactive', 'is_active' => false]);

        $otherShop = Shop::create(['name' => 'Other Shop', 'code' => 'OTHER']);
        User::factory()->create(['shop_id' => $otherShop->id, 'name' => 'Foreign']);

        $this->getJson('/api/v1/staff')
            ->assertOk()
            ->assertJsonCount(3, 'data')
            ->assertJsonPath('data.0.name', 'Has Profile')
            ->assertJsonPath('data.0.staff_profile.employee_code', 'EMP-001')
            ->assertJsonPath('data.1.staff_profile', null);

        $this->getJson('/api/v1/staff?include_inactive=1')
            ->assertOk()
            ->assertJsonCount(4, 'data');
    }

    public function test_update_changes_the_users_staff_profile(): void
    {
        $shop = $this->authenticate();
        $staff = User::factory()->create(['shop_id' => $shop->id]);
        StaffProfile::create(['user_id' => $staff->id, 'employee_code' => 'EMP-001']);

        $this->patchJson("/api/v1/staff/{$staff->id}", [
            'hourly_rate' => '10.25',
            'emergency_contact' => '999',
        ])
            ->assertOk()
            ->assertJsonPath('data.staff_profile.hourly_rate', '10.25');

        $this->assertDatabaseHas('staff_profiles', [
            'user_id' => $staff->id,
            'hourly_rate' => '10.25',
            'emergency_contact' => '999',
        ]);
    }

    public function test_destroy_deactivates_the_user_but_keeps_the_profile(): void
    {
        $shop = $this->authenticate();
        $admin = auth()->user();
        $staff = User::factory()->create(['shop_id' => $shop->id, 'is_active' => true]);
        StaffProfile::create(['user_id' => $staff->id, 'employee_code' => 'EMP-001']);

        $token = $staff->createToken('test')->plainTextToken;

        // Control: the staff token authenticates before deactivation.
        $this->app['auth']->forgetGuards();
        $this->withHeader('Authorization', 'Bearer '.$token)
            ->getJson('/api/v1/staff/me')
            ->assertOk();
        $this->app['auth']->forgetGuards();

        Sanctum::actingAs($admin);
        $this->deleteJson("/api/v1/staff/{$staff->id}")->assertNoContent();

        $this->assertDatabaseHas('users', ['id' => $staff->id, 'is_active' => false]);
        $this->assertDatabaseHas('staff_profiles', ['user_id' => $staff->id, 'employee_code' => 'EMP-001']);

        // The deactivated account's token must stop working immediately.
        $this->app['auth']->forgetGuards();
        $this->withHeader('Authorization', 'Bearer '.$token)
            ->getJson('/api/v1/staff/me')
            ->assertUnauthorized();
    }

    public function test_destroy_refuses_to_deactivate_your_own_account(): void
    {
        $this->authenticate();
        $admin = auth()->user();

        $this->deleteJson("/api/v1/staff/{$admin->id}")
            ->assertUnprocessable()
            ->assertJson(['message' => 'You cannot deactivate your own account.']);

        $this->assertDatabaseHas('users', ['id' => $admin->id, 'is_active' => true]);
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
