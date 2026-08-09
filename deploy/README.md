# Pčelinjak deploy

SSH deploy na server (isti obrazac kao Farma).

## Prvi put

1. Kopiraj config (kao Farma):
   ```powershell
   copy deploy\config.example deploy\config
   ```
2. Popuni `DEPLOY_HOST`, `DEPLOY_USER`, `DEPLOY_PATH`, JWT, MySQL, mail, notification…
   Na shared hostu (`beeback`) koristi slobodne portove, npr. `BACKEND_PORT=8082`, `MYSQL_PORT=3310`,
   `NOTIFICATION_SERVICE_URL=http://host.docker.internal:8087`.
3. Jednokratni setup (git + Docker + clone):
   ```powershell
   .\deploy\deploy.ps1 -Setup
   ```
4. Deploy sa rebuild:
   ```powershell
   .\deploy\deploy.ps1 -Build
   ```

## Svakodnevni deploy

```powershell
.\deploy\deploy.ps1 -Build                   # prod (deploy/config)
.\deploy\deploy.ps1 -Environment test -Build
.\deploy\deploy.ps1 -SkipPull -Build         # bez git pull
.\deploy\deploy.ps1 -Down                    # zaustavi stack
```

## Backup (opciono)

```powershell
.\deploy\deploy.ps1 -SetupLocalBackup   # lokalni dumpovi + cron
.\deploy\deploy.ps1 -SetupBackup        # S3 + cron (treba S3_* u configu)
.\deploy\deploy.ps1 -BackupNow          # odmah pokreni S3 backup
```

## Database / Liquibase

Šema ide **isključivo preko Liquibase** (`hibernate.generation=none`).

Changelog: `pcelinjak-backend/src/main/resources/db/changelog/`

- `20260809-00-initial-schema` — sve tabele (prazna baza)
- `20260809-0x-work-group-*` — dedupe + unique (stare baze; na fresh install MARK_RAN)

**Preporuka ako smeš da obrišeš podatke:** drop + create baze, pa deploy:

```bash
docker exec -i <mysql> mysql -u root -p"$MYSQL_ROOT_PASSWORD" \
  -e "DROP DATABASE IF EXISTS pcelinjak; CREATE DATABASE pcelinjak CHARACTER SET utf8mb4; GRANT ALL ON pcelinjak.* TO 'pcelinjak'@'%'; FLUSH PRIVILEGES;"
```

Zatim `.\deploy\deploy.ps1 -Build` — Liquibase kreira šemu na startu backenda.

Bez brisanja produkcije: samo deploy (initial MARK_RAN, zatim dedupe → unique).

Ručni fallback:

```bash
bash deploy/scripts/dedupe-work-groups.sh
```

Config sa tajnama (`config`, `config.local`, `config.test*`) ne commitovati.
