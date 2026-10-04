<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Model;

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
    protected function casts(): array
    {
        return [
            'tax_rate' => 'decimal:2',
            'is_active' => 'boolean',
        ];
    }
}
