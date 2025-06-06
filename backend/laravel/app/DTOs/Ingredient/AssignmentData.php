<?php

namespace App\DTOs\Ingredient;

class AssignmentData
{
    public function __construct(
        public readonly int $userId,
        public readonly float $quantity
    ) {}

    public static function fromRequest(array $data): self
    {
        return new self(
            userId: $data['user_id'],
            quantity: $data['quantity']
        );
    }

    public function toArray(): array
    {
        return [
            'user_id' => $this->userId,
            'quantity' => $this->quantity,
        ];
    }
}
