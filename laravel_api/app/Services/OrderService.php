<?php

namespace App\Services;

use App\Enums\OrderStatus;
use App\Enums\PaymentStatus;
use App\Enums\StockMovementType;
use App\Models\Ingredient;
use App\Models\Order;
use App\Models\Payment;
use App\Models\ProductIngredient;
use App\Models\ProductVariant;
use App\Models\User;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;

final class OrderService
{
    public function __construct(private readonly InventoryService $inventory) {}

    /**
     * Create an order plus its item snapshots and history row in one transaction.
     *
     * @param  array{type: string, items: array<int, array{product_variant_id: int, quantity: int}>, discount_amount?: string|null, payment_method?: string|null, notes?: string|null}  $data
     */
    public function create(array $data, User $user): Order
    {
        return DB::transaction(function () use ($data, $user): Order {
            $requestedItems = collect($data['items'])
                ->groupBy('product_variant_id')
                ->map(fn ($lines, $variantId) => [
                    'product_variant_id' => (int) $variantId,
                    'quantity' => (int) $lines->sum('quantity'),
                ])
                ->values();

            $variants = ProductVariant::query()
                ->with('product')
                ->whereIn('id', $requestedItems->pluck('product_variant_id'))
                ->where('is_available', true)
                ->whereHas('product', fn ($query) => $query
                    ->where('shop_id', $user->shop_id)
                    ->where('is_available', true))
                ->get()
                ->keyBy('id');

            abort_if($variants->count() !== $requestedItems->count(), 422,
                'One or more product variants are unavailable.');

            $subtotal = '0.00';
            $items = [];
            foreach ($requestedItems as $input) {
                $variant = $variants[$input['product_variant_id']];
                $lineTotal = bcmul((string) $variant->price, (string) $input['quantity'], 2);
                $subtotal = bcadd($subtotal, $lineTotal, 2);
                $items[] = [
                    'product_variant_id' => $variant->id,
                    'product_name' => $variant->product->name,
                    'variant_name' => $variant->name,
                    'quantity' => $input['quantity'],
                    'unit_price' => (string) $variant->price,
                    'line_total' => $lineTotal,
                ];
            }

            $discount = $this->boundedDiscount($data['discount_amount'] ?? null, $subtotal);
            $taxable = bcsub($subtotal, $discount, 2);
            // bcmul truncates; adding half a cent first gives the doc's round-half-up.
            $tax = bcadd(bcmul($taxable, bcdiv((string) $user->shop->tax_rate, '100', 6), 6), '0.005', 2);

            $order = $user->shop->orders()->create([
                'user_id' => $user->id,
                // Random suffix keeps same-millisecond orders apart; the unique
                // (shop_id, order_number) index is the final guarantee.
                'order_number' => 'BB-'.now()->format('YmdHisv').Str::upper(Str::random(4)),
                'type' => $data['type'],
                'status' => OrderStatus::Pending,
                'payment_method' => $data['payment_method'] ?? null,
                'payment_status' => PaymentStatus::Unpaid,
                'subtotal' => $subtotal,
                'discount_amount' => $discount,
                'tax_amount' => $tax,
                'total_amount' => bcadd($taxable, $tax, 2),
                'notes' => $data['notes'] ?? null,
            ]);

            $order->items()->createMany($items);
            $order->statusHistories()->create([
                'user_id' => $user->id,
                'from_status' => null,
                'to_status' => OrderStatus::Pending,
            ]);

            return $order->load('items');
        });
    }

    /**
     * Move the order through the allowed status graph. Completing an order
     * deducts its recipe ingredients; cancelling never touches stock.
     */
    public function updateStatus(Order $order, OrderStatus $status, User $user, ?string $note = null): Order
    {
        return DB::transaction(function () use ($order, $status, $user, $note): Order {
            $order = Order::query()->whereKey($order->id)->lockForUpdate()->firstOrFail();
            $from = $order->status;

            abort_unless($from->canTransitionTo($status), 409,
                "An order cannot move from {$from->value} to {$status->value}.");

            abort_if($status === OrderStatus::Cancelled && $order->payment_status === PaymentStatus::Paid, 409,
                'A paid order cannot be cancelled.');

            if ($status === OrderStatus::Completed) {
                $this->deductStock($order, $user);
            }

            $order->update([
                'status' => $status,
                'completed_at' => $status === OrderStatus::Completed ? now() : $order->completed_at,
                'cancelled_at' => $status === OrderStatus::Cancelled ? now() : $order->cancelled_at,
            ]);

            $order->statusHistories()->create([
                'user_id' => $user->id,
                'from_status' => $from,
                'to_status' => $status,
                'note' => $note,
            ]);

            return $order->refresh()->load(['items', 'statusHistories']);
        });
    }

    /**
     * Record the full order total as paid. Partial payments are out of scope,
     * so the amount always comes from the order, never the request.
     *
     * @param  array{method: string, transaction_reference?: string|null}  $data
     */
    public function pay(Order $order, array $data): Payment
    {
        return DB::transaction(function () use ($order, $data): Payment {
            $order = Order::query()->whereKey($order->id)->lockForUpdate()->firstOrFail();

            abort_if($order->payment_status === PaymentStatus::Paid, 409, 'This order is already paid.');
            abort_if($order->status === OrderStatus::Cancelled, 409, 'A cancelled order cannot be paid.');

            $payment = $order->payments()->create([
                'method' => $data['method'],
                'status' => PaymentStatus::Paid,
                'amount' => $order->total_amount,
                'transaction_reference' => $data['transaction_reference'] ?? null,
                'paid_at' => now(),
            ]);

            // Cached summary columns move only here, in the same transaction as the ledger row.
            $order->update([
                'payment_status' => PaymentStatus::Paid,
                'payment_method' => $data['method'],
                'paid_at' => now(),
            ]);

            return $payment;
        });
    }

    private function deductStock(Order $order, User $user): void
    {
        $items = $order->items()->get(['product_variant_id', 'quantity']);
        $recipes = ProductIngredient::query()
            ->whereIn('product_variant_id', $items->pluck('product_variant_id')->filter())
            ->get(['product_variant_id', 'ingredient_id', 'quantity']);

        $consumption = [];
        foreach ($recipes as $recipe) {
            $sold = $items->where('product_variant_id', $recipe->product_variant_id)->sum('quantity');
            $used = bcmul((string) $recipe->quantity, (string) $sold, 3);
            $consumption[$recipe->ingredient_id] = bcadd($consumption[$recipe->ingredient_id] ?? '0.000', $used, 3);
        }

        // Sort so concurrent completions lock ingredients in the same order.
        ksort($consumption);

        // Recipes can outlive a soft-deleted ingredient, so include trashed rows.
        $ingredients = Ingredient::withTrashed()
            ->whereIn('id', array_keys($consumption))
            ->get()
            ->keyBy('id');

        foreach ($consumption as $ingredientId => $quantity) {
            $this->inventory->record($user, $ingredients[$ingredientId], [
                'type' => StockMovementType::OrderConsumption->value,
                'quantity' => $quantity,
                'reference_type' => 'order',
                'reference_id' => $order->id,
                'notes' => 'Order '.$order->order_number,
            ]);
        }
    }

    private function boundedDiscount(?string $amount, string $subtotal): string
    {
        $discount = bcadd((string) ($amount ?? '0'), '0', 2);

        return bccomp($discount, $subtotal, 2) > 0 ? $subtotal : $discount;
    }
}
