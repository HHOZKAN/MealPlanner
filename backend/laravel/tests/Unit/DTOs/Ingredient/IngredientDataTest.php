<?php

namespace Tests\Unit\DTOs\Ingredient;

use Tests\TestCase;
use App\DTOs\Ingredient\IngredientData;

class IngredientDataTest extends TestCase
{
    /** @test */
    public function it_can_be_created_from_constructor()
    {
        $data = new IngredientData(
            name: 'Test Ingredient',
            quantity: 5.5,
            unit: 'kg',
            estimatedPrice: 10.99,
            actualPrice: null,
            status: 'needed',
            notes: 'Test notes',
            emoji: '🥔'
        );

        $this->assertEquals('Test Ingredient', $data->name);
        $this->assertEquals(5.5, $data->quantity);
        $this->assertEquals('kg', $data->unit);
        $this->assertEquals(10.99, $data->estimatedPrice);
        $this->assertNull($data->actualPrice);
        $this->assertEquals('needed', $data->status);
        $this->assertEquals('Test notes', $data->notes);
        $this->assertEquals('🥔', $data->emoji);
    }

    /** @test */
    public function it_can_be_created_from_request_array()
    {
        $requestData = [
            'name' => 'Test Ingredient',
            'quantity' => 5.5,
            'unit' => 'kg',
            'estimated_price' => 10.99,
            'actual_price' => null,
            'status' => 'needed',
            'notes' => 'Test notes',
            'emoji' => '🥔'
        ];

        $data = IngredientData::fromRequest($requestData);

        $this->assertEquals('Test Ingredient', $data->name);
        $this->assertEquals(5.5, $data->quantity);
        $this->assertEquals('kg', $data->unit);
        $this->assertEquals(10.99, $data->estimatedPrice);
        $this->assertNull($data->actualPrice);
        $this->assertEquals('needed', $data->status);
        $this->assertEquals('Test notes', $data->notes);
        $this->assertEquals('🥔', $data->emoji);
    }

    /** @test */
    public function it_handles_optional_fields_from_request()
    {
        $requestData = [
            'name' => 'Test Ingredient',
            'quantity' => 5.5,
            'unit' => 'kg'
        ];

        $data = IngredientData::fromRequest($requestData);

        $this->assertEquals('Test Ingredient', $data->name);
        $this->assertEquals(5.5, $data->quantity);
        $this->assertEquals('kg', $data->unit);
        $this->assertNull($data->estimatedPrice);
        $this->assertNull($data->actualPrice);
        $this->assertNull($data->status);
        $this->assertNull($data->notes);
        $this->assertNull($data->emoji);
    }

    /** @test */
    public function it_can_be_converted_to_array()
    {
        $data = new IngredientData(
            name: 'Test Ingredient',
            quantity: 5.5,
            unit: 'kg',
            estimatedPrice: 10.99,
            actualPrice: null,
            status: 'needed',
            notes: 'Test notes',
            emoji: '🥔'
        );

        $array = $data->toArray();

        $this->assertIsArray($array);
        $this->assertEquals('Test Ingredient', $array['name']);
        $this->assertEquals(5.5, $array['quantity']);
        $this->assertEquals('kg', $array['unit']);
        $this->assertEquals(10.99, $array['estimated_price']);
        $this->assertNull($array['actual_price']);
        $this->assertEquals('needed', $array['status']);
        $this->assertEquals('Test notes', $array['notes']);
        $this->assertEquals('🥔', $array['emoji']);
    }
}
