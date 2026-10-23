<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Requests\StoreIngredientRequest;
use App\Http\Requests\UpdateIngredientRequest;
use App\Http\Resources\IngredientResource;
use App\Models\Ingredient;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;
use Illuminate\Http\Response;

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

    public function show(Request $request, int $ingredient): IngredientResource
    {
        return new IngredientResource($this->ingredientForUser($request, $ingredient));
    }

    public function update(UpdateIngredientRequest $request, int $ingredient): IngredientResource
    {
        $ingredient = $this->ingredientForUser($request, $ingredient);
        $ingredient->update($request->validated());

        return new IngredientResource($ingredient);
    }

    public function destroy(Request $request, int $ingredient): Response
    {
        $ingredient = $this->ingredientForUser($request, $ingredient);

        // The unique index covers soft-deleted rows, so free the name for reuse.
        // mb_substr: byte-wise substr can split a multi-byte character and produce invalid UTF-8.
        $ingredient->update([
            'name' => mb_substr($ingredient->name, 0, 200).' (deleted '.$ingredient->id.')',
        ]);
        $ingredient->delete();

        return response()->noContent();
    }

    private function ingredientForUser(Request $request, int $ingredient): Ingredient
    {
        return Ingredient::query()
            ->where('shop_id', $request->user()->shop_id)
            ->findOrFail($ingredient);
    }
}
