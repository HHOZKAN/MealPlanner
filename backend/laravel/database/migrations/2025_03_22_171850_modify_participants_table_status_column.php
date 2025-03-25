<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

class ModifyParticipantsTableStatusColumn extends Migration
{
    public function up()
    {
        Schema::dropIfExists('participants');

        Schema::create('participants', function (Blueprint $table) {
            $table->id();
            $table->foreignId('event_id')->constrained()->onDelete('cascade');
            $table->foreignId('user_id')->constrained();
            $table->string('status')->default('pending');
            $table->text('note')->nullable();
            $table->timestamp('responded_at')->nullable();
            $table->timestamps();
            
            $table->unique(['event_id', 'user_id']);
        });
    }

    public function down()
    {
        Schema::dropIfExists('participants');
    }
}