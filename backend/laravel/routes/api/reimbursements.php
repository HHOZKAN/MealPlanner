<?php

use App\Http\Controllers\Api\Reimbursement\ReimbursementController;
use Illuminate\Support\Facades\Route;

// Routes des remboursements
Route::post('{event}/reimbursements/mark-paid', [ReimbursementController::class, 'markAsPaid']);
Route::get('{event}/reimbursements/history', [ReimbursementController::class, 'getPaidHistory']);
