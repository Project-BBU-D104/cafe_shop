<?php

namespace App\Http\Controllers\Api\V1;

use App\Enums\OrderStatus;
use App\Http\Controllers\Controller;
use App\Http\Requests\CancelOrderRequest;
use App\Http\Requests\StoreOrderRequest;
use App\Http\Requests\StorePaymentRequest;
use App\Http\Requests\UpdateOrderStatusRequest;
use App\Http\Resources\OrderResource;
use App\Http\Resources\PaymentResource;
use App\Models\Order;
use App\Services\OrderService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;
use Illuminate\Validation\Rule;

class OrderController extends Controller
{
    public function __construct(private readonly OrderService $orders) {}

    public function index(Request $request): AnonymousResourceCollection
    {
        $request->validate([
            'status' => ['nullable', Rule::enum(OrderStatus::class)],
            'from' => ['nullable', 'date'],
            'to' => ['nullable', 'date'],
        ]);

        // Dates arrive in the shop's timezone; stored timestamps are UTC.
        $timezone = $request->user()->shop?->timezone ?? config('app.timezone');
        $from = $request->filled('from') ? $request->date('from', tz: $timezone)?->startOfDay()->utc() : null;
        $to = $request->filled('to') ? $request->date('to', tz: $timezone)?->endOfDay()->utc() : null;

        return OrderResource::collection(
            Order::query()
                ->where('shop_id', $request->user()->shop_id)
                ->with('items')
                ->when($request->filled('status'), fn ($query) => $query->where('status', $request->input('status')))
                ->when($from, fn ($query) => $query->where('created_at', '>=', $from))
                ->when($to, fn ($query) => $query->where('created_at', '<=', $to))
                ->orderByDesc('id')
                ->paginate()
        );
    }

    public function store(StoreOrderRequest $request): JsonResponse
    {
        $user = $request->user();
        abort_unless($user->shop_id !== null, 403, 'Your account is not associated with a shop.');

        $order = $this->orders->create($request->validated(), $user);

        return (new OrderResource($order))->response()->setStatusCode(201);
    }

    public function show(Request $request, int $order): OrderResource
    {
        return new OrderResource(
            $this->orderForUser($request, $order)->load(['items', 'payments', 'statusHistories'])
        );
    }

    public function updateStatus(UpdateOrderStatusRequest $request, int $order): OrderResource
    {
        $order = $this->orders->updateStatus(
            $this->orderForUser($request, $order),
            OrderStatus::from($request->validated('status')),
            $request->user(),
            $request->validated('note'),
        );

        return new OrderResource($order);
    }

    public function pay(StorePaymentRequest $request, int $order): JsonResponse
    {
        $payment = $this->orders->pay($this->orderForUser($request, $order), $request->validated());

        return (new PaymentResource($payment))->response()->setStatusCode(201);
    }

    public function cancel(CancelOrderRequest $request, int $order): OrderResource
    {
        $order = $this->orders->updateStatus(
            $this->orderForUser($request, $order),
            OrderStatus::Cancelled,
            $request->user(),
            $request->validated('note'),
        );

        return new OrderResource($order);
    }

    private function orderForUser(Request $request, int $order): Order
    {
        return Order::query()
            ->where('shop_id', $request->user()->shop_id)
            ->findOrFail($order);
    }
}
