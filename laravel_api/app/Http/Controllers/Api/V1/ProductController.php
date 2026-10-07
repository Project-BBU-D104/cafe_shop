<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Requests\StoreProductRequest;
use App\Http\Requests\UpdateProductRequest;
use App\Http\Resources\ProductResource;
use App\Models\Product;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;
use Illuminate\Http\Response;

class ProductController extends Controller
{
    public function index(Request $request): AnonymousResourceCollection
    {
        $products = Product::query()
            ->where('shop_id', $request->user()->shop_id)
            ->when(! $request->boolean('include_unavailable'), fn ($query) => $query->where('is_available', true))
            ->orderBy('sort_order')
            ->orderBy('name')
            ->get();

        return ProductResource::collection($products);
    }

    public function store(StoreProductRequest $request): JsonResponse
    {
        $data = $request->validated();

        if ($request->hasFile('image')) {
            $data['image_path'] = $request->file('image')->store('products', 'public');
        }

        $product = Product::create([
            ...$data,
            'shop_id' => $request->user()->shop_id,
        ]);

        return (new ProductResource($product))
            ->response()
            ->setStatusCode(201);
    }

    public function show(Request $request, int $product): ProductResource
    {
        return new ProductResource($this->productForUser($request, $product));
    }

    public function update(UpdateProductRequest $request, int $product): ProductResource
    {
        $product = $this->productForUser($request, $product);
        $data = $request->validated();

        if ($request->hasFile('image')) {
            $data['image_path'] = $request->file('image')->store('products', 'public');
        }

        $product->update($data);

        return new ProductResource($product->refresh());
    }

    public function destroy(Request $request, int $product): Response
    {
        $this->productForUser($request, $product)->delete();

        return response()->noContent();
    }

    private function productForUser(Request $request, int $product): Product
    {
        return Product::query()
            ->where('shop_id', $request->user()->shop_id)
            ->findOrFail($product);
    }
}
