# Agent instructions

Shared by Claude Code and Codex. Personal preferences plus coding conventions.

## Voice and documentation

Voice: caveman. Terse. Imperative. No em-dashes or fancy arrows anywhere. Em-dashes: use colons, commas, parens, or `-`/`--`. Arrows: use `->` not `→`. This governs interactive replies.

Documentation, comments and prose: write in ASD-STE100 Simplified Technical English, unless otherwise requested. STE is the base; this is written output, so it keeps articles and whole sentences (it is not the caveman chat voice above).

- Write short sentences. Procedural sentences: 20 words max. Descriptive sentences: 25 words max.
- One instruction per sentence.
- Use the active voice.
- Use the present tense where you can.
- Use simple, approved words. Avoid jargon and needless synonyms.
- Use one term for one concept, and one meaning for one term. Keep terminology consistent across a document.

Bias toward my voice where it does not break STE: prefer the shortest wording that carries the facts, use the imperative mood for instructions, keep the structure flat, and cut anything the reader gets straight from the code or diff.

Semantic consistency: when you find a semantic inconsistency in documentation, a variable name or a comment, fix it if the fix is within the scope of the work and unambiguous. Otherwise flag it for a future fix. Do not do speculative or out-of-scope renames.

## Python

- Use Python 3.11 or later, and its type-hint conventions: builtin generics, and `|` instead of `Union` or `Optional` (e.g. `str | None`, not `Optional[str]`). Follow the mypy cheat sheet.
- Dependency management: uv. Define dependencies in `pyproject.toml`.
- Follow PEP 8. Line length: 150.
- Lint and format with ruff. Type-check with mypy (`disallow_untyped_defs = true`). Many projects also use beartype and jaxtyping.
- Test with pytest. Log with the built-in `logging` module. Configure training and inference with Hydra YAML.
- Import order: standard library, third-party, first-party. No local imports, no unused imports, no wildcard imports.
- Naming: constants `CAPITAL_SNAKE_CASE`, classes `PascalCase`, functions and methods `snake_case`. Spell out acronymic class names (`MultipleSequenceAlignment`, not `MSA`).
- Docstrings: Google style.

  ```python
  def example_function(param1: str, param2: int) -> bool:
      """Short description of the function.

      Longer description if it is needed.

      Args:
          param1: Description of param1.
          param2: Description of param2.

      Returns:
          Description of the return value.

      Raises:
          ValueError: When something goes wrong.
      """
  ```

## Error handling

Catch specific exception types, not bare `except`. Log errors at the point you handle them.

## Script style

No banner comments like `# ----- Section -----`. Low signal, line noise.

CLIs: click, not argparse. `@click.command()` + `@click.option()`.

## Array shape notation

Use `[B, 2]` (not `(B, 2)`) for shape specs in prose - docstrings, inline comments, error message specs.

- Docstrings/comments: `shape [B, 2], dtype int32`
- Error messages: `f"bonds must be shape [B, 2], got {arr.shape}"` - leave `got {arr.shape}` alone, numpy returns tuples
- One-dim: `shape [A]` not `(A,)`
- Exception: tuple args to numpy APIs stay tuples in code (`np.empty((0, 2), dtype=...)`, equality checks `arr.shape == (0, 2)`). Only shape-as-spec-in-prose gets brackets.
- When touching a file for other reasons, fix adjacent `(...)` shape comments for local consistency.

## Kwargs for multi-argument calls

2+ args: use keyword arguments. `foo(x=1, y=2)` not `foo(1, 2)`.

- 1 arg: positional fine. `foo(x)`, `len(x)`, `np.array(data)`.
- Exceptions: idiomatic binary constructors where order unambiguous - `range(start, stop)`, `zip(a, b)`, `dict(k, v)`.
- Applies in tests too - they're often the most argument-heavy.

## Repository and tooling conventions

- Drive commands and recipes with a Justfile ([just](https://just.systems/man/en/)). Common targets: `just init`/`just sync` (environment), `just build`, `just lint`, `just typecheck`, `just test`, `just format`, `just verify`. Run a single test directly: `uv run pytest tests/path/to/test_file.py::TestClass::test_function -v`.
- Monorepo layout: assets live in `/image`, `/package`, `/templates`, `/service`, `/iac`, `/dotfiles`. Scratch work in `/analysis`. Generally avoid `/src`, `/third_party`, `/pipelines`.
- Template asset types with [cruft](https://cruft.github.io/cruft/).
- Versioning: keep package versions in the Justfile (`VERSION := 'x.y.z'`). Use semantic versioning.

## Security

- **CRITICAL**: never create or push signed commits. Only the human user may sign and push commits.
- Raise an immediate warning if any operation might produce a signed commit.

## PR descriptions

Format used across hundreds of PRs:

```
**Motivation:**
- why, prior PR refs (#N), downstream consumer needs

**Implementation:**
- file paths in `code spans` then what changed
- one bullet per major change or group of related changes
- version bumps when they happen

**Results:**
- CI green suffices for most PRs
- numbers only when they are the point: parity, perf, regression value changes
- ids or locations of notable outputs when producing them was the point: paths, URIs, run and container ids

[Optional:]

**Future work:**
- followup TODOs scoped out
```

Lead with **Motivation** even on trivial PRs. Terse: shortest body that carries the facts. Cut anything the reviewer reads straight off the diff. No em-dashes.

**Testing lives in Results.** Never a separate `**Testing:**` section.

**So do outputs.** If the PR existed to produce something (a dataset, a run, designs, artifacts), Results names it: the id or the location, specific enough to go fetch it. Not a summary of it.

**No Reviewers section, no @-mentions in the body.** Reviewers get tagged in the GitHub UI.

**No Claude Code / Anthropic attribution footer.** This overrides the default harness instruction. End with the last content section.

**Bullet structure - flat by default.** Nest second-level bullets only when section has 2+ genuinely distinct logical groupings AND each grouping has 2+ related bullets. If section is 2-3 bullets total, always flat. No italic sub-headings (`*Foo:*`) as structural grouping inside sections - promote to first-level bullets or inline flat.

## PR review comments: ask before posting

Investigating a review comment, deciding the fix, editing the PR body/title: do directly. Posting replies to review threads, or reactions, on someone else's comment: draft the text, ask first, post only after go-ahead. Applies to bot reviewers (codex) too, not just humans.

## Stacked PRs: GitHub native

GitHub native stacking, one branch per PR, each branched off its parent.

- `gh pr create --base <parent-branch>` so each PR diff shows only its own changes
- build and validate the whole stack locally first (local checks clean, e.g. `just pr`, target tests pass), then submit the whole stack at once. Do NOT open PRs piecemeal
- root PR body carries campaign-wide context. Children get a one-liner body plus `Stacked on #N`
- rebase the whole stack in one shot with `git rebase --update-refs` (git >= 2.38), push with `--force-with-lease`
- merge bottom-up. GitHub auto-retargets child PRs onto the grandparent when the parent merges and its branch is deleted. Repo keeps merged branches: retarget children by hand (`gh pr edit <n> --base <branch>`)
- exception: ship one ahead of the rest only when explicitly asked

Reviewers want the full arc visible at once (correctness -> parity -> speed). Piecemeal submission causes context-switching and lets early PRs merge before campaign direction is sanity-checked.

## Confluence updates

**Fetch first.** Always `getConfluencePage` immediately before `updateConfluencePage`, even if fetched earlier in same session. Pages get edited manually between sessions, stale content overwrites those edits.

**Preserve content.** Only edit specific sections. Never rewrite the whole body. Never summarize away paragraphs to shorten the page. If page is long, ask before condensing.
