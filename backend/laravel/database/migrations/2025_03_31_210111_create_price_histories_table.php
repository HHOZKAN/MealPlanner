<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

class CreatePriceHistoriesTable extends Migration
{
    public function up()
    {
        Schema::create('stores', function (Blueprint $table) {
            $table->id();
            $table->string('name');
            $table->string('website');
            $table->string('api_key')->nullable();
            $table->boolean('is_active')->default(true);
            $table->timestamps();
        });

        Schema::create('price_histories', function (Blueprint $table) {
            $table->id();
            $table->string('product_name');
            $table->string('product_url')->nullable();
            $table->decimal('price', 10, 2);
            $table->foreignId('store_id')->constrained();
            $table->timestamp('fetched_at');
            $table->timestamps();
        });
    }

    public function down()
    {
        Schema::dropIfExists('price_histories');
        Schema::dropIfExists('stores');
    }
}