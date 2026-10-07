<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Requests\StoreProductVariantRequest;
use App\Http\Requests\UpdateProductVariantRequest;
use App\Http\Resources\ProductVariantResource;
use App\Models\Product;
use App\Models\ProductVariant;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;
use Illuminate\Http\Response;

class ProductVariantController extends Controller
{
    public function index(Request $request, int $product): AnonymousResourceCollection
    {
        $product = $this->productForUser($request, $product);

        return ProductVariantResource::collection($product->variants()->orderBy('name')->get());
    }

    public function store(StoreProductVariantRequest $request, int $product): JsonResponse
    {
        $product = $this->productForUser($request, $product);
        $variant = $product->variants()->create($request->validated());

        return (new ProductVariantResource($variant))
            ->response()
            ->setStatusCode(201);
    }

    public function show(Request $request, int $product, int $variant): ProductVariantResource
    {
        return new ProductVariantResource($this->variantForUser($request, $product, $variant));
    }

    public function update(UpdateProductVariantRequest $request, int $product, int $variant): ProductVariantResource
    {
        $variant = $this->variantForUser($request, $product, $variant);
        $variant->update($request->validated());

        return new ProductVariantResource($variant->refresh());
    }

    public function destroy(Request $request, int $product, int $variant): Response
    {
        $this->variantForUser($request, $product, $variant)->delete();

        return response()->noContent();
    }

    private function productForUser(Request $request, int $product): Product
    {
        return Product::query()
            ->where('shop_id', $request->user()->shop_id)
            ->findOrFail($product);
    }

    private function variantForUser(Request $request, int $product, int $variant): ProductVariant
    {
        return $this->productForUser($request, $product)
            ->variants()
            ->findOrFail($variant);
    }
}
