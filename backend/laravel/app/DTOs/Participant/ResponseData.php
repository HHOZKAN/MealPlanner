<?php

namespace App\DTOs\Participant;

class ResponseData
{
    public function __construct(
        public readonly string $status,
        public readonly ?string $note
    ) {}

    public static function fromRequest(array $data): self
    {
        return new self(
            status: $data['status'],
            note: $data['note'] ?? null
        );
    }
}
