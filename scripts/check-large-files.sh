#!/usr/bin/env bash
# check-large-files.sh — detect large files / binaries in staged changes before commit.
#
# Usage:
#   ./scripts/check-large-files.sh                # scan currently staged files
#   ./scripts/check-large-files.sh <file>...      # scan specific files
#
# Exit codes:
#   0  all staged files are OK (text, < 10MB)
#   1  large file or binary detected — caller MUST prompt user
#   2  invocation error
#
# Thresholds:
#   - File size: > 10MB → warn
#   - Binary detection: file looks binary (null bytes in first 8KB) → warn

set -euo pipefail

SIZE_LIMIT_BYTES=$((10 * 1024 * 1024))  # 10 MB

err()  { printf '%s\n' "$*" >&2; }
warn() { printf '⚠️  %s\n' "$*" >&2; }
ok()   { printf '✅ %s\n' "$*"; }

FOUND=0

human_size() {
  local bytes="$1"
  if [ "$bytes" -lt 1024 ]; then
    printf '%dB' "$bytes"
  elif [ "$bytes" -lt $((1024 * 1024)) ]; then
    awk -v b="$bytes" 'BEGIN { printf "%.1fKB", b/1024 }'
  elif [ "$bytes" -lt $((1024 * 1024 * 1024)) ]; then
    awk -v b="$bytes" 'BEGIN { printf "%.1fMB", b/(1024*1024) }'
  else
    awk -v b="$bytes" 'BEGIN { printf "%.2fGB", b/(1024*1024*1024) }'
  fi
}

is_binary() {
  # Reads first 8KB, returns 0 (binary) if any NUL byte is present.
  # Uses Perl as a reliable cross-platform NUL byte detector — bash $'\0' in
  # grep patterns is unreliable (GNU grep treats it as empty pattern).
  local file="$1"
  if command -v perl >/dev/null 2>&1; then
    perl -e '
      open(F, "<", $ARGV[0]) or exit 2;
      binmode F;
      read F, $buf, 8192;
      exit (index($buf, "\0") >= 0 ? 0 : 1);
    ' -- "$file"
    return $?
  fi
  # Fallback: use `file` command if available
  if command -v file >/dev/null 2>&1; then
    local mime
    mime="$(file --mime-encoding -b -- "$file" 2>/dev/null || true)"
    case "$mime" in
      binary) return 0 ;;
      *) return 1 ;;
    esac
  fi
  # Last resort: assume text
  return 1
}

check_file() {
  local file="$1"
  if [ ! -f "$file" ]; then
    return
  fi

  local size
  size="$(wc -c < "$file" | tr -d '[:space:]')"

  if [ "$size" -gt "$SIZE_LIMIT_BYTES" ]; then
    warn "Large file: $file ($(human_size "$size"))"
    FOUND=1
  fi

  if is_binary "$file"; then
    # Allow common safe binaries
    case "$file" in
      *.png|*.jpg|*.jpeg|*.gif|*.webp|*.ico|*.svg)
        # small images < 1MB are usually fine, warn anyway if larger
        if [ "$size" -gt $((1024 * 1024)) ]; then
          warn "Large binary (image): $file ($(human_size "$size"))"
          FOUND=1
        fi
        ;;
      *)
        warn "Binary file: $file ($(human_size "$size"))"
        FOUND=1
        ;;
    esac
  fi
}

if [ "$#" -eq 0 ]; then
  if ! git rev-parse --git-dir >/dev/null 2>&1; then
    err "Not a git repository."
    exit 2
  fi
  STAGED_FILES="$(git diff --cached --name-only --diff-filter=ACMR)"
  if [ -z "$STAGED_FILES" ]; then
    ok "No staged files to check."
    exit 0
  fi
  while IFS= read -r file; do
    [ -z "$file" ] && continue
    check_file "$file"
  done <<< "$STAGED_FILES"
else
  for file in "$@"; do
    check_file "$file"
  done
fi

if [ "$FOUND" -eq 0 ]; then
  ok "No large or binary files detected."
  exit 0
fi

err ""
err "❌ Large or binary file(s) detected."
err "   The easy-git skill will pause and ask the user before committing."
err "   Suggestions:"
err "   - Move large assets out of git (use git-lfs, S3, or external storage)"
err "   - Add the file to .gitignore if it's a build artifact"
err "   - If intentional (e.g., a logo asset), user can confirm and proceed"
exit 1
