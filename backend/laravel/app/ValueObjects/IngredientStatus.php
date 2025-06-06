<?php

namespace App\ValueObjects;

enum IngredientStatus: string
{
    case NEEDED = 'needed';
    case ASSIGNED = 'assigned';
    case PURCHASED = 'purchased';

    public function label(): string
    {
        return match($this) {
            self::NEEDED => 'Nécessaire',
            self::ASSIGNED => 'Assigné',
            self::PURCHASED => 'Acheté',
        };
    }

    public function canBeAssigned(): bool
    {
        return $this === self::NEEDED;
    }

    public function canBePurchased(): bool
    {
        return $this === self::ASSIGNED;
    }

    public function isPurchased(): bool
    {
        return $this === self::PURCHASED;
    }

    public static function getValidStatuses(): array
    {
        return array_column(self::cases(), 'value');
    }

    public static function fromString(string $status): self
    {
        return match($status) {
            'needed' => self::NEEDED,
            'assigned' => self::ASSIGNED,
            'purchased' => self::PURCHASED,
            default => throw new \InvalidArgumentException("Statut d'ingrédient invalide: $status")
        };
    }
}
