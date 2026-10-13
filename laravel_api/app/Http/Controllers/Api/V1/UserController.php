<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Requests\StoreUserRequest;
use App\Http\Resources\UserResource;
use App\Models\User;
use Illuminate\Http\JsonResponse;

class UserController extends Controller
{
    public function store(StoreUserRequest $request): JsonResponse
    {
        // The hashed cast on User::$password hashes the plain password on write.
        $user = User::create([
            ...$request->validated(),
            'shop_id' => $request->user()->shop_id,
            'is_active' => true,
        ]);

        return (new UserResource($user))
            ->response()
            ->setStatusCode(201);
    }
}
