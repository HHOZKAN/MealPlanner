<?php

namespace App\Contracts\Services;

use App\Models\Event;
use App\Models\Expense;
use App\Models\ExpenseShare;
use App\DTOs\Expense\ExpenseData;
use App\DTOs\Expense\ExpenseShareData;
use Illuminate\Support\Collection;

interface ExpenseServiceInterface
{
    /**
     * Récupère la liste des dépenses d'un événement
     * Inclut les informations sur le payeur, l'ingrédient et les parts
     *
     * @param Event $event L'événement concerné
     * @return Collection Collection des dépenses formatées
     */
    public function listExpenses(Event $event): Collection;

    /**
     * Crée une nouvelle dépense pour un événement
     *
     * @param Event $event L'événement concerné
     * @param ExpenseData $data Les données de la dépense
     * @param array $shares Les parts de la dépense [user_id => amount]
     * @return array La dépense créée formatée
     */
    public function createExpense(Event $event, ExpenseData $data, array $shares): array;

    /**
     * Met à jour une dépense existante
     *
     * @param Event $event L'événement concerné
     * @param Expense $expense La dépense à mettre à jour
     * @param ExpenseData $data Les nouvelles données
     * @param array $shares Les nouvelles parts [user_id => amount]
     * @return array La dépense mise à jour formatée
     */
    public function updateExpense(Event $event, Expense $expense, ExpenseData $data, array $shares): array;

    /**
     * Calcule automatiquement les dépenses basées sur les ingrédients achetés
     *
     * @param Event $event L'événement concerné
     * @return array Résultat du calcul avec les dépenses créées
     */
    public function calculateExpenses(Event $event): array;

    /**
     * Génère un résumé des dépenses pour un événement
     *
     * @param Event $event L'événement concerné
     * @param int $userId L'ID de l'utilisateur pour les parts personnelles
     * @return array Résumé complet des dépenses
     */
    public function getExpensesSummary(Event $event, int $userId): array;

    /**
     * Calcule les soldes et transactions optimisées
     *
     * @param Event $event L'événement concerné
     * @return array Soldes et remboursements optimisés
     */
    public function calculateBalances(Event $event): array;

    /**
     * Marque une part de dépense comme payée
     *
     * @param Event $event L'événement concerné
     * @param ExpenseShare $share La part à marquer comme payée
     * @param int $userId L'ID de l'utilisateur qui effectue l'action
     * @return ExpenseShare La part mise à jour
     */
    public function markShareAsPaid(Event $event, ExpenseShare $share, int $userId): ExpenseShare;

    /**
     * Formate une dépense pour la réponse API
     *
     * @param Expense $expense La dépense à formater
     * @return array La dépense formatée
     */
    public function formatExpense(Expense $expense): array;

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
