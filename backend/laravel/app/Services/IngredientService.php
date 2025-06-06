<?php

namespace App\Services;

use App\Contracts\Services\IngredientServiceInterface;
use App\DTOs\Ingredient\IngredientData;
use App\DTOs\Ingredient\AssignmentData;
use App\DTOs\Ingredient\UpdateAssignmentData;
use App\Models\Event;
use App\Models\Ingredient;
use App\Models\IngredientAssignment;
use App\ValueObjects\IngredientStatus;
use App\ValueObjects\IngredientUnit;
use Illuminate\Support\Collection;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Storage;

class IngredientService implements IngredientServiceInterface
{
    /**
     * {@inheritdoc}
     */
    public function listIngredients(Event $event): Collection
    {
        return $event->ingredients()
            ->with(['addedBy', 'assignments.user'])
            ->get()
            ->map(fn($ingredient) => $this->formatIngredient($ingredient));
    }

    /**
     * {@inheritdoc}
     */
    public function createIngredient(Event $event, IngredientData $data, int $userId): array
    {
        $ingredient = new Ingredient();
        $ingredient->event_id = $event->id;
        $ingredient->name = $data->name;
        $ingredient->quantity = $data->quantity;
        $ingredient->unit = $data->unit;
        $ingredient->estimated_price = $data->estimatedPrice;
        $ingredient->notes = $data->notes;
        $ingredient->emoji = $data->emoji ?? '🛒';
        $ingredient->added_by = $userId;
        $ingredient->status = IngredientStatus::NEEDED->value;
        $ingredient->save();

        Log::info('Ingrédient créé', [
            'ingredient_id' => $ingredient->id,
            'event_id' => $event->id,
            'created_by' => $userId
        ]);

        return $this->formatIngredient($ingredient->load(['addedBy']));
    }

    /**
     * {@inheritdoc}
     */
    public function getIngredient(Event $event, Ingredient $ingredient): array
    {
        if ($ingredient->event_id !== $event->id) {
            throw new \Exception('Ingrédient non trouvé pour cet événement');
        }

        return $this->formatIngredient($ingredient->load(['addedBy', 'assignments.user']));
    }

    /**
     * {@inheritdoc}
     */
    public function updateIngredient(Event $event, Ingredient $ingredient, IngredientData $data): array
    {
        if ($ingredient->event_id !== $event->id) {
            throw new \Exception('Ingrédient non trouvé pour cet événement');
        }

        $updateData = array_filter($data->toArray(), fn($value) => $value !== null);
        $ingredient->update($updateData);

        Log::info('Ingrédient mis à jour', [
            'ingredient_id' => $ingredient->id,
            'event_id' => $event->id,
            'updated_by' => Auth::id()
        ]);

        return $this->formatIngredient($ingredient->load(['addedBy', 'assignments.user']));
    }

    /**
     * {@inheritdoc}
     */
    public function deleteIngredient(Event $event, Ingredient $ingredient): bool
    {
        if ($ingredient->event_id !== $event->id) {
            throw new \Exception('Ingrédient non trouvé pour cet événement');
        }

        // Supprimer les assignments associés
        $ingredient->assignments()->delete();

        // Soft delete de l'ingrédient
        $ingredient->delete();

        Log::info('Ingrédient supprimé', [
            'ingredient_id' => $ingredient->id,
            'event_id' => $event->id,
            'deleted_by' => Auth::id()
        ]);

        return true;
    }

    /**
     * {@inheritdoc}
     */
    public function assignIngredient(Event $event, Ingredient $ingredient, AssignmentData $data): IngredientAssignment
    {
        if ($ingredient->event_id !== $event->id) {
            throw new \Exception('Ingrédient non trouvé pour cet événement');
        }

        // Vérifier si l'utilisateur est participant à l'événement ou organisateur
        if (!$event->participants()->where('user_id', $data->userId)->exists() && 
            $event->organizer_id !== $data->userId) {
            throw new \Exception('L\'utilisateur doit être participant à l\'événement');
        }

        // Vérifier que la quantité assignée ne dépasse pas la quantité totale
        if ($data->quantity > $ingredient->quantity) {
            throw new \Exception('La quantité assignée ne peut pas dépasser la quantité totale');
        }

        $assignment = $ingredient->assignments()->create([
            'user_id' => $data->userId,
            'quantity' => $data->quantity,
            'status' => 'pending'
        ]);

        // Mettre à jour le statut de l'ingrédient
        $ingredient->update(['status' => IngredientStatus::ASSIGNED->value]);

        Log::info('Ingrédient assigné', [
            'ingredient_id' => $ingredient->id,
            'user_id' => $data->userId,
            'quantity' => $data->quantity,
            'assigned_by' => Auth::id()
        ]);

        return $assignment->load(['user']);
    }

    /**
     * {@inheritdoc}
     */
    public function getAssignments(Event $event, Ingredient $ingredient): Collection
    {
        if ($ingredient->event_id !== $event->id) {
            throw new \Exception('Ingrédient non trouvé pour cet événement');
        }

        return $ingredient->assignments()->with('user')->get();
    }

    /**
     * {@inheritdoc}
     */
    public function updateAssignment(
        Event $event, 
        Ingredient $ingredient, 
        IngredientAssignment $assignment, 
        UpdateAssignmentData $data
    ): IngredientAssignment {
        if ($ingredient->event_id !== $event->id || $assignment->ingredient_id !== $ingredient->id) {
            throw new \Exception('Assignation non trouvée pour cet ingrédient');
        }

        $updateData = $data->toArray();

        // Gérer l'upload de l'image si présente
        if ($data->receiptImage) {
            $imageName = 'receipt_' . time() . '.jpg';
            Storage::disk('public')->put(
                'receipts/' . $imageName,
                base64_decode(explode(',', $data->receiptImage)[1])
            );
            $updateData['receipt_image'] = 'receipts/' . $imageName;
        }

        $assignment->update($updateData);

        // Si marqué comme acheté, mettre à jour le prix réel de l'ingrédient
        if ($data->status === 'purchased' && $data->pricePaid) {
            $ingredient->update([
                'actual_price' => $data->pricePaid,
                'status' => IngredientStatus::PURCHASED->value
            ]);
        }

        Log::info('Assignation mise à jour', [
            'ingredient_id' => $ingredient->id,
            'assignment_id' => $assignment->id,
            'status' => $data->status,
            'updated_by' => Auth::id()
        ]);

        return $assignment->load('user');
    }

    /**
     * {@inheritdoc}
     */
    public function formatIngredient(Ingredient $ingredient): array
    {
        return [
            'id' => $ingredient->id,
            'name' => $ingredient->name,
            'quantity' => $ingredient->quantity,
            'unit' => $ingredient->unit,
            'unit_label' => IngredientUnit::fromString($ingredient->unit)->label(),
            'estimated_price' => $ingredient->estimated_price,
            'actual_price' => $ingredient->actual_price,
            'status' => $ingredient->status,
            'status_label' => IngredientStatus::fromString($ingredient->status)->label(),
            'notes' => $ingredient->notes,
            'emoji' => $ingredient->emoji ?? '🛒',
            'added_by' => $ingredient->addedBy,
            'assignments' => $ingredient->assignments,
            'created_at' => $ingredient->created_at,
            'updated_at' => $ingredient->updated_at
        ];
    }

    /**
     * {@inheritdoc}
     */
    public function canAccessEvent(Event $event, int $userId): bool
    {
        return $event->organizer_id === $userId ||
            $event->participants()->where('user_id', $userId)->exists();
    }

    /**
     * {@inheritdoc}
     */
    public function canManageEvent(Event $event, int $userId): bool
    {
        return $event->organizer_id === $userId;
    }
}
