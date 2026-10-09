<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class StaffProfileResource extends JsonResource
{
    /**
     * Transform the resource into an array.
     *
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'employee_code' => $this->employee_code,
            'hire_date' => $this->hire_date?->toDateString(),
            'hourly_rate' => $this->hourly_rate,
            'emergency_contact' => $this->emergency_contact,
            'created_at' => $this->created_at,
            'updated_at' => $this->updated_at,
        ];
    }
}
