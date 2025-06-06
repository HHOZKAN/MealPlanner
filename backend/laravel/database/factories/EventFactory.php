<?php

namespace Database\Factories;

use App\Models\Event;
use App\Models\User;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends \Illuminate\Database\Eloquent\Factories\Factory<\App\Models\Event>
 */
class EventFactory extends Factory
{
    /**
     * Define the model's default state.
     *
     * @return array<string, mixed>
     */
    public function definition(): array
    {
        return [
            'title' => fake()->sentence(3),
            'description' => fake()->paragraph(),
            'date' => fake()->dateTimeBetween('now', '+1 month'),
            'location' => fake()->address(),
            'type' => fake()->randomElement(['meal', 'party', 'meeting', 'other']),
            'organizer_id' => User::factory(),
            'status' => fake()->randomElement(['draft', 'planning', 'confirmed', 'cancelled', 'completed']),
            'emoji' => fake()->optional()->randomElement(['🍽️', '🎉', '🤝', '📅']),
        ];
    }

    /**
     * Indicate that the event is upcoming.
     */
    public function upcoming(): static
    {
        return $this->state(fn (array $attributes) => [
            'date' => fake()->dateTimeBetween('+1 day', '+1 month'),
            'status' => 'confirmed',
        ]);
    }

    /**
     * Indicate that the event is past.
     */
    public function past(): static
    {
        return $this->state(fn (array $attributes) => [
            'date' => fake()->dateTimeBetween('-1 month', '-1 day'),
            'status' => 'completed',
        ]);
    }

    /**
     * Indicate that the event is a meal type.
     */
    public function meal(): static
    {
        return $this->state(fn (array $attributes) => [
            'type' => 'meal',
            'emoji' => '🍽️',
        ]);
    }

    /**
     * Indicate that the event is in draft status.
     */
    public function draft(): static
    {
        return $this->state(fn (array $attributes) => [
            'status' => 'draft',
        ]);
    }

    /**
     * Indicate that the event is in planning status.
     */
    public function planning(): static
    {
        return $this->state(fn (array $attributes) => [
            'status' => 'planning',
        ]);
    }

    /**
     * Indicate that the event is confirmed.
     */
    public function confirmed(): static
    {
        return $this->state(fn (array $attributes) => [
            'status' => 'confirmed',
        ]);
    }
}
