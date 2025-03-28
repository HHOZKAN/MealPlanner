<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

class UpdateIngredientAssignmentsTable extends Migration
{
    public function up()
    {
        Schema::dropIfExists('ingredient_assignments');
        
        Schema::create('ingredient_assignments', function (Blueprint $table) {
            $table->id();
            $table->foreignId('ingredient_id')->constrained()->onDelete('cascade');
            $table->foreignId('user_id')->constrained();
            $table->decimal('quantity', 8, 2);
            $table->decimal('price_paid', 8, 2)->nullable();
            $table->string('store_name')->nullable();
            $table->string('receipt_image')->nullable();
            $table->string('status')->default('pending'); // Pas de contrainte check ici
            $table->timestamps();
        });
    }

    public function down()
    {
        Schema::dropIfExists('ingredient_assignments');
    }
}