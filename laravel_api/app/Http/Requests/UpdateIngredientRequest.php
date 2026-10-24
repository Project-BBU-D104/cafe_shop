<?php

namespace App\Http\Requests;

class UpdateIngredientRequest extends StoreIngredientRequest
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
        $rules = $this->ingredientRules($this->route('ingredient'));
        unset($rules['current_stock']);

        return $rules;
    }
}
