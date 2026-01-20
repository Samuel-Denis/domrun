import 'package:get/get.dart';
import 'package:domrun/app/achievement/Page/achievement_page.dart';
import 'package:domrun/app/achievement/bindings/achievement_binding.dart';
import 'package:domrun/app/profile/bindings/profile_binding.dart';
import 'package:domrun/app/profile/views/edit_profile.dart';
import 'package:domrun/app/profile/views/profile.dart';
import 'package:domrun/app/auth/bindings/auth_binding.dart';
import 'package:domrun/app/auth/bindings/forgot_password_binding.dart';
import 'package:domrun/app/auth/bindings/signup_binding.dart';
import 'package:domrun/app/auth/views/forgot_password_page.dart';
import 'package:domrun/app/auth/views/login_page.dart';
import 'package:domrun/app/auth/views/signup_page.dart';
import 'package:domrun/app/maps/bindings/map_binding.dart';
import 'package:domrun/app/maps/views/map_page.dart';
import 'package:domrun/app/profile/bindings/edit_profile_binding.dart';
import 'package:domrun/app/profile/bindings/photo_selector_binding.dart';
import 'package:domrun/app/profile/bindings/public_profile_binding.dart';
import 'package:domrun/app/profile/views/photo_selector_page.dart';
import 'package:domrun/app/profile/views/public_profile_page.dart';
import 'package:domrun/app/home/views/home_page.dart';
import 'package:domrun/app/ranking/bindings/ranking_binding.dart';
import 'package:domrun/app/ranking/views/ranking_page.dart';
import 'package:domrun/app/search/views/search_page.dart';
import 'package:domrun/app/chat/views/chat_page.dart';
import 'package:domrun/app/battles/bindings/battle_binding.dart';
import 'package:domrun/app/battles/views/battle_page.dart';
import 'app_routes.dart';

/// Configuração de páginas/rotas usando GetX
class AppPages {
  static final List<GetPage> pages = [
    GetPage(
      name: AppRoutes.login,
      page: () => const LoginPage(),
      binding:
          AuthBinding(), // Injeta as dependências do módulo de autenticação
    ),
    // Rota de cadastro
    GetPage(
      name: AppRoutes.signUp,
      page: () => const SignUpPage(),
      binding: SignUpBinding(), // Injeta as dependências do módulo de cadastro
    ),
    GetPage(
      name: AppRoutes.profile,
      page: () => const ProfilePage(),
      binding: ProfileBinding(),
    ),
    GetPage(
      name: AppRoutes.editNewProfile,
      page: () => const EditProfilePage(),
      binding: EditProfileBinding(),
    ),
    // Rota de recuperação de senha
    GetPage(
      name: AppRoutes.forgotPassword,
      page: () => const ForgotPasswordPage(),
      binding:
          ForgotPasswordBinding(), // Injeta as dependências do módulo de recuperação
    ),
    // Rota Home
    GetPage(name: AppRoutes.home, page: () => const HomePage()),
    // Rota do mapa
    GetPage(
      name: AppRoutes.map,
      page: () => const MapPage(),
      binding: MapBinding(), // Injeta as dependências do módulo
    ),
    // Rota de Ranking
    GetPage(
      name: AppRoutes.ranking,
      page: () => const RankingPage(),
      binding: RankingBinding(),
    ),
    // Rota de Search
    GetPage(name: AppRoutes.search, page: () => const SearchPage()),
    // Rota de Chat
    GetPage(name: AppRoutes.chat, page: () => const ChatPage()),

    // Rota de seleção de foto
    GetPage(
      name: AppRoutes.photoSelector,
      page: () => PhotoSelectorPage(),
      binding: PhotoSelectorBinding(),
    ),
    // Rota de Batalhas
    GetPage(
      name: AppRoutes.battles,
      page: () => const BattlePage(),
      binding: BattleBinding(),
    ),
    // Rota de perfil público
    GetPage(
      name: AppRoutes.userProfile,
      page: () => const PublicProfilePage(),
      binding: PublicProfileBinding(),
    ),

    // Adicionar mais rotas aqui conforme necessário
    // GetPage(
    //   name: AppRoutes.profile,
    //   page: () => const ProfilePage(),
    //   binding: ProfileBinding(),
    // ),
    GetPage(
      name: AppRoutes.achievements,
      page: () => const AchievementsPage(),
      binding: AchievementBinding(),
    ),
  ];
}
