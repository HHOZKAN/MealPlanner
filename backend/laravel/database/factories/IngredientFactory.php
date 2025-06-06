<?php

namespace Database\Factories;

use App\Models\Ingredient;
use App\Models\Event;
use App\Models\User;
use App\ValueObjects\IngredientStatus;
use App\ValueObjects\IngredientUnit;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends \Illuminate\Database\Eloquent\Factories\Factory<\App\Models\Ingredient>
 */
class IngredientFactory extends Factory
{
    /**
     * Define the model's default state.
     *
     * @return array<string, mixed>
     */
    public function definition(): array
    {
        $units = array_keys(IngredientUnit::getUnits());
        $statuses = IngredientStatus::getValidStatuses();
        
        return [
            'event_id' => Event::factory(),
            'name' => fake()->randomElement([
                'Tomates', 'Oignons', 'Pommes de terre', 'Carottes', 'Courgettes',
                'Poivrons', 'Aubergines', 'Brocolis', 'Épinards', 'Salade',
                'Poulet', 'Bœuf', 'Porc', 'Poisson', 'Œufs',
                'Riz', 'Pâtes', 'Pain', 'Farine', 'Huile d\'olive'
            ]),
            'quantity' => fake()->randomFloat(2, 0.1, 10),
            'unit' => fake()->randomElement($units),
            'estimated_price' => fake()->randomFloat(2, 1, 50),
            'actual_price' => null,
            'added_by' => User::factory(),
            'status' => fake()->randomElement($statuses),
            'notes' => fake()->optional()->sentence(),
            'emoji' => fake()->randomElement(['🥔', '🥕', '🧅', '🍅', '🥒', '🥬', '🍖', '🐟', '🥚', '🍞']),
        ];
    }

    /**
     * Indicate that the ingredient is needed.
     */
    public function needed(): static
    {
        return $this->state(fn (array $attributes) => [
            'status' => IngredientStatus::NEEDED->value,
            'actual_price' => null,
        ]);
    }

    /**
     * Indicate that the ingredient is assigned.
     */
    public function assigned(): static
    {
        return $this->state(fn (array $attributes) => [
            'status' => IngredientStatus::ASSIGNED->value,
            'actual_price' => null,
        ]);
    }

    /**
     * Indicate that the ingredient is purchased.
     */
    public function purchased(): static
    {
        return $this->state(fn (array $attributes) => [
            'status' => IngredientStatus::PURCHASED->value,
            'actual_price' => fake()->randomFloat(2, 1, 50),
        ]);
    }

    /**
     * Set a specific price for the ingredient.
     */
    public function withPrice(float $price): static
    {
        return $this->state(fn (array $attributes) => [
            'estimated_price' => $price,
        ]);
    }

    /**
     * Set a specific quantity and unit for the ingredient.
     */
    public function withQuantity(float $quantity, string $unit): static
    {
        return $this->state(fn (array $attributes) => [
            'quantity' => $quantity,
            'unit' => $unit,
        ]);
    }
}
