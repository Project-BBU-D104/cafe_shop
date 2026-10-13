<?php

namespace Tests\Feature\Api\V1;

use App\Enums\UserRole;
use App\Models\Shop;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Hash;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class UsersApiTest extends TestCase
{
    use RefreshDatabase;

    public function test_user_creation_requires_authentication(): void
    {
        $this->postJson('/api/v1/users', [])->assertUnauthorized();
    }

    public function test_cashiers_cannot_create_users(): void
    {
        $this->authenticate(UserRole::Cashier);

        $this->postJson('/api/v1/users', $this->validData())->assertForbidden();
    }

    public function test_admin_can_create_a_user_in_their_own_shop(): void
    {
        $shop = $this->authenticate();

        $response = $this->postJson('/api/v1/users', $this->validData(['email' => 'mia@cafe.local']))
            ->assertCreated()
            ->assertJsonPath('data.shop_id', $shop->id)
            ->assertJsonPath('data.name', 'Mia Staff')
            ->assertJsonPath('data.email', 'mia@cafe.local')
            ->assertJsonPath('data.role', 'cashier')
            ->assertJsonPath('data.is_active', true);

        $user = User::firstWhere('email', 'mia@cafe.local');
        $this->assertNotNull($user);
        $this->assertSame($response->json('data.id'), $user->id);
        $this->assertTrue(Hash::check('password123', $user->password));
    }

    public function test_owner_can_create_an_admin(): void
    {
        $shop = $this->authenticate(UserRole::Owner);

        $this->postJson('/api/v1/users', $this->validData(['email' => 'sam@cafe.local', 'role' => 'admin']))
            ->assertCreated()
            ->assertJsonPath('data.shop_id', $shop->id)
            ->assertJsonPath('data.role', 'admin');
    }

    public function test_required_fields_are_validated(): void
    {
        $this->authenticate();

        $this->postJson('/api/v1/users', [])
            ->assertUnprocessable()
            ->assertJsonValidationErrors(['name', 'email', 'password', 'role']);
    }

    public function test_email_must_be_unique(): void
    {
        $shop = $this->authenticate();
        User::factory()->create(['shop_id' => $shop->id, 'email' => 'taken@cafe.local']);

        $this->postJson('/api/v1/users', $this->validData(['email' => 'taken@cafe.local']))
            ->assertUnprocessable()
            ->assertJsonValidationErrors('email');
    }

    public function test_password_must_be_at_least_eight_characters_and_confirmed(): void
    {
        $this->authenticate();

        $this->postJson('/api/v1/users', $this->validData(['password' => 'short', 'password_confirmation' => 'short']))
            ->assertUnprocessable()
            ->assertJsonValidationErrors('password');

        $this->postJson('/api/v1/users', $this->validData(['password' => 'password123', 'password_confirmation' => 'different123']))
            ->assertUnprocessable()
            ->assertJsonValidationErrors('password');
    }

    public function test_owner_role_cannot_be_assigned(): void
    {
        $this->authenticate();

        $this->postJson('/api/v1/users', $this->validData(['role' => 'owner']))
            ->assertUnprocessable()
            ->assertJsonValidationErrors('role');

        $this->postJson('/api/v1/users', $this->validData(['role' => 'janitor']))
            ->assertUnprocessable()
            ->assertJsonValidationErrors('role');
    }

    public function test_shop_id_must_match_the_requesters_shop(): void
    {
        $this->authenticate();
        $otherShop = Shop::create(['name' => 'Other Shop', 'code' => 'OTHER']);

        $this->postJson('/api/v1/users', $this->validData(['email' => 'foreign@cafe.local', 'shop_id' => $otherShop->id]))
            ->assertUnprocessable()
            ->assertJsonValidationErrors('shop_id');

        $this->assertDatabaseMissing('users', ['email' => 'foreign@cafe.local']);
    }

    /**
     * @return array<string, string>
     */
    private function validData(array $overrides = []): array
    {
        return array_merge([
            'name' => 'Mia Staff',
            'email' => fake()->unique()->safeEmail(),
            'password' => 'password123',
            'password_confirmation' => 'password123',
            'role' => 'cashier',
        ], $overrides);
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
