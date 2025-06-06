<?php

namespace App\DTOs\Ingredient;

class UpdateAssignmentData
{
    public function __construct(
        public readonly string $status,
        public readonly ?float $pricePaid = null,
        public readonly ?string $storeName = null,
        public readonly ?string $receiptImage = null
    ) {}

    public static function fromRequest(array $data): self
    {
        return new self(
            status: $data['status'],
            pricePaid: $data['price_paid'] ?? null,
            storeName: $data['store_name'] ?? null,
            receiptImage: $data['receipt_image'] ?? null
        );
    }

    public function toArray(): array
    {
        return array_filter([
            'status' => $this->status,
            'price_paid' => $this->pricePaid,
            'store_name' => $this->storeName,
            'receipt_image' => $this->receiptImage,
        ], fn($value) => $value !== null);
    }
}
