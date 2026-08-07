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

Config sa tajnama (`config`, `config.local`, `config.test*`) ne commitovati.
