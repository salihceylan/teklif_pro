# Teklif Pro — Build & Deploy Script
# Kullanim: .\deploy.ps1 [-apk] [-web] [-ftp]
# Ornekler:
#   .\deploy.ps1 -apk -web -ftp   # hepsini yap
#   .\deploy.ps1 -web -ftp        # sadece web build + upload
#   .\deploy.ps1 -apk             # sadece APK

param(
    [switch]$apk,
    [switch]$web,
    [switch]$ftp
)

$ErrorActionPreference = "Stop"
Set-Location $PSScriptRoot

if (-not $apk -and -not $web -and -not $ftp) {
    Write-Host "Kullanim: .\deploy.ps1 [-apk] [-web] [-ftp]" -ForegroundColor Yellow
    exit 0
}

# --- APK Build ---
if ($apk) {
    Write-Host "`n=== APK Build ===" -ForegroundColor Cyan
    flutter build apk --release
    Write-Host "APK: build\app\outputs\flutter-apk\app-release.apk" -ForegroundColor Green
}

# --- Web Build ---
if ($web) {
    Write-Host "`n=== Web Build ===" -ForegroundColor Cyan
    flutter build web --release
    Write-Host "Web: build\web" -ForegroundColor Green
}

# --- FTP Upload ---
if ($ftp) {
    Write-Host "`n=== FTP Upload ===" -ForegroundColor Cyan
    python3 - <<'PYEOF'
import ftplib, pathlib, sys

HOST      = "mint.trdns.com"
USER      = "gudetekn"
PASS      = "2I7lo7mx1K"
REMOTE    = "/public_html"
LOCAL     = pathlib.Path("build/web")

if not LOCAL.exists():
    print("HATA: build/web bulunamadi. Once -web ile build alin.", file=sys.stderr)
    sys.exit(1)

def upload_dir(ftp, local, remote):
    try:
        ftp.mkd(remote)
    except ftplib.error_perm:
        pass
    for item in sorted(local.iterdir()):
        r = f"{remote}/{item.name}"
        if item.is_dir():
            upload_dir(ftp, item, r)
        else:
            with open(item, "rb") as f:
                ftp.storbinary(f"STOR {r}", f)
                print(f"  {r}")

ftp = ftplib.FTP(HOST)
ftp.login(USER, PASS)
ftp.encoding = "utf-8"
upload_dir(ftp, LOCAL, REMOTE)
ftp.quit()
print("FTP upload tamamlandi.")
PYEOF
}

Write-Host "`nTamam!" -ForegroundColor Green
