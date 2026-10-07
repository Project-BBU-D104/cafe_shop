<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class StoreIngredientRequest extends FormRequest
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
            'name' => ['required', 'string', 'max:255', Rule::unique('ingredients', 'name')->where('shop_id', $this->user()->shop_id)],
            'unit' => ['required', 'string', 'max:32'],
            'current_stock' => ['sometimes', 'numeric', 'decimal:0,3', 'between:0,999999999.999'],
            'minimum_stock' => ['sometimes', 'numeric', 'decimal:0,3', 'between:0,999999999.999'],
            'cost_per_unit' => ['sometimes', 'numeric', 'decimal:0,4', 'between:0,99999999.9999'],
            'is_active' => ['sometimes', 'boolean'],
        ];
    }
}
