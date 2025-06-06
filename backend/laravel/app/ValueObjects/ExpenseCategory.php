<?php

namespace App\ValueObjects;

enum ExpenseCategory: string
{
    case INGREDIENT = 'ingredient';
    case TRANSPORT = 'transport';
    case ACCOMMODATION = 'accommodation';
    case ACTIVITY = 'activity';
    case OTHER = 'other';

    public function label(): string
    {
        return match($this) {
            self::INGREDIENT => 'Ingrédient',
            self::TRANSPORT => 'Transport',
            self::ACCOMMODATION => 'Hébergement',
            self::ACTIVITY => 'Activité',
            self::OTHER => 'Autre',
        };
    }

    public function emoji(): string
    {
        return match($this) {
            self::INGREDIENT => '🛒',
            self::TRANSPORT => '🚗',
            self::ACCOMMODATION => '🏠',
            self::ACTIVITY => '🎯',
            self::OTHER => '💰',
        };
    }

    public function isIngredientRelated(): bool
    {
        return $this === self::INGREDIENT;
    }

    public static function getCategories(): array
    {
        return array_combine(
            array_column(self::cases(), 'value'),
            array_map(fn($case) => $case->label(), self::cases())
        );
    }

    public static function getValidCategories(): array
    {
        return array_column(self::cases(), 'value');
    }

    public static function fromString(string $category): self
    {
        return match($category) {
            'ingredient' => self::INGREDIENT,
            'transport' => self::TRANSPORT,
            'accommodation' => self::ACCOMMODATION,
            'activity' => self::ACTIVITY,
            'other' => self::OTHER,
            default => throw new \InvalidArgumentException("Catégorie de dépense invalide: $category")
        };
    }
}
