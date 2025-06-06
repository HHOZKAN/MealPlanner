class ApiConstants {
  // URL de base de l'API
  // Pour l'émulateur Android, utiliser 10.0.2.2 au lieu de 127.0.0.1
  static const String baseUrl = 'http://10.0.2.2:8001/api';
  
  // Endpoints d'authentification
  static const String register = '/auth/register';
  static const String login = '/auth/login';
  static const String logout = '/auth/logout';
  static const String me = '/auth/me';
  static const String updateProfile = '/auth/profile';
  static const String changePassword = '/auth/change-password';
  
  // Endpoints d'événements
  static const String events = '/events';
  static const String eventParticipants = '/events/{id}/participants';
  static const String eventIngredients = '/events/{id}/ingredients';
  static const String eventExpenses = '/events/{id}/expenses';
  static const String eventReimbursements = '/events/{id}/reimbursements';
  
  // Endpoints de tableau de bord
  static const String dashboardOverview = '/dashboard/overview';
  static const String eventHistory = '/dashboard/event-history';
  static const String personalStats = '/dashboard/personal-stats';
  
  // Endpoints de groupes
  static const String groups = '/groups';

  // Endpoint Google login
  static const String googleLogin = '/auth/google-login';
}