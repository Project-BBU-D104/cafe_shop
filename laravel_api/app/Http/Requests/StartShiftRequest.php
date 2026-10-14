<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class StartShiftRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'opening_cash' => ['required', 'numeric', 'decimal:0,2', 'min:0'],
            'notes' => ['sometimes', 'nullable', 'string', 'max:1000'],
        ];
    }
}
