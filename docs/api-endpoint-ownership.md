# Klippr API Endpoint Ownership

Fuente: Swagger `https://klippr-backend-production.up.railway.app/swagger/v1/swagger.json`.

## Klippr Business

- `POST /api/Authentication/sign-up/business`
- `/api/profiles/business*`
- `POST /api/verification/submit`
- `POST /api/promotions`
- `GET /api/promotions/businesses/{businessId}`
- `PUT /api/promotions/{promotionId}`
- `DELETE /api/promotions/{promotionId}`
- `POST /api/promotions/{promotionId}/publish`
- `POST /api/promotions/{promotionId}/cancel`
- `GET /api/redemptions/businesses/{businessId}`
- `POST /api/redemptions/tokens/{uniqueToken}/confirm`
- `GET /api/analytics/campaign/{campaignId}`
- `GET /api/analytics/dashboard/{businessId}`
- `POST /api/analytics/metrics`

## Compartidos

- `POST /api/Authentication/sign-in`
- `POST /api/Authentication/forgot-password`
- `PUT /api/Authentication/reset-password`
- `GET /api/promotions/{promotionId}`
- `GET /api/Users/{userId}`

## Fuera del cliente Business

- Endpoints Consumer: `POST /api/Authentication/sign-up/consumer`, `/api/profiles/consumer*`, `/api/v1/Preferences*`, `/api/v1/Favorites*`, `/api/reviews*`, `POST /api/redemptions`, `/api/redemptions/consumers/*`.
- Endpoints Admin: `/api/admin/**`, `POST /api/verification/approve`, `POST /api/verification/reject`.
- Reviews legacy: `/api/v1/Reviews*`; el contrato canónico social es `/api/reviews*`.
- `POST /api/analytics/abuse-reports` queda fuera hasta que exista un flujo explícito de reportes.
