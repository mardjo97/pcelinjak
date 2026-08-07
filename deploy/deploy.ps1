# Pcelinjak deploy script – sync and run docker compose on server
# Usage: .\deploy.ps1 [-Environment prod|test] [--build] [--skip-pull] [--pull] [--setup] [--down]
# With -Setup: installs git and Docker on server if missing, then clones repo.
# Git pull: kao na prod — origin na serveru SSH (git@github.com:...). Opciono SKIP_GIT_PULL / GIT_ORIGIN_SSH u configu (vidi config.example).

param(
    [switch]$Build,       # run docker compose up -d --build
    [switch]$SkipPull,    # skip git pull on server
    [switch]$Pull,        # forsiraj git pull (i kada bi inace bio preskocen)
    [switch]$Setup,       # one-time: create DEPLOY_PATH on server and clone repo
    [switch]$Down,        # run docker compose down on server
    [switch]$SetupBackup, # one-time: setup S3 backup config + cron
    [switch]$SetupLocalBackup, # one-time: setup local emergency backup + cron
    [switch]$BackupNow,   # run backup script immediately on server
    [ValidateSet("prod", "test")]
    [string]$Environment = "prod"
)

$ErrorActionPreference = "Stop"
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$projectRoot = Split-Path -Parent $scriptDir

# Load config by environment
$configCandidates = @()
if ($Environment -eq "test") {
    $configCandidates += (Join-Path $scriptDir "config.test.local")
    $configCandidates += (Join-Path $scriptDir "config.test")
} else {
    $configCandidates += (Join-Path $scriptDir "config.local")
    $configCandidates += (Join-Path $scriptDir "config")
}

$configPath = $null
foreach ($candidate in $configCandidates) {
    if (Test-Path $candidate) {
        $configPath = $candidate
        break
    }
}
if (-not (Test-Path $configPath)) {
    if ($Environment -eq "test") {
        Write-Error "Missing test deploy config. Copy deploy\config.test.example to deploy\config.test (or config.test.local) and set DEPLOY_HOST, DEPLOY_USER, DEPLOY_PATH."
    } else {
        Write-Error "Missing deploy config. Copy deploy\config.example to deploy\config (or config.local) and set DEPLOY_HOST, DEPLOY_USER, DEPLOY_PATH."
    }
    exit 1
}

$lines = Get-Content $configPath | Where-Object { $_ -match "^\s*[A-Za-z_][A-Za-z0-9_]*=" }
$config = @{}
foreach ($line in $lines) {
    if ($line -match "^\s*([A-Za-z_][A-Za-z0-9_]*)=(.*)$") {
        $config[$matches[1]] = $matches[2].Trim().Trim('"').Trim("'")
    }
}

$host_name = $config["DEPLOY_HOST"]
$user = $config["DEPLOY_USER"]
$path = $config["DEPLOY_PATH"]
$sshKey = $config["SSH_KEY"]
$composeProjectName = $config["COMPOSE_PROJECT_NAME"]
$composeFilesRaw = $config["COMPOSE_FILES"]
$deployBackendUrl = $config["DEPLOY_BACKEND_URL"]

if (-not $host_name -or -not $user -or -not $path) {
    Write-Error "Config must set DEPLOY_HOST, DEPLOY_USER, DEPLOY_PATH."
    exit 1
}
if (-not $composeProjectName) {
    if ($Environment -eq "test") { $composeProjectName = "pcelinjak-test" } else { $composeProjectName = "pcelinjak" }
}
if (-not $deployBackendUrl) {
    if ($Environment -eq "test") {
        $deployBackendUrl = "http://${host_name}:8088"
    } else {
        $deployBackendUrl = "http://${host_name}:8082"
    }
}

$sshTarget = "${user}@${host_name}"
$sshOpts = @()
if ($sshKey) { $sshOpts = @("-i", $sshKey) }

function Invoke-Remote {
    param([string]$Command)
    $argList = $sshOpts + @("$sshTarget", $Command)
    & ssh $argList
    if ($LASTEXITCODE -ne 0) { throw "ssh failed: $Command" }
}

function Invoke-RemoteScript {
    param([string]$Script)
    # LF u stringu; tr \015 skida CR koji PowerShell/ssh cesto doda pri pipe-u
    $Script = $Script -replace "`r`n", "`n" -replace "`r", ""
    $sshArgs = @()
    if ($sshKey) { $sshArgs += @("-i", $sshKey) }
    $sshArgs += @("$sshTarget", 'tr -d ''\015'' | bash -s')
    $Script | & ssh $sshArgs
    if ($LASTEXITCODE -ne 0) { throw "Remote script failed." }
}

function Escape-BashSingleQuotedValue {
    param([string]$Value)
    if ($null -eq $Value) { return "" }
    return ($Value -replace "'", "'""'""'")
}

Write-Host "Deploy target: $sshTarget ($path)" -ForegroundColor Cyan
Write-Host "Environment: $Environment | Config: $configPath | Compose project: $composeProjectName" -ForegroundColor DarkCyan

$composeParts = @("docker", "compose", "-p", "'$($composeProjectName -replace "'", "'\\''")'")
if ($composeFilesRaw) {
    $composeFiles = $composeFilesRaw -split "\s+" | Where-Object { $_ -and $_.Trim() -ne "" }
    foreach ($file in $composeFiles) {
        $fileEscaped = $file -replace "'", "'\\''"
        $composeParts += @("-f", "'$fileEscaped'")
    }
}
$composeCmd = ($composeParts -join " ")

if ($Setup) {
    $repoUrl = ( & git -C $projectRoot remote get-url origin 2>$null )
    if (-not $repoUrl) {
        Write-Error "Could not get git remote origin URL. Run from repo root and ensure origin is set."
        exit 1
    }
    $repoUrl = $repoUrl.Trim()
    $parentDir = Split-Path -Parent $path
    $pathEscaped = $path -replace "'", "'\\''"
    $urlEscaped = $repoUrl -replace "'", "'\\''"
    $parentEscaped = $parentDir -replace "'", "'\\''"
    # Literal $(id -u) for remote bash (avoid PowerShell expanding it)
    $idU = [char]36 + '(id -u)'

    $bootstrap = @"
set -e
export DEPLOY_PATH='$pathEscaped'
export REPO_URL='$urlEscaped'
export PARENT_DIR='$parentEscaped'
SUDO=''; [ $idU -ne 0 ] && SUDO='sudo'

if [ -x /usr/bin/dpkg ]; then
  echo 'Ensuring dpkg is configured (dpkg --configure -a)...'
  `$SUDO env DEBIAN_FRONTEND=noninteractive dpkg --configure -a
fi

echo '=== Checking Git ==='
if command -v git >/dev/null 2>&1; then
  echo 'Git already installed.'
else
  echo 'Installing Git...'
  if [ -x /usr/bin/apt-get ]; then
    `$SUDO apt-get update -qq && `$SUDO apt-get install -y git
  elif [ -x /usr/bin/dnf ]; then
    `$SUDO dnf install -y git
  elif [ -x /usr/bin/yum ]; then
    `$SUDO yum install -y git
  elif [ -x /sbin/apk ]; then
    `$SUDO apk add --no-cache git
  else
    echo 'Cannot install Git: no supported package manager (apt/dnf/yum/apk).' >&2
    exit 1
  fi
fi

echo '=== Checking Docker ==='
if command -v docker >/dev/null 2>&1 && docker info >/dev/null 2>&1; then
  echo 'Docker already installed and running.'
else
  if ! command -v docker >/dev/null 2>&1; then
    echo 'Installing Docker...'
    curl -fsSL https://get.docker.com | `$SUDO sh
  fi
  echo 'Starting Docker...'
  `$SUDO systemctl start docker 2>/dev/null || `$SUDO service docker start 2>/dev/null || true
  `$SUDO systemctl enable docker 2>/dev/null || true
  sleep 2
  if ! docker info >/dev/null 2>&1; then
    echo 'Docker failed to start. Check: systemctl status docker' >&2
    exit 1
  fi
fi

echo '=== Checking Docker Compose ==='
if docker compose version >/dev/null 2>&1; then
  echo 'Docker Compose (plugin) OK.'
elif command -v docker-compose >/dev/null 2>&1; then
  echo 'Docker Compose (standalone) OK.'
else
  echo 'Installing Docker Compose plugin...'
  if [ -x /usr/bin/apt-get ]; then
    `$SUDO apt-get update -qq && `$SUDO apt-get install -y docker-compose-plugin
  elif [ -x /usr/bin/dnf ]; then
    `$SUDO dnf install -y docker-compose-plugin
  elif [ -x /usr/bin/yum ]; then
    `$SUDO yum install -y docker-compose-plugin
  else
    echo 'Install docker-compose-plugin manually, then re-run setup.' >&2
    exit 1
  fi
fi

echo '=== Creating deploy path and cloning repo ==='
mkdir -p "`$PARENT_DIR"
if [ ! -d "`$DEPLOY_PATH" ]; then
  git clone "`$REPO_URL" "`$DEPLOY_PATH"
  echo "Cloned into `$DEPLOY_PATH"
else
  echo "Path `$DEPLOY_PATH already exists. Skipping clone."
fi
echo '=== Setup complete ==='
"@
    Write-Host "One-time setup: checking/installing Git and Docker on server, then cloning repo..." -ForegroundColor Yellow
    Invoke-RemoteScript $bootstrap
    Write-Host "Setup done. Run .\deploy\deploy.ps1 -Build to deploy." -ForegroundColor Green
    exit 0
}

if ($Down) {
    Write-Host "Stopping containers on server..." -ForegroundColor Yellow
    Invoke-Remote "cd '$path' && $composeCmd down"
    Write-Host "Done." -ForegroundColor Green
    exit 0
}

$doGitPull = -not $SkipPull
if ($doGitPull -and -not $Pull) {
    $backupOnlyRun = ($SetupBackup -or $BackupNow -or $SetupLocalBackup) -and -not $Build
    if ($backupOnlyRun) {
        Write-Host "Skipping git pull (SetupBackup / BackupNow / SetupLocalBackup). Koristi -Pull da forsiras." -ForegroundColor DarkYellow
        $doGitPull = $false
    }
}
if ($doGitPull -and -not $Pull -and $config["SKIP_GIT_PULL"] -eq "1") {
    Write-Host "Skipping git pull (SKIP_GIT_PULL=1 u configu). Koristi -Pull da forsiras." -ForegroundColor DarkYellow
    $doGitPull = $false
}
if ($doGitPull) {
    Write-Host "Pulling latest on server..." -ForegroundColor Yellow
    $pathBashEsc = Escape-BashSingleQuotedValue $path
    $gitSsh = $config["GIT_ORIGIN_SSH"]
    if ($gitSsh) {
        $gitSshEsc = Escape-BashSingleQuotedValue $gitSsh.Trim()
        $pullScript = @'
set -e
cd '__DEPLOY_PATH__'
SSHURL='__GIT_SSH__'
u=$(git remote get-url origin 2>/dev/null || true)
case "$u" in
  https://github.com/*|http://github.com/*)
    echo "Prebacujem origin sa HTTPS na SSH ($SSHURL)..."
    git remote set-url origin "$SSHURL"
    ;;
esac
GIT_TERMINAL_PROMPT=0 git pull --autostash
'@
        $pullScript = $pullScript.Replace("__DEPLOY_PATH__", $pathBashEsc).Replace("__GIT_SSH__", $gitSshEsc)
        Invoke-RemoteScript $pullScript
    } else {
        Invoke-Remote "cd '$pathBashEsc' && GIT_TERMINAL_PROMPT=0 git pull --autostash"
    }
}

$pathEscapedForRemote = $path -replace "'", "'\\''"
# MAIL_PASSWORD iz configa (deploy/config ili config.local) – za slanje mailova u produkciji
$mailPassword = $config["MAIL_PASSWORD"]
$mailFrom = $config["MAIL_FROM"]
$mailHost = $config["MAIL_HOST"]
$mailPort = $config["MAIL_PORT"]
$mailUsername = $config["MAIL_USERNAME"]
$exportMail = ""
if ($mailPassword) {
    $mailEscaped = $mailPassword -replace "'", "'\\''"
    $exportMail += "export MAIL_PASSWORD='$mailEscaped'; "
}
if ($mailFrom) {
    $mailFromEscaped = $mailFrom -replace "'", "'\\''"
    $exportMail += "export MAIL_FROM='$mailFromEscaped'; "
}
if ($mailHost) {
    $mailHostEscaped = $mailHost -replace "'", "'\\''"
    $exportMail += "export MAIL_HOST='$mailHostEscaped'; "
}
if ($mailPort) {
    $mailPortEscaped = $mailPort -replace "'", "'\\''"
    $exportMail += "export MAIL_PORT='$mailPortEscaped'; "
}
if ($mailUsername) {
    $mailUsernameEscaped = $mailUsername -replace "'", "'\\''"
    $exportMail += "export MAIL_USERNAME='$mailUsernameEscaped'; "
}

# SENTRY_DSN iz configa (deploy/config ili config.local) – za error alerting
$sentryDsn = $config["SENTRY_DSN"]
$sentryEnabled = $config["SENTRY_ENABLED"]
$exportSentry = ""
if ($sentryDsn) {
    $sentryEscaped = $sentryDsn -replace "'", "'\\''"
    $exportSentry = "export SENTRY_DSN='$sentryEscaped'; "
}
if (-not $sentryEnabled) { $sentryEnabled = "true" }
$sentryEnabledEscaped = $sentryEnabled -replace "'", "'\\''"
$exportSentryEnabled = "export SENTRY_ENABLED='$sentryEnabledEscaped'; "
$jwtSecret = $config["PCELINJAK_JWT_SECRET"]
$exportJwt = ""
if ($jwtSecret) {
    $jwtSecretEscaped = $jwtSecret -replace "'", "'\\''"
    $exportJwt = "export PCELINJAK_JWT_SECRET='$jwtSecretEscaped'; "
}
$jwtExp = $config["PCELINJAK_JWT_EXPIRATION_SECONDS"]
if ($jwtExp) {
    $jwtExpEscaped = $jwtExp -replace "'", "'\\''"
    $exportJwt += "export PCELINJAK_JWT_EXPIRATION_SECONDS='$jwtExpEscaped'; "
}

$notificationUrl = $config["NOTIFICATION_SERVICE_URL"]
$notificationKey = $config["NOTIFICATION_API_KEY"]
$notificationEnabled = $config["NOTIFICATION_ENABLED"]
$exportNotification = ""
if ($notificationUrl) {
    $notificationUrlEscaped = $notificationUrl -replace "'", "'\\''"
    $exportNotification += "export NOTIFICATION_SERVICE_URL='$notificationUrlEscaped'; "
}
if ($notificationKey) {
    $notificationKeyEscaped = $notificationKey -replace "'", "'\\''"
    $exportNotification += "export NOTIFICATION_API_KEY='$notificationKeyEscaped'; "
}
if ($notificationEnabled) {
    $notificationEnabledEscaped = $notificationEnabled -replace "'", "'\\''"
    $exportNotification += "export NOTIFICATION_ENABLED='$notificationEnabledEscaped'; "
}

$backendPort = $config["BACKEND_PORT"]
$mysqlPort = $config["MYSQL_PORT"]
$mysqlRootPassword = $config["MYSQL_ROOT_PASSWORD"]
$mysqlDatabase = $config["MYSQL_DATABASE"]
$mysqlUser = $config["MYSQL_USER"]
$mysqlPassword = $config["MYSQL_PASSWORD"]
$backendLogDir = $config["BACKEND_LOG_DIR"]
$mailBaseUrl = $config["PCELINJAK_MAIL_BASE_URL"]
if (-not $backendPort) {
    # Shared host: 8081 = farma; prod default 8082
    if ($Environment -eq "test") { $backendPort = "8088" } else { $backendPort = "8082" }
}
if (-not $mysqlPort) {
    # Shared host: 3306 = farma; prod default 3310
    if ($Environment -eq "test") { $mysqlPort = "3311" } else { $mysqlPort = "3310" }
}
if (-not $backendLogDir) {
    if ($Environment -eq "test") { $backendLogDir = "backend-test" } else { $backendLogDir = "backend" }
}
if (-not $mailBaseUrl) { $mailBaseUrl = $deployBackendUrl }
if (-not $mysqlRootPassword) { $mysqlRootPassword = "change-me-root" }
if (-not $mysqlDatabase) { $mysqlDatabase = "pcelinjak" }
if (-not $mysqlUser) { $mysqlUser = "pcelinjak" }
if (-not $mysqlPassword) { $mysqlPassword = "change-me-app" }

$mysqlVolumeName = $config["PCELINJAK_MYSQL_VOLUME_NAME"]
if (-not $mysqlVolumeName) {
    if ($Environment -eq "test") { $mysqlVolumeName = "pcelinjak-test_mysql_data" } else { $mysqlVolumeName = "pcelinjak_mysql_data" }
}

$backendPortEscaped = $backendPort -replace "'", "'\\''"
$mysqlPortEscaped = $mysqlPort -replace "'", "'\\''"
$backendLogDirEscaped = $backendLogDir -replace "'", "'\\''"
$mailBaseUrlEscaped = $mailBaseUrl -replace "'", "'\\''"
$mysqlVolumeNameEscaped = $mysqlVolumeName -replace "'", "'\\''"
$mysqlRootPasswordEscaped = $mysqlRootPassword -replace "'", "'\\''"
$mysqlDatabaseEscaped = $mysqlDatabase -replace "'", "'\\''"
$mysqlUserEscaped = $mysqlUser -replace "'", "'\\''"
$mysqlPasswordEscaped = $mysqlPassword -replace "'", "'\\''"
$exportComposeEnv = "export BACKEND_PORT='$backendPortEscaped'; export MYSQL_PORT='$mysqlPortEscaped'; export BACKEND_LOG_DIR='$backendLogDirEscaped'; export PCELINJAK_MAIL_BASE_URL='$mailBaseUrlEscaped'; export PCELINJAK_MYSQL_VOLUME_NAME='$mysqlVolumeNameEscaped'; export MYSQL_ROOT_PASSWORD='$mysqlRootPasswordEscaped'; export MYSQL_DATABASE='$mysqlDatabaseEscaped'; export MYSQL_USER='$mysqlUserEscaped'; export MYSQL_PASSWORD='$mysqlPasswordEscaped'; "

# Backup/S3 config (used with -SetupBackup)
$s3Bucket = $config["S3_BUCKET"]
$s3Region = $config["S3_REGION"]
$s3AccessKey = $config["S3_ACCESS_KEY"]
$s3SecretKey = $config["S3_SECRET_KEY"]
$s3Endpoint = $config["S3_ENDPOINT"]
$s3Prefix = $config["S3_PREFIX"]
$logS3Prefix = $config["LOG_S3_PREFIX"]
$backupLogsEnabled = $config["BACKUP_LOGS_ENABLED"]
$logSourceDir = $config["LOG_SOURCE_DIR"]
$backupCron = $config["BACKUP_CRON"]
$localBackupCron = $config["LOCAL_BACKUP_CRON"]
$localBackupKeepMinutes = $config["LOCAL_BACKUP_KEEP_MINUTES"]
$localBackupSaveOnlyOnChange = $config["LOCAL_BACKUP_SAVE_ONLY_ON_CHANGE"]
$backupNotifyEmail = $config["BACKUP_NOTIFY_EMAIL"]
$s3ApplyLifecycle = $config["S3_APPLY_LIFECYCLE"]
if (-not $backupCron) { $backupCron = "30 2 * * *" }
if (-not $localBackupCron) { $localBackupCron = "*/5 * * * *" }
if (-not $localBackupKeepMinutes) { $localBackupKeepMinutes = "180" }
if (-not $localBackupSaveOnlyOnChange) { $localBackupSaveOnlyOnChange = "0" }
if (-not $s3Prefix) { $s3Prefix = "pcelinjak/mysql" }
if (-not $logS3Prefix) { $logS3Prefix = "pcelinjak/logs" }
if (-not $backupLogsEnabled) { $backupLogsEnabled = "1" }
if (-not $logSourceDir) { $logSourceDir = "$path/logs/backend" }
if (-not $s3ApplyLifecycle) { $s3ApplyLifecycle = "1" }

if ($SetupBackup) {
    if (-not $s3Bucket -or -not $s3AccessKey -or -not $s3SecretKey) {
        Write-Error "For -SetupBackup, config must set S3_BUCKET, S3_ACCESS_KEY, S3_SECRET_KEY."
        exit 1
    }
    if (-not $s3Region) { $s3Region = "us-east-1" }

    $pathEsc = Escape-BashSingleQuotedValue $path
    $bucketEsc = Escape-BashSingleQuotedValue $s3Bucket
    $regionEsc = Escape-BashSingleQuotedValue $s3Region
    $accessEsc = Escape-BashSingleQuotedValue $s3AccessKey
    $secretEsc = Escape-BashSingleQuotedValue $s3SecretKey
    $endpointEsc = Escape-BashSingleQuotedValue $s3Endpoint
    $prefixEsc = Escape-BashSingleQuotedValue $s3Prefix
    $logPrefixEsc = Escape-BashSingleQuotedValue $logS3Prefix
    $backupLogsEsc = Escape-BashSingleQuotedValue $backupLogsEnabled
    $logSourceDirEsc = Escape-BashSingleQuotedValue $logSourceDir
    $mysqlDatabaseEsc = Escape-BashSingleQuotedValue $mysqlDatabase
    $mysqlRootPasswordEsc = Escape-BashSingleQuotedValue $mysqlRootPassword
    $composeProjectNameEsc = Escape-BashSingleQuotedValue $composeProjectName
    $composeFilesEsc = Escape-BashSingleQuotedValue $composeFilesRaw
    $cronEsc = Escape-BashSingleQuotedValue $backupCron
    $notifyEsc = Escape-BashSingleQuotedValue $backupNotifyEmail
    $applyLifecycleEsc = Escape-BashSingleQuotedValue $s3ApplyLifecycle

    # Literal $(id -u) for remote bash (PowerShell would otherwise expand $(id -u) itself)
    $idU = [char]36 + '(id -u)'
    $bashUnameM = [char]36 + '(uname -m)'
    $bashMktempD = [char]36 + '(mktemp -d)'

    $backupSetupScript = @"
set -e
DEPLOY_PATH='$pathEsc'
S3_BUCKET='$bucketEsc'
S3_REGION='$regionEsc'
S3_ACCESS_KEY='$accessEsc'
S3_SECRET_KEY='$secretEsc'
S3_ENDPOINT='$endpointEsc'
S3_PREFIX='$prefixEsc'
LOG_S3_PREFIX='$logPrefixEsc'
BACKUP_LOGS_ENABLED='$backupLogsEsc'
LOG_SOURCE_DIR='$logSourceDirEsc'
COMPOSE_PROJECT_NAME='$composeProjectNameEsc'
COMPOSE_FILES='$composeFilesEsc'
BACKUP_CRON='$cronEsc'
BACKUP_NOTIFY_EMAIL='$notifyEsc'
S3_APPLY_LIFECYCLE='$applyLifecycleEsc'

SUDO=''; [ $idU -ne 0 ] && SUDO='sudo'

export AWS_ACCESS_KEY_ID="`$S3_ACCESS_KEY"
export AWS_SECRET_ACCESS_KEY="`$S3_SECRET_KEY"
export AWS_DEFAULT_REGION="`$S3_REGION"

# Popravka prekinutog apt/dpkg (inace apt-get install puca sa "dpkg was interrupted")
if [ -x /usr/bin/dpkg ]; then
  echo 'Ensuring dpkg is configured (dpkg --configure -a)...'
  `$SUDO env DEBIAN_FRONTEND=noninteractive dpkg --configure -a
fi

if ! command -v aws >/dev/null 2>&1; then
  echo 'Installing AWS CLI (package manager)...'
  if [ -x /usr/bin/apt-get ]; then
    `$SUDO apt-get update -qq && `$SUDO apt-get install -y awscli || true
  elif [ -x /usr/bin/dnf ]; then
    `$SUDO dnf install -y awscli || true
  elif [ -x /usr/bin/yum ]; then
    `$SUDO yum install -y awscli || true
  elif [ -x /sbin/apk ]; then
    `$SUDO apk add --no-cache aws-cli || true
  fi
fi
if ! command -v aws >/dev/null 2>&1; then
  echo 'Installing AWS CLI v2 from Amazon (needed on Ubuntu 24.04+ without awscli package)...'
  command -v curl >/dev/null 2>&1 || { echo 'curl is required for AWS CLI install' >&2; exit 1; }
  if ! command -v unzip >/dev/null 2>&1; then
    if [ -x /usr/bin/apt-get ]; then
      `$SUDO apt-get update -qq && `$SUDO apt-get install -y unzip
    elif [ -x /usr/bin/dnf ]; then
      `$SUDO dnf install -y unzip
    elif [ -x /usr/bin/yum ]; then
      `$SUDO yum install -y unzip
    else
      echo 'unzip is required for AWS CLI install' >&2
      exit 1
    fi
  fi
  ARCH=$bashUnameM
  case "`$ARCH" in
    x86_64) AWS_ZIP=awscli-exe-linux-x86_64.zip ;;
    aarch64|arm64) AWS_ZIP=awscli-exe-linux-aarch64.zip ;;
    *) echo "Unsupported architecture: `$ARCH" >&2; exit 1 ;;
  esac
  TMPDIR=$bashMktempD
  curl -fsSL "https://awscli.amazonaws.com/`$AWS_ZIP" -o "`$TMPDIR/awscliv2.zip"
  unzip -q "`$TMPDIR/awscliv2.zip" -d "`$TMPDIR"
  `$SUDO "`$TMPDIR/aws/install" --update
  rm -rf "`$TMPDIR"
fi
if ! command -v aws >/dev/null 2>&1; then
  echo 'AWS CLI could not be installed automatically.' >&2
  exit 1
fi

if ! command -v crontab >/dev/null 2>&1; then
  echo 'Installing cron...'
  if [ -x /usr/bin/apt-get ]; then
    `$SUDO apt-get update -qq && `$SUDO apt-get install -y cron
  elif [ -x /usr/bin/dnf ]; then
    `$SUDO dnf install -y cronie
  elif [ -x /usr/bin/yum ]; then
    `$SUDO yum install -y cronie
  elif [ -x /sbin/apk ]; then
    `$SUDO apk add --no-cache dcron
  else
    echo 'Cannot install cron automatically; install it manually.' >&2
    exit 1
  fi
fi

`$SUDO systemctl enable cron 2>/dev/null || `$SUDO systemctl enable crond 2>/dev/null || true
`$SUDO systemctl start cron 2>/dev/null || `$SUDO systemctl start crond 2>/dev/null || true

if [ ! -f "`$DEPLOY_PATH/deploy/scripts/backup-mysql-to-s3.sh" ]; then
  echo "Missing backup script at `$DEPLOY_PATH/deploy/scripts/backup-mysql-to-s3.sh. Did you deploy latest code?" >&2
  exit 1
fi

mkdir -p "`$DEPLOY_PATH/.backups"
chmod +x "`$DEPLOY_PATH/deploy/scripts/backup-mysql-to-s3.sh"

cat > "`$DEPLOY_PATH/.backup.env" <<EOF
AWS_ACCESS_KEY_ID='`$S3_ACCESS_KEY'
AWS_SECRET_ACCESS_KEY='`$S3_SECRET_KEY'
AWS_DEFAULT_REGION='`$S3_REGION'
S3_BUCKET='`$S3_BUCKET'
S3_REGION='`$S3_REGION'
S3_ENDPOINT='`$S3_ENDPOINT'
S3_PREFIX='`$S3_PREFIX'
LOG_S3_PREFIX='`$LOG_S3_PREFIX'
BACKUP_LOGS_ENABLED='`$BACKUP_LOGS_ENABLED'
LOG_SOURCE_DIR='`$LOG_SOURCE_DIR'
COMPOSE_PROJECT_NAME='`$COMPOSE_PROJECT_NAME'
COMPOSE_FILES='`$COMPOSE_FILES'
MYSQL_CONTAINER='mysql'
MYSQL_DATABASE='$mysqlDatabaseEsc'
MYSQL_USER='root'
MYSQL_PASSWORD='$mysqlRootPasswordEsc'
BACKUP_TMP_DIR='`$DEPLOY_PATH/.backups'
LOCAL_RETENTION_DAYS='7'
RETENTION_DAYS='90'
APPLY_RETENTION_FALLBACK='0'
BACKUP_NOTIFY_EMAIL='`$BACKUP_NOTIFY_EMAIL'
EOF
chmod 600 "`$DEPLOY_PATH/.backup.env"

# Cron koristi uzan PATH; docker/aws obicno su u /usr/bin ali eksplicitno setujemo.
# Uklanjamo samo S3 red za ovaj DEPLOY_PATH — ne brisati drugi env (prod vs test) na istom serveru.
CRON_CMD="cd '`$DEPLOY_PATH' && PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin BACKUP_ENV_FILE='`$DEPLOY_PATH/.backup.env' /usr/bin/env bash deploy/scripts/backup-mysql-to-s3.sh >> '`$DEPLOY_PATH/.backups/backup.log' 2>&1"
{
  while IFS= read -r line || [ -n "`$line" ]; do
    if [[ "`$line" == *backup-mysql-to-s3.sh* && "`$line" == *"cd '`$DEPLOY_PATH' &&"* ]]; then
      continue
    fi
    printf '%s\n' "`$line"
  done < <(crontab -l 2>/dev/null)
  printf '%s %s\n' "`$BACKUP_CRON" "`$CRON_CMD"
} | crontab -
if ! crontab -l 2>/dev/null | grep -F 'backup-mysql-to-s3.sh' | grep -qF "cd '`$DEPLOY_PATH' &&"; then
  echo 'ERROR: crontab nije primio S3 backup red za ovaj DEPLOY_PATH (proveri sintaksu BACKUP_CRON u configu).' >&2
  exit 1
fi

if [ "`$S3_APPLY_LIFECYCLE" = "1" ]; then
  ENDPOINT_ARGS=""
  if [ -n "`$S3_ENDPOINT" ]; then ENDPOINT_ARGS="--endpoint-url `$S3_ENDPOINT"; fi
  TMP_RULES="/tmp/pcelinjak-s3-lifecycle.json"
  cat > "`$TMP_RULES" <<'EOF_RULES'
{
  "Rules": [
    {
      "ID": "pcelinjak-backup-retention-90d",
      "Status": "Enabled",
      "Filter": { "Prefix": "pcelinjak/mysql/" },
      "Expiration": { "Days": 90 }
    }
  ]
}
EOF_RULES
  if [ "`$S3_PREFIX" != "pcelinjak/mysql" ]; then
    sed -i "s#pcelinjak/mysql/#`$S3_PREFIX/#g" "`$TMP_RULES"
  fi
  aws `$ENDPOINT_ARGS s3api put-bucket-lifecycle-configuration --bucket "`$S3_BUCKET" --lifecycle-configuration "file://`$TMP_RULES"
  rm -f "`$TMP_RULES"
fi

echo "Backup setup complete. Cron: `$BACKUP_CRON"
"@

    Write-Host "Setting up S3 backup and cron on server..." -ForegroundColor Yellow
    Invoke-RemoteScript $backupSetupScript
    Write-Host "Backup setup done. Use -BackupNow to test immediately." -ForegroundColor Green
    exit 0
}

if ($SetupLocalBackup) {
    $pathEsc = Escape-BashSingleQuotedValue $path
    $composeProjectNameEsc = Escape-BashSingleQuotedValue $composeProjectName
    $composeFilesEsc = Escape-BashSingleQuotedValue $composeFilesRaw
    $mysqlRootPasswordEsc = Escape-BashSingleQuotedValue $mysqlRootPassword
    $mysqlDatabaseEsc = Escape-BashSingleQuotedValue $mysqlDatabase
    $localBackupCronEsc = Escape-BashSingleQuotedValue $localBackupCron
    $localBackupKeepMinutesEsc = Escape-BashSingleQuotedValue $localBackupKeepMinutes
    $localBackupSaveOnlyOnChangeEsc = Escape-BashSingleQuotedValue $localBackupSaveOnlyOnChange
    $idU = [char]36 + '(id -u)'

    $localBackupSetupScript = @"
set -e
DEPLOY_PATH='$pathEsc'
COMPOSE_PROJECT_NAME='$composeProjectNameEsc'
COMPOSE_FILES='$composeFilesEsc'
MYSQL_ROOT_PASSWORD='$mysqlRootPasswordEsc'
MYSQL_DATABASE='$mysqlDatabaseEsc'
LOCAL_BACKUP_CRON='$localBackupCronEsc'
LOCAL_BACKUP_KEEP_MINUTES='$localBackupKeepMinutesEsc'
LOCAL_BACKUP_SAVE_ONLY_ON_CHANGE='$localBackupSaveOnlyOnChangeEsc'

SUDO=''; [ $idU -ne 0 ] && SUDO='sudo'

if [ -x /usr/bin/dpkg ]; then
  echo 'Ensuring dpkg is configured (dpkg --configure -a)...'
  `$SUDO env DEBIAN_FRONTEND=noninteractive dpkg --configure -a
fi

if ! command -v crontab >/dev/null 2>&1; then
  echo 'Installing cron...'
  if [ -x /usr/bin/apt-get ]; then
    `$SUDO apt-get update -qq && `$SUDO apt-get install -y cron
  elif [ -x /usr/bin/dnf ]; then
    `$SUDO dnf install -y cronie
  elif [ -x /usr/bin/yum ]; then
    `$SUDO yum install -y cronie
  elif [ -x /sbin/apk ]; then
    `$SUDO apk add --no-cache dcron
  else
    echo 'Cannot install cron automatically; install it manually.' >&2
    exit 1
  fi
fi

`$SUDO systemctl enable cron 2>/dev/null || `$SUDO systemctl enable crond 2>/dev/null || true
`$SUDO systemctl start cron 2>/dev/null || `$SUDO systemctl start crond 2>/dev/null || true

if [ ! -f "`$DEPLOY_PATH/deploy/scripts/backup-mysql-local.sh" ]; then
  echo "Missing local backup script at `$DEPLOY_PATH/deploy/scripts/backup-mysql-local.sh. Did you deploy latest code?" >&2
  exit 1
fi

mkdir -p "`$DEPLOY_PATH/.backups/local"
chmod +x "`$DEPLOY_PATH/deploy/scripts/backup-mysql-local.sh"

# Samo lokalni backup red za ovaj DEPLOY_PATH (ne brisati drugi env).
CRON_CMD="cd '`$DEPLOY_PATH' && COMPOSE_PROJECT_NAME='`$COMPOSE_PROJECT_NAME' COMPOSE_FILES='`$COMPOSE_FILES' MYSQL_PASSWORD='`$MYSQL_ROOT_PASSWORD' MYSQL_DATABASE='`$MYSQL_DATABASE' KEEP_MINUTES='`$LOCAL_BACKUP_KEEP_MINUTES' SAVE_ONLY_ON_CHANGE='`$LOCAL_BACKUP_SAVE_ONLY_ON_CHANGE' bash deploy/scripts/backup-mysql-local.sh >> '`$DEPLOY_PATH/.backups/local/backup-local.log' 2>&1"
{
  while IFS= read -r line || [ -n "`$line" ]; do
    if [[ "`$line" == *backup-mysql-local.sh* && "`$line" == *"cd '`$DEPLOY_PATH' &&"* ]]; then
      continue
    fi
    printf '%s\n' "`$line"
  done < <(crontab -l 2>/dev/null)
  printf '%s %s\n' "`$LOCAL_BACKUP_CRON" "`$CRON_CMD"
} | crontab -

echo "Local backup setup complete. Cron: `$LOCAL_BACKUP_CRON"
"@

    Write-Host "Setting up local emergency backup cron on server..." -ForegroundColor Yellow
    Invoke-RemoteScript $localBackupSetupScript
    Write-Host "Local backup setup done." -ForegroundColor Green
    exit 0
}

if ($BackupNow) {
    Write-Host "Running backup now on server..." -ForegroundColor Yellow
    Invoke-Remote "cd '$pathEscapedForRemote' && BACKUP_ENV_FILE='$pathEscapedForRemote/.backup.env' bash deploy/scripts/backup-mysql-to-s3.sh"
    Write-Host "Backup command completed." -ForegroundColor Green
    exit 0
}
if ($Build) {
    Write-Host "Building and starting containers (retrying on network errors)..." -ForegroundColor Yellow
    # Uklanjamo samo backend (ne mysql), da se ne izgubi baza.
    Invoke-Remote "cd '$pathEscapedForRemote' && $composeCmd rm -sf backend 2>/dev/null; true"
    $retryCmd = "cd '$pathEscapedForRemote' && ${exportMail}${exportSentry}${exportSentryEnabled}${exportJwt}${exportNotification}${exportComposeEnv}for i in 1 2 3 4 5; do $composeCmd pull && $composeCmd up -d --build && exit 0; echo `"Attempt `$i failed, retry in 45s...`"; sleep 45; done; exit 1"
    Invoke-Remote $retryCmd
} else {
    Write-Host "Starting containers (no rebuild)..." -ForegroundColor Yellow
    Invoke-Remote "cd '$pathEscapedForRemote' && $composeCmd rm -sf backend 2>/dev/null; true"
    $retryCmd = "cd '$pathEscapedForRemote' && ${exportMail}${exportSentry}${exportSentryEnabled}${exportJwt}${exportNotification}${exportComposeEnv}for i in 1 2 3 4 5; do $composeCmd pull 2>/dev/null; $composeCmd up -d && exit 0; echo `"Attempt `$i failed, retry in 45s...`"; sleep 45; done; exit 1"
    Invoke-Remote $retryCmd
}

Write-Host "Deploy done. Backend: $deployBackendUrl" -ForegroundColor Green
