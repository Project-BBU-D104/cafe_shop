<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Requests\StoreStaffRequest;
use App\Http\Requests\UpdateStaffRequest;
use App\Http\Resources\StaffResource;
use App\Models\User;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;
use Illuminate\Http\Response;

class StaffController extends Controller
{
    public function me(Request $request): StaffResource
    {
        $user = $request->user()->load('staffProfile');
        abort_if($user->staffProfile === null, 404);

        return new StaffResource($user);
    }

    public function index(Request $request): AnonymousResourceCollection
    {
        $staff = User::query()
            ->where('shop_id', $request->user()->shop_id)
            ->when(! $request->boolean('include_inactive'), fn ($query) => $query->where('is_active', true))
            ->with('staffProfile')
            ->orderBy('name')
            ->get();

        return StaffResource::collection($staff);
    }

    public function store(StoreStaffRequest $request): JsonResponse
    {
        $user = User::query()
            ->where('shop_id', $request->user()->shop_id)
            ->findOrFail($request->validated('user_id'));

        $user->staffProfile()->create($request->safe()->except('user_id'));

        return (new StaffResource($user->load('staffProfile')))
            ->response()
            ->setStatusCode(201);
    }

    public function update(UpdateStaffRequest $request, int $staff): StaffResource
    {
        $user = $this->staffForUser($request, $staff);
        $profile = $user->staffProfile;
        abort_unless($profile, 404);

        $data = $request->validated();
        $user->update(collect($data)->only(['name', 'phone'])->all());
        $profile->update(collect($data)->except(['name', 'phone'])->all());

        return new StaffResource($user->load('staffProfile'));
    }

    public function destroy(Request $request, int $staff): Response
    {
        $this->staffForUser($request, $staff)->update(['is_active' => false]);

        return response()->noContent();
    }

    private function staffForUser(Request $request, int $staff): User
    {
        return User::query()
            ->where('shop_id', $request->user()->shop_id)
            ->findOrFail($staff);
    }
}
