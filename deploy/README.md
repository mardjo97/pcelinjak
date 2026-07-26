# Pčelinjak deploy

SSH deploy na server (isti obrazac kao Farma).

## Prvi put

1. Kopiraj config:
   ```powershell
   copy deploy\config.example deploy\config.local
   ```
2. Popuni `DEPLOY_HOST`, `DEPLOY_USER`, `DEPLOY_PATH`, JWT, MySQL, mail, notification…
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
.\deploy\deploy.ps1 -Build                 # prod (config / config.local)
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
