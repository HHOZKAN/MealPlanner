FROM php:8.2-fpm

# Installation des dépendances système
RUN apt-get update && apt-get install -y \
    git \
    curl \
    libpng-dev \
    libonig-dev \
    libxml2-dev \
    zip \
    unzip \
    libpq-dev

# Nettoyage du cache
RUN apt-get clean && rm -rf /var/lib/apt/lists/*

# Installation des extensions PHP
RUN docker-php-ext-install pdo_pgsql mbstring exif pcntl bcmath gd

# Récupération de la dernière version de Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Création d'un utilisateur non-root
RUN useradd -ms /bin/bash appuser

# Définition du répertoire de travail
WORKDIR /var/www

# Copie des fichiers de l'application avec les bonnes permissions
COPY --chown=appuser:appuser backend/laravel .

# Passage à l'utilisateur non-root pour l'installation de composer
USER appuser

# Installation des dépendances
RUN composer install

# Retour à l'utilisateur root pour définir les permissions finales
USER root
RUN chown -R www-data:www-data /var/www

# Passage à l'utilisateur www-data pour l'exécution
USER www-data
