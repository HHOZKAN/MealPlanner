# Documentation des Tests Unitaires

## Vue d'ensemble

Cette suite de tests unitaires couvre les fonctionnalités essentielles du backend Laravel de l'application MealPlanner. Les tests sont organisés en plusieurs catégories pour assurer une couverture complète des composants clés.

## Structure des Tests

### 1. Tests de Modèles (EventTest)

Le fichier `tests/Unit/Models/EventTest.php` teste le modèle Event :

```php
/** @test */
public function it_belongs_to_an_organizer()
```
- **Objectif** : Vérifie la relation entre un événement et son organisateur
- **Vérification** : S'assure qu'un Event appartient bien à un User (organisateur)

```php
/** @test */
public function it_has_many_participants()
```
- **Objectif** : Teste la relation one-to-many avec les participants
- **Vérification** : Confirme qu'un Event peut avoir plusieurs Participants

```php
/** @test */
public function it_calculates_total_cost_from_ingredients()
```
- **Objectif** : Vérifie le calcul du coût total des ingrédients
- **Vérification** : S'assure que seuls les prix réels sont inclus dans le total

### 2. Tests de Services (IngredientServiceTest)

Le fichier `tests/Unit/Services/IngredientServiceTest.php` vérifie la logique métier :

```php
/** @test */
public function it_can_create_ingredient()
```
- **Objectif** : Teste la création d'un ingrédient
- **Vérification** : Valide les données et les permissions

```php
/** @test */
public function it_checks_access_permissions_correctly()
```
- **Objectif** : Vérifie la gestion des permissions
- **Vérification** : S'assure que seuls les utilisateurs autorisés peuvent accéder aux ingrédients

### 3. Tests de ValueObjects

#### IngredientStatusTest
Le fichier `tests/Unit/ValueObjects/IngredientStatusTest.php` teste les états des ingrédients :

```php
/** @test */
public function it_can_check_if_can_be_assigned()
```
- **Objectif** : Vérifie les transitions d'état possibles
- **Vérification** : Confirme qu'un ingrédient peut être assigné uniquement dans certains états

#### IngredientUnitTest
Le fichier `tests/Unit/ValueObjects/IngredientUnitTest.php` teste les unités de mesure :

```php
/** @test */
public function it_can_identify_weight_units()
```
- **Objectif** : Vérifie la catégorisation des unités
- **Vérification** : S'assure que les unités sont correctement identifiées (poids/volume/quantité)

### 4. Tests de DTOs (IngredientDataTest)

Le fichier `tests/Unit/DTOs/Ingredient/IngredientDataTest.php` teste le transfert de données :

```php
/** @test */
public function it_can_be_created_from_request()
```
- **Objectif** : Vérifie la création d'objets DTO depuis les requêtes
- **Vérification** : Valide la transformation des données

## Factories

Les factories permettent de générer des données de test réalistes :

### EventFactory
```php
public function definition(): array
{
    return [
        'title' => fake()->sentence(3),
        'date' => fake()->dateTimeBetween('now', '+1 month'),
        // ...
    ];
}
```
- **Utilisation** : Crée des événements avec des données aléatoires mais cohérentes
- **États** : Supporte upcoming(), past(), meal() pour des cas spécifiques

### ParticipantFactory
```php
public function accepted(): static
{
    return $this->state([
        'status' => 'accepted',
        'responded_at' => fake()->dateTimeBetween('-1 week', 'now'),
    ]);
}
```
- **Utilisation** : Génère des participants avec différents états
- **États** : accepted(), pending(), declined()

## Exécution des Tests

Pour exécuter les tests :

```bash
# Tous les tests unitaires
php artisan test --testsuite=Unit

# Un fichier spécifique
php artisan test tests/Unit/Models/EventTest.php

# Une méthode spécifique
php artisan test --filter=it_belongs_to_an_organizer
```

## Maintenance

Pour ajouter de nouveaux tests :
1. Créer le fichier de test dans le dossier approprié
2. Étendre TestCase et utiliser RefreshDatabase si nécessaire
3. Suivre la convention de nommage : `it_does_something()`
4. Utiliser les factories pour générer les données de test
5. Écrire des assertions claires et spécifiques

## Bonnes Pratiques

1. **Isolation** : Chaque test doit être indépendant
2. **Clarté** : Les noms des tests doivent décrire le comportement testé
3. **Préparation** : Utiliser setUp() pour le code commun
4. **Assertions** : Vérifier un seul concept par test
5. **Documentation** : Commenter les cas complexes
