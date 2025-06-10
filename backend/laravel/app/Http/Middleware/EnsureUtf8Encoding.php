<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;

class EnsureUtf8Encoding
{
    /**
     * Handle an incoming request.
     *
     * @param  \Illuminate\Http\Request  $request
     * @param  \Closure  $next
     * @return mixed
     */
    public function handle(Request $request, Closure $next)
    {
        // Set UTF-8 encoding for the request
        if ($request->server('CONTENT_TYPE') === 'application/json') {
            $content = $request->getContent();
            if (!empty($content)) {
                // Detect and convert encoding if needed
                $encoding = mb_detect_encoding($content, ['UTF-8', 'ISO-8859-1', 'ASCII'], true);
                if ($encoding && $encoding !== 'UTF-8') {
                    $content = mb_convert_encoding($content, 'UTF-8', $encoding);
                }
                
                $data = json_decode($content, true);
                if (json_last_error() === JSON_ERROR_NONE) {
                    $request->merge($this->sanitizeData($data));
                }
            }
        }

        // Process the request
        $response = $next($request);

        // Handle JSON response
        if ($response->headers->get('Content-Type') === 'application/json') {
            $response->header('Content-Type', 'application/json; charset=UTF-8');
            
            // Get response content
            $content = $response->getContent();
            if (!empty($content)) {
                $data = json_decode($content, true);
                if (json_last_error() === JSON_ERROR_NONE) {
                    // Re-encode with proper UTF-8 handling
                    $sanitizedData = $this->sanitizeData($data);
                    $response->setContent(json_encode($sanitizedData, 
                        JSON_UNESCAPED_UNICODE | 
                        JSON_UNESCAPED_SLASHES | 
                        JSON_INVALID_UTF8_SUBSTITUTE
                    ));
                }
            }
        }

        return $response;
    }

    /**
     * Recursively sanitize data to ensure UTF-8 encoding
     *
     * @param mixed $data
     * @return mixed
     */
    protected function sanitizeData($data)
    {
        if (is_string($data)) {
            // Detect encoding
            $encoding = mb_detect_encoding($data, ['UTF-8', 'ISO-8859-1', 'ASCII'], true);
            if ($encoding && $encoding !== 'UTF-8') {
                $data = mb_convert_encoding($data, 'UTF-8', $encoding);
            }
            
            // Remove invalid UTF-8 sequences
            $data = preg_replace('/[\x00-\x08\x10\x0B\x0C\x0E-\x19\x7F]'.
                '|[\x00-\x7F][\x80-\xBF]+'.
                '|([\xC0\xC1]|[\xF0-\xFF])[\x80-\xBF]*'.
                '|[\xC2-\xDF]((?![\x80-\xBF])|[\x80-\xBF]{2,})'.
                '|[\xE0-\xEF](([\x80-\xBF](?![\x80-\xBF]))|(?![\x80-\xBF]{2})|[\x80-\xBF]{3,})/S',
                '', $data);
            
            return $data;
        }

        if (is_array($data)) {
            $result = [];
            foreach ($data as $key => $value) {
                // Sanitize both key and value if they're strings
                $sanitizedKey = is_string($key) ? $this->sanitizeData($key) : $key;
                $result[$sanitizedKey] = $this->sanitizeData($value);
            }
            return $result;
        }

        if (is_object($data)) {
            // Convert objects to arrays and sanitize
            return $this->sanitizeData((array) $data);
        }

        return $data;
    }
}
