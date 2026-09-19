<#
    Her Hafta 1 Uygulama — push öncesi güvenlik kontrolü.

    Dört kontrolü sırayla çalıştırır, sonunda tek özet basar.
    Okunacak bir şey değil, ÇALIŞTIRILACAK bir şey — serinin ana fikri bu.

    Kullanım (depo kökünden):
        .\guvenlik-kontrol.ps1
        .\guvenlik-kontrol.ps1 -Derle    # eksik release derlemelerini de alır

    Ne kontrol eder:
        1. Sır taraması          gitleaks, tüm git geçmişi
        2. Bağımlılık açıkları   osv-scanner, her pubspec.lock
        3. İzin + yedek denetimi release derlemesinin BİRLEŞMİŞ manifest'i
        4. Depo hijyeni          yasaklı dosyalar, commit e-postaları

    3. adım neden önemli: kendi AndroidManifest.xml'ine izin yazmamak, uygulamanın
    o izni istemediği anlamına gelmiyor. Eklentiler derleme sırasında kendi
    izinlerini birleştiriyor. Bu seride bir uygulamanın manifest'inde tek satır
    CAMERA yazılıyken birleşmiş manifest'te beş izin daha çıktı — biri, cihazda
    çalışan bir ML modelinin yanında gelen telemetri kütüphanesinin INTERNET izniydi.

    Kurulu olmayan araç betiği DURDURMAZ: uyarır, o adımı atlar ve sonuçta
    "atlandı" diye raporlar. (.githooks/pre-commit'teki gitleaks davranışının
    aynısı — sessizce geçmek yok, ama iş de durmuyor.)

    Gereken araçlar:
        winget install --id Gitleaks.Gitleaks
        winget install --id Google.OSVScanner

    NOT: Bu dosya UTF-8 + BOM olarak kaydedilmeli. Windows PowerShell 5.1
    BOM'suz UTF-8'i ANSI sanıyor; Türkçe karakterler bozuluyor ve ayraç olarak
    kullanılan kutu karakterleri akıllı tırnağa dönüşüp betiği ayrıştırılamaz
    hale getiriyor.
#>

[CmdletBinding()]
param(
    # Bu bayrak verilirse eksik release derlemeleri için uygulama tek tek
    # derlenir. Yavaş (uygulama başına dakikalar), o yüzden varsayılan kapalı.
    [switch]$Derle
)

$ErrorActionPreference = 'Continue'
$kok = $PSScriptRoot
$sonuclar = [ordered]@{}

function Yaz-Baslik($metin) {
    Write-Host ""
    Write-Host "=== $metin ===" -ForegroundColor Cyan
}

function Bul-Arac($ad, $wingetYolu) {
    $komut = Get-Command $ad -ErrorAction SilentlyContinue
    if ($null -ne $komut) { return $komut.Source }
    if ($wingetYolu) {
        $tam = Join-Path $env:LOCALAPPDATA $wingetYolu
        if (Test-Path $tam) { return $tam }
    }
    return $null
}

# Uygulama klasörleri: partNN-... deseni
$uygulamalar = Get-ChildItem -Path $kok -Directory |
    Where-Object { $_.Name -match '^part\d\d-' } |
    Sort-Object Name

# -------------------------------------------------------------
# 1 — Sır taraması (tüm geçmiş, sadece staged değil)
# -------------------------------------------------------------
Yaz-Baslik "1/4  Sır taraması (gitleaks)"

$gitleaks = Bul-Arac 'gitleaks' `
    'Microsoft\WinGet\Packages\Gitleaks.Gitleaks_Microsoft.Winget.Source_8wekyb3d8bbwe\gitleaks.exe'

if (-not $gitleaks) {
    Write-Host "  gitleaks bulunamadı — ATLANDI." -ForegroundColor Yellow
    Write-Host "  Kurulum:  winget install --id Gitleaks.Gitleaks"
    $sonuclar['Sır taraması'] = 'ATLANDI'
} else {
    & $gitleaks git $kok --no-banner --redact
    if ($LASTEXITCODE -eq 0) {
        Write-Host "  Sır bulunmadı." -ForegroundColor Green
        $sonuclar['Sır taraması'] = 'TEMİZ'
    } else {
        $sonuclar['Sır taraması'] = 'SIZINTI VAR'
    }
}

# -------------------------------------------------------------
# 2 — Bağımlılık açıkları (pubspec.lock -> OSV veritabanı)
# -------------------------------------------------------------
Yaz-Baslik "2/4  Bağımlılık açıkları (osv-scanner)"

$osv = Bul-Arac 'osv-scanner' `
    'Microsoft\WinGet\Packages\Google.OSVScanner_Microsoft.Winget.Source_8wekyb3d8bbwe\osv-scanner.exe'

if (-not $osv) {
    Write-Host "  osv-scanner bulunamadı — ATLANDI." -ForegroundColor Yellow
    Write-Host "  Kurulum:  winget install --id Google.OSVScanner"
    Write-Host "  (winget'te yoksa: github.com/google/osv-scanner/releases)"
    $sonuclar['Bağımlılık açıkları'] = 'ATLANDI'
} else {
    $acikVar = $false
    foreach ($u in $uygulamalar) {
        $lock = Join-Path $u.FullName 'pubspec.lock'
        if (-not (Test-Path $lock)) { continue }
        Write-Host "  $($u.Name) " -NoNewline
        # --verbosity=warn: araç normalde "filesystem walk for root: C:\"
        # diye bir satır basıyor, tüm diski tarıyormuş gibi duruyor.
        # Taramıyor — sadece verilen lockfile'a bakıyor.
        & $osv scan source --verbosity=warn --lockfile=$lock
        if ($LASTEXITCODE -ne 0) { $acikVar = $true }
    }
    if ($acikVar) {
        $sonuclar['Bağımlılık açıkları'] = 'AÇIK VAR'
    } else {
        Write-Host "  Bilinen açık yok." -ForegroundColor Green
        $sonuclar['Bağımlılık açıkları'] = 'TEMİZ'
    }
}

# -------------------------------------------------------------
# 3 — Gerçek izinler + yedek ayarı (birleşmiş manifest)
#
# Kendi manifest'ine izin yazmamak YETMİYOR: eklentiler birleşme sırasında
# kendi izinlerini getiriyor. Part 04'te beş fazla izin böyle bulundu.
# Tek doğru kaynak release derlemesinin birleşmiş manifest'i.
# -------------------------------------------------------------
Yaz-Baslik "3/4  İzin denetimi (birleşmiş manifest)"

$denetlendi = 0
$eksikDerleme = @()

foreach ($u in $uygulamalar) {
    $manifest = Join-Path $u.FullName `
        'build\app\intermediates\merged_manifest\release\processReleaseMainManifest\AndroidManifest.xml'

    if (-not (Test-Path $manifest) -and $Derle) {
        Write-Host "  $($u.Name) — release derleniyor..." -ForegroundColor Yellow
        Push-Location $u.FullName
        flutter build apk --release | Out-Null
        Pop-Location
    }

    if (-not (Test-Path $manifest)) {
        $eksikDerleme += $u.Name
        continue
    }

    # Derleme kaynak manifest'ten eskiyse okuduğumuz şey güncel değildir.
    $kaynak = Join-Path $u.FullName 'android\app\src\main\AndroidManifest.xml'
    $bayat = (Test-Path $kaynak) -and
             ((Get-Item $kaynak).LastWriteTime -gt (Get-Item $manifest).LastWriteTime)

    $metin = Get-Content $manifest -Raw
    $izinler = [regex]::Matches($metin, 'uses-permission android:name="([^"]*)"') |
        ForEach-Object { $_.Groups[1].Value } |
        Where-Object { $_ -notmatch 'DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION' }

    $yedek = if ($metin -match 'android:allowBackup="([^"]*)"') { $matches[1] } else { 'AYARSIZ (varsayılan true)' }

    Write-Host "  $($u.Name)" -NoNewline
    if ($bayat) { Write-Host "   [BAYAT — manifest derlemeden yeni]" -ForegroundColor Yellow } else { Write-Host "" }
    Write-Host "      izinler : $(if ($izinler) { $izinler -join ', ' } else { 'yok' })"
    Write-Host "      yedek   : allowBackup=$yedek"
    $denetlendi++
}

if ($eksikDerleme.Count -gt 0) {
    Write-Host "  Release derlemesi olmayan: $($eksikDerleme -join ', ')" -ForegroundColor Yellow
    Write-Host "  Denetlemek için:  .\guvenlik-kontrol.ps1 -Derle"
}

$sonuclar['İzin denetimi'] = if ($eksikDerleme.Count -gt 0) {
    "$denetlendi denetlendi, $($eksikDerleme.Count) atlandı"
} else {
    "$denetlendi uygulama denetlendi"
}

# -------------------------------------------------------------
# 4 — Depo hijyeni
# -------------------------------------------------------------
Yaz-Baslik "4/4  Depo hijyeni"

$hijyenSorun = @()

# Takip edilmemesi gereken dosyalar gerçekten takipsiz mi?
$yasakli = @('key.properties', '.env', 'dart_define.json', '*.jks', '*.keystore')
$takipteki = git -C $kok ls-files
foreach ($desen in $yasakli) {
    $bulunan = $takipteki | Where-Object { (Split-Path $_ -Leaf) -like $desen }
    if ($bulunan) {
        $hijyenSorun += "TAKİPTE OLMAMALI: $($bulunan -join ', ')"
    }
}

# Commit e-postaları — gerçek adres sızmış mı?
$epostalar = git -C $kok log --format='%ae' | Sort-Object -Unique
$sizan = $epostalar | Where-Object { $_ -notmatch 'noreply' }
if ($sizan) { $hijyenSorun += "Gerçek e-posta geçmişte: $($sizan -join ', ')" }

# Çalışma alanı temiz mi?
$kirli = git -C $kok status --short
if ($kirli) {
    Write-Host "  Commit'lenmemiş değişiklik var:" -ForegroundColor Yellow
    $kirli | ForEach-Object { Write-Host "      $_" }
}

if ($hijyenSorun.Count -eq 0) {
    Write-Host "  Yasaklı dosya takipte değil, e-postalar noreply." -ForegroundColor Green
    $sonuclar['Depo hijyeni'] = 'TEMİZ'
} else {
    $hijyenSorun | ForEach-Object { Write-Host "  $_" -ForegroundColor Red }
    $sonuclar['Depo hijyeni'] = 'SORUN VAR'
}

# -------------------------------------------------------------
# Özet
# -------------------------------------------------------------
Write-Host ""
Write-Host "------------ ÖZET ------------" -ForegroundColor Cyan
$kotu = $false
foreach ($anahtar in $sonuclar.Keys) {
    $deger = $sonuclar[$anahtar]
    $renk = switch -Regex ($deger) {
        'TEMİZ'              { 'Green' }
        'ATLANDI|atlandı'    { 'Yellow' }
        'VAR'                { 'Red' }
        default              { 'Gray' }
    }
    if ($deger -match 'VAR$') { $kotu = $true }
    Write-Host ("  {0,-22} {1}" -f $anahtar, $deger) -ForegroundColor $renk
}

Write-Host ""
if ($kotu) {
    Write-Host "  Push etme — yukarıdakini çöz." -ForegroundColor Red
    exit 1
}
Write-Host "  Bu kontroller temiz. Son adım elle:" -ForegroundColor Green
Write-Host "  README'de iddia ettiğin her gizlilik cümlesinin bir doğrulama"
Write-Host "  komutu var mı? (GUVENLIK.md bölüm 4)"
exit 0
