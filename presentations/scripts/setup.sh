#!/usr/bin/env bash
# Phlux Presentation Toolchain Setup
# Installs pandoc + LaTeX (XeLaTeX) for building Beamer PDF presentations.
# Supports: macOS, Ubuntu/Debian, Fedora/RHEL, Windows (Git Bash / MSYS2)
set -euo pipefail

echo "========================================="
echo " Phlux Presentation Toolchain Setup"
echo "========================================="
echo ""

# --- Detect OS ---
OS="unknown"
if [[ "$OSTYPE" == "darwin"* ]]; then
    OS="macos"
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    if command -v apt &>/dev/null; then
        OS="debian"
    elif command -v dnf &>/dev/null; then
        OS="fedora"
    else
        OS="linux-other"
    fi
elif [[ "$OSTYPE" == "msys" || "$OSTYPE" == "cygwin" || "$OSTYPE" == "win32" ]]; then
    OS="windows"
fi

echo "Detected OS: $OS"
echo ""

# --- Check what's already installed ---
NEED_PANDOC=true
NEED_LATEX=true

if command -v pandoc &>/dev/null; then
    echo "[OK] pandoc $(pandoc --version | head -1 | awk '{print $2}')"
    NEED_PANDOC=false
else
    echo "[MISSING] pandoc"
fi

if command -v xelatex &>/dev/null; then
    echo "[OK] xelatex found"
    NEED_LATEX=false
else
    echo "[MISSING] xelatex"
fi

NEED_MAGICK=true
if command -v magick &>/dev/null; then
    echo "[OK] ImageMagick $(magick --version | head -1 | awk '{print $3}')"
    NEED_MAGICK=false
else
    echo "[OPTIONAL] ImageMagick not found (needed for image tools only)"
fi

if [[ "$NEED_PANDOC" == false && "$NEED_LATEX" == false ]]; then
    echo ""
    echo "All required tools already installed. You're ready to build presentations!"
    echo "  ./scripts/build.sh your-presentation.md"
    if [[ "$NEED_MAGICK" == true ]]; then
        echo ""
        echo "Optional: Install ImageMagick for image processing tools:"
        echo "  bash scripts/tools.sh help"
    fi
    exit 0
fi

echo ""

# --- Install ---
case "$OS" in
    macos)
        if ! command -v brew &>/dev/null; then
            echo "ERROR: Homebrew not found. Install it first:"
            echo '  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"'
            exit 1
        fi

        if [[ "$NEED_PANDOC" == true ]]; then
            echo "Installing pandoc..."
            brew install pandoc
        fi

        if [[ "$NEED_LATEX" == true ]]; then
            echo "Installing BasicTeX (minimal LaTeX, ~300 MB)..."
            brew install --cask basictex
            echo ""
            echo "Updating PATH for BasicTeX..."
            eval "$(/usr/libexec/path_helper)"
            export PATH="/Library/TeX/texbin:$PATH"

            echo "Installing required LaTeX packages..."
            sudo tlmgr update --self
            sudo tlmgr install \
                beamer metropolis pgfopts etoolbox \
                booktabs multirow fontspec \
                pgf tikz-cd xkeyval \
                fira fira-math \
                collection-fontsrecommended
        fi

        if [[ "$NEED_MAGICK" == true ]]; then
            echo "Installing ImageMagick (optional, for image tools)..."
            brew install imagemagick
        fi
        ;;

    debian)
        echo "Installing via apt (may require sudo)..."

        if [[ "$NEED_PANDOC" == true ]]; then
            sudo apt update
            sudo apt install -y pandoc
        fi

        if [[ "$NEED_LATEX" == true ]]; then
            sudo apt install -y \
                texlive-xetex \
                texlive-latex-extra \
                texlive-fonts-extra \
                texlive-fonts-recommended \
                lmodern
        fi

        if [[ "$NEED_MAGICK" == true ]]; then
            echo "Installing ImageMagick (optional, for image tools)..."
            sudo apt install -y imagemagick
        fi
        ;;

    fedora)
        echo "Installing via dnf (may require sudo)..."

        if [[ "$NEED_PANDOC" == true ]]; then
            sudo dnf install -y pandoc
        fi

        if [[ "$NEED_LATEX" == true ]]; then
            sudo dnf install -y \
                texlive-xetex \
                texlive-beamer \
                texlive-booktabs \
                texlive-multirow \
                texlive-fontspec \
                texlive-pgf \
                texlive-collection-fontsrecommended \
                lmodern
            # Metropolis may need manual install
            echo ""
            echo "NOTE: If 'metropolis' theme is missing, install manually:"
            echo "  sudo tlmgr install metropolis pgfopts"
        fi

        if [[ "$NEED_MAGICK" == true ]]; then
            echo "Installing ImageMagick (optional, for image tools)..."
            sudo dnf install -y ImageMagick
        fi
        ;;

    windows)
        echo ""
        echo "On Windows, use the PowerShell setup script instead:"
        echo "  powershell -ExecutionPolicy Bypass -File scripts\\setup.ps1"
        echo ""
        echo "Or install manually:"
        echo ""
        if [[ "$NEED_PANDOC" == true ]]; then
            echo "  Pandoc:  winget install JohnMacFarlane.Pandoc"
            echo "     or:   choco install pandoc"
        fi
        if [[ "$NEED_LATEX" == true ]]; then
            echo "  MiKTeX:  winget install MiKTeX.MiKTeX"
            echo "     or:   choco install miktex"
            echo ""
            echo "  MiKTeX auto-installs LaTeX packages on first use."
            echo "  On first build, click 'Install' when MiKTeX prompts for packages."
            echo "  To enable auto-install: MiKTeX Console -> Settings -> 'Always install'"
        fi
        if [[ "$NEED_MAGICK" == true ]]; then
            echo ""
            echo "  ImageMagick (optional, for image tools):"
            echo "           winget install ImageMagick.ImageMagick"
            echo "     or:   choco install imagemagick"
        fi
        exit 0
        ;;

    *)
        echo "Unsupported OS. Install manually:"
        echo "  1. Pandoc:  https://pandoc.org/installing.html"
        echo "  2. XeLaTeX: https://www.tug.org/texlive/"
        echo "  3. LaTeX packages: beamer, metropolis, booktabs, fontspec, pgf, tikz"
        exit 1
        ;;
esac

echo ""
echo "========================================="
echo " Setup complete!"
echo "========================================="
echo ""
echo "Build a presentation:"
echo "  cd docs/presentations"
echo "  ./scripts/build.sh your-presentation.md"
echo ""
if [[ "$NEED_MAGICK" == true ]]; then
    echo "Image tools (optional): Install ImageMagick for image processing."
    echo "  bash scripts/tools.sh help"
    echo ""
fi
echo "Or use Claude Code:"
echo "  /create-presentation"
