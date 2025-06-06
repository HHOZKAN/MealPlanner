<?php

namespace App\Contracts\Services;

use App\Models\Event;
use App\Models\Ingredient;
use App\Models\IngredientAssignment;
use App\DTOs\Ingredient\IngredientData;
use App\DTOs\Ingredient\AssignmentData;
use App\DTOs\Ingredient\UpdateAssignmentData;
use Illuminate\Support\Collection;

interface IngredientServiceInterface
{
    /**
     * Récupère la liste des ingrédients d'un événement
     * Inclut les informations sur qui a ajouté l'ingrédient et les assignations
     *
     * @param Event $event L'événement concerné
     * @return Collection Collection des ingrédients formatés
     */
    public function listIngredients(Event $event): Collection;

    /**
     * Crée un nouvel ingrédient pour un événement
     *
     * @param Event $event L'événement concerné
     * @param IngredientData $data Les données de l'ingrédient
     * @param int $userId L'ID de l'utilisateur qui ajoute l'ingrédient
     * @return array L'ingrédient créé formaté
     */
    public function createIngredient(Event $event, IngredientData $data, int $userId): array;

    /**
     * Récupère un ingrédient spécifique avec ses détails
     *
     * @param Event $event L'événement concerné
     * @param Ingredient $ingredient L'ingrédient à récupérer
     * @return array L'ingrédient formaté avec ses assignations
     */
    public function getIngredient(Event $event, Ingredient $ingredient): array;

    /**
     * Met à jour un ingrédient existant
     *
     * @param Event $event L'événement concerné
     * @param Ingredient $ingredient L'ingrédient à mettre à jour
     * @param IngredientData $data Les nouvelles données
     * @return array L'ingrédient mis à jour formaté
     */
    public function updateIngredient(Event $event, Ingredient $ingredient, IngredientData $data): array;

    /**
     * Supprime un ingrédient et ses assignations
     *
     * @param Event $event L'événement concerné
     * @param Ingredient $ingredient L'ingrédient à supprimer
     * @return bool True si la suppression a réussi
     */
    public function deleteIngredient(Event $event, Ingredient $ingredient): bool;

    /**
     * Assigne un ingrédient à un utilisateur
     *
     * @param Event $event L'événement concerné
     * @param Ingredient $ingredient L'ingrédient à assigner
     * @param AssignmentData $data Les données d'assignation
     * @return IngredientAssignment L'assignation créée
     */
    public function assignIngredient(Event $event, Ingredient $ingredient, AssignmentData $data): IngredientAssignment;

    /**
     * Récupère les assignations d'un ingrédient
     *
     * @param Event $event L'événement concerné
     * @param Ingredient $ingredient L'ingrédient concerné
     * @return Collection Collection des assignations
     */
    public function getAssignments(Event $event, Ingredient $ingredient): Collection;

    /**
     * Met à jour une assignation (marquer comme acheté, ajouter reçu, etc.)
     *
     * @param Event $event L'événement concerné
     * @param Ingredient $ingredient L'ingrédient concerné
     * @param IngredientAssignment $assignment L'assignation à mettre à jour
     * @param UpdateAssignmentData $data Les nouvelles données
     * @return IngredientAssignment L'assignation mise à jour
     */
    public function updateAssignment(
        Event $event, 
        Ingredient $ingredient, 
        IngredientAssignment $assignment, 
        UpdateAssignmentData $data
    ): IngredientAssignment;

    /**
     * Formate un ingrédient pour la réponse API
     *
     * @param Ingredient $ingredient L'ingrédient à formater
     * @return array L'ingrédient formaté
     */
    public function formatIngredient(Ingredient $ingredient): array;

    /**
     * Vérifie si un utilisateur peut accéder à un événement
     *
     * @param Event $event L'événement à vérifier
     * @param int $userId L'ID de l'utilisateur
     * @return bool True si l'utilisateur peut accéder à l'événement
     */
    public function canAccessEvent(Event $event, int $userId): bool;

    /**
     * Vérifie si un utilisateur peut gérer un événement
     *
     * @param Event $event L'événement à vérifier
     * @param int $userId L'ID de l'utilisateur
     * @return bool True si l'utilisateur peut gérer l'événement
     */
    public function canManageEvent(Event $event, int $userId): bool;
}
