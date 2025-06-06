<?php

namespace Tests\Unit\Services;

use Tests\TestCase;
use App\Models\Event;
use App\Models\User;
use App\Models\Ingredient;
use App\Services\IngredientService;
use App\DTOs\Ingredient\IngredientData;
use App\ValueObjects\IngredientStatus;
use Illuminate\Foundation\Testing\RefreshDatabase;

class IngredientServiceTest extends TestCase
{
    use RefreshDatabase;

    private IngredientService $ingredientService;
    private User $user;
    private Event $event;

    protected function setUp(): void
    {
        parent::setUp();
        
        $this->ingredientService = app(IngredientService::class);
        
        // Créer un utilisateur et un événement pour les tests
        $this->user = User::factory()->create();
        $this->event = Event::factory()->create([
            'organizer_id' => $this->user->id
        ]);
    }

    /** @test */
    public function it_can_create_ingredient()
    {
        $data = new IngredientData(
            name: 'Test Ingredient',
            quantity: 5,
            unit: 'piece',
            estimatedPrice: 10.00,
            notes: 'Test notes',
            emoji: '🥔'
        );

        $result = $this->ingredientService->createIngredient(
            $this->event,
            $data,
            $this->user->id
        );

        $this->assertArrayHasKey('id', $result);
        $this->assertEquals('Test Ingredient', $result['name']);
        $this->assertEquals(5, $result['quantity']);
        $this->assertEquals('piece', $result['unit']);
        $this->assertEquals(10.00, $result['estimated_price']);
        $this->assertEquals('Test notes', $result['notes']);
        $this->assertEquals('🥔', $result['emoji']);
        $this->assertEquals(IngredientStatus::NEEDED->value, $result['status']);
    }

    /** @test */
    public function it_can_list_ingredients()
    {
        // Créer quelques ingrédients
        Ingredient::factory()->count(3)->create([
            'event_id' => $this->event->id,
            'added_by' => $this->user->id
        ]);

        $result = $this->ingredientService->listIngredients($this->event);

        $this->assertCount(3, $result);
        $this->assertArrayHasKey('id', $result[0]);
        $this->assertArrayHasKey('name', $result[0]);
        $this->assertArrayHasKey('quantity', $result[0]);
    }

    /** @test */
    public function it_can_update_ingredient()
    {
        $ingredient = Ingredient::factory()->create([
            'event_id' => $this->event->id,
            'added_by' => $this->user->id
        ]);

        $data = new IngredientData(
            name: 'Updated Ingredient',
            quantity: 10,
            unit: 'kg',
            estimatedPrice: 20.00,
            notes: 'Updated notes',
            emoji: '🥩'
        );

        $result = $this->ingredientService->updateIngredient(
            $this->event,
            $ingredient,
            $data
        );

        $this->assertEquals($ingredient->id, $result['id']);
        $this->assertEquals('Updated Ingredient', $result['name']);
        $this->assertEquals(10, $result['quantity']);
        $this->assertEquals('kg', $result['unit']);
        $this->assertEquals(20.00, $result['estimated_price']);
        $this->assertEquals('Updated notes', $result['notes']);
        $this->assertEquals('🥩', $result['emoji']);
    }

    /** @test */
    public function it_can_delete_ingredient()
    {
        $ingredient = Ingredient::factory()->create([
            'event_id' => $this->event->id,
            'added_by' => $this->user->id
        ]);

        $result = $this->ingredientService->deleteIngredient(
            $this->event,
            $ingredient
        );

        $this->assertTrue($result);
        $this->assertSoftDeleted($ingredient);
    }

    /** @test */
    public function it_checks_access_permissions_correctly()
    {
        $otherUser = User::factory()->create();

        $this->assertTrue(
            $this->ingredientService->canAccessEvent($this->event, $this->user->id),
            'Organizer should have access'
        );

        $this->assertFalse(
            $this->ingredientService->canAccessEvent($this->event, $otherUser->id),
            'Non-participant should not have access'
        );
    }
}
