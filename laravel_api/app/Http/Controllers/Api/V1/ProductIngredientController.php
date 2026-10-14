<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Requests\StoreProductIngredientRequest;
use App\Http\Resources\ProductIngredientResource;
use App\Models\Ingredient;
use App\Models\ProductIngredient;
use App\Models\ProductVariant;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;
use Illuminate\Http\Response;

class ProductIngredientController extends Controller
{
    public function index(Request $request, int $variant): AnonymousResourceCollection
    {
        $variant = $this->variantForUser($request, $variant);

        return ProductIngredientResource::collection(
            ProductIngredient::query()
                ->where('product_variant_id', $variant->id)
                ->with('ingredient')
                ->orderBy('id')
                ->get()
        );
    }

    public function store(StoreProductIngredientRequest $request, int $variant): JsonResponse
    {
        $variant = $this->variantForUser($request, $variant);
        $ingredient = $this->ingredientForUser($request, (int) $request->validated('ingredient_id'));

        // shortcut: unit is pinned at write time; changing an ingredient's unit
        // later does not rewrite existing recipe rows. Revisit with unit conversion.
        $recipe = ProductIngredient::create([
            'product_variant_id' => $variant->id,
            'ingredient_id' => $ingredient->id,
            'quantity' => $request->validated('quantity'),
            'unit' => $ingredient->unit,
        ]);

        return (new ProductIngredientResource($recipe->load('ingredient')))
            ->response()
            ->setStatusCode(201);
    }

    public function update(StoreProductIngredientRequest $request, int $variant, int $ingredient): ProductIngredientResource
    {
        $recipe = $this->recipeForUser($request, $variant, $ingredient);
        $recipe->update($request->safe()->only(['quantity']));

        return new ProductIngredientResource($recipe->refresh()->load('ingredient'));
    }

    public function destroy(Request $request, int $variant, int $ingredient): Response
    {
        $this->recipeForUser($request, $variant, $ingredient)->delete();

        return response()->noContent();
    }

    private function variantForUser(Request $request, int $variant): ProductVariant
    {
        return ProductVariant::query()
            ->whereHas('product', fn ($query) => $query->where('shop_id', $request->user()->shop_id))
            ->findOrFail($variant);
    }

    private function recipeForUser(Request $request, int $variant, int $ingredient): ProductIngredient
    {
        return ProductIngredient::query()
            ->where('product_variant_id', $this->variantForUser($request, $variant)->id)
            ->where('ingredient_id', $ingredient)
            ->firstOrFail();
    }

    private function ingredientForUser(Request $request, int $ingredient): Ingredient
    {
        return Ingredient::query()
            ->where('shop_id', $request->user()->shop_id)
            ->findOrFail($ingredient);
    }
}
