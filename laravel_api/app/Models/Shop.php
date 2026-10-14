<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;

#[Fillable([
    'name',
    'code',
    'phone',
    'email',
    'address',
    'tax_rate',
    'currency',
    'receipt_footer',
    'timezone',
    'is_active',
])]
class Shop extends Model
{
    public function shifts(): HasMany
    {
        return $this->hasMany(Shift::class);
    }

    protected function casts(): array
    {
        return [
            'tax_rate' => 'decimal:2',
            'is_active' => 'boolean',
        ];
    }
}
