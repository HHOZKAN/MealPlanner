<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\IngredientAssignment;
use App\Models\Event;
use App\Models\Ingredient;
use App\Traits\ApiResponse;

class IngredientAssignmentController extends Controller
{
    use ApiResponse;

    /**
     * Display a listing of the resource.
     */
    public function index()
    {
        //
    }

    /**
     * Store a newly created resource in storage.
     */
    public function store(Request $request)
    {
        //
    }

    /**
     * Display the specified resource.
     */
    public function show(string $id)
    {
        //
    }

    /**
     * Update the specified resource in storage.
     */
    public function update(Request $request, string $id)
    {
        //
    }

    /**
     * Remove the specified assignment.
     *
     * @param Event $event
     * @param Ingredient $ingredient
     * @param IngredientAssignment $assignment
     * @return \Illuminate\Http\JsonResponse
     */
    public function destroy(Event $event, Ingredient $ingredient, IngredientAssignment $assignment)
    {
        try {
            // Verify that the assignment belongs to the correct event and ingredient
            if ($assignment->ingredient_id !== $ingredient->id || $ingredient->event_id !== $event->id) {
                return $this->errorResponse('Assignment not found', 404);
            }

            // Check if the assignment is already purchased
            if ($assignment->status === 'purchased') {
                return $this->errorResponse('Cannot remove a purchased assignment', 400);
            }

            // Delete the assignment
            $assignment->delete();

            return $this->successResponse(null, 'Assignment removed successfully');
        } catch (\Exception $e) {
            return $this->errorResponse('Error removing assignment: ' . $e->getMessage(), 500);
        }
    }
}
