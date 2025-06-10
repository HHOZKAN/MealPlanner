<?php

namespace App\Providers;

use Illuminate\Support\ServiceProvider;

class Utf8ServiceProvider extends ServiceProvider
{
    /**
     * Register services.
     */
    public function register(): void
    {
        //
    }

    /**
     * Bootstrap services.
     */
    public function boot(): void
    {
        // Set default internal encoding to UTF-8
        mb_internal_encoding('UTF-8');
        
        // Set default HTTP output encoding to UTF-8
        mb_http_output('UTF-8');
        
        // Set default regex encoding to UTF-8
        mb_regex_encoding('UTF-8');
        
        // Set default locale for string functions with fallbacks
        $locales = [
            'fr_FR.UTF-8',
            'fr_FR.utf8',
            'fr_FR',
            'French_France.1252',
            'French',
            'fr',
            'C.UTF-8',
            'C'
        ];
        
        foreach ($locales as $locale) {
            if (setlocale(LC_ALL, $locale) !== false) {
                break;
            }
        }
        
        // Ensure JSON responses are UTF-8 encoded
        ini_set('default_charset', 'UTF-8');
        
        // Set additional PHP settings for UTF-8 support
        if (function_exists('mb_substitute_character')) {
            mb_substitute_character('none');
        }
        
        // Ensure proper JSON encoding options
        if (defined('JSON_UNESCAPED_UNICODE')) {
            ini_set('serialize_precision', -1);
        }
    }
}
