<?php

namespace Tests\Unit\ValueObjects;

use Tests\TestCase;
use App\ValueObjects\IngredientUnit;

class IngredientUnitTest extends TestCase
{
    /** @test */
    public function it_has_correct_values()
    {
        $this->assertEquals('piece', IngredientUnit::PIECE->value);
        $this->assertEquals('g', IngredientUnit::GRAM->value);
        $this->assertEquals('kg', IngredientUnit::KILOGRAM->value);
        $this->assertEquals('l', IngredientUnit::LITER->value);
        $this->assertEquals('ml', IngredientUnit::MILLILITER->value);
    }

    /** @test */
    public function it_has_correct_labels()
    {
        $this->assertEquals('Pièce(s)', IngredientUnit::PIECE->label());
        $this->assertEquals('Gramme(s)', IngredientUnit::GRAM->label());
        $this->assertEquals('Kilogramme(s)', IngredientUnit::KILOGRAM->label());
        $this->assertEquals('Litre(s)', IngredientUnit::LITER->label());
        $this->assertEquals('Millilitre(s)', IngredientUnit::MILLILITER->label());
    }

    /** @test */
    public function it_can_identify_weight_units()
    {
        $this->assertTrue(IngredientUnit::GRAM->isWeight());
        $this->assertTrue(IngredientUnit::KILOGRAM->isWeight());
        $this->assertFalse(IngredientUnit::PIECE->isWeight());
        $this->assertFalse(IngredientUnit::LITER->isWeight());
    }

    /** @test */
    public function it_can_identify_volume_units()
    {
        $this->assertTrue(IngredientUnit::LITER->isVolume());
        $this->assertTrue(IngredientUnit::MILLILITER->isVolume());
        $this->assertTrue(IngredientUnit::CUP->isVolume());
        $this->assertFalse(IngredientUnit::PIECE->isVolume());
        $this->assertFalse(IngredientUnit::GRAM->isVolume());
    }

    /** @test */
    public function it_can_identify_count_units()
    {
        $this->assertTrue(IngredientUnit::PIECE->isCount());
        $this->assertTrue(IngredientUnit::PACKAGE->isCount());
        $this->assertTrue(IngredientUnit::BOTTLE->isCount());
        $this->assertTrue(IngredientUnit::CAN->isCount());
        $this->assertFalse(IngredientUnit::GRAM->isCount());
        $this->assertFalse(IngredientUnit::LITER->isCount());
    }

    /** @test */
    public function it_returns_units_array()
    {
        $units = IngredientUnit::getUnits();
        
        $this->assertIsArray($units);
        $this->assertArrayHasKey('piece', $units);
        $this->assertArrayHasKey('g', $units);
        $this->assertArrayHasKey('kg', $units);
        $this->assertEquals('Pièce(s)', $units['piece']);
        $this->assertEquals('Gramme(s)', $units['g']);
    }

    /** @test */
    public function it_can_create_from_string()
    {
        $this->assertEquals(IngredientUnit::PIECE, IngredientUnit::fromString('piece'));
        $this->assertEquals(IngredientUnit::GRAM, IngredientUnit::fromString('g'));
        $this->assertEquals(IngredientUnit::KILOGRAM, IngredientUnit::fromString('kg'));
        $this->assertEquals(IngredientUnit::LITER, IngredientUnit::fromString('l'));
        $this->assertEquals(IngredientUnit::MILLILITER, IngredientUnit::fromString('ml'));
    }

    /** @test */
    public function it_throws_exception_for_invalid_string()
    {
        $this->expectException(\InvalidArgumentException::class);
        $this->expectExceptionMessage("Unité d'ingrédient invalide: invalid");
        
        IngredientUnit::fromString('invalid');
    }
}
