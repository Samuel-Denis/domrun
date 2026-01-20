/// Constantes relacionadas a APIs e serviços externos
class ApiConstants {
  // Token do Mapbox (deve ser movido para variáveis de ambiente em produção)
  static const String mapboxAccessToken =
      "pk.eyJ1Ijoic2FtdWVsLWRlbmlzIiwiYSI6ImNtazRpZXlvazA5MG8zZHExMTFnMmRvcmkifQ.UWnRSHeJbol3vBt65GWXsQ";

  // URL base da API do servidor
  static const String baseUrl = 'http://192.168.0.102:3000';

  // Endpoints da API
  static const String registerEndpoint = '/auth/register';
  static const String loginEndpoint = '/auth/login';
  static const String refreshEndpoint = '/auth/refresh';
  static const String logoutEndpoint = '/auth/logout';
  static const String forgotPasswordEndpoint = '/auth/forgot-password';

  // Endpoints de territórios
  static const String territoriesEndpoint = '/territories';
  static const String mapTerritoriesEndpoint =
      '/runs/map'; // GeoJSON FeatureCollection

  // Endpoints de corridas
  static const String runsEndpoint = '/runs'; // Corrida com território
  static const String simpleRunEndpoint =
      '/runs/simple'; // Corrida simples (sem território)

  // Endpoints de conquistas
  static const String achievementsEndpoint = '/users/me/achievements';

  // Endpoints de perfil
  static const String updateProfileEndpoint = '/users/profile';
  static const String profileCompleteEndpoint = '/users/profile/complete';
  static const String trophyRankingEndpoint = '/users/ranking/trophies';
  static const String publicUserEndpoint = '/users';

  // Endpoints de batalhas
  static const String battlesQueueEndpoint = '/battles/queue';
  static const String battlesSubmitEndpoint = '/battles/submit';
  static const String battlesHistoryEndpoint = '/battles/history';
  static const String battlesCancelEndpoint =
      '/battles'; // DELETE /battles/:battleId

  // Estilos de mapa do Mapbox
  // Estilos disponíveis:
  // - streets-v12: Estilo padrão com ruas detalhadas
  // - outdoors-v12: Estilo para atividades ao ar livre
  // - light-v11: Estilo claro e minimalista
  // - dark-v11: Estilo escuro (ideal para apps com tema dark)
  // - satellite-v9: Imagens de satélite
  // - satellite-streets-v12: Satélite com ruas sobrepostas
  static const String mapboxStyleDark =
      //mapbox://styles/samuel-denis/cmkhuygwe00ju01rx62edf61u
      'mapbox://styles/mapbox/dark-v11';
  //'mapbox://styles/samuel-denis/cmkips5kn000501qphymyfy22';
  static const String mapboxStyleLight = 'mapbox://styles/mapbox/light-v11';
  static const String mapboxStyleStreets = 'mapbox://styles/mapbox/streets-v12';
  static const String mapboxStyleOutdoors =
      'mapbox://styles/mapbox/outdoors-v12';
  static const String mapboxStyleSatellite =
      'mapbox://styles/mapbox/satellite-v9';
  static const String mapboxStyleSatelliteStreets =
      'mapbox://styles/mapbox/satellite-streets-v12';

  // Privatizar construtor para evitar instanciação
  ApiConstants._();
}
