<?php

namespace App\ValueObjects;

enum ExpenseStatus: string
{
    case PENDING = 'pending';
    case PAID = 'paid';
    case CANCELLED = 'cancelled';
    case DISPUTED = 'disputed';

    public function label(): string
    {
        return match($this) {
            self::PENDING => 'En attente',
            self::PAID => 'Payé',
            self::CANCELLED => 'Annulé',
            self::DISPUTED => 'Contesté',
        };
    }

    public function canBeMarkedAsPaid(): bool
    {
        return $this === self::PENDING;
    }

    public function canBeDisputed(): bool
    {
        return in_array($this, [self::PENDING, self::PAID]);
    }

    public function canBeCancelled(): bool
    {
        return in_array($this, [self::PENDING, self::DISPUTED]);
    }

    public static function getValidStatuses(): array
    {
        return array_column(self::cases(), 'value');
    }

    public static function fromString(string $status): self
    {
        return match($status) {
            'pending' => self::PENDING,
            'paid' => self::PAID,
            'cancelled' => self::CANCELLED,
            'disputed' => self::DISPUTED,
            default => throw new \InvalidArgumentException("Statut de dépense invalide: $status")
        };
    }
}
