#!/usr/bin/env bash
# onboard-repo.sh
# Adds CodeGraph + shared CLAUDE.md to any Muze-Fitness repository.
#
# Usage (run from the root of the target repo):
#   curl -fsSL https://raw.githubusercontent.com/Muze-Fitness/developer-tools/main/scripts/onboard-repo.sh | bash
#
# Or clone developer-tools and run locally:
#   bash /path/to/developer-tools/scripts/onboard-repo.sh

set -euo pipefail

TEMPLATES_URL="https://raw.githubusercontent.com/Muze-Fitness/developer-tools/main"
REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"

log()  { printf "\033[0;34m[codegraph]\033[0m %s\n" "$*"; }
ok()   { printf "\033[0;32m[codegraph]\033[0m %s\n" "$*"; }
warn() { printf "\033[0;33m[codegraph]\033[0m %s\n" "$*"; }
err()  { printf "\033[0;31m[codegraph]\033[0m %s\n" "$*" >&2; exit 1; }

# ── 1. Verify we're inside a git repo ──────────────────────────────────────────
[[ -d "$REPO_ROOT/.git" ]] || err "Not a git repository. Run from the repo root."

log "Target repo: $REPO_ROOT"

# ── 2. Install CodeGraph CLI if missing ───────────────────────────────────────
if ! command -v codegraph &>/dev/null; then
  log "Installing CodeGraph CLI..."
  npm install -g @colbymchenry/codegraph
fi

CODEGRAPH_VERSION=$(codegraph --version 2>/dev/null || echo "unknown")
ok "CodeGraph CLI: $CODEGRAPH_VERSION"

# ── 3. Initialize or sync the index ───────────────────────────────────────────
cd "$REPO_ROOT"

if [[ -f ".codegraph/config.json" ]]; then
  warn ".codegraph/ already exists — running sync instead of init"
  codegraph sync
else
  log "Initializing CodeGraph index..."
  # Copy shared config template first so init uses org defaults
  mkdir -p .codegraph
  if command -v curl &>/dev/null; then
    curl -fsSL "$TEMPLATES_URL/codegraph/templates/config.json" -o .codegraph/config.json
  else
    log "curl not found — using codegraph default config"
  fi
  codegraph init -i
fi

ok "Index built: $(du -sh .codegraph/codegraph.db 2>/dev/null | cut -f1) DB"

# ── 4. Add .codegraph to .gitignore (except config.json) ─────────────────────
GITIGNORE="$REPO_ROOT/.gitignore"

if ! grep -q "codegraph.db" "$GITIGNORE" 2>/dev/null; then
  log "Updating .gitignore..."
  printf '\n# CodeGraph index (binary, rebuilt in CI)\n.codegraph/codegraph.db\n.codegraph/codegraph.db-shm\n.codegraph/codegraph.db-wal\n' >> "$GITIGNORE"
  ok ".gitignore updated"
else
  warn ".gitignore already has codegraph.db entries — skipping"
fi

# ── 5. Place CLAUDE.md if missing ─────────────────────────────────────────────
if [[ ! -f "$REPO_ROOT/CLAUDE.md" ]]; then
  log "Adding CLAUDE.md..."
  if command -v curl &>/dev/null; then
    curl -fsSL "$TEMPLATES_URL/codegraph/templates/CLAUDE.md" -o "$REPO_ROOT/CLAUDE.md"
    ok "CLAUDE.md created from org template"
  else
    warn "curl not found — copy CLAUDE.md manually from developer-tools/codegraph/templates/CLAUDE.md"
  fi
else
  warn "CLAUDE.md already exists — not overwriting. Consider merging with the org template."
fi

# ── 6. Add GitHub Action ───────────────────────────────────────────────────────
WORKFLOW_DIR="$REPO_ROOT/.github/workflows"
WORKFLOW_FILE="$WORKFLOW_DIR/codegraph.yml"

if [[ ! -f "$WORKFLOW_FILE" ]]; then
  mkdir -p "$WORKFLOW_DIR"
  log "Adding codegraph.yml workflow..."
  cat > "$WORKFLOW_FILE" << 'EOF'
name: CodeGraph

on:
  push:
    branches: [main]
  pull_request:

jobs:
  codegraph:
    uses: Muze-Fitness/developer-tools/.github/workflows/codegraph-sync.yml@main
    with:
      upload-artifact: ${{ github.event_name == 'pull_request' }}
EOF
  ok "Workflow added: .github/workflows/codegraph.yml"
else
  warn ".github/workflows/codegraph.yml already exists — skipping"
fi

# ── 7. Summary ─────────────────────────────────────────────────────────────────
echo ""
ok "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
ok " CodeGraph onboarding complete for: $(basename "$REPO_ROOT")"
ok "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "  Next steps:"
echo "  1. Review CLAUDE.md and add any repo-specific notes"
echo "  2. git add .codegraph/config.json .gitignore CLAUDE.md .github/workflows/codegraph.yml"
echo "  3. git commit -m 'chore: add codegraph index + CI sync'"
echo "  4. git push → CI will keep the index up to date automatically"
echo ""
