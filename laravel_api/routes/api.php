<?php

use App\Http\Controllers\Api\V1\AuthController;
use App\Http\Controllers\Api\V1\CategoryController;
use App\Http\Controllers\Api\V1\IngredientController;
use App\Http\Controllers\Api\V1\ProductController;
use App\Http\Controllers\Api\V1\ProductVariantController;
use App\Http\Controllers\Api\V1\StaffController;
use Illuminate\Support\Facades\Route;

Route::prefix('v1')->group(function (): void {
    Route::prefix('auth')->group(function (): void {
        Route::post('login', [AuthController::class, 'login']);

        Route::middleware('auth:sanctum')->group(function (): void {
            Route::post('logout', [AuthController::class, 'logout']);
            Route::get('me', [AuthController::class, 'me']);
        });
    });

    Route::middleware('auth:sanctum')->group(function (): void {
        Route::apiResource('categories', CategoryController::class);
        Route::apiResource('products', ProductController::class);
        Route::apiResource('products.variants', ProductVariantController::class);
        Route::apiResource('ingredients', IngredientController::class);
        // Owners and admins can manage all staff; authenticated staff can view only their own profile.
        Route::get('staff/me', [StaffController::class, 'me']);
        Route::apiResource('staff', StaffController::class)
            ->except(['show'])
            ->middleware('role:owner,admin');
    });
});
