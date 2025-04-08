<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up()
    {
        Schema::create('manual_prices', function (Blueprint $table) {
            $table->id();
            $table->string('product_name');
            $table->decimal('price', 10, 2);
            $table->string('store_name')->nullable();
            $table->foreignId('added_by')->constrained('users');
            $table->string('receipt_image')->nullable();
            $table->text('notes')->nullable();
            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('manual_prices');
    }
};
