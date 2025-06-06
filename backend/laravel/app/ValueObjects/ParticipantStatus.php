<?php

namespace App\ValueObjects;

enum ParticipantStatus: string
{
    case PENDING = 'pending';
    case ACCEPTED = 'accepted';
    case DECLINED = 'declined';
    case MAYBE = 'maybe';

    public function label(): string
    {
        return match($this) {
            self::PENDING => 'En attente',
            self::ACCEPTED => 'Accepté',
            self::DECLINED => 'Refusé',
            self::MAYBE => 'Peut-être',
        };
    }

    public function canBeUpdated(): bool
    {
        return $this !== self::DECLINED;
    }

    public function isConfirmed(): bool
    {
        return $this === self::ACCEPTED;
    }

    public function isPending(): bool
    {
        return $this === self::PENDING;
    }

    public static function getValidStatuses(): array
    {
        return array_column(self::cases(), 'value');
    }

    public static function fromString(string $status): self
    {
        return match($status) {
            'pending' => self::PENDING,
            'accepted' => self::ACCEPTED,
            'declined' => self::DECLINED,
            'maybe' => self::MAYBE,
            default => throw new \InvalidArgumentException("Statut de participant invalide: $status")
        };
    }
}
