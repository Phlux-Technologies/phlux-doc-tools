#!/usr/bin/env bash
# Phlux Presentation Image & PDF Tools
# Wrapper around ImageMagick and poppler-utils for preparing presentation assets.
# Usage: bash scripts/tools.sh <command> [args...]
# Run from docs/presentations/ or let the script detect the right directory.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PRES_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

die() { echo "ERROR: $*" >&2; exit 1; }

need_magick() {
    command -v magick &>/dev/null || die "ImageMagick v7 not found. Install it:
  macOS:   brew install imagemagick
  Debian:  sudo apt install -y imagemagick
  Fedora:  sudo dnf install -y ImageMagick
  Windows: winget install ImageMagick.ImageMagick"
}

# Create a .bak backup of a file (unless --no-backup is in the args)
backup_file() {
    local file="$1"
    shift
    local no_backup=false
    for arg in "$@"; do
        [[ "$arg" == "--no-backup" ]] && no_backup=true
    done
    if [[ "$no_backup" == false ]]; then
        cp "$file" "${file}.bak"
        echo "  Backup: ${file}.bak"
    fi
}

human_size() {
    local bytes="$1"
    if (( bytes >= 1048576 )); then
        echo "$(( bytes / 1048576 )) MB"
    elif (( bytes >= 1024 )); then
        echo "$(( bytes / 1024 )) KB"
    else
        echo "${bytes} B"
    fi
}

# ---------------------------------------------------------------------------
# Image commands
# ---------------------------------------------------------------------------

cmd_resize() {
    local usage="Usage: tools.sh resize <image> <WxH> [--no-backup]
  Resize image keeping aspect ratio (fits within WxH bounds).
  Example: tools.sh resize photo.png 800x600"

    [[ $# -lt 2 ]] && { echo "$usage"; exit 1; }
    need_magick
    local image="$1" geometry="$2"
    shift 2
    [[ -f "$image" ]] || die "File not found: $image"

    backup_file "$image" "$@"
    magick "$image" -resize "$geometry" "$image"
    echo "  Resized: $image -> ${geometry} (aspect ratio preserved)"
}

cmd_compress() {
    local usage="Usage: tools.sh compress <image> [quality] [--no-backup]
  Optimize file size. Quality: 1-100 for JPEG (default 85), ignored for PNG.
  Example: tools.sh compress photo.jpg 80"

    [[ $# -lt 1 ]] && { echo "$usage"; exit 1; }
    need_magick
    local image="$1"
    local quality="${2:-85}"
    shift
    [[ -n "${1:-}" ]] && shift
    [[ -f "$image" ]] || die "File not found: $image"

    local ext="${image##*.}"
    ext="${ext,,}"

    backup_file "$image" "$@"

    case "$ext" in
        jpg|jpeg)
            magick "$image" -quality "$quality" -strip "$image"
            echo "  Compressed JPEG: quality=$quality, metadata stripped"
            ;;
        png)
            magick "$image" -strip -define png:compression-level=9 "$image"
            echo "  Compressed PNG: max compression, metadata stripped"
            ;;
        *)
            magick "$image" -quality "$quality" "$image"
            echo "  Compressed: quality=$quality"
            ;;
    esac

    local size
    size=$(wc -c < "$image" | tr -d ' ')
    echo "  Size: $(human_size "$size")"
}

cmd_info() {
    local usage="Usage: tools.sh info <image>
  Show dimensions, format, file size, and color space.
  Example: tools.sh info photo.png"

    [[ $# -lt 1 ]] && { echo "$usage"; exit 1; }
    need_magick
    local image="$1"
    [[ -f "$image" ]] || die "File not found: $image"

    local size
    size=$(wc -c < "$image" | tr -d ' ')

    echo "  File:       $image"
    echo "  Size:       $(human_size "$size") ($size bytes)"
    magick identify -format "  Format:     %m\n  Dimensions: %wx%h\n  Color:      %[colorspace]\n  Depth:      %z-bit\n" "$image"
}

cmd_trim() {
    local usage="Usage: tools.sh trim <image> [--no-backup]
  Auto-remove whitespace/uniform borders (great for screenshots).
  Example: tools.sh trim screenshot.png"

    [[ $# -lt 1 ]] && { echo "$usage"; exit 1; }
    need_magick
    local image="$1"
    shift
    [[ -f "$image" ]] || die "File not found: $image"

    local before after
    before=$(magick identify -format "%wx%h" "$image")

    backup_file "$image" "$@"
    magick "$image" -trim +repage "$image"

    after=$(magick identify -format "%wx%h" "$image")
    echo "  Trimmed: $before -> $after"
}

cmd_crop() {
    local usage="Usage: tools.sh crop <image> <WxH+X+Y> [--no-backup]
  Crop to a specific region.
  Example: tools.sh crop photo.png 400x300+50+100"

    [[ $# -lt 2 ]] && { echo "$usage"; exit 1; }
    need_magick
    local image="$1" geometry="$2"
    shift 2
    [[ -f "$image" ]] || die "File not found: $image"

    backup_file "$image" "$@"
    magick "$image" -crop "$geometry" +repage "$image"
    echo "  Cropped: $image -> ${geometry}"
}

cmd_fit() {
    local usage="Usage: tools.sh fit <image> [maxW] [maxH] [--no-backup]
  Shrink to fit within bounds (default 1920x1080). Never upscales.
  Example: tools.sh fit photo.png 1280 720"

    [[ $# -lt 1 ]] && { echo "$usage"; exit 1; }
    need_magick
    local image="$1"
    local max_w="${2:-1920}"
    local max_h="${3:-1080}"
    shift
    [[ -n "${1:-}" ]] && shift
    [[ -n "${1:-}" ]] && shift
    [[ -f "$image" ]] || die "File not found: $image"

    local before
    before=$(magick identify -format "%wx%h" "$image")

    backup_file "$image" "$@"
    magick "$image" -resize "${max_w}x${max_h}>" "$image"

    local after
    after=$(magick identify -format "%wx%h" "$image")

    if [[ "$before" == "$after" ]]; then
        echo "  Already fits within ${max_w}x${max_h}: $before (no change)"
    else
        echo "  Fit: $before -> $after (max ${max_w}x${max_h})"
    fi
}

cmd_convert() {
    local usage="Usage: tools.sh convert <input> <output>
  Convert between image formats based on file extension.
  Example: tools.sh convert diagram.svg diagram.png"

    [[ $# -lt 2 ]] && { echo "$usage"; exit 1; }
    need_magick
    local input="$1" output="$2"
    [[ -f "$input" ]] || die "File not found: $input"

    magick "$input" "$output"
    local size
    size=$(wc -c < "$output" | tr -d ' ')
    echo "  Converted: $input -> $output ($(human_size "$size"))"
}

cmd_strip() {
    local usage="Usage: tools.sh strip <image> [--no-backup]
  Remove EXIF/metadata to reduce file size.
  Example: tools.sh strip photo.jpg"

    [[ $# -lt 1 ]] && { echo "$usage"; exit 1; }
    need_magick
    local image="$1"
    shift
    [[ -f "$image" ]] || die "File not found: $image"

    local before after
    before=$(wc -c < "$image" | tr -d ' ')

    backup_file "$image" "$@"
    magick "$image" -strip "$image"

    after=$(wc -c < "$image" | tr -d ' ')
    local saved=$(( before - after ))
    echo "  Stripped metadata: $(human_size "$before") -> $(human_size "$after") (saved $(human_size "$saved"))"
}

cmd_optimize_all() {
    local usage="Usage: tools.sh optimize-all [dir]
  Batch optimize all images in a directory (default: images/).
  Originals are saved to images/.originals/ before processing."

    local dir="${1:-images}"
    [[ -d "$dir" ]] || die "Directory not found: $dir"
    need_magick

    local originals_dir="${dir}/.originals"
    mkdir -p "$originals_dir"

    local count=0
    local total_before=0
    local total_after=0

    while IFS= read -r -d '' file; do
        local ext="${file##*.}"
        ext="${ext,,}"
        case "$ext" in
            jpg|jpeg|png|gif|webp|tiff|bmp) ;;
            *) continue ;;
        esac

        local basename
        basename=$(basename "$file")
        cp "$file" "${originals_dir}/${basename}"

        local before
        before=$(wc -c < "$file" | tr -d ' ')
        total_before=$(( total_before + before ))

        # Fit to 1920x1080, strip metadata, compress
        magick "$file" -resize "1920x1080>" -strip "$file"

        case "$ext" in
            jpg|jpeg)
                magick "$file" -quality 85 "$file"
                ;;
            png)
                magick "$file" -define png:compression-level=9 "$file"
                ;;
        esac

        local after
        after=$(wc -c < "$file" | tr -d ' ')
        total_after=$(( total_after + after ))

        count=$(( count + 1 ))
        echo "  $basename: $(human_size "$before") -> $(human_size "$after")"
    done < <(find "$dir" -maxdepth 1 -type f -print0)

    echo ""
    echo "  Optimized $count files"
    echo "  Total: $(human_size "$total_before") -> $(human_size "$total_after") (saved $(human_size $(( total_before - total_after ))))"
    echo "  Originals saved to: $originals_dir"
}

cmd_montage() {
    local usage="Usage: tools.sh montage <output> <img1> <img2> [img3...]
  Create a side-by-side comparison grid.
  Example: tools.sh montage comparison.png board-a.png board-b.png"

    [[ $# -lt 3 ]] && { echo "$usage"; exit 1; }
    need_magick
    local output="$1"
    shift
    local inputs=("$@")

    for f in "${inputs[@]}"; do
        [[ -f "$f" ]] || die "File not found: $f"
    done

    magick montage "${inputs[@]}" \
        -geometry +10+10 \
        -tile "${#inputs[@]}x1" \
        -background white \
        -border 2 \
        -bordercolor "#23373B" \
        "$output"

    local size
    size=$(wc -c < "$output" | tr -d ' ')
    echo "  Montage created: $output (${#inputs[@]} images, $(human_size "$size"))"
}

# ---------------------------------------------------------------------------
# PDF commands
# ---------------------------------------------------------------------------

cmd_pdf_info() {
    local usage="Usage: tools.sh pdf-info <pdf>
  Show page count, dimensions, and file size.
  Example: tools.sh pdf-info presentation.pdf"

    [[ $# -lt 1 ]] && { echo "$usage"; exit 1; }
    local pdf="$1"
    [[ -f "$pdf" ]] || die "File not found: $pdf"

    local size
    size=$(wc -c < "$pdf" | tr -d ' ')
    echo "  File: $pdf"
    echo "  Size: $(human_size "$size") ($size bytes)"

    if command -v pdfinfo &>/dev/null; then
        pdfinfo "$pdf" 2>/dev/null | grep -E "^(Pages|Page size|PDF version)" | sed 's/^/  /'
    elif command -v magick &>/dev/null; then
        local pages
        pages=$(magick identify -format "%n\n" "$pdf" 2>/dev/null | head -1)
        echo "  Pages: ${pages:-unknown}"
    else
        echo "  (Install poppler-utils or ImageMagick for detailed PDF info)"
    fi
}

cmd_pdf_extract_page() {
    local usage="Usage: tools.sh pdf-extract-page <pdf> <page#> <output.png>
  Extract a single page as an image (1-indexed).
  Example: tools.sh pdf-extract-page deck.pdf 3 slide3.png"

    [[ $# -lt 3 ]] && { echo "$usage"; exit 1; }
    need_magick
    local pdf="$1" page="$2" output="$3"
    [[ -f "$pdf" ]] || die "File not found: $pdf"

    # ImageMagick uses 0-indexed pages
    local idx=$(( page - 1 ))
    magick "${pdf}[${idx}]" -density 300 "$output"

    local size
    size=$(wc -c < "$output" | tr -d ' ')
    echo "  Extracted page $page -> $output ($(human_size "$size"))"
}

# ---------------------------------------------------------------------------
# Help
# ---------------------------------------------------------------------------

cmd_help() {
    cat <<'HELP'
Phlux Presentation Image & PDF Tools
=====================================

Usage: bash scripts/tools.sh <command> [args...]

IMAGE COMMANDS (require ImageMagick v7):

  resize <image> <WxH>             Resize keeping aspect ratio
  compress <image> [quality]       Optimize file size (JPEG default: 85)
  info <image>                     Show dimensions, format, size, color space
  trim <image>                     Auto-remove whitespace borders
  crop <image> <WxH+X+Y>          Crop to specific region
  fit <image> [maxW] [maxH]        Shrink to fit bounds (default 1920x1080)
  convert <input> <output>         Format conversion (PNG->JPG, SVG->PNG, etc.)
  strip <image>                    Remove EXIF/metadata to reduce size
  optimize-all [dir]               Batch optimize all images in a directory
  montage <output> <img1> <img2>   Create side-by-side comparison grid

PDF COMMANDS:

  pdf-info <pdf>                   Page count, dimensions, file size
  pdf-extract-page <pdf> <#> <out> Extract a slide as an image

COMMON FLAGS:

  --no-backup                      Skip creating .bak files (image commands)

EXAMPLES:

  # Check an image before adding to slides
  bash scripts/tools.sh info images/board-photo.png

  # Prepare a large photo for slides
  bash scripts/tools.sh fit images/board-photo.png
  bash scripts/tools.sh compress images/board-photo.png 80

  # Clean up a screenshot
  bash scripts/tools.sh trim images/screenshot.png

  # Compare two board options
  bash scripts/tools.sh montage images/comparison.png images/board-a.png images/board-b.png

  # Optimize all images before final build
  bash scripts/tools.sh optimize-all images

  # Check the built PDF
  bash scripts/tools.sh pdf-info my-presentation.pdf
HELP
}

# ---------------------------------------------------------------------------
# Dispatch
# ---------------------------------------------------------------------------

# Note: No cd — paths are passed as arguments relative to the caller's cwd.

command="${1:-help}"
shift || true

case "$command" in
    resize)           cmd_resize "$@" ;;
    compress)         cmd_compress "$@" ;;
    info)             cmd_info "$@" ;;
    trim)             cmd_trim "$@" ;;
    crop)             cmd_crop "$@" ;;
    fit)              cmd_fit "$@" ;;
    convert)          cmd_convert "$@" ;;
    strip)            cmd_strip "$@" ;;
    optimize-all)     cmd_optimize_all "$@" ;;
    montage)          cmd_montage "$@" ;;
    pdf-info)         cmd_pdf_info "$@" ;;
    pdf-extract-page) cmd_pdf_extract_page "$@" ;;
    help|--help|-h)   cmd_help ;;
    *)                die "Unknown command: $command (run 'tools.sh help' for usage)" ;;
esac
