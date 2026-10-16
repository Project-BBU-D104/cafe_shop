<?php

namespace App\Http\Requests;

use App\Enums\StockMovementType;
use Closure;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class StoreInventoryMovementRequest extends FormRequest
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
            'type' => ['required', Rule::enum(StockMovementType::class)],
            'quantity' => $this->quantityRules(),
            'unit_cost' => ['sometimes', 'nullable', 'numeric', 'decimal:0,4', 'between:0,99999999.9999'],
            'reference_type' => ['sometimes', 'nullable', 'string', 'max:50'],
            'reference_id' => ['sometimes', 'nullable', 'integer', 'min:1'],
            'notes' => ['sometimes', 'nullable', 'string', 'max:1000'],
        ];
    }

    /**
     * @return array<int, string|Closure>
     */
    private function quantityRules(): array
    {
        if ($this->input('type') === StockMovementType::Adjustment->value) {
            // Laravel's decimal rule rejects negatives, so adjustments use an explicit signed regex.
            return [
                'required',
                'numeric',
                'regex:/^-?\d{1,9}(\.\d{1,3})?$/',
                function (string $attribute, mixed $value, Closure $fail): void {
                    if ((float) $value === 0.0) {
                        $fail('The adjustment quantity cannot be zero.');
                    }
                },
            ];
        }

        return ['required', 'numeric', 'decimal:0,3', 'between:0.001,999999999.999'];
    }
}
