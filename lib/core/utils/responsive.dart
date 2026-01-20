import 'package:flutter/material.dart';

/// Utilitário para tornar o aplicativo responsivo
/// Adapta tamanhos, espaçamentos e fontes para diferentes tamanhos de tela
class Responsive {
  final BuildContext context;
  final MediaQueryData mediaQuery;

  Responsive(this.context) : mediaQuery = MediaQuery.of(context);

  /// Largura da tela
  double get width => mediaQuery.size.width;

  /// Altura da tela
  double get height => mediaQuery.size.height;

  /// Largura da tela sem padding horizontal
  double get widthWithoutPadding => width - (paddingHorizontal * 2);

  /// Altura da tela sem padding vertical
  double get heightWithoutPadding => height - (paddingVertical * 2);

  /// Padding horizontal padrão (responsivo)
  double get paddingHorizontal => width * 0.05;

  /// Padding vertical padrão (responsivo)
  double get paddingVertical => height * 0.02;

  /// Verifica se é tablet (largura >= 600)
  bool get isTablet => width >= 600;

  /// Verifica se é celular pequeno (largura < 360)
  bool get isSmallPhone => width < 360;

  /// Verifica se é celular médio (360 <= largura < 600)
  bool get isMediumPhone => width >= 360 && width < 600;

  /// Verifica se é celular grande (600 <= largura < 900)
  bool get isLargePhone => width >= 600 && width < 900;

  /// Retorna um valor proporcional à largura da tela
  /// [value] - Valor base para telas de 360px de largura
  double wp(double value) {
    return (value / 360) * width;
  }

  /// Retorna um valor proporcional à altura da tela
  /// [value] - Valor base para telas de 800px de altura
  double hp(double value) {
    return (value / 800) * height;
  }

  /// Retorna um tamanho de fonte responsivo
  /// [size] - Tamanho base da fonte
  double fontSize(double size) {
    if (isTablet) {
      return size * 1.3; // 30% maior em tablets
    } else if (isSmallPhone) {
      return size * 0.9; // 10% menor em celulares pequenos
    }
    return size;
  }

  /// Retorna um espaçamento responsivo
  /// [value] - Valor base do espaçamento
  double spacing(double value) {
    if (isTablet) {
      return value * 1.5; // 50% maior em tablets
    } else if (isSmallPhone) {
      return value * 0.8; // 20% menor em celulares pequenos
    }
    return value;
  }

  /// Retorna um tamanho de ícone responsivo
  /// [size] - Tamanho base do ícone
  double iconSize(double size) {
    if (isTablet) {
      return size * 1.2;
    } else if (isSmallPhone) {
      return size * 0.9;
    }
    return size;
  }

  /// Retorna um tamanho de botão responsivo
  /// [baseHeight] - Altura base do botão
  double buttonHeight(double baseHeight) {
    if (isTablet) {
      return baseHeight * 1.2;
    } else if (isSmallPhone) {
      return baseHeight * 0.9;
    }
    return baseHeight;
  }

  /// Retorna um tamanho de container responsivo
  /// [baseSize] - Tamanho base do container
  double containerSize(double baseSize) {
    if (isTablet) {
      return baseSize * 1.3;
    } else if (isSmallPhone) {
      return baseSize * 0.85;
    }
    return baseSize;
  }

  /// Retorna o número de colunas para grid responsivo
  int get gridColumns {
    if (isTablet) {
      return 3;
    } else if (width >= 400) {
      return 2;
    }
    return 1;
  }

  /// Retorna o tamanho máximo de largura para conteúdo
  /// Útil para tablets, mantém o conteúdo centralizado
  double get maxContentWidth {
    if (isTablet) {
      return 1200;
    }
    return width;
  }
}

/// Extensão para facilitar o acesso ao Responsive
extension ResponsiveExtension on BuildContext {
  Responsive get responsive => Responsive(this);
}
