<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Requests\StoreInventoryMovementRequest;
use App\Http\Resources\InventoryMovementResource;
use App\Models\Ingredient;
use App\Models\InventoryMovement;
use App\Services\InventoryService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;

class InventoryMovementController extends Controller
{
    public function index(Request $request): AnonymousResourceCollection
    {
        return InventoryMovementResource::collection(
            InventoryMovement::query()
                // Deleted ingredients still name their history rows.
                ->with(['ingredient' => fn ($query) => $query->withTrashed()])
                ->where('shop_id', $request->user()->shop_id)
                ->when($request->filled('ingredient_id'), fn ($query) => $query->where('ingredient_id', $request->integer('ingredient_id')))
                ->orderByDesc('created_at')
                ->orderByDesc('id')
                ->paginate(50)
        );
    }

    public function store(StoreInventoryMovementRequest $request, int $ingredient): JsonResponse
    {
        $ingredient = $this->ingredientForUser($request, $ingredient);

        $movement = app(InventoryService::class)->record($request->user(), $ingredient, $request->validated());

        return (new InventoryMovementResource($movement->load('ingredient')))
            ->response()
            ->setStatusCode(201);
    }

    private function ingredientForUser(Request $request, int $ingredient): Ingredient
    {
        return Ingredient::query()
            ->where('shop_id', $request->user()->shop_id)
            ->findOrFail($ingredient);
    }
}
