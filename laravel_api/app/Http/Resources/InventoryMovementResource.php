<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class InventoryMovementResource extends JsonResource
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
            'shop_id' => $this->shop_id,
            'ingredient_id' => $this->ingredient_id,
            'user_id' => $this->user_id,
            'type' => $this->type->value,
            'quantity' => $this->quantity,
            'unit_cost' => $this->unit_cost,
            'reference_type' => $this->reference_type,
            'reference_id' => $this->reference_id,
            'notes' => $this->notes,
            'ingredient' => new IngredientResource($this->whenLoaded('ingredient')),
            'created_at' => $this->created_at,
        ];
    }
}
