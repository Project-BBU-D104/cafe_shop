<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

#[Fillable(['user_id', 'employee_code', 'hire_date', 'hourly_rate', 'emergency_contact'])]
class StaffProfile extends Model
{
    protected function casts(): array
    {
        return [
            'hire_date' => 'date',
            'hourly_rate' => 'decimal:2',
        ];
    }

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }
}
