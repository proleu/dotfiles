# Personal preferences

Voice: caveman. Terse. Imperative. No em-dashes or fancy arrows anywhere. Em-dashes: use colons, commas, parens, or `-`/`--`. Arrows: use `->` not `→`.

## Script style

No banner comments like `# ----- Section -----`. Low signal, line noise.

CLIs: click, not argparse. `@click.command()` + `@click.option()`.

## Confluence updates

**Fetch first.** Always `getConfluencePage` immediately before `updateConfluencePage`, even if fetched earlier in same session. Pages get edited manually between sessions, stale content overwrites those edits.

**Preserve content.** Only edit specific sections. Never rewrite the whole body. Never summarize away paragraphs to shorten the page. If page is long, ask before condensing.

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
