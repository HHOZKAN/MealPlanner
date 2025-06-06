<?php

namespace App\DTOs\Ingredient;

class IngredientData
{
    public function __construct(
        public readonly string $name,
        public readonly float $quantity,
        public readonly string $unit,
        public readonly ?float $estimatedPrice = null,
        public readonly ?float $actualPrice = null,
        public readonly ?string $status = null,
        public readonly ?string $notes = null,
        public readonly ?string $emoji = null
    ) {}

    public static function fromRequest(array $data): self
    {
        return new self(
            name: $data['name'],
            quantity: $data['quantity'],
            unit: $data['unit'],
            estimatedPrice: $data['estimated_price'] ?? null,
            actualPrice: $data['actual_price'] ?? null,
            status: $data['status'] ?? null,
            notes: $data['notes'] ?? null,
            emoji: $data['emoji'] ?? null
        );
    }

    public function toArray(): array
    {
        return [
            'name' => $this->name,
            'quantity' => $this->quantity,
            'unit' => $this->unit,
            'estimated_price' => $this->estimatedPrice,
            'actual_price' => $this->actualPrice,
            'status' => $this->status,
            'notes' => $this->notes,
            'emoji' => $this->emoji,
        ];
    }
}
