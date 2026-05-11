#!/usr/bin/env bash
# scan-secrets.sh — detect likely secrets in staged changes before commit.
#
# Usage:
#   ./scripts/scan-secrets.sh              # scan currently staged diff
#   ./scripts/scan-secrets.sh <file>...    # scan specific files
#
# Exit codes:
#   0  no secrets detected
#   1  potential secret(s) detected — caller MUST prompt user
#   2  invocation error
#
# This script is conservative: false positives are preferred over false negatives.
# Caller (easy-git-zh skill) decides what to do — never auto-commit on exit 1.

set -euo pipefail

# ---------- patterns ----------
# Filename patterns that often contain secrets
SECRET_FILENAMES=(
  '\.env$'
  '\.env\..*'
  '.*\.pem$'
  '.*\.key$'
  '.*\.p12$'
  '.*\.pfx$'
  '.*\.kdbx$'
  'credentials\.json$'
  'id_rsa$'
  'id_dsa$'
  'id_ed25519$'
  'id_ecdsa$'
  'service-account.*\.json$'
)

# Content regex patterns (POSIX ERE)
# Each entry: "label|regex"
SECRET_PATTERNS=(
  'AWS Access Key|AKIA[0-9A-Z]{16}'
  'GitHub PAT (classic)|ghp_[A-Za-z0-9]{36}'
  'GitHub PAT (fine-grained)|github_pat_[A-Za-z0-9_]{82}'
  'GitHub OAuth token|gho_[A-Za-z0-9]{36}'
  'GitHub user-to-server token|ghu_[A-Za-z0-9]{36}'
  'GitHub server-to-server token|ghs_[A-Za-z0-9]{36}'
  'GitHub refresh token|ghr_[A-Za-z0-9]{36}'
  'Slack token|xox[abprs]-[A-Za-z0-9-]{10,}'
  'Stripe live key|sk_live_[A-Za-z0-9]{20,}'
  'Stripe restricted key|rk_live_[A-Za-z0-9]{20,}'
  'Google API key|AIza[0-9A-Za-z_-]{35}'
  'OpenAI API key|sk-(proj-)?[A-Za-z0-9_-]{20,}'
  'Anthropic API key|sk-ant-[A-Za-z0-9_-]{20,}'
  'Generic API key assignment|(api[_-]?key|apikey|secret|token|password|passwd)[[:space:]]*[:=][[:space:]]*["'"'"'][A-Za-z0-9+/=_-]{16,}["'"'"']'
  'Private key header|-----BEGIN ([A-Z ]*)?PRIVATE KEY( BLOCK)?-----'
  'JWT token|eyJ[A-Za-z0-9_-]{10,}\.eyJ[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}'
)

# ---------- helpers ----------

err()  { printf '%s\n' "$*" >&2; }
warn() { printf '⚠️  %s\n' "$*" >&2; }
ok()   { printf '✅ %s\n' "$*"; }

FOUND=0

report_filename() {
  local file="$1"
  warn "Suspicious filename (likely secret): $file"
  FOUND=1
}

report_match() {
  local file="$1"
  local label="$2"
  local line="$3"
  warn "Likely $label in $file:"
  printf '   → %s\n' "$line" | head -c 200 >&2
  printf '\n' >&2
  FOUND=1
}

check_filename() {
  local file="$1"
  local base
  base="$(basename -- "$file")"
  # Skip well-known template filenames (.env.example, .env.sample, etc.).
  # These conventionally contain no real secrets; content scan still applies.
  case "$base" in
    .env.example|.env.sample|.env.template|.env.defaults|.env.dist)
      return
      ;;
  esac
  for pat in "${SECRET_FILENAMES[@]}"; do
    if printf '%s' "$base" | grep -Eq -e "^$pat"; then
      report_filename "$file"
      return
    fi
  done
}

is_binary_file() {
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
  return 1
}

check_content() {
  local file="$1"
  local content="$2"
  for entry in "${SECRET_PATTERNS[@]}"; do
    local label="${entry%%|*}"
    local regex="${entry#*|}"
    local matched
    matched="$(printf '%s' "$content" | grep -Ein -e "$regex" || true)"
    if [ -n "$matched" ]; then
      report_match "$file" "$label" "$matched"
    fi
  done
}

# ---------- main ----------

if [ "$#" -eq 0 ]; then
  # No args → scan staged diff
  if ! git rev-parse --git-dir >/dev/null 2>&1; then
    err "Not a git repository."
    exit 2
  fi
  STAGED_FILES="$(git diff --cached --name-only --diff-filter=ACMR)"
  if [ -z "$STAGED_FILES" ]; then
    ok "No staged files to scan."
    exit 0
  fi
  while IFS= read -r file; do
    [ -z "$file" ] && continue
    check_filename "$file"
    # Skip content scan on binary files (no meaningful text patterns + noisy warnings)
    if [ -f "$file" ] && is_binary_file "$file"; then
      continue
    fi
    if content="$(git show ":$file" 2>/dev/null)"; then
      check_content "$file" "$content"
    fi
  done <<< "$STAGED_FILES"
else
  # Args → scan specific files
  for file in "$@"; do
    if [ ! -f "$file" ]; then
      err "Skip: $file (not a regular file)"
      continue
    fi
    check_filename "$file"
    if is_binary_file "$file"; then
      continue
    fi
    content="$(cat -- "$file")"
    check_content "$file" "$content"
  done
fi

if [ "$FOUND" -eq 0 ]; then
  ok "No likely secrets detected."
  exit 0
fi

err ""
err "❌ One or more potential secrets detected."
err "   The easy-git-zh skill will pause and ask the user before committing."
err "   If false positive, the user can confirm and proceed."
exit 1
