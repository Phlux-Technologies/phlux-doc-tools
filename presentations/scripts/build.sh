#!/usr/bin/env bash
# Build a Phlux presentation from Markdown to PDF
# Usage: build.sh <input.md> [output.pdf]
#
# Input can be any .md file anywhere on disk.
# Infrastructure (template, preamble, logos) is resolved relative to this script.
# Images referenced in the markdown are resolved relative to the input file's directory.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PRES_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# --- Preflight checks ---
if ! command -v pandoc &>/dev/null; then
    echo "ERROR: pandoc is not installed."
    echo "Run the setup script first:"
    echo "  Unix:    bash $(dirname "$0")/setup.sh"
    echo "  Windows: powershell -ExecutionPolicy Bypass -File $(dirname "$0")\\setup.ps1"
    exit 1
fi

if ! command -v xelatex &>/dev/null; then
    echo "ERROR: xelatex is not installed."
    echo "Run the setup script first:"
    echo "  Unix:    bash $(dirname "$0")/setup.sh"
    echo "  Windows: powershell -ExecutionPolicy Bypass -File $(dirname "$0")\\setup.ps1"
    exit 1
fi

# --- Arguments ---
if [ $# -eq 0 ]; then
    echo "Phlux Presentation Builder"
    echo ""
    echo "Usage: build.sh <presentation.md> [output.pdf]"
    echo ""
    echo "Examples:"
    echo "  bash tools/doc-tools/presentations/scripts/build.sh docs/presentations/my-deck.md"
    echo "  bash tools/doc-tools/presentations/scripts/build.sh docs/presentations/my-deck.md output/my-deck.pdf"
    echo ""
    echo "The input .md can be anywhere. Images are resolved relative to the input file's directory."
    exit 0
fi

INPUT="$1"

# Resolve input to absolute path
if [[ "$INPUT" = /* ]] || [[ "$INPUT" =~ ^[A-Za-z]: ]]; then
    INPUT_ABS="$INPUT"
else
    INPUT_ABS="$(cd "$(dirname "$INPUT")" && pwd)/$(basename "$INPUT")"
fi

if [ ! -f "$INPUT_ABS" ]; then
    echo "ERROR: Input file not found: $INPUT_ABS"
    exit 1
fi

INPUT_DIR="$(cd "$(dirname "$INPUT_ABS")" && pwd)"
INPUT_BASE="$(basename "$INPUT_ABS" .md)"
INPUT_NAME="$(basename "$INPUT_ABS")"

# Output: default to same directory as input, same name with .pdf
if [ $# -ge 2 ]; then
    OUTPUT="$2"
    # Resolve output to absolute path
    if [[ "$OUTPUT" != /* ]] && [[ ! "$OUTPUT" =~ ^[A-Za-z]: ]]; then
        OUTPUT="$(pwd)/$OUTPUT"
    fi
else
    OUTPUT="${INPUT_DIR}/${INPUT_BASE}.pdf"
fi

# --- Set TEXINPUTS so xelatex can find logos and images ---
if [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "cygwin" ]] || [[ "$OSTYPE" == "win32" ]]; then
    SEP=";"
else
    SEP=":"
fi

export TEXINPUTS="${INPUT_DIR}//${SEP}${PRES_DIR}//${SEP}${TEXINPUTS:-}"

# --- Build ---
# Change to PRES_DIR so preamble paths (images/logos/...) resolve correctly.
# Input and output use absolute paths so they work from any cwd.
cd "$PRES_DIR"

# On MSYS/Cygwin, convert paths to Windows-native format for pandoc.exe.
if command -v cygpath &>/dev/null; then
    PANDOC_RESOURCE_PATH="$(cygpath -w "$INPUT_DIR")${SEP}$(cygpath -w "$PRES_DIR")"
else
    PANDOC_RESOURCE_PATH="${INPUT_DIR}${SEP}${PRES_DIR}"
fi

echo "Building: $INPUT_NAME -> $(basename "$OUTPUT")"
echo "  Input:  $INPUT_ABS"
echo "  Output: $OUTPUT"

pandoc "$INPUT_ABS" \
    -t beamer \
    --pdf-engine=xelatex \
    --template="$PRES_DIR/templates/phlux-beamer.tex" \
    -H "$PRES_DIR/preamble.tex" \
    --resource-path="$PANDOC_RESOURCE_PATH" \
    --slide-level=2 \
    -V linkcolor:phluxaccent \
    -V urlcolor:phluxblue \
    -V section-titles:true \
    -o "$OUTPUT"

echo "Done: $OUTPUT"
