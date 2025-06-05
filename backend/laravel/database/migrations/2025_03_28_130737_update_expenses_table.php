<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::table('expenses', function (Blueprint $table) {
            // Rename paid_by to payer_id for consistency
            $table->renameColumn('paid_by', 'payer_id');
            
            // Add ingredient reference
            $table->foreignId('ingredient_id')->nullable()->constrained()->onDelete('set null');
            
            // Make description and receipt_image nullable since they're not always needed
            $table->string('description')->nullable()->change();
            $table->string('receipt_image')->nullable()->change();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('expenses', function (Blueprint $table) {
            $table->renameColumn('payer_id', 'paid_by');
            $table->dropForeign(['ingredient_id']);
            $table->dropColumn('ingredient_id');
            $table->string('description')->nullable(false)->change();
            $table->string('receipt_image')->nullable(false)->change();
        });
    }
};
