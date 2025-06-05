<?php

namespace App\ValueObjects;

enum EventType: string
{
    case DINNER = 'dinner';
    case LUNCH = 'lunch';
    case BRUNCH = 'brunch';
    case BREAKFAST = 'breakfast';
    case OTHER = 'other';

    public function label(): string
    {
        return match($this) {
            self::DINNER => 'Dîner',
            self::LUNCH => 'Déjeuner',
            self::BRUNCH => 'Brunch',
            self::BREAKFAST => 'Petit-déjeuner',
            self::OTHER => 'Autre',
        };
    }

    public function icon(): string
    {
        return match($this) {
            self::DINNER => '🍽️',
            self::LUNCH => '🥗',
            self::BRUNCH => '🥐',
            self::BREAKFAST => '🥞',
            self::OTHER => '🍴',
        };
    }

    public static function getValidTypes(): array
    {
        return array_column(self::cases(), 'value');
    }
}
