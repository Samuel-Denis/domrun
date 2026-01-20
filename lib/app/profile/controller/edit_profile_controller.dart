import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:domrun/app/auth/models/user_model.dart';
import 'package:domrun/app/auth/service/auth_service.dart';
import 'package:domrun/app/navigation/controller/navigation_controller.dart';
import 'package:domrun/app/user/service/user_service.dart';
import 'package:domrun/core/constants/api_constants.dart';
import 'package:domrun/core/services/storage_service.dart';
import 'package:domrun/routes/app_routes.dart';

/// Controller para gerenciar a edição de perfil do usuário
/// Controla os campos do formulário e a atualização dos dados
class EditProfileController extends GetxController {
  // Serviço de autenticação
  late final AuthService _authService;
  late final UserService _userService;
  late final StorageService _storage;

  // Foto de perfil selecionada (arquivo File)
  final Rxn<File> selectedPhotoBytes = Rxn<File>();

  // Controladores dos campos de texto
  // Inicializados no onInit para evitar erros
  late final TextEditingController nameController;
  late final TextEditingController usernameController;
  late final TextEditingController biographyController;
  late final TextEditingController newPasswordController;
  late final TextEditingController confirmPasswordController;

  // Variáveis reativas para controlar o estado da UI
  var isPasswordVisible = false.obs; // Controla a visibilidade da senha
  var isConfirmPasswordVisible =
      false.obs; // Controla a visibilidade da senha de confirmação
  var isLoading = false.obs; // Indica se está processando a atualização
  var selectedColor = Rxn<String>(); // Cor selecionada para o domínio
  bool _isEditSessionActive = false;
  late final Worker _userWorker;

  // Cores disponíveis para seleção
  // CORES ANTIGAS (ROXO COMO PADRÃO) - COMENTADAS PARA POSSÍVEL VOLTA FUTURA
  // final List<String> availableColors = [
  //   '#7B2CBF', // Roxo (padrão)
  //   '#00E5FF', // Ciano
  //   '#FF0000', // Vermelho
  //   '#00FF00', // Verde
  //   '#FFFF00', // Amarelo
  //   '#FF6B35', // Laranja/Vermelho gradiente
  // ];

  // NOVAS CORES (CIANO COMO PADRÃO - CORES QUE COMBINAM COM CIANO)
  final List<String> availableColors = [
    /* '#FF0042', // vermelho quente
    '#FF8C00', // Azul claro
    '#0099FF', // Azul vibrante
    '#00C9CC', // Turquesa
    '#00A8A8', // Turquesa escuro
    '#0066CC', // Azul médio
    '#7B2CBF', // Roxo (padrão)
    '#FF0000', // Vermelho
    '#00FF00', // Verde
    '#FFFF00', // Amarelo
    '#FF6B35', // Laranja/Vermelho gradiente */
    //Vermelho Neon
    '#FF0042', //Quente,Jogadores agressivos/ataque
    //Laranja Solar,
    '#FF8C00', //Quente,Territórios em destaque
    //Amarelo Elétrico
    '#FFD700', //Quente,Áreas de alta energia
    //Verde Esmeralda,
    '#00C853', //Natureza,Áreas dominadas há muito tempo
    //Ciano Água,
    '#00E5FF', //Frio,Regiões litorâneas ou lagos
    //Azul Royal,
    '#2979FF', //Frio,Base principal ou capitais
    //Azul Cobalto,
    '#3D5AFE', //Frio,Equipes de defesa
    //Roxo Profundo,
    '#6200EA', //Místico,Áreas raras ou lendárias
    //Violeta Vivido,
    '#AA00FF', //Místico,Territórios de elite
    //Rosa Choque,
    '#FF00FF', //Vibrante,Jogadores com alto XP
    //Magenta Escuro
    '#C51162', //Vibrante,Áreas de conflito intenso
    //Turquesa Escuro
    '#00838F', //Sobrio,Uso em modo noturno
    //Cinza Ardósia
    '#FF6B35', //Neutro,Territórios neutros/abandonados
    //Ouro Velho
    '#B8860B', //Premium,Conquistas de campeões
    //Branco Puro,
    '#FF3F6F', //Neutro,Neve ou áreas desabitadas
  ];

  /// Método chamado quando o controller é inicializado
  /// Configura valores iniciais e obtém o serviço de autenticação
  /// Observa mudanças no usuário para atualizar os campos automaticamente
  @override
  void onInit() {
    super.onInit();
    _authService = Get.find<AuthService>();
    _userService = Get.find<UserService>();
    _storage = Get.find<StorageService>();

    // Inicializa os controladores primeiro
    final user = _userService.currentUser.value;
    if (user != null) {
      nameController = TextEditingController(text: user.name ?? '');
      usernameController = TextEditingController(text: user.username);
      biographyController = TextEditingController(text: user.biography ?? '');
      newPasswordController = TextEditingController();
      confirmPasswordController = TextEditingController();
      selectedColor.value = user.color ?? availableColors[0];
    } else {
      nameController = TextEditingController();
      usernameController = TextEditingController();
      biographyController = TextEditingController();
      newPasswordController = TextEditingController();
      confirmPasswordController = TextEditingController();
      selectedColor.value = availableColors[0];
    }

    // Observa mudanças no usuário para atualizar os campos automaticamente
    // Isso garante que se o perfil for atualizado, os campos sejam atualizados
    _userWorker = ever(_userService.currentUser, (user) {
      if (user != null) {
        _loadUserData();
      }
    });
  }

  /// Carrega os dados do usuário atual nos campos do formulário
  /// Atualiza os controladores com os valores do usuário
  void _loadUserData() {
    if (isClosed) {
      return;
    }
    final user = _userService.currentUser.value;
    if (user != null) {
      // Atualiza os controladores com os valores atuais do usuário
      nameController.text = user.name ?? '';
      usernameController.text = user.username;
      biographyController.text = user.biography ?? '';
      selectedColor.value = user.color ?? availableColors[0];
      selectedPhotoBytes.value = null;

      // Limpa os campos de senha (não devem ser preenchidos automaticamente)
      newPasswordController.clear();
      confirmPasswordController.clear();
    } else {
      // Se não houver usuário, limpa os campos
      nameController.clear();
      usernameController.clear();
      biographyController.clear();
      newPasswordController.clear();
      confirmPasswordController.clear();
      selectedColor.value = availableColors[0];
      selectedPhotoBytes.value = null;
    }
  }

  /// Método chamado quando o controller é destruído
  /// Limpa os recursos para evitar vazamento de memória
  @override
  void onClose() {
    _userWorker.dispose();
    nameController.dispose();
    usernameController.dispose();
    biographyController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    super.onClose();
  }

  /// Alterna a visibilidade da senha
  void togglePasswordVisibility() {
    isPasswordVisible.value = !isPasswordVisible.value;
  }

  /// Alterna a visibilidade da senha de confirmação
  void toggleConfirmPasswordVisibility() {
    isConfirmPasswordVisible.value = !isConfirmPasswordVisible.value;
  }

  /// Inicia uma nova sessão de edição, limpando dados temporários
  void startEditSession() {
    if (_isEditSessionActive) {
      return;
    }
    _isEditSessionActive = true;
    selectedPhotoBytes.value = null;
    newPasswordController.clear();
    confirmPasswordController.clear();
  }

  /// Encerra a sessão de edição e limpa dados temporários
  void endEditSession() {
    _isEditSessionActive = false;
    selectedPhotoBytes.value = null;
    newPasswordController.clear();
    confirmPasswordController.clear();
  }

  /// Intercepta o "voltar" do sistema
  Future<bool> handleWillPop() async {
    endEditSession();
    return true;
  }

  /// Seleciona uma cor para o domínio
  /// [color] - Cor em formato hexadecimal (ex: #00E5FF - era #7B2CBF)
  void selectColor(String color) {
    selectedColor.value = color;
  }

  /// Valida se o formulário está válido
  /// Retorna true se todos os campos obrigatórios estão preenchidos corretamente
  bool _validateForm() {
    if (nameController.text.trim().isEmpty) {
      Get.snackbar('Erro', 'O nome é obrigatório');
      return false;
    }

    // Valida username (converte para minúsculas e valida formato)
    final username = usernameController.text.trim().toLowerCase();

    // Atualiza o controller com o valor em minúsculas
    if (usernameController.text.trim() != username) {
      usernameController.value = TextEditingValue(
        text: username,
        selection: TextSelection.collapsed(offset: username.length),
      );
    }

    if (username.isEmpty) {
      Get.snackbar('Erro', 'O username é obrigatório');
      return false;
    }

    if (username.length < 3) {
      Get.snackbar('Erro', 'O username deve ter pelo menos 3 caracteres');
      return false;
    }

    // Valida se contém apenas letras minúsculas, números e os caracteres especiais: . (ponto), - (hífen), _ (underscore)
    final usernameRegex = RegExp(r'^[a-z0-9._-]+$');
    if (!usernameRegex.hasMatch(username)) {
      Get.snackbar(
        'Erro',
        'O username deve conter apenas letras minúsculas, números e os caracteres: . (ponto), - (hífen), _ (underscore)',
      );
      return false;
    }

    // Valida senha se foi preenchida
    if (newPasswordController.text.isNotEmpty) {
      if (newPasswordController.text.length < 6) {
        Get.snackbar('Erro', 'A senha deve ter pelo menos 6 caracteres');
        return false;
      }

      if (newPasswordController.text != confirmPasswordController.text) {
        Get.snackbar('Erro', 'As senhas não coincidem');
        return false;
      }
    }

    return true;
  }

  /// Salva as alterações do perfil
  /// Atualiza os dados do usuário no servidor
  Future<void> saveProfile() async {
    if (!_validateForm()) {
      return;
    }

    isLoading.value = true;

    try {
      final user = _userService.currentUser.value;
      if (user == null) {
        Get.snackbar('Erro', 'Usuário não autenticado');
        isLoading.value = false;
        return;
      }

      final name = nameController.text.trim();
      final username = usernameController.text.trim().toLowerCase();
      final password = newPasswordController.text.isNotEmpty
          ? newPasswordController.text
          : null;
      final biography = biographyController.text.trim().isNotEmpty
          ? biographyController.text.trim()
          : null;
      final color = selectedColor.value;
      final photo = selectedPhotoBytes.value;

      // Atualiza o perfil usando o AuthService
      await _authService.updateProfile(
        name: name,
        username: username,
        color: color,
        password: password,
        biography: biography,
        photo: photo,
      );

      // Mostra mensagem de sucesso
      Get.snackbar(
        'Sucesso',
        'Perfil atualizado com sucesso!',
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );

      endEditSession();

      // Aguarda um momento para garantir que o snackbar seja exibido
      await Future.delayed(const Duration(milliseconds: 500));

      // Navega para a página de perfil usando offAllNamed para limpar toda a pilha
      // e ir direto para o perfil, garantindo que os dados atualizados sejam exibidos
      // O AuthService já atualizou o currentUser.value, então a página de perfil mostrará os dados novos automaticamente
      Get.offAllNamed(AppRoutes.profile);
    } catch (e) {
      Get.snackbar(
        'Erro',
        'Não foi possível atualizar o perfil: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      if (!isClosed) {
        isLoading.value = false;
      }
    }
  }

  /// Cancela a edição e volta para a tela anterior
  void cancel() {
    endEditSession();
    Get.back();
  }

  /// Abre a tela de seleção de foto
  /// Retorna o arquivo da foto cropada ou null se cancelado
  /// A foto será salva apenas quando o usuário clicar em "Salvar Alterações"
  Future<void> selectPhoto() async {
    final result = await Get.toNamed(AppRoutes.photoSelector);
    if (result != null && result is File) {
      // Lê os bytes do arquivo e atualiza a foto selecionada (apenas preview)

      selectedPhotoBytes.value = result;
      // Não faz upload ainda - será feito apenas quando salvar
    }
  }

  /// Atualiza a foto de perfil
  /// [photoFile] - Arquivo da imagem cropada
  /// [manageLoading] - Se true, gerencia o estado de loading (padrão: false, pois geralmente é chamado dentro de saveProfile)
  Future<void> updateProfilePhoto(
    File photoFile, {
    bool manageLoading = false,
  }) async {
    try {
      if (manageLoading) {
        isLoading.value = true;
      }

      final accessToken = _storage.getAccessToken();
      if (accessToken == null) {
        throw Exception('Token de acesso não encontrado');
      }

      // Cria uma requisição multipart para upload da foto
      final request = http.MultipartRequest(
        'PUT',
        Uri.parse(
          '${ApiConstants.baseUrl}${ApiConstants.updateProfileEndpoint}',
        ),
      );

      // Adiciona o header de autorização
      request.headers['Authorization'] = 'Bearer $accessToken';

      // Adiciona a foto como multipart file (servidor espera o campo 'file')
      // O ParseFilePipe valida tipos: jpg, jpeg, png, gif, webp
      final extension = photoFile.path.split('.').last.toLowerCase();
      String? contentType;

      switch (extension) {
        case 'jpg':
        case 'jpeg':
          contentType = 'image/jpeg';
          break;
        case 'png':
          contentType = 'image/png';
          break;
        case 'gif':
          contentType = 'image/gif';
          break;
        case 'webp':
          contentType = 'image/webp';
          break;
      }

      request.files.add(
        await http.MultipartFile.fromPath(
          'file', // Campo esperado pelo ParseFilePipe
          photoFile.path,
          filename: 'profile_photo.$extension',
          contentType: contentType != null
              ? http.MediaType.parse(contentType)
              : null,
        ),
      );

      // Envia a requisição
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body) as Map<String, dynamic>;

        // Atualiza o usuário com os novos dados
        final userMap = Map<String, dynamic>.from(data);
        userMap.remove('password');
        userMap.remove('postLikes');
        userMap.remove('userAchievements');
        userMap.remove('runs');
        userMap.remove('posts');
        userMap.remove('territories');

        final updatedUser = UserModel.fromJson(userMap);
        _userService.setUser(updatedUser);

        // Só mostra snackbar se estiver gerenciando o loading (chamado diretamente)
        if (manageLoading) {
          Get.snackbar(
            'Sucesso',
            'Foto de perfil atualizada com sucesso!',
            backgroundColor: Colors.green,
            colorText: Colors.white,
            duration: const Duration(seconds: 2),
          );
        }
      } else {
        throw Exception(
          'Erro ao atualizar foto: Status ${response.statusCode}',
        );
      }
    } catch (e) {
      // Só mostra snackbar de erro se estiver gerenciando o loading
      if (manageLoading) {
        Get.snackbar(
          'Erro',
          'Não foi possível atualizar a foto: $e',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      } else {
        // Re-lança o erro para ser tratado no saveProfile
        rethrow;
      }
    } finally {
      if (manageLoading) {
        isLoading.value = false;
      }
    }
  }
}
