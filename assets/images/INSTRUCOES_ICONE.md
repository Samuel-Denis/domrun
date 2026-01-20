# Instruções para Adicionar o Ícone do Aplicativo

## Passo 1: Adicionar a Imagem

1. Coloque a imagem do logo (a foto do escudo com o tênis) na pasta `assets/images/`
2. Renomeie o arquivo para: `app_icon.png`
3. **IMPORTANTE**: A imagem deve ser:
   - Formato: PNG (com fundo transparente, se possível)
   - Tamanho recomendado: **1024x1024 pixels** (ou maior, quadrada)
   - Resolução: Alta qualidade

## Passo 2: Gerar os Ícones

Após adicionar a imagem, execute no terminal:

```bash
flutter pub get
flutter pub run flutter_launcher_icons
```

Isso irá gerar automaticamente todos os tamanhos de ícone necessários para:
- Android (vários tamanhos: mdpi, hdpi, xhdpi, xxhdpi, xxxhdpi)
- iOS (todos os tamanhos necessários)

## Passo 3: Rebuild do App

Após gerar os ícones, faça um rebuild completo:

```bash
flutter clean
flutter pub get
flutter run
```

## Notas

- O ícone será usado em todas as plataformas (Android, iOS)
- O Android usará um ícone adaptativo (com fundo branco)
- Se a imagem não for quadrada, ela será centralizada e cortada
- Para melhor resultado, use uma imagem quadrada de alta qualidade
