<?php

namespace Tests\Unit\Models;

use Tests\TestCase;
use App\Models\Event;
use App\Models\User;
use App\Models\Ingredient;
use App\Models\Participant;
use App\Models\Payment;
use Carbon\Carbon;
use Illuminate\Foundation\Testing\RefreshDatabase;

class EventTest extends TestCase
{
    use RefreshDatabase;

    /** @test */
    public function it_belongs_to_an_organizer()
    {
        $user = User::factory()->create();
        $event = Event::factory()->create(['organizer_id' => $user->id]);

        $this->assertInstanceOf(User::class, $event->organizer);
        $this->assertEquals($user->id, $event->organizer->id);
    }

    /** @test */
    public function it_has_many_participants()
    {
        $event = Event::factory()->create();
        $participants = Participant::factory()->count(3)->create(['event_id' => $event->id]);

        $this->assertCount(3, $event->participants);
        $this->assertInstanceOf(Participant::class, $event->participants->first());
    }

    /** @test */
    public function it_has_many_ingredients()
    {
        $event = Event::factory()->create();
        $ingredients = Ingredient::factory()->count(5)->create(['event_id' => $event->id]);

        $this->assertCount(5, $event->ingredients);
        $this->assertInstanceOf(Ingredient::class, $event->ingredients->first());
    }

    /** @test */
    public function it_has_many_payments()
    {
        $event = Event::factory()->create();
        $payments = Payment::factory()->count(2)->create(['event_id' => $event->id]);

        $this->assertCount(2, $event->payments);
        $this->assertInstanceOf(Payment::class, $event->payments->first());
    }

    /** @test */
    public function it_can_determine_if_event_is_upcoming()
    {
        // Événement futur
        $futureEvent = Event::factory()->create([
            'date' => Carbon::now()->addDays(5)
        ]);

        // Événement passé
        $pastEvent = Event::factory()->create([
            'date' => Carbon::now()->subDays(5)
        ]);

        $this->assertTrue($futureEvent->is_upcoming);
        $this->assertFalse($pastEvent->is_upcoming);
    }

    /** @test */
    public function it_calculates_total_cost_from_ingredients()
    {
        $event = Event::factory()->create();
        
        // Créer des ingrédients avec des prix réels
        Ingredient::factory()->create([
            'event_id' => $event->id,
            'actual_price' => 10.50
        ]);
        
        Ingredient::factory()->create([
            'event_id' => $event->id,
            'actual_price' => 15.75
        ]);
        
        // Ingrédient sans prix réel (ne doit pas être compté)
        Ingredient::factory()->create([
            'event_id' => $event->id,
            'actual_price' => null
        ]);

        $this->assertEquals(26.25, $event->total_cost);
    }

    /** @test */
    public function it_uses_soft_deletes()
    {
        $event = Event::factory()->create();
        $eventId = $event->id;

        $event->delete();

        // L'événement doit être soft deleted
        $this->assertSoftDeleted($event);
        
        // Il ne doit plus apparaître dans les requêtes normales
        $this->assertNull(Event::find($eventId));
        
        // Mais il doit être trouvable avec withTrashed
        $this->assertNotNull(Event::withTrashed()->find($eventId));
    }

    /** @test */
    public function it_casts_date_to_datetime()
    {
        $dateString = '2024-12-25 15:30:00';
        $event = Event::factory()->create(['date' => $dateString]);

        $this->assertInstanceOf(Carbon::class, $event->date);
        $this->assertEquals('2024-12-25 15:30:00', $event->date->format('Y-m-d H:i:s'));
    }

    /** @test */
    public function it_has_correct_fillable_attributes()
    {
        $fillable = [
            'title',
            'description',
            'date',
            'location',
            'type',
            'emoji',
            'organizer_id',
            'status'
        ];

        $event = new Event();
        $this->assertEquals($fillable, $event->getFillable());
    }
}
