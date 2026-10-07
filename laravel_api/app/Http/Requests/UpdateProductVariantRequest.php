<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class UpdateProductVariantRequest extends FormRequest
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
            'name' => ['sometimes', 'required', 'string', 'max:255', Rule::unique('product_variants', 'name')->where('product_id', $this->route('product'))->ignore($this->route('variant'))],
            'price' => ['sometimes', 'required', 'numeric', 'decimal:0,2', 'min:0'],
            'is_default' => ['sometimes', 'boolean'],
            'is_available' => ['sometimes', 'boolean'],
        ];
    }
}
