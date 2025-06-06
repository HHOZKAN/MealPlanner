<?php

use App\Http\Controllers\Api\Participant\ParticipantController;
use App\Http\Controllers\Api\Participant\InvitationController;
use Illuminate\Support\Facades\Route;

// Routes de base des participants
Route::get('{event}/participants', [ParticipantController::class, 'index']);
Route::put('participants/{participant}/respond', [ParticipantController::class, 'respond']);
Route::delete('participants/{participant}', [ParticipantController::class, 'destroy']);
Route::post('participants/accept-invitation', [ParticipantController::class, 'acceptInvitation']);

// Routes des invitations
Route::post('{event}/participants/invite', [InvitationController::class, 'invite']);
Route::get('{event}/participants/share-link', [InvitationController::class, 'generateShareableLink']);
Route::post('participants/validate-token', [InvitationController::class, 'validateToken']);
