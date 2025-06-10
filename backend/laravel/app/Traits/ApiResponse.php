<?php

namespace App\Traits;

trait ApiResponse
{
    /**
     * Success response
     */
    protected function successResponse($data, $message = null, $code = 200)
    {
        return response()->json([
            'status' => 'success',
            'message' => $message,
            'data' => $data
        ], $code, [], JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
    }

    /**
     * Error response
     */
    protected function errorResponse($message, $code = 400)
    {
        return response()->json([
            'status' => 'error',
            'message' => $message,
        ], $code, [], JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
    }

    /**
     * Sanitize data for JSON encoding
     */
    protected function sanitizeForJson($data)
    {
        if (is_string($data)) {
            // Clean and ensure proper UTF-8 encoding
            $cleaned = mb_convert_encoding($data, 'UTF-8', 'UTF-8');
            // Remove any invalid UTF-8 sequences
            return filter_var($cleaned, FILTER_SANITIZE_STRING, FILTER_FLAG_STRIP_HIGH);
        }
        
        if (is_array($data)) {
            $result = [];
            foreach ($data as $key => $value) {
                $cleanKey = is_string($key) ? $this->sanitizeForJson($key) : $key;
                $result[$cleanKey] = $this->sanitizeForJson($value);
            }
            return $result;
        }
        
        if (is_object($data)) {
            // Handle Eloquent models
            if (method_exists($data, 'toArray')) {
                return $this->sanitizeForJson($data->toArray());
            }
            
            // Handle other objects by converting to array
            if ($data instanceof \stdClass) {
                return $this->sanitizeForJson((array) $data);
            }
            
            // For other objects, try to get public properties
            try {
                $reflection = new \ReflectionClass($data);
                $properties = $reflection->getProperties(\ReflectionProperty::IS_PUBLIC);
                $result = [];
                foreach ($properties as $property) {
                    $result[$property->getName()] = $this->sanitizeForJson($property->getValue($data));
                }
                return $result;
            } catch (\Exception $e) {
                // If reflection fails, convert to string
                return $this->sanitizeForJson((string) $data);
            }
        }
        
        // Handle null, boolean, numeric values
        if (is_null($data) || is_bool($data) || is_numeric($data)) {
            return $data;
        }
        
        // For any other type, convert to string and sanitize
        return $this->sanitizeForJson((string) $data);
    }
}
