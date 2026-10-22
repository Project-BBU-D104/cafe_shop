<?php

namespace App\Enums;

enum OrderStatus: string
{
    case Pending = 'pending';
    case Preparing = 'preparing';
    case Completed = 'completed';
    case Cancelled = 'cancelled';

    /**
     * Allowed transitions: pending → preparing → completed,
     * and pending/preparing → cancelled.
     */
    public function canTransitionTo(self $status): bool
    {
        return match ($this) {
            self::Pending => in_array($status, [self::Preparing, self::Cancelled], true),
            self::Preparing => in_array($status, [self::Completed, self::Cancelled], true),
            self::Completed, self::Cancelled => false,
        };
    }
}
