#!/usr/bin/env bash
#
# check-compliance.sh — guardrail for the BugWare research repository.
#
# Scans tracked files for artifacts that should never be committed to a public
# educational security repo and that risk violating GitHub's Acceptable Use
# Policies — chiefly ready-to-run compiled executables (live, drop-and-run
# payloads) rather than source code or proof-of-concept scripts.
#
# It flags a file when EITHER:
#   * its extension is a compiled/executable/installer type, OR
#   * its first bytes match a known executable binary format (PE, ELF, Mach-O),
#     regardless of extension.
#
# Image, font and other benign binary assets used by the website are allowed.
#
# Usage:
#   scripts/check-compliance.sh            # scan all git-tracked files
#   scripts/check-compliance.sh <files...> # scan a specific list (e.g. a hook)
#
# Exit status: 0 = clean, 1 = violations found, 2 = usage/setup error.

set -euo pipefail

# --- Extensions that indicate a compiled binary, installer, or packaged app.
# These are the artifacts a "no pre-built binaries" research repo must not ship.
BLOCK_EXT_RE='\.(exe|dll|scr|com|cpl|ocx|sys|msi|msix|appx|efi|elf|out|bin|o|obj|a|lib|so|dylib|ko|apk|dex|jar|class|iso|img|vhd|vhdx|dmg|pkg|deb|rpm)$'

# --- Benign binary assets that are allowed (website images, fonts, etc.).
ALLOW_EXT_RE='\.(png|jpg|jpeg|gif|webp|svg|ico|woff|woff2|ttf|otf|pdf|md|yml|yaml|html|css|js|json|txt)$'

# --- Files/paths to skip entirely (this script, the site build output).
SKIP_PATH_RE='^(scripts/check-compliance\.sh|_site/|vendor/)'

violations=()
reasons=()

is_binary_executable() {
  # Reads the first bytes and matches PE (MZ), ELF (\x7fELF) or Mach-O magics.
  local f="$1" sig
  sig=$(head -c 4 "$f" 2>/dev/null | xxd -p 2>/dev/null || true)
  case "$sig" in
    4d5a*)      return 0 ;; # MZ  -> Windows PE (.exe/.dll)
    7f454c46)   return 0 ;; # \x7fELF -> Linux ELF
    feedface|feedfacf|cefaedfe|cffaedfe|cafebabe|bebafeca) return 0 ;; # Mach-O / fat
    *)          return 1 ;;
  esac
}

# Build the file list: explicit args, else all tracked files.
if [ "$#" -gt 0 ]; then
  files=("$@")
else
  # shellcheck disable=SC2207
  files=($(git ls-files))
fi

for f in "${files[@]}"; do
  [ -f "$f" ] || continue
  echo "$f" | grep -Eq "$SKIP_PATH_RE" && continue

  lc=$(echo "$f" | tr '[:upper:]' '[:lower:]')

  if echo "$lc" | grep -Eq "$BLOCK_EXT_RE"; then
    violations+=("$f"); reasons+=("blocked file type (compiled/executable/installer)")
    continue
  fi

  # Magic-byte check for executables hiding behind an innocuous extension,
  # skipping files whose extension is a known-benign asset type.
  if ! echo "$lc" | grep -Eq "$ALLOW_EXT_RE"; then
    if is_binary_executable "$f"; then
      violations+=("$f"); reasons+=("executable binary signature (PE/ELF/Mach-O)")
    fi
  fi
done

if [ "${#violations[@]}" -eq 0 ]; then
  echo "✅ Compliance check passed: no committed executables or prohibited binaries found."
  exit 0
fi

echo "❌ Compliance check FAILED — ${#violations[@]} prohibited artifact(s) found:"
echo
for i in "${!violations[@]}"; do
  printf '  • %s\n      ↳ %s\n' "${violations[$i]}" "${reasons[$i]}"
done
cat <<'EOF'

BugWare is a research repository that ships source and proof-of-concept code
only — never ready-to-run binaries. Remove these files (and purge them from
history if already pushed), or build them locally in an isolated lab instead.

If a flagged file is a legitimate, non-executable asset, add its extension to
ALLOW_EXT_RE in scripts/check-compliance.sh.
EOF
exit 1
