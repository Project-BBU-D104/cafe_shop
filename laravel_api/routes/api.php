<?php

use App\Http\Controllers\Api\V1\AuthController;
use App\Http\Controllers\Api\V1\CategoryController;
use App\Http\Controllers\Api\V1\IngredientController;
use App\Http\Controllers\Api\V1\InventoryMovementController;
use App\Http\Controllers\Api\V1\ProductController;
use App\Http\Controllers\Api\V1\ProductIngredientController;
use App\Http\Controllers\Api\V1\ProductVariantController;
use App\Http\Controllers\Api\V1\ShiftController;
use App\Http\Controllers\Api\V1\StaffController;
use App\Http\Controllers\Api\V1\UserController;
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
        // Cashiers need the menu to take orders, so category/product reads stay open
        Route::apiResource('categories', CategoryController::class)->only(['index', 'show']);
        Route::apiResource('products', ProductController::class)->only(['index', 'show']);

        Route::middleware('role:owner,admin,manager')->group(function (): void {
            // index/show are registered open above; re-registering them here would
            // replace those routes (same method+URI) and lock cashiers out of the menu.
            Route::apiResource('categories', CategoryController::class)->except(['index', 'show']);
            Route::apiResource('products', ProductController::class)->except(['index', 'show']);
            Route::apiResource('products.variants', ProductVariantController::class);
            Route::get('variants/{variant}/ingredients', [ProductIngredientController::class, 'index']);
            Route::post('variants/{variant}/ingredients', [ProductIngredientController::class, 'store']);
            Route::patch('variants/{variant}/ingredients/{ingredient}', [ProductIngredientController::class, 'update']);
            Route::delete('variants/{variant}/ingredients/{ingredient}', [ProductIngredientController::class, 'destroy']);
            Route::apiResource('ingredients', IngredientController::class);
            Route::post('ingredients/{ingredient}/movements', [InventoryMovementController::class, 'store'])->whereNumber('ingredient');
            Route::get('inventory/movements', [InventoryMovementController::class, 'index']);
        });
        // Owners and admins can manage all staff; authenticated staff can view only their own profile.
        Route::get('staff/me', [StaffController::class, 'me']);
        Route::apiResource('staff', StaffController::class)
            ->except(['show'])
            ->middleware('role:owner,admin');
        // Owners and admins can create users (e.g. to onboard staff) in their own shop only.
        Route::post('users', [UserController::class, 'store'])->middleware('role:owner,admin');

        Route::post('shifts/start', [ShiftController::class, 'start'])->middleware('role:cashier,manager');
        Route::post('shifts/{shift}/close', [ShiftController::class, 'close'])->middleware('role:cashier,manager');
        Route::get('shifts', [ShiftController::class, 'index'])->middleware('role:owner,admin,manager');
    });
});
