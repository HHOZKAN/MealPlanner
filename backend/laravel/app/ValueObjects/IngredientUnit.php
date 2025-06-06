<?php

namespace App\ValueObjects;

enum IngredientUnit: string
{
    case PIECE = 'piece';
    case GRAM = 'g';
    case KILOGRAM = 'kg';
    case LITER = 'l';
    case MILLILITER = 'ml';
    case CUP = 'cup';
    case TABLESPOON = 'tbsp';
    case TEASPOON = 'tsp';
    case PACKAGE = 'package';
    case BOTTLE = 'bottle';
    case CAN = 'can';

    public function label(): string
    {
        return match($this) {
            self::PIECE => 'Pièce(s)',
            self::GRAM => 'Gramme(s)',
            self::KILOGRAM => 'Kilogramme(s)',
            self::LITER => 'Litre(s)',
            self::MILLILITER => 'Millilitre(s)',
            self::CUP => 'Tasse(s)',
            self::TABLESPOON => 'Cuillère(s) à soupe',
            self::TEASPOON => 'Cuillère(s) à café',
            self::PACKAGE => 'Paquet(s)',
            self::BOTTLE => 'Bouteille(s)',
            self::CAN => 'Boîte(s)',
        };
    }

    public function isWeight(): bool
    {
        return in_array($this, [self::GRAM, self::KILOGRAM]);
    }

    public function isVolume(): bool
    {
        return in_array($this, [self::LITER, self::MILLILITER, self::CUP]);
    }

    public function isCount(): bool
    {
        return in_array($this, [self::PIECE, self::PACKAGE, self::BOTTLE, self::CAN]);
    }

    public static function getUnits(): array
    {
        return array_combine(
            array_column(self::cases(), 'value'),
            array_map(fn($case) => $case->label(), self::cases())
        );
    }

    public static function fromString(string $unit): self
    {
        return match($unit) {
            'piece' => self::PIECE,
            'g' => self::GRAM,
            'kg' => self::KILOGRAM,
            'l' => self::LITER,
            'ml' => self::MILLILITER,
            'cup' => self::CUP,
            'tbsp' => self::TABLESPOON,
            'tsp' => self::TEASPOON,
            'package' => self::PACKAGE,
            'bottle' => self::BOTTLE,
            'can' => self::CAN,
            default => throw new \InvalidArgumentException("Unité d'ingrédient invalide: $unit")
        };
    }
}
