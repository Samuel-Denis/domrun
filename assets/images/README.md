# Pasta de Imagens

## Como adicionar uma imagem de mapa

1. Coloque sua imagem de mapa nesta pasta (`assets/images/`)
2. Nomeie o arquivo como `map_background.png` (ou outro formato: .jpg, .webp)
3. No arquivo `lib/app/auth/views/login_page.dart`, substitua:

```dart
// De:
MapBackground(
  opacity: 0.6,
  glowIntensity: 1.0,
),

// Para:
MapImageBackground(
  imagePath: 'assets/images/map_background.png',
  opacity: 1.0,
),
```

4. Execute `flutter pub get` para atualizar os assets

## Formatos suportados
- PNG (recomendado para transparência)
- JPG/JPEG
- WebP

## Tamanho recomendado
Para melhor qualidade, use uma imagem com resolução de pelo menos 1080x1920 pixels (proporção de tela de celular).
