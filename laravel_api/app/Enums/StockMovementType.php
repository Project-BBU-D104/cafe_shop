<?php

namespace App\Enums;

enum StockMovementType: string
{
    case StockIn = 'stock_in';
    case StockOut = 'stock_out';
    case Adjustment = 'adjustment';
    case Waste = 'waste';
    case OrderConsumption = 'order_consumption';

    /**
     * Delta multiplier applied to the movement quantity. Adjustment is
     * handled separately (its signed quantity is the delta itself).
     */
    public function sign(): int
    {
        return $this === self::StockIn ? 1 : -1;
    }
}
