<?php

namespace App\Http\Controllers\Api\V1;

use App\Enums\UserRole;
use App\Http\Controllers\Controller;
use App\Http\Requests\CloseShiftRequest;
use App\Http\Requests\StartShiftRequest;
use App\Http\Resources\ShiftResource;
use App\Models\Shift;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;
use Illuminate\Support\Facades\DB;

class ShiftController extends Controller
{
    public function index(Request $request): AnonymousResourceCollection
    {
        return ShiftResource::collection(
            Shift::query()
                ->where('shop_id', $request->user()->shop_id)
                ->orderByDesc('started_at')
                ->paginate()
        );
    }

    public function start(StartShiftRequest $request): JsonResponse
    {
        $user = $request->user();
        abort_unless($user->shop_id !== null, 403, 'Your account is not associated with a shop.');

        $shift = DB::transaction(function () use ($request, $user): Shift {
            $user->newQuery()->whereKey($user->id)->lockForUpdate()->firstOrFail();

            abort_if(
                Shift::query()->where('user_id', $user->id)->whereNull('ended_at')->exists(),
                409,
                'You already have an open shift.'
            );

            return Shift::create([
                ...$request->validated(),
                'shop_id' => $user->shop_id,
                'user_id' => $user->id,
                'started_at' => now(),
            ]);
        });

        return (new ShiftResource($shift))->response()->setStatusCode(201);
    }

    public function close(CloseShiftRequest $request, int $shift): ShiftResource
    {
        $user = $request->user();
        $shift = DB::transaction(function () use ($request, $user, $shift): Shift {
            $shift = Shift::query()
                ->where('shop_id', $user->shop_id)
                ->when($user->role === UserRole::Cashier, fn ($query) => $query->where('user_id', $user->id))
                ->lockForUpdate()
                ->findOrFail($shift);

            abort_if($shift->ended_at !== null, 409, 'This shift is already closed.');

            $shift->update([
                'closing_cash' => $request->validated('closing_cash'),
                'ended_at' => now(),
            ]);

            return $shift;
        });

        return new ShiftResource($shift);
    }
}
