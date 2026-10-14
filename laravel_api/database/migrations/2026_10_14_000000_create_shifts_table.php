<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('shifts', function (Blueprint $table): void {
            $table->id();
            $table->foreignId('shop_id')->constrained()->restrictOnDelete();
            $table->foreignId('user_id')->constrained()->restrictOnDelete();
            $table->timestamp('started_at');
            $table->timestamp('ended_at')->nullable();
            $table->decimal('opening_cash', 12, 2);
            $table->decimal('closing_cash', 12, 2)->nullable();
            $table->text('notes')->nullable();
            $table->timestamps();
            $table->index(['shop_id', 'started_at']);
            $table->index(['user_id', 'ended_at']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('shifts');
    }
};
