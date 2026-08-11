#!/usr/bin/env bash
set -u

ROOT_DEFAULT="${CODEX_CLAUDE_WORKFLOWS_HOME:-$HOME/.local/share/codex-claude-research-tools}"
INSTALL_ROOT="$ROOT_DEFAULT"

usage() {
  cat <<'USAGE'
Usage: bash doctor.sh [--root PATH]
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --root)
      [[ $# -ge 2 ]] || { echo "ERROR: --root requires a path" >&2; exit 2; }
      INSTALL_ROOT="$2"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "ERROR: unknown option: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

FAILURES=0
WARNINGS=0

ok() { printf 'PASS  %s\n' "$*"; }
warn() { printf 'WARN  %s\n' "$*"; WARNINGS=$((WARNINGS + 1)); }
fail() { printf 'FAIL  %s\n' "$*"; FAILURES=$((FAILURES + 1)); }

check_cmd_required() {
  if command -v "$1" >/dev/null 2>&1; then ok "$1: $(command -v "$1")"; else fail "$1 is required but not found"; fi
}

check_cmd_optional() {
  if command -v "$1" >/dev/null 2>&1; then ok "$1: $(command -v "$1")"; else warn "$1 not found"; fi
}

printf 'Codex · Claude Code Research Workflows doctor\n'
printf 'Install root: %s\n\n' "$INSTALL_ROOT"

check_cmd_required git

if command -v python3 >/dev/null 2>&1; then
  PYTHON_BIN="$(command -v python3)"
elif command -v python >/dev/null 2>&1; then
  PYTHON_BIN="$(command -v python)"
else
  PYTHON_BIN=""
  fail "Python 3 not found"
fi

if [[ -n "$PYTHON_BIN" ]]; then
  if "$PYTHON_BIN" -c 'import sys; raise SystemExit(0 if sys.version_info >= (3, 9) else 1)' >/dev/null 2>&1; then
    ok "Python: $($PYTHON_BIN --version 2>&1)"
  else
    fail "Python 3.9 or newer is required"
  fi
fi

for repo in book-to-skill translate-book; do
  if [[ -d "$INSTALL_ROOT/$repo/.git" ]]; then
    branch="$(git -C "$INSTALL_ROOT/$repo" branch --show-current 2>/dev/null || true)"
    head="$(git -C "$INSTALL_ROOT/$repo" rev-parse --short HEAD 2>/dev/null || true)"
    ok "$repo repository: branch=${branch:-detached} head=${head:-unknown}"
  else
    fail "$repo repository missing at $INSTALL_ROOT/$repo"
  fi
done

if command -v research-to-skill >/dev/null 2>&1; then
  if research-to-skill --help >/dev/null 2>&1; then ok "research-to-skill CLI"; else fail "research-to-skill exists but --help failed"; fi
else
  fail "research-to-skill CLI not found on PATH"
fi

if [[ -n "$PYTHON_BIN" ]]; then
  for module in pypandoc bs4; do
    if "$PYTHON_BIN" -c "import $module" >/dev/null 2>&1; then ok "Python module: $module"; else warn "Python module missing: $module"; fi
  done
fi

check_cmd_optional pandoc
check_cmd_optional ebook-convert
check_cmd_optional codex
check_cmd_optional claude

for skill_path in "$HOME/.agents/skills/translate-book" "$HOME/.claude/skills/translate-book"; do
  if [[ -e "$skill_path" || -L "$skill_path" ]]; then ok "skill path: $skill_path"; else warn "skill path missing: $skill_path"; fi
done

printf '\nSummary: %d failure(s), %d warning(s)\n' "$FAILURES" "$WARNINGS"
[[ "$FAILURES" -eq 0 ]]
