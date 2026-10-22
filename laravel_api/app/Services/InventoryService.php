<?php

namespace App\Services;

use App\Enums\StockMovementType;
use App\Models\Ingredient;
use App\Models\InventoryMovement;
use App\Models\User;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\ValidationException;

class InventoryService
{
    public function record(User $user, Ingredient $ingredient, array $data): InventoryMovement
    {
        return DB::transaction(function () use ($user, $ingredient, $data): InventoryMovement {
            // Re-read under lock so the delta applies to fresh stock. Trashed rows
            // still hold stock: recipes referencing a soft-deleted ingredient stay valid.
            $ingredient = Ingredient::withTrashed()->whereKey($ingredient->id)->lockForUpdate()->firstOrFail();

            $type = StockMovementType::from($data['type']);
            $quantity = (string) $data['quantity'];
            $delta = $type === StockMovementType::Adjustment
                ? $quantity
                : bcmul($quantity, (string) $type->sign(), 3);

            // DECIMAL(12,3) holds at most +/-999999999.999; MySQL rejects larger totals.
            $newStock = bcadd((string) $ingredient->current_stock, $delta, 3);

            if (bccomp($newStock, '-999999999.999', 3) < 0 || bccomp($newStock, '999999999.999', 3) > 0) {
                throw ValidationException::withMessages([
                    'quantity' => 'The resulting stock would exceed the supported range.',
                ]);
            }

            $ingredient->update(['current_stock' => $newStock]);

            return InventoryMovement::create([
                'shop_id' => $ingredient->shop_id,
                'ingredient_id' => $ingredient->id,
                'user_id' => $user->id,
                'type' => $type,
                'quantity' => $quantity,
                'unit_cost' => $data['unit_cost'] ?? $ingredient->cost_per_unit,
                'reference_type' => $data['reference_type'] ?? null,
                'reference_id' => $data['reference_id'] ?? null,
                'notes' => $data['notes'] ?? null,
            ]);
        });
    }
}
