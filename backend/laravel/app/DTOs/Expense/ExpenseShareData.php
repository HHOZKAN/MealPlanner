<?php

namespace App\DTOs\Expense;

class ExpenseShareData
{
    public function __construct(
        public readonly int $userId,
        public readonly float $amount,
        public readonly string $status = 'pending'
    ) {}

    public static function fromRequest(array $data): self
    {
        return new self(
            userId: $data['user_id'],
            amount: $data['amount'],
            status: $data['status'] ?? 'pending'
        );
    }

    public function toArray(): array
    {
        return [
            'user_id' => $this->userId,
            'amount' => $this->amount,
            'status' => $this->status,
        ];
    }
}
