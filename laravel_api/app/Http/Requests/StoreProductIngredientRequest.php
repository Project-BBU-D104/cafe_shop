<?php

namespace App\Http\Requests;

use App\Models\Ingredient;
use Closure;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class StoreProductIngredientRequest extends FormRequest
{
    /**
     * Determine if the user is authorized to make this request.
     */
    public function authorize(): bool
    {
        return true;
    }

    /**
     * Get the validation rules that apply to the request.
     *
     * @return array<string, array<mixed>|string>
     */
    public function rules(): array
    {
        return [
            'ingredient_id' => array_merge([
                Rule::requiredIf($this->isMethod('post')),
                'integer',
                Rule::exists('ingredients', 'id')->where('shop_id', $this->user()->shop_id),
                // The controller ignores ingredient_id on PATCH; the unique rule would
                // then reject the row being updated against itself.
            ], $this->isMethod('post')
                ? [Rule::unique('product_ingredients', 'ingredient_id')->where('product_variant_id', $this->route('variant'))]
                : []),
            'quantity' => [
                Rule::requiredIf($this->isMethod('post')),
                'numeric',
                'decimal:0,3',
                'between:0.001,999999999.999',
            ],
            // The recipe unit is pinned to the ingredient's stock unit so stock
            // deduction stays a plain multiply instead of a unit conversion.
            'unit' => [
                'sometimes',
                'required',
                'string',
                'max:32',
                function (string $attribute, mixed $value, Closure $fail): void {
                    $ingredient = $this->targetIngredient();

                    if ($ingredient !== null && $value !== $ingredient->unit) {
                        $fail("The unit must match the ingredient unit ({$ingredient->unit}).");
                    }
                },
            ],
        ];
    }

    /**
     * The ingredient being added or updated: the route parameter on PATCH, or the payload on POST.
     */
    private function targetIngredient(): ?Ingredient
    {
        $ingredientId = $this->route('ingredient') ?? $this->input('ingredient_id');

        return $ingredientId === null ? null : Ingredient::query()
            ->where('shop_id', $this->user()->shop_id)
            ->find($ingredientId);
    }
}
