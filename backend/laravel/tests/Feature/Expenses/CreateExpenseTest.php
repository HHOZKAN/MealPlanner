<?php

namespace Tests\Feature\Expenses;

use Tests\TestCase;
use App\Models\User;
use App\Models\Event;
use App\Models\Ingredient;
use App\Models\Participant;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Foundation\Testing\WithFaker;

class CreateExpenseTest extends TestCase
{
    use RefreshDatabase, WithFaker;

    private User $organizer;
    private User $participant1;
    private User $participant2;
    private Event $event;
    private Ingredient $ingredient;

    protected function setUp(): void
    {
        parent::setUp();

        // Créer l'organisateur
        $this->organizer = User::factory()->create();

        // Créer les participants
        $this->participant1 = User::factory()->create();
        $this->participant2 = User::factory()->create();

        // Créer l'événement
        $this->event = Event::factory()->create([
            'organizer_id' => $this->organizer->id
        ]);

        // Ajouter les participants à l'événement
        Participant::create([
            'event_id' => $this->event->id,
            'user_id' => $this->participant1->id,
            'status' => 'accepted'
        ]);
        Participant::create([
            'event_id' => $this->event->id,
            'user_id' => $this->participant2->id,
            'status' => 'accepted'
        ]);

        // Créer un ingrédient pour l'événement
        $this->ingredient = Ingredient::factory()->create([
            'event_id' => $this->event->id,
            'name' => 'Test Ingredient',
            'quantity' => 1,
            'unit' => 'piece'
        ]);
    }

    public function test_organizer_can_create_expense()
    {
        $expenseData = [
            'ingredient_id' => $this->ingredient->id,
            'payer_id' => $this->participant1->id,
            'amount' => 30.00,
            'description' => 'Test expense',
            'shares' => [
                $this->organizer->id => 10.00,
                $this->participant1->id => 10.00,
                $this->participant2->id => 10.00
            ]
        ];

        $response = $this->actingAs($this->organizer)
            ->postJson("/api/events/{$this->event->id}/expenses", $expenseData);

        $response->assertStatus(201)
            ->assertJsonStructure([
                'status',
                'message',
                'data' => [
                    'id',
                    'event_id',
                    'ingredient_id',
                    'payer_id',
                    'amount',
                    'description',
                    'shares'
                ]
            ]);

        $this->assertDatabaseHas('expenses', [
            'event_id' => $this->event->id,
            'ingredient_id' => $this->ingredient->id,
            'payer_id' => $this->participant1->id,
            'amount' => 30.00
        ]);

        // Vérifier que les parts ont été créées
        foreach ($expenseData['shares'] as $userId => $amount) {
            $this->assertDatabaseHas('expense_shares', [
                'user_id' => $userId,
                'amount' => $amount
            ]);
        }
    }

    public function test_participant_can_create_expense()
    {
        $expenseData = [
            'ingredient_id' => $this->ingredient->id,
            'payer_id' => $this->participant1->id,
            'amount' => 30.00,
            'description' => 'Test expense',
            'shares' => [
                $this->organizer->id => 10.00,
                $this->participant1->id => 10.00,
                $this->participant2->id => 10.00
            ]
        ];

        $response = $this->actingAs($this->participant1)
            ->postJson("/api/events/{$this->event->id}/expenses", $expenseData);

        $response->assertStatus(201);
    }

    public function test_non_participant_cannot_create_expense()
    {
        $nonParticipant = User::factory()->create();

        $expenseData = [
            'ingredient_id' => $this->ingredient->id,
            'payer_id' => $this->participant1->id,
            'amount' => 30.00,
            'description' => 'Test expense',
            'shares' => [
                $this->organizer->id => 10.00,
                $this->participant1->id => 10.00,
                $this->participant2->id => 10.00
            ]
        ];

        $response = $this->actingAs($nonParticipant)
            ->postJson("/api/events/{$this->event->id}/expenses", $expenseData);

        $response->assertStatus(403);
    }

    public function test_expense_validation()
    {
        $invalidExpenseData = [
            'ingredient_id' => 999999, // ID inexistant
            'payer_id' => 999999, // ID inexistant
            'amount' => -10.00, // Montant négatif
            'shares' => [] // Aucune part
        ];

        $response = $this->actingAs($this->organizer)
            ->postJson("/api/events/{$this->event->id}/expenses", $invalidExpenseData);

        $response->assertStatus(422)
            ->assertJsonValidationErrors(['ingredient_id', 'payer_id', 'amount', 'shares']);
    }

    public function test_shares_total_must_equal_amount()
    {
        $expenseData = [
            'ingredient_id' => $this->ingredient->id,
            'payer_id' => $this->participant1->id,
            'amount' => 30.00,
            'description' => 'Test expense',
            'shares' => [
                $this->organizer->id => 5.00,
                $this->participant1->id => 5.00,
                $this->participant2->id => 5.00
            ] // Total des parts (15.00) ne correspond pas au montant total (30.00)
        ];

        $response = $this->actingAs($this->organizer)
            ->postJson("/api/events/{$this->event->id}/expenses", $expenseData);

        $response->assertStatus(422);
    }
}
