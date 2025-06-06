<?php

namespace Tests\Unit\ValueObjects;

use Tests\TestCase;
use App\ValueObjects\IngredientStatus;

class IngredientStatusTest extends TestCase
{
    /** @test */
    public function it_has_correct_values()
    {
        $this->assertEquals('needed', IngredientStatus::NEEDED->value);
        $this->assertEquals('assigned', IngredientStatus::ASSIGNED->value);
        $this->assertEquals('purchased', IngredientStatus::PURCHASED->value);
    }

    /** @test */
    public function it_has_correct_labels()
    {
        $this->assertEquals('Nécessaire', IngredientStatus::NEEDED->label());
        $this->assertEquals('Assigné', IngredientStatus::ASSIGNED->label());
        $this->assertEquals('Acheté', IngredientStatus::PURCHASED->label());
    }

    /** @test */
    public function it_can_check_if_can_be_assigned()
    {
        $this->assertTrue(IngredientStatus::NEEDED->canBeAssigned());
        $this->assertFalse(IngredientStatus::ASSIGNED->canBeAssigned());
        $this->assertFalse(IngredientStatus::PURCHASED->canBeAssigned());
    }

    /** @test */
    public function it_can_check_if_can_be_purchased()
    {
        $this->assertFalse(IngredientStatus::NEEDED->canBePurchased());
        $this->assertTrue(IngredientStatus::ASSIGNED->canBePurchased());
        $this->assertFalse(IngredientStatus::PURCHASED->canBePurchased());
    }

    /** @test */
    public function it_can_check_if_is_purchased()
    {
        $this->assertFalse(IngredientStatus::NEEDED->isPurchased());
        $this->assertFalse(IngredientStatus::ASSIGNED->isPurchased());
        $this->assertTrue(IngredientStatus::PURCHASED->isPurchased());
    }

    /** @test */
    public function it_returns_valid_statuses()
    {
        $expected = ['needed', 'assigned', 'purchased'];
        $this->assertEquals($expected, IngredientStatus::getValidStatuses());
    }

    /** @test */
    public function it_can_create_from_string()
    {
        $this->assertEquals(IngredientStatus::NEEDED, IngredientStatus::fromString('needed'));
        $this->assertEquals(IngredientStatus::ASSIGNED, IngredientStatus::fromString('assigned'));
        $this->assertEquals(IngredientStatus::PURCHASED, IngredientStatus::fromString('purchased'));
    }

    /** @test */
    public function it_throws_exception_for_invalid_string()
    {
        $this->expectException(\InvalidArgumentException::class);
        $this->expectExceptionMessage("Statut d'ingrédient invalide: invalid");
        
        IngredientStatus::fromString('invalid');
    }
}
