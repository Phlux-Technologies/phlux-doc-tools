#!/usr/bin/env bash
# Build a Phlux document from Markdown to PDF
# Usage: ./build.sh <input.md> [output-dir]
#
# Input can be any .md file anywhere on disk.
# The source .md is copied into a pdfs/ folder (next to the source),
# and the PDF is generated there. The original file is never modified.
#
# Default output dir: <source-dir>/pdfs/
# The skill modifies the COPY in pdfs/, not the original.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOC_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# --- Preflight checks ---
if ! command -v pandoc &>/dev/null; then
    echo "ERROR: pandoc is not installed."
    echo "Install pandoc: https://pandoc.org/installing.html"
    exit 1
fi

if ! command -v xelatex &>/dev/null; then
    echo "ERROR: xelatex is not installed."
    echo "Install a TeX distribution (MiKTeX or TeX Live)."
    exit 1
fi

# --- Arguments ---
if [ $# -eq 0 ]; then
    echo "Phlux Document Builder"
    echo ""
    echo "Usage: build.sh <document.md> [output-dir]"
    echo ""
    echo "Examples:"
    echo "  ./scripts/build.sh /path/to/research-doc.md"
    echo "  ./scripts/build.sh /path/to/research-doc.md /path/to/output/"
    echo ""
    echo "The source .md is copied to <output-dir>/ (default: pdfs/ next to source)."
    echo "The PDF is built from the copy. The original file is never modified."
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

# Output directory: default to pdfs/ next to source file
OUTPUT_DIR="${2:-${INPUT_DIR}/pdfs}"

# Resolve output dir to absolute path
if [[ "$OUTPUT_DIR" != /* ]] && [[ ! "$OUTPUT_DIR" =~ ^[A-Za-z]: ]]; then
    OUTPUT_DIR="$(pwd)/$OUTPUT_DIR"
fi

# Create output directory
mkdir -p "$OUTPUT_DIR"

# Copy source .md into output directory only if it doesn't already exist.
# This preserves edits made by the /create-document skill between rebuilds.
# To force a fresh copy, delete the working copy first.
WORK_MD="$OUTPUT_DIR/$INPUT_NAME"
if [ ! -f "$WORK_MD" ]; then
    cp "$INPUT_ABS" "$WORK_MD"
    echo "  Copied source to working directory"
fi

# Copy any images/ directory from the source location so image refs resolve
if [ -d "$INPUT_DIR/images" ]; then
    cp -r "$INPUT_DIR/images" "$OUTPUT_DIR/" 2>/dev/null || true
fi

OUTPUT="$OUTPUT_DIR/${INPUT_BASE}.pdf"

# --- Set TEXINPUTS so xelatex can find logos and images ---
# Use platform-appropriate path separator
if [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "cygwin" ]] || [[ "$OSTYPE" == "win32" ]]; then
    SEP=";"
else
    SEP=":"
fi

export TEXINPUTS="${OUTPUT_DIR}//${SEP}${INPUT_DIR}//${SEP}${DOC_DIR}//${SEP}${TEXINPUTS:-}"

# --- Build ---
# Change to DOC_DIR so preamble paths (images/logos/...) resolve correctly.
# Input and output use absolute paths so they work from any cwd.
cd "$DOC_DIR"

# On MSYS/Cygwin, convert paths to Windows-native format for pandoc.exe.
# MSYS auto-translates simple path arguments but NOT semicolon-separated
# compound strings like --resource-path, so pandoc receives /c/... paths
# it cannot resolve. cygpath -w fixes this.
if command -v cygpath &>/dev/null; then
    PANDOC_RESOURCE_PATH="$(cygpath -w "$OUTPUT_DIR")${SEP}$(cygpath -w "$INPUT_DIR")${SEP}$(cygpath -w "$DOC_DIR")"
else
    PANDOC_RESOURCE_PATH="${OUTPUT_DIR}${SEP}${INPUT_DIR}${SEP}${DOC_DIR}"
fi

echo "Building: $INPUT_NAME -> ${INPUT_BASE}.pdf"
echo "  Source (original): $INPUT_ABS"
echo "  Working copy:      $WORK_MD"
echo "  Output:            $OUTPUT"

pandoc "$WORK_MD" \
    --pdf-engine=xelatex \
    --template="$DOC_DIR/templates/phlux-article.tex" \
    -H "$DOC_DIR/preamble.tex" \
    --resource-path="$PANDOC_RESOURCE_PATH" \
    --toc --toc-depth=3 --number-sections \
    --syntax-highlighting=tango \
    -V documentclass:article \
    -V papersize:letter \
    -V geometry:"margin=1in" \
    -V fontsize:11pt \
    -V linkcolor:phluxblue \
    -V urlcolor:phluxblue \
    -V toccolor:phluxdark \
    -V colorlinks:true \
    -o "$OUTPUT"

echo "Done: $OUTPUT"
