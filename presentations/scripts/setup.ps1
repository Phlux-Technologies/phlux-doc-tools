# Phlux Presentation Toolchain Setup (Windows)
# Installs pandoc + MiKTeX for building Beamer PDF presentations.
# Run: powershell -ExecutionPolicy Bypass -File scripts\setup.ps1

Write-Host "=========================================" -ForegroundColor Cyan
Write-Host " Phlux Presentation Toolchain Setup" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""

# --- Check what's already installed ---
$needPandoc = $true
$needLatex = $true

if (Get-Command pandoc -ErrorAction SilentlyContinue) {
    $ver = (pandoc --version | Select-Object -First 1).Split(" ")[1]
    Write-Host "[OK] pandoc $ver" -ForegroundColor Green
    $needPandoc = $false
} else {
    Write-Host "[MISSING] pandoc" -ForegroundColor Yellow
}

if (Get-Command xelatex -ErrorAction SilentlyContinue) {
    Write-Host "[OK] xelatex found" -ForegroundColor Green
    $needLatex = $false
} else {
    Write-Host "[MISSING] xelatex" -ForegroundColor Yellow
}

$needMagick = $true
if (Get-Command magick -ErrorAction SilentlyContinue) {
    $magickVer = (magick --version | Select-Object -First 1).Split(" ")[2]
    Write-Host "[OK] ImageMagick $magickVer" -ForegroundColor Green
    $needMagick = $false
} else {
    Write-Host "[OPTIONAL] ImageMagick not found (needed for image tools only)" -ForegroundColor DarkYellow
}

if (-not $needPandoc -and -not $needLatex) {
    Write-Host ""
    Write-Host "All required tools already installed. You're ready to build presentations!" -ForegroundColor Green
    Write-Host "  bash scripts/build.sh your-presentation.md"
    if ($needMagick) {
        Write-Host ""
        Write-Host "Optional: Install ImageMagick for image processing tools:" -ForegroundColor DarkYellow
        Write-Host "  winget install ImageMagick.ImageMagick"
        Write-Host "  bash scripts/tools.sh help"
    }
    exit 0
}

Write-Host ""

# --- Detect package manager ---
$hasWinget = [bool](Get-Command winget -ErrorAction SilentlyContinue)
$hasChoco = [bool](Get-Command choco -ErrorAction SilentlyContinue)

if (-not $hasWinget -and -not $hasChoco) {
    Write-Host "ERROR: Neither winget nor chocolatey found." -ForegroundColor Red
    Write-Host "Install winget (comes with App Installer from Microsoft Store)"
    Write-Host "  or install Chocolatey: https://chocolatey.org/install"
    exit 1
}

$mgr = if ($hasWinget) { "winget" } else { "choco" }
Write-Host "Using package manager: $mgr"
Write-Host ""

# --- Install pandoc ---
if ($needPandoc) {
    Write-Host "Installing pandoc..." -ForegroundColor Cyan
    if ($mgr -eq "winget") {
        winget install --id JohnMacFarlane.Pandoc --accept-package-agreements --accept-source-agreements
    } else {
        choco install pandoc -y
    }

    # Refresh PATH
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" +
                [System.Environment]::GetEnvironmentVariable("Path", "User")

    if (Get-Command pandoc -ErrorAction SilentlyContinue) {
        Write-Host "[OK] pandoc installed" -ForegroundColor Green
    } else {
        Write-Host "[WARN] pandoc installed but not in PATH yet. Restart your terminal." -ForegroundColor Yellow
    }
}

# --- Install MiKTeX ---
if ($needLatex) {
    Write-Host "Installing MiKTeX..." -ForegroundColor Cyan
    if ($mgr -eq "winget") {
        winget install --id MiKTeX.MiKTeX --accept-package-agreements --accept-source-agreements
    } else {
        choco install miktex -y
    }

    # Refresh PATH
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" +
                [System.Environment]::GetEnvironmentVariable("Path", "User")

    if (Get-Command xelatex -ErrorAction SilentlyContinue) {
        Write-Host "[OK] MiKTeX installed" -ForegroundColor Green
    } else {
        Write-Host "[WARN] MiKTeX installed but not in PATH yet. Restart your terminal." -ForegroundColor Yellow
    }

    Write-Host ""
    Write-Host "IMPORTANT: Configure MiKTeX to auto-install packages:" -ForegroundColor Yellow
    Write-Host "  1. Open 'MiKTeX Console' from Start Menu"
    Write-Host "  2. Go to Settings -> General"
    Write-Host "  3. Set 'Install missing packages' to 'Always'"
    Write-Host ""
    Write-Host "  This lets MiKTeX auto-download beamer, metropolis, tikz, etc."
    Write-Host "  on your first presentation build."
}

# --- Install ImageMagick (optional) ---
if ($needMagick) {
    Write-Host ""
    Write-Host "Installing ImageMagick (optional, for image tools)..." -ForegroundColor Cyan
    if ($mgr -eq "winget") {
        winget install --id ImageMagick.ImageMagick --accept-package-agreements --accept-source-agreements
    } else {
        choco install imagemagick -y
    }

    # Refresh PATH
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" +
                [System.Environment]::GetEnvironmentVariable("Path", "User")

    if (Get-Command magick -ErrorAction SilentlyContinue) {
        Write-Host "[OK] ImageMagick installed" -ForegroundColor Green
    } else {
        Write-Host "[WARN] ImageMagick installed but not in PATH yet. Restart your terminal." -ForegroundColor Yellow
    }
}

Write-Host ""
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host " Setup complete!" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "You may need to restart your terminal for PATH changes to take effect."
Write-Host ""
Write-Host "Build a presentation:"
Write-Host "  cd docs\presentations"
Write-Host "  bash scripts/build.sh your-presentation.md"
Write-Host ""
Write-Host "Or use Claude Code:"
Write-Host "  /create-presentation"
