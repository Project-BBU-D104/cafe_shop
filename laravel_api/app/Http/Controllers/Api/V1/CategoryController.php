<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Requests\StoreCategoryRequest;
use App\Http\Requests\UpdateCategoryRequest;
use App\Http\Resources\CategoryResource;
use App\Models\Category;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;
use Illuminate\Http\Response;

class CategoryController extends Controller
{
    public function index(Request $request): AnonymousResourceCollection
    {
        $categories = Category::query()
            ->where('shop_id', $request->user()->shop_id)
            ->when(! $request->boolean('include_inactive'), fn ($query) => $query->where('is_active', true))
            ->orderBy('sort_order')
            ->orderBy('name')
            ->get();

        return CategoryResource::collection($categories);
    }

    public function store(StoreCategoryRequest $request): JsonResponse
    {
        $category = Category::create([
            ...$request->validated(),
            'shop_id' => $request->user()->shop_id,
        ]);

        return (new CategoryResource($category))
            ->response()
            ->setStatusCode(201);
    }

    public function show(Request $request, int $category): CategoryResource
    {
        return new CategoryResource($this->categoryForUser($request, $category));
    }

    public function update(UpdateCategoryRequest $request, int $category): CategoryResource
    {
        $category = $this->categoryForUser($request, $category);
        $category->update($request->validated());

        return new CategoryResource($category->refresh());
    }

    public function destroy(Request $request, int $category): Response
    {
        $this->categoryForUser($request, $category)->delete();

        return response()->noContent();
    }

    private function categoryForUser(Request $request, int $category): Category
    {
        return Category::query()
            ->where('shop_id', $request->user()->shop_id)
            ->findOrFail($category);
    }
}
