<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Requests\StoreIngredientRequest;
use App\Http\Resources\IngredientResource;
use App\Models\Ingredient;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;

class IngredientController extends Controller
{
    public function index(Request $request): AnonymousResourceCollection
    {
        $ingredients = Ingredient::query()
            ->where('shop_id', $request->user()->shop_id)
            ->when(! $request->boolean('include_inactive'), fn ($query) => $query->where('is_active', true))
            ->when($request->boolean('low_stock'), fn ($query) => $query->whereColumn('current_stock', '<=', 'minimum_stock'))
            ->orderBy('name')
            ->get();

        return IngredientResource::collection($ingredients);
    }

    public function store(StoreIngredientRequest $request): JsonResponse
    {
        $ingredient = Ingredient::create([
            ...$request->validated(),
            'shop_id' => $request->user()->shop_id,
        ]);

        return (new IngredientResource($ingredient))
            ->response()
            ->setStatusCode(201);
    }

    public function show(Ingredient $ingredient): IngredientResource
    {
        return new IngredientResource($ingredient);
    }

    public function update(StoreIngredientRequest $request, Ingredient $ingredient): IngredientResource
    {
        $ingredient->update($request->validated());

        return new IngredientResource($ingredient);
    }

}
