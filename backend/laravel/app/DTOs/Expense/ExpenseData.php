<?php

namespace App\DTOs\Expense;

class ExpenseData
{
    public function __construct(
        public readonly int $ingredientId,
        public readonly int $payerId,
        public readonly float $amount,
        public readonly ?string $description = null,
        public readonly ?string $category = null,
        public readonly ?string $receiptImage = null
    ) {}

    public static function fromRequest(array $data): self
    {
        return new self(
            ingredientId: $data['ingredient_id'],
            payerId: $data['payer_id'],
            amount: $data['amount'],
            description: $data['description'] ?? null,
            category: $data['category'] ?? null,
            receiptImage: $data['receipt_image'] ?? null
        );
    }

    public function toArray(): array
    {
        return [
            'ingredient_id' => $this->ingredientId,
            'payer_id' => $this->payerId,
            'amount' => $this->amount,
            'description' => $this->description,
            'category' => $this->category,
            'receipt_image' => $this->receiptImage,
        ];
    }
}
