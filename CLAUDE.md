# Teklif Pro — Proje Bağlamı

## Proje Hakkında
Flutter tabanlı saha servis yönetim uygulaması. Serbest/küçük işletmeler için müşteri, teklif, fatura ve servis takibi.

## VPS Sunucu
- **IP:** 178.210.161.55 — SSH port: 22667
- **User:** salihceylan
- **OS:** Ubuntu Linux 5.15.0
- **Disk:** 49GB (19GB kullanılmış), **RAM:** 1.9GB

### Sunucudaki Servisler
- **Nginx** — reverse proxy (80/443)
- **PM2** — process manager (teklif-pro-api, kapi-api)
- **Docker** — site_kapi_kontrol_postgres (PostgreSQL 16 — teklif_pro DB burada!)
- **Redis** — localhost:6379
- **Mosquitto** — MQTT broker (port 8883)
- **PHP 8.3-FPM**

### Diğer Projeler
- `site_kapi_kontrol` — /var/www/site_kapi_kontrol
- `my_ai` — Docker: AI API + Qdrant + Ollama + Redis + Postgres (port 8000)
- `workflow` — /var/www/workflow

## Teklif Pro API (Backend)

### Konum & Çalıştırma
- **Dizin:** `/opt/teklif_pro`
- **Start:** `venv/bin/uvicorn api.main:app --host 0.0.0.0 --port 8001 --workers 2`
- **PM2 name:** `teklif-pro-api`
- **Logs:** `~/.pm2/logs/teklif-pro-{out,error}.log`

### Teknoloji
- FastAPI + SQLAlchemy (async) + asyncpg
- Uvicorn, 2 worker

### .env (`/opt/teklif_pro/.env`)
```
DATABASE_URL=postgresql+asyncpg://postgres:postgres@127.0.0.1:5432/teklif_pro
SECRET_KEY=teklif_pro_super_secret_key_2024_gudeteknoloji
ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=10080
```

### API Yapısı
```
/opt/teklif_pro/api/
├── main.py         # FastAPI app, CORS, router kayıtları
├── database.py     # SQLAlchemy async engine
├── models.py       # SQLAlchemy ORM modelleri
├── schemas.py      # Pydantic şemaları
├── auth.py         # JWT token işlemleri
└── routers/
    ├── auth.py
    ├── customers.py
    ├── service_requests.py
    ├── quotes.py
    ├── visits.py
    └── invoices.py
```

### Endpoint Prefix
`/api/v1/` — örn: GET `/api/v1/customers/`

## Veritabanı

- **Container:** `site_kapi_kontrol_postgres` (Docker)
- **DB adı:** `teklif_pro`
- **User/Pass:** `postgres` / `postgres`
- **Port:** 127.0.0.1:5432

### Tablolar
| Tablo | Açıklama |
|-------|----------|
| users | Kullanıcılar (JWT auth) |
| customers | Müşteriler |
| service_requests | Servis talepleri |
| quotes | Teklifler |
| quote_items | Teklif kalemleri |
| service_visits | Ziyaretler |
| invoices | Faturalar |
| invoice_items | Fatura kalemleri |

### DB Erişimi (sunucudan)
```bash
docker exec site_kapi_kontrol_postgres psql -U postgres -d teklif_pro
```

## Nginx (teklif.gudeteknoloji.com.tr)
HTTPS → proxy_pass http://127.0.0.1:8001

## Flutter App (bu repo)

### API
- Base URL: `https://teklif.gudeteknoloji.com.tr/api/v1`
- Auth: Bearer token (SharedPreferences'ta saklanır)
- Client: Dio (`lib/core/api_client.dart`) — 15s connect, 30s receive timeout

### Mimari
- **State Management:** Provider + ChangeNotifier
- **Routing:** GoRouter (`lib/core/router.dart`) — korumalı rotalar, unauthenticated → /login
- **Storage:** SharedPreferences wrapper (`lib/core/storage.dart`)
- **Locale:** Türkçe (tr_TR), intl paketi

### Modüller

| Modül | Model | Provider | Service | Screens |
|-------|-------|----------|---------|---------|
| Auth | user.dart | auth_provider.dart | auth_service.dart | auth/ |
| Müşteriler | customer.dart | customer_provider.dart | customer_service.dart | customers/ |
| Servis Talepleri | service_request.dart | service_request_provider.dart | service_request_service.dart | service_requests/ |
| Teklifler | quote.dart | quote_provider.dart | quote_service.dart | quotes/ |
| Ziyaretler | visit.dart | visit_provider.dart | visit_service.dart | visits/ |
| Faturalar | invoice.dart | invoice_provider.dart | invoice_service.dart | invoices/ |

### Ekranlar
- `/` → DashboardScreen
- `/login`, `/register`
- `/customers`, `/customers/new`, `/customers/:id/edit`
- `/service-requests`, `/service-requests/new`, `/service-requests/:id/edit`
- `/quotes`, `/quotes/new`, `/quotes/:id/edit`
- `/visits`, `/visits/new`, `/visits/:id/edit`
- `/invoices`, `/invoices/new`, `/invoices/:id/edit`

### Model Statüsleri
- **Quote:** draft, sent, accepted, rejected, expired
- **Invoice:** draft, sent, paid, overdue, cancelled
- **ServiceRequest:** new, quoted, in_progress, completed, cancelled
- **Visit:** scheduled, in_progress, completed, cancelled

## Geliştirme Notları
- Tüm UI metinleri Türkçe
- Dashboard'da zaman bazlı selamlama (Günaydın/İyi günler/İyi akşamlar)
- API restart: `pm2 restart teklif-pro-api`
- API logları: `pm2 logs teklif-pro-api`
