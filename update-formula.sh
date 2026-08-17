#!/usr/bin/env bash
#
# Update the Homebrew formula to the latest GitHub release.
#
# Auto-detects the formula (Formula/*.rb) and repo (from its homepage),
# fetches the latest release, resolves each platform asset's SHA256, and
# rewrites the formula's url/sha256 lines accordingly.
#
# Requirements: gh (authenticated), jq

set -euo pipefail

# --- Dependencies -----------------------------------------------------------
for cmd in gh jq; do
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "Error: required command '$cmd' not found in PATH." >&2
    exit 1
  fi
done

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# --- Resolve formula file ---------------------------------------------------
mapfile -t formulae < <(find "$SCRIPT_DIR/Formula" -maxdepth 1 -name '*.rb' 2>/dev/null)
if [[ ${#formulae[@]} -ne 1 ]]; then
  echo "Error: expected exactly one formula in Formula/, found ${#formulae[@]}." >&2
  exit 1
fi
FORMULA="${formulae[0]}"

# --- Resolve repo -----------------------------------------------------------
REPO="$(grep -oE 'homepage "https://github.com/[^"]+"' "$FORMULA" \
  | head -1 \
  | sed -E 's#.*github.com/([^"/]+/[^"/]+).*#\1#')"
if [[ -z "$REPO" ]]; then
  echo "Error: could not infer repo from formula homepage." >&2
  exit 1
fi

echo "Repo:    $REPO"
echo "Formula: $FORMULA"

# --- Fetch latest release ---------------------------------------------------
RELEASE_JSON="$(gh release view --repo "$REPO" --json tagName,assets)"
TAG="$(echo "$RELEASE_JSON" | jq -er '.tagName')"
echo "Release: $TAG"

# Build a lookup of asset-name -> sha256 (strip "sha256:" prefix from digest).
declare -A ASSET_SHA
while IFS=$'\t' read -r name digest; do
  ASSET_SHA["$name"]="${digest#sha256:}"
done < <(echo "$RELEASE_JSON" | jq -r '.assets[] | [.name, .digest] | @tsv')

# Current version referenced in the formula (from an existing url line).
OLD_VERSION="$(grep -oE 'releases/download/[^/]+/' "$FORMULA" \
  | head -1 | sed -E 's#releases/download/(.+)/#\1#')"

if [[ -z "$OLD_VERSION" ]]; then
  echo "Error: could not detect current version in formula." >&2
  exit 1
fi

if [[ "$OLD_VERSION" == "$TAG" ]]; then
  echo "Formula is already at $TAG. Nothing to do."
  exit 0
fi

echo "Updating $OLD_VERSION -> $TAG"

# --- Rewrite formula --------------------------------------------------------
# Read the formula line by line. When a `url` line is found:
#   1. Bump the version in the download path and asset filename.
#   2. Extract the asset filename and remember its sha256.
# When the following `sha256` line is found, replace it with the new value.
TMP="$(mktemp)"
trap 'rm -f "$TMP"' EXIT

pending_sha=""
missing=0

while IFS= read -r line || [[ -n "$line" ]]; do
  if [[ "$line" == *'url "'* ]]; then
    line="${line//releases\/download\/$OLD_VERSION\//releases/download/$TAG/}"
    line="${line//_${OLD_VERSION#v}_/_${TAG#v}_}"

    # Extract the asset filename (last path segment before the closing quote).
    asset="${line%\"*}"      # strip trailing quote and beyond
    asset="${asset##*/}"     # keep only the filename

    pending_sha="${ASSET_SHA[$asset]:-}"
    if [[ -z "$pending_sha" ]]; then
      echo "Warning: no sha256 found for asset '$asset'." >&2
      missing=1
    fi
    printf '%s\n' "$line"
    continue
  fi

  if [[ -n "$pending_sha" && "$line" == *'sha256 "'* ]]; then
    indent="${line%%sha256*}"
    printf '%s%s\n' "$indent" "sha256 \"$pending_sha\""
    pending_sha=""
    continue
  fi

  printf '%s\n' "$line"
done < "$FORMULA" > "$TMP"

mv "$TMP" "$FORMULA"
trap - EXIT

if [[ "$missing" -eq 1 ]]; then
  echo "Some assets had no matching sha256; review the formula." >&2
  exit 1
fi

project_name=${FORMULA##*/}
project_name=${project_name%.rb}
git commit -a -m "Update $project_name to $TAG"
