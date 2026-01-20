# Estrutura de Dados da API - Tela de Perfil

Este documento descreve a estrutura de dados que a API precisa retornar para a tela de perfil funcionar completamente.

## Endpoint: GET /users/profile/stats

Retorna as estatísticas do usuário e suas conquistas.

### Resposta Esperada:

```json
{
  "user": {
    "id": "42d001c5-39bc-4aa9-8318-4d6644737fc1",
    "username": "speedylucas",
    "email": "lucas@example.com",
    "name": "Lucas Silva",
    "photoUrl": "https://example.com/photo.jpg",
    "color": "#7B2CBF",
    "biography": "Dominando as ruas da Zona Sul, um quarteirão por vez. 🏃‍♂️☁️",
    "level": 24,
    "createdAt": "2026-01-08T18:34:10.059Z",
    "updatedAt": "2026-01-08T22:30:16.804Z",
    "lastLogin": "2026-01-08T22:30:16.804Z"
  },
  "stats": {
    "totalDistance": 450.0,
    "territoryPercentage": 15.0,
    "trophies": 12
  },
  "achievements": [
    {
      "id": "ach_001",
      "title": "Primeiros Passos",
      "description": "Corra 3km em uma sessão",
      "icon": "running",
      "iconColor": "#00FF00",
      "status": "completed",
      "progress": null,
      "progressText": null
    },
    {
      "id": "ach_002",
      "title": "Dominador Local",
      "description": "Domine 5 territórios",
      "icon": "map",
      "iconColor": "#7B2CBF",
      "status": "completed",
      "progress": null,
      "progressText": null
    },
    {
      "id": "ach_003",
      "title": "Viajante",
      "description": "Domine em outra cidade/país",
      "icon": "globe",
      "iconColor": "#808080",
      "status": "inProgress",
      "progress": 0.5,
      "progressText": "50%"
    },
    {
      "id": "ach_004",
      "title": "Rei da Montanha",
      "description": "Vença 3 temporadas seguidas",
      "icon": "trophy",
      "iconColor": "#808080",
      "status": "locked",
      "progress": null,
      "progressText": null
    }
  ]
}
```

## Campos Detalhados:

### User Object:
- `id` (string, obrigatório): ID único do usuário
- `username` (string, obrigatório): Nome de usuário
- `email` (string, obrigatório): Email do usuário
- `name` (string, opcional): Nome completo
- `photoUrl` (string, opcional): URL da foto de perfil
- `color` (string, opcional): Cor do usuário em hexadecimal (ex: "#7B2CBF")
- `biography` (string, opcional): Biografia do usuário
- `level` (number, opcional): Nível do usuário (ex: 24)
- `createdAt` (string ISO 8601, obrigatório): Data de criação
- `updatedAt` (string ISO 8601, opcional): Data de atualização
- `lastLogin` (string ISO 8601, opcional): Último login

### Stats Object:
- `totalDistance` (number, obrigatório): Distância total percorrida em KM
- `territoryPercentage` (number, obrigatório): Porcentagem de território dominado (0-100)
- `trophies` (number, obrigatório): Número total de troféus/conquistas

### Achievement Object:
- `id` (string, obrigatório): ID único da conquista
- `title` (string, obrigatório): Título da conquista
- `description` (string, obrigatório): Descrição da conquista
- `icon` (string, obrigatório): Nome do ícone ("running", "map", "globe", "trophy")
- `iconColor` (string, obrigatório): Cor do ícone em hexadecimal
- `status` (string, obrigatório): Status da conquista ("completed", "inProgress", "locked")
- `progress` (number, opcional): Progresso de 0.0 a 1.0 (apenas se status = "inProgress")
- `progressText` (string, opcional): Texto de progresso (ex: "50%") (apenas se status = "inProgress")

## Ícones Suportados:
- `"running"` ou `"directions_run"` → Icons.directions_run
- `"map"` ou `"map_outlined"` → Icons.map_outlined
- `"globe"` ou `"public"` → Icons.public
- `"trophy"` ou `"emoji_events"` → Icons.emoji_events

## Status de Conquistas:
- `"completed"`: Conquista concluída (mostra check verde)
- `"inProgress"`: Conquista em progresso (mostra barra de progresso e porcentagem)
- `"locked"`: Conquista bloqueada (mostra ícone de cadeado)

## Notas:
- Todos os valores numéricos devem ser números (não strings)
- Datas devem estar no formato ISO 8601
- Cores devem estar no formato hexadecimal com "#" (ex: "#7B2CBF")
- O campo `level` é novo e deve ser adicionado ao UserModel se ainda não existir
