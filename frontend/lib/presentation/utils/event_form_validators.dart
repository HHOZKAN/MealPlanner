/// Classe utilitaire pour la validation des formulaires d'événement
class EventFormValidators {
  /// Valide le titre de l'événement
  static String? validateTitle(String? value) {
    if (value == null || value.isEmpty) {
      return 'Veuillez entrer un titre';
    }
    if (value.length < 3) {
      return 'Le titre doit contenir au moins 3 caractères';
    }
    if (value.length > 100) {
      return 'Le titre ne peut pas dépasser 100 caractères';
    }
    return null;
  }

  /// Valide la description de l'événement
  static String? validateDescription(String? value) {
    if (value != null && value.length > 500) {
      return 'La description ne peut pas dépasser 500 caractères';
    }
    return null;
  }

  /// Valide le lieu de l'événement
  static String? validateLocation(String? value) {
    if (value != null && value.length > 200) {
      return 'Le lieu ne peut pas dépasser 200 caractères';
    }
    return null;
  }
}
