#!/usr/bin/env bash
set -euo pipefail

ROOT_DEFAULT="${CODEX_CLAUDE_WORKFLOWS_HOME:-$HOME/.local/share/codex-claude-research-tools}"
INSTALL_ROOT="$ROOT_DEFAULT"
SKIP_SKILL_LINKS=0
SKIP_PYTHON_DEPS=0

usage() {
  cat <<'USAGE'
Usage: bash install.sh [options]

Options:
  --root PATH            Install component repositories under PATH.
  --skip-skill-links     Do not link translate-book into Codex/Claude skill dirs.
  --skip-python-deps     Skip pip installation of Python dependencies.
  -h, --help             Show this help.

Environment:
  CODEX_CLAUDE_WORKFLOWS_HOME  Alternative default install root.
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --root)
      [[ $# -ge 2 ]] || { echo "ERROR: --root requires a path" >&2; exit 2; }
      INSTALL_ROOT="$2"
      shift 2
      ;;
    --skip-skill-links)
      SKIP_SKILL_LINKS=1
      shift
      ;;
    --skip-python-deps)
      SKIP_PYTHON_DEPS=1
      shift
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

say() { printf '\n==> %s\n' "$*"; }
warn() { printf 'WARN: %s\n' "$*" >&2; }
fail() { printf 'ERROR: %s\n' "$*" >&2; exit 1; }

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || fail "Required command not found: $1"
}

if command -v python3 >/dev/null 2>&1; then
  PYTHON_BIN="$(command -v python3)"
elif command -v python >/dev/null 2>&1; then
  PYTHON_BIN="$(command -v python)"
else
  fail "Python 3 is required."
fi

require_cmd git
"$PYTHON_BIN" -c 'import sys; raise SystemExit(0 if sys.version_info >= (3, 9) else 1)' \
  || fail "Python 3.9 or newer is required."

mkdir -p "$INSTALL_ROOT"
BOOK_REPO="$INSTALL_ROOT/book-to-skill"
TRANSLATE_REPO="$INSTALL_ROOT/translate-book"

sync_repo() {
  local url="$1"
  local path="$2"
  local branch="$3"

  if [[ -d "$path/.git" ]]; then
    say "Updating $(basename "$path")"
    git -C "$path" fetch origin "$branch"
    git -C "$path" checkout "$branch"
    git -C "$path" pull --ff-only origin "$branch"
  elif [[ -e "$path" ]]; then
    fail "$path exists but is not a Git repository. Move it or choose a different --root."
  else
    say "Cloning $(basename "$path")"
    git clone --branch "$branch" --single-branch "$url" "$path"
  fi
}

sync_repo "https://github.com/icerain-cmd/book-to-skill.git" "$BOOK_REPO" "master"
sync_repo "https://github.com/icerain-cmd/translate-book.git" "$TRANSLATE_REPO" "main"

if [[ "$SKIP_PYTHON_DEPS" -eq 0 ]]; then
  say "Installing Research-to-Skill and common document dependencies"
  "$PYTHON_BIN" -m pip --version >/dev/null 2>&1 \
    || fail "pip is not available for $PYTHON_BIN. Install pip or re-run with --skip-python-deps."
  "$PYTHON_BIN" -m pip install -e "${BOOK_REPO}[pdf,docx]"

  say "Installing scholarly translation Python helpers"
  "$PYTHON_BIN" -m pip install pypandoc beautifulsoup4
else
  warn "Python dependency installation skipped."
fi

ensure_skill_link() {
  local target="$1"
  local source="$2"
  mkdir -p "$(dirname "$target")"

  if [[ -L "$target" ]]; then
    local current
    current="$(readlink "$target" || true)"
    if [[ "$current" == "$source" ]]; then
      printf 'OK: skill link already exists: %s\n' "$target"
    else
      warn "Skill link already exists and points elsewhere: $target -> $current"
    fi
    return
  fi

  if [[ -e "$target" ]]; then
    warn "Skill path already exists; leaving it unchanged: $target"
    return
  fi

  ln -s "$source" "$target"
  printf 'OK: linked %s -> %s\n' "$target" "$source"
}

if [[ "$SKIP_SKILL_LINKS" -eq 0 ]]; then
  say "Linking the maintained translate-book fork into agent skill directories"
  ensure_skill_link "$HOME/.agents/skills/translate-book" "$TRANSLATE_REPO"
  ensure_skill_link "$HOME/.claude/skills/translate-book" "$TRANSLATE_REPO"
else
  warn "Agent skill links skipped."
fi

say "Checking external tools"
for cmd in pandoc ebook-convert; do
  if command -v "$cmd" >/dev/null 2>&1; then
    printf 'OK: %s\n' "$cmd"
  else
    warn "$cmd not found. It is required for full PDF/DOCX/EPUB translation conversion."
  fi
done

if command -v research-to-skill >/dev/null 2>&1; then
  research-to-skill --help >/dev/null
  printf 'OK: research-to-skill CLI is available on PATH.\n'
else
  warn "research-to-skill was installed but is not visible on PATH in this shell. Check your Python scripts/bin path."
fi

cat <<END_SUMMARY

Installation root:
  $INSTALL_ROOT

Components:
  $BOOK_REPO
  $TRANSLATE_REPO

Next:
  bash doctor.sh --root "$INSTALL_ROOT"
END_SUMMARY
