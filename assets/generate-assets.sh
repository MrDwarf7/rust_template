#!/usr/bin/env bash
# Generate monogram project assets under assets/ (next to this script, or --out DIR).
#
# Pipeline:
#   1. Write logo.svg  -- rounded square + letter (pure SVG text)
#   2. magick: SVG -> logo-1024.png + icon-{16,32,48,64,128,256,512}.png + icon.png
#   3. magick: multi-size icon.ico (16/32/48/256)
#   4. magick: social-banner.png (1280x640) + README-header.png (1280x320)
#      solid BG, left accent bar, monogram mark, name + tagline lettering
#
# Deps: ImageMagick 7 (`magick`). Font: Noto Sans Bold (or override --font).
#
# Usage:
#   ./generate-assets.sh --letter R --name rust_template --tagline "Rust project template"
#   ./generate-assets.sh -l C -n chapterize -t "YouTube-style chapters via ffmpeg" --accent "#EF4444"
#   ./generate-assets.sh --out /path/to/other/assets ...
#
# Defaults match rust_template current branding.
set -euo pipefail

readonly DEFAULT_BG="#2D2D2D"
readonly DEFAULT_ACCENT="#00D9A5"
readonly DEFAULT_LETTER="R"
readonly DEFAULT_NAME="rust_template"
readonly DEFAULT_TAGLINE="Rust project template"
readonly SIZES=(16 32 48 64 128 256 512)
readonly ICO_SIZES=(16 32 48 256)

usage() {
  cat <<'USAGE'
generate-assets.sh - monogram SVG/PNG/ICO + social banners via ImageMagick

Options:
  -l, --letter CHAR       Monogram letter (default: R)
  -n, --name NAME         Project name for banners (default: rust_template)
  -t, --tagline TEXT      Banner tagline (default: Rust project template)
  -a, --accent HEX        Accent color (default: #00D9A5)
  -b, --bg HEX            Background color (default: #2D2D2D)
  -o, --out DIR           Output directory (default: dir of this script)
  -f, --font PATH         Bold TTF/OTF for raster lettering + banners
      --source-png PATH   Use existing PNG as master art instead of monogram
  -h, --help              Show this help
USAGE
}

xml_escape() {
  printf '%s' "$1" | sed -e 's/&/\&amp;/g' -e 's/</\&lt;/g' -e 's/>/\&gt;/g' -e 's/"/\&quot;/g'
}

write_svg() {
  local path="$1"
  local letter_xml="$2"
  local bg="$3"
  local accent="$4"
  # Pure ASCII SVG monogram -- rounded square + centered letter
  cat > "${path}" <<SVG
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 512 512">
  <rect width="512" height="512" rx="96" fill="${bg}"/>
  <text x="256" y="340" font-family="DejaVu Sans, Liberation Sans, Noto Sans, Arial, sans-serif"
        font-size="280" font-weight="700" fill="${accent}" text-anchor="middle">${letter_xml}</text>
</svg>
SVG
}

resolve_font() {
  local font="${1:-}"
  if [ -n "${font}" ]; then
    printf '%s\n' "${font}"
    return 0
  fi
  local candidate
  for candidate in \
    /usr/share/fonts/noto/NotoSans-Bold.ttf \
    /usr/share/fonts/TTF/DejaVuSans-Bold.ttf \
    /usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf \
    /usr/share/fonts/liberation/LiberationSans-Bold.ttf \
    /usr/share/fonts/noto/NotoSans-Regular.ttf
  do
    if [ -f "${candidate}" ]; then
      printf '%s\n' "${candidate}"
      return 0
    fi
  done
  return 1
}

# Core pipeline: write monogram + raster icons + banners into OUT.
run() {
  local out="$1"
  local letter="$2"
  local name="$3"
  local tagline="$4"
  local accent="$5"
  local bg="$6"
  local font="$7"
  local source_png="$8"

  local letter_xml svg_path master mark_sz mark_x mark_y text_x s

  letter_xml="$(xml_escape "${letter}")"
  svg_path="${out}/logo.svg"

  echo "==> out: ${out}"
  echo "    letter=${letter} accent=${accent} bg=${bg}"
  echo "    name=${name}"
  echo "    tagline=${tagline}"
  echo "    font=${font}"

  if [ -n "${source_png}" ]; then
    if [ ! -f "${source_png}" ]; then
      echo "error: --source-png not found: ${source_png}" >&2
      return 1
    fi
    echo "==> master from source png: ${source_png}"
    # Fit into square on BG, then 1024
    magick "${source_png}" -background "${bg}" -alpha remove -alpha off \
      -gravity center -extent "%[fx:max(w,h)]x%[fx:max(w,h)]" \
      -resize 1024x1024 \
      "${out}/logo-1024.png"
    # Still write monogram SVG as the vector brand mark for README
    write_svg "${svg_path}" "${letter_xml}" "${bg}" "${accent}"
  else
    echo "==> write logo.svg"
    write_svg "${svg_path}" "${letter_xml}" "${bg}" "${accent}"
    echo "==> rasterize logo-1024.png from SVG"
    # denser raster for clean letterforms
    magick -background none -density 512 "${svg_path}" -resize 1024x1024 "${out}/logo-1024.png"
  fi

  master="${out}/logo-1024.png"

  echo "==> icon-*.png"
  for s in "${SIZES[@]}"; do
    magick "${master}" -resize "${s}x${s}" "${out}/icon-${s}.png"
  done
  # convenience 256 copy
  cp -f "${out}/icon-256.png" "${out}/icon.png"

  echo "==> icon.ico (16/32/48/256)"
  # ImageMagick packs multi-resolution ICO from the listed PNGs
  magick \
    "${out}/icon-16.png" \
    "${out}/icon-32.png" \
    "${out}/icon-48.png" \
    "${out}/icon-256.png" \
    "${out}/icon.ico"

  echo "==> social-banner.png 1280x640"
  # Canvas + left accent bar + monogram + name/tagline
  mark_sz=280
  mark_x=80
  mark_y=$(( (640 - mark_sz) / 2 ))
  text_x=$(( mark_x + mark_sz + 48 ))

  magick -size 1280x640 "xc:${bg}" \
    -fill "${accent}" -draw "rectangle 0,0 16,640" \
    \( "${master}" -resize "${mark_sz}x${mark_sz}" \) \
    -geometry "+${mark_x}+${mark_y}" -composite \
    -font "${font}" -fill "#F0F0F0" -pointsize 72 \
    -gravity Northwest -annotate "+${text_x}+240" "${name}" \
    -font "${font}" -fill "${accent}" -pointsize 36 \
    -gravity Northwest -annotate "+${text_x}+340" "${tagline}" \
    "${out}/social-banner.png"

  echo "==> README-header.png 1280x320"
  magick "${out}/social-banner.png" -resize 1280x320! "${out}/README-header.png"

  echo "==> done -> ${out}"
  ls -la "${out}/logo.svg" "${out}/logo-1024.png" "${out}/icon.ico" \
    "${out}/icon.png" "${out}/social-banner.png" "${out}/README-header.png"
}

main() {
  local bg="${DEFAULT_BG}"
  local accent="${DEFAULT_ACCENT}"
  local letter="${DEFAULT_LETTER}"
  local name="${DEFAULT_NAME}"
  local tagline="${DEFAULT_TAGLINE}"
  local out=""
  local font=""
  local source_png=""
  local script_dir

  while [ $# -gt 0 ]; do
    case "$1" in
      -l|--letter) letter="${2:?}"; shift 2 ;;
      -n|--name) name="${2:?}"; shift 2 ;;
      -t|--tagline) tagline="${2:?}"; shift 2 ;;
      -a|--accent) accent="${2:?}"; shift 2 ;;
      -b|--bg) bg="${2:?}"; shift 2 ;;
      -o|--out) out="${2:?}"; shift 2 ;;
      -f|--font) font="${2:?}"; shift 2 ;;
      --source-png) source_png="${2:?}"; shift 2 ;;
      -h|--help) usage; exit 0 ;;
      *) echo "unknown arg: $1" >&2; usage >&2; exit 2 ;;
    esac
  done

  script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  if [ -z "${out}" ]; then
    out="${script_dir}"
  fi
  mkdir -p "${out}"
  out="$(cd "${out}" && pwd)"

  if ! command -v magick >/dev/null 2>&1; then
    echo "error: ImageMagick 7 'magick' not found in PATH" >&2
    exit 1
  fi

  if ! font="$(resolve_font "${font}")"; then
    echo "error: no usable bold font found; pass --font /path/to/Bold.ttf" >&2
    exit 1
  fi
  if [ ! -f "${font}" ]; then
    echo "error: font not found: ${font}" >&2
    exit 1
  fi

  run "${out}" "${letter}" "${name}" "${tagline}" "${accent}" "${bg}" "${font}" "${source_png}"
}

main "$@"
