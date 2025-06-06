<?php

use App\Http\Controllers\Api\Ingredient\IngredientController;
use App\Http\Controllers\Api\Ingredient\IngredientAssignmentController;
use Illuminate\Support\Facades\Route;

// Routes de base des ingrédients
Route::get('{event}/ingredients', [IngredientController::class, 'index']);
Route::post('{event}/ingredients', [IngredientController::class, 'store']);
Route::get('{event}/ingredients/{ingredient}', [IngredientController::class, 'show']);
Route::put('{event}/ingredients/{ingredient}', [IngredientController::class, 'update']);
Route::delete('{event}/ingredients/{ingredient}', [IngredientController::class, 'destroy']);

// Routes des assignations d'ingrédients
Route::post('{event}/ingredients/{ingredient}/assign', [IngredientAssignmentController::class, 'assign']);
Route::get('{event}/ingredients/{ingredient}/assignments', [IngredientAssignmentController::class, 'index']);
Route::put('{event}/ingredients/{ingredient}/assignments/{assignment}', [IngredientAssignmentController::class, 'update']);
Route::delete('{event}/ingredients/{ingredient}/assignments/{assignment}', [IngredientAssignmentController::class, 'destroy']);
Route::post('{event}/ingredients/{ingredient}/assignments/{assignment}/purchased', [IngredientAssignmentController::class, 'markAsPurchased']);
