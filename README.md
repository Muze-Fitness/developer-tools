# Muze-Fitness Developer Tools

Shared tooling, templates, and GitHub Actions for all Muze-Fitness repositories.

## Structure

```
developer-tools/
├── codegraph/
│   └── templates/
│       ├── config.json   # Shared CodeGraph index config
│       └── CLAUDE.md     # Org-level AI assistant guidelines
├── github-actions/
│   └── codegraph-sync.yml  # Reusable workflow: index on every push
├── otel/                   # AI token observability (Stage 2)
│   ├── collector/
│   ├── adapters/
│   └── grafana-dashboards/
└── scripts/
    └── onboard-repo.sh   # One-command repo onboarding
```

## Onboarding a new repository

Run this from the root of any Muze-Fitness repo:

```bash
curl -fsSL https://raw.githubusercontent.com/Muze-Fitness/developer-tools/main/scripts/onboard-repo.sh | bash
```

This will:
1. Install CodeGraph CLI (if not present)
2. Build the initial code index
3. Add `.codegraph/config.json` with org defaults
4. Add `CLAUDE.md` with AI assistant guidelines
5. Add `.github/workflows/codegraph.yml` so CI keeps the index fresh

Then commit the result:
```bash
git add .codegraph/config.json .gitignore CLAUDE.md .github/workflows/codegraph.yml
git commit -m "chore: add codegraph index + CI sync"
git push
```

## Using the reusable workflow directly

In any repo's `.github/workflows/codegraph.yml`:

```yaml
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
```

## AI Tools Setup

See [codegraph/templates/CLAUDE.md](codegraph/templates/CLAUDE.md) for the full
guidelines distributed to all AI tools (Claude Code, Cursor, etc.).
