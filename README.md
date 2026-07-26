# Pčelinjak

Offline-first evidencija pčelinjaka: **Flutter** mobilna app + **Quarkus** backend + **MySQL** (Docker stack kao Farma).

## Struktura

```
pcelinjak/
  mobile/                 # Flutter (Android / iOS)
  pcelinjak-backend/      # Quarkus 3.6 + Panache
  docker-compose.yml
  .env.example
```

## Backend (Docker)

```bash
cp .env.example .env
docker compose up --build -d
```

- API: http://localhost:8081  
- Health: `GET /api/ping`  
- Auth: `POST /auth/register` i `POST /auth/login` (body: email, password, name?, deviceUuid)

**Jedan uređaj po nalogu:** svaki zaštićeni zahtev mora imati header `X-Device-Id`. Login sa novog telefona preuzima nalog; stari dobija `401` sa `code: DEVICE_MISMATCH`.

Lokalni Quarkus (bez Dockera, MySQL mora biti podignut):

```bash
cd pcelinjak-backend
mvn quarkus:dev
```

## Flutter

```bash
cd mobile
flutter pub get
flutter run
```

Na Android emulatoru default server je `http://10.0.2.2:8081` (host localhost). URL se može promeniti na login ekranu.

Tok:

1. Registracija / prijava (ili offline)
2. Početna → pčelinjaci + grupe
3. Pčelinjak → tabela košnica → **Pristupi**
4. Na košnici: **Napomena**, **Matica**, **Prinos**
5. Grupe (seljene, paša, zamena matice, kontrola, dohrana, reprodukcija)
6. Sync → „Pošalji na server”
7. Izvoz barkodova (meni → Izvezi barkodove) za subvencije / Prilog 4

## Napomena

Windows Developer Mode može biti potreban zbog Flutter plugin symlinkova.
