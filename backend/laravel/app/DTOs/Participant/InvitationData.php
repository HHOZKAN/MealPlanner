<?php

namespace App\DTOs\Participant;

class InvitationData
{
    public function __construct(
        public readonly ?string $nickname,
        public readonly ?string $message
    ) {}

    public static function fromRequest(array $data): self
    {
        return new self(
            nickname: $data['nickname'] ?? null,
            message: $data['message'] ?? null
        );
    }
}
