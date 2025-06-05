<?php

namespace App\ValueObjects;

enum EventStatus: string
{
    case DRAFT = 'draft';
    case PLANNING = 'planning';
    case CONFIRMED = 'confirmed';
    case CANCELLED = 'cancelled';
    case COMPLETED = 'completed';

    public function label(): string
    {
        return match($this) {
            self::DRAFT => 'Brouillon',
            self::PLANNING => 'En planification',
            self::CONFIRMED => 'Confirmé',
            self::CANCELLED => 'Annulé',
            self::COMPLETED => 'Terminé',
        };
    }

    public function canBeUpdated(): bool
    {
        return in_array($this, [self::DRAFT, self::PLANNING]);
    }

    public function canBeCancelled(): bool
    {
        return in_array($this, [self::DRAFT, self::PLANNING, self::CONFIRMED]);
    }

    public static function getValidStatuses(): array
    {
        return array_column(self::cases(), 'value');
    }
}
