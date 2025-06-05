<?php

namespace App\DTOs;

use App\ValueObjects\EventStatus;
use App\ValueObjects\EventType;
use DateTime;

class EventData
{
    public function __construct(
        public readonly string $title,
        public readonly ?string $description,
        public readonly DateTime $date,
        public readonly ?string $location,
        public readonly EventType $type,
        public readonly ?string $emoji = null,
        public readonly ?EventStatus $status = null,
        public readonly ?int $organizerId = null
    ) {}

    public static function fromRequest(array $data, ?int $organizerId = null): self
    {
        return new self(
            title: $data['title'],
            description: $data['description'] ?? null,
            date: new DateTime($data['date']),
            location: $data['location'] ?? null,
            type: EventType::from($data['type']),
            emoji: $data['emoji'] ?? null,
            status: isset($data['status']) ? EventStatus::from($data['status']) : EventStatus::DRAFT,
            organizerId: $organizerId
        );
    }

    public function toArray(): array
    {
        return [
            'title' => $this->title,
            'description' => $this->description,
            'date' => $this->date->format('Y-m-d H:i:s'),
            'location' => $this->location,
            'type' => $this->type->value,
            'emoji' => $this->emoji,
            'status' => $this->status?->value,
            'organizer_id' => $this->organizerId,
        ];
    }

    public function validate(): array
    {
        return [
            'title' => 'required|string|max:255',
            'description' => 'nullable|string',
            'date' => 'required|date|after:now',
            'location' => 'nullable|string|max:255',
            'type' => 'required|string|in:' . implode(',', EventType::getValidTypes()),
            'emoji' => 'nullable|string|max:10',
            'status' => 'sometimes|required|string|in:' . implode(',', EventStatus::getValidStatuses()),
        ];
    }
}
