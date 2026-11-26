#!/usr/bin/env bash
set -euo pipefail
root="$(cd "$(dirname "$0")/.." && pwd)"
while IFS= read -r -d '' f; do
  rel="${f#"$root"/tool/b64/res/}"
  dest="$root/android/app/src/main/res/${rel%.b64}"
  mkdir -p "$(dirname "$dest")"
  base64 -d "$f" > "$dest"
done < <(find "$root/tool/b64/res" -type f -name '*.b64' -print0)
