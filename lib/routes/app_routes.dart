/// Rotas da aplicação
/// Define todas as rotas disponíveis no app
class AppRoutes {
  // Rotas de autenticação
  static const String login = '/login';
  static const String signUp = '/signup';
  static const String forgotPassword = '/forgot-password';
  static const String app = '/app';

  // Rotas principais
  static const String home = '/home';
  static const String map = '/map';
  static const String ranking = '/ranking';
  static const String search = '/search';
  static const String chat = '/chat';
  static const String profile = '/profile';
  static const String editProfile = '/edit-profile';
  static const String photoSelector = '/photo-selector';
  static const String cropPhoto = '/crop-photo';
  static const String runs = '/runs';
  static const String settings = '/settings';
  static const String battles = '/battles';
  static const String userProfile = '/user-profile';
  static const String newProfile = '/new-profile';
  static const String editNewProfile = '/edit-new-profile';
  static const String achievements = '/achievements';

  // Privatizar construtor para evitar instanciação
  AppRoutes._();
}
