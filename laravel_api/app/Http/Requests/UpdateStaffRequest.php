<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class UpdateStaffRequest extends FormRequest
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
            'name' => ['sometimes', 'required', 'string', 'max:120'],
            'phone' => ['sometimes', 'nullable', 'string', 'max:30'],
            'employee_code' => ['sometimes', 'required', 'string', 'max:30', Rule::unique('staff_profiles', 'employee_code')->where('user_id', '!=', $this->route('staff'))],
            'hire_date' => ['sometimes', 'nullable', 'date'],
            'hourly_rate' => ['sometimes', 'nullable', 'numeric', 'decimal:0,2', 'min:0'],
            'emergency_contact' => ['sometimes', 'nullable', 'string', 'max:255'],
        ];
    }
}
