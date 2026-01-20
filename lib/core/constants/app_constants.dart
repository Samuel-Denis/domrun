/// Constantes gerais da aplicação
class AppConstants {
  // Nome da aplicação
  static const String appName = 'NUR App';

  // Versão
  static const String appVersion = '1.0.0';

  // Configurações de localização padrão
  static const double defaultZoom = 15.0;
  static const double trackingZoom = 16.0;
  static const int defaultDistanceFilter = 5; // metros

  // Configurações de animação
  static const int cameraAnimationDuration = 1000; // milissegundos

  // Privatizar construtor para evitar instanciação
  AppConstants._();
}
