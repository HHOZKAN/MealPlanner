class ApiConstants {
  // URL de base de l'API
  // Pour l'émulateur Android, utiliser 10.0.2.2 au lieu de 127.0.0.1
  static const String baseUrl = 'http://10.0.2.2:8001';
  
  // Endpoints d'authentification
  static const String register = '/api/auth/register';
  static const String login = '/api/auth/login';
  static const String logout = '/api/auth/logout';
  static const String me = '/api/auth/me';
  static const String updateProfile = '/api/auth/profile';
  static const String changePassword = '/api/auth/change-password';
  
  // Endpoints d'événements
  static const String events = '/api/events';
  static const String eventParticipants = '/api/events/{id}/participants';
  static const String eventParticipantShareLink = '/api/events/{id}/participants/share-link';
  static const String eventParticipantAcceptInvitation = '/api/events/participants/accept-invitation';
  static const String eventIngredients = '/api/events/{id}/ingredients';
  static const String eventExpenses = '/api/events/{id}/expenses';
  static const String eventReimbursements = '/api/events/{id}/reimbursements';
  
  // Endpoints de tableau de bord
  static const String dashboardOverview = '/api/dashboard/overview';
  static const String eventHistory = '/api/dashboard/event-history';
  static const String personalStats = '/api/dashboard/personal-stats';
  
  // Endpoints de groupes
  static const String groups = '/api/groups';

  // Endpoint Google login
  static const String googleLogin = '/api/auth/google-login';
}