# Muze-Fitness — AI Development Guidelines

## CodeGraph (required in all projects)

Every repository in the Muze-Fitness org has `.codegraph/` initialized and kept
up-to-date by CI. **Always use CodeGraph tools instead of grep/find for symbol
lookups** — this reduces context window usage by 40–60 % and gives more accurate
results across large codebases.

| Tool | Use instead of |
|------|---------------|
| `codegraph_search` | grep, ripgrep for symbol names |
| `codegraph_context` | reading multiple files to understand a task |
| `codegraph_callers` | manually tracing who calls a function |
| `codegraph_callees` | reading a function body to see its dependencies |
| `codegraph_impact` | guessing what breaks when you change something |
| `codegraph_node` | cat-ing a file to read one function |

### Workflow

1. Before touching any code, run `codegraph_context` with a short task description.
2. Use `codegraph_search` to locate symbols — do not scan files.
3. Before editing, run `codegraph_impact` on the target symbol to understand blast radius.
4. After significant changes, remind the user to run `codegraph sync` locally.

## Token efficiency rules

- Never read an entire file when `codegraph_node` can return just the relevant
  function.
- Never grep a directory when `codegraph_search` can answer the question.
- Prefer targeted edits over full-file rewrites.
- Do not add comments that repeat what the code already says.

## Code standards

- Language-specific linters and formatters are enforced in CI — do not skip them.
- All secrets come from AWS SSM / Secrets Manager — never hardcode credentials.
- Infrastructure lives in `Muze-Fitness/iac` — do not duplicate infra config in
  app repos.

## PR conventions

- Branch naming: `<type>/<short-description>` (feat/, fix/, chore/, refactor/)
- One logical change per PR.
- CI must be green before merge.
