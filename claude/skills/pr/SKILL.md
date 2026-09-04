---
name: pr
description: "Draft or update a pull request body in the house format (Motivation / Implementation / Results / optional Future work), for one PR or a whole stack. Use when asked to open a PR, write or fix a PR description, or submit a stack; also on /pr."
allowed-tools: Bash, Read, Grep, Glob
---

Write the PR body from what the branch actually changed. Never invent motivation.

## Gather first

- `git log --oneline <base>..HEAD` and `git diff --stat <base>..HEAD` for scope
- base branch: the parent PR's branch when stacking, else the default branch
- `gh pr view --json number,title,body,baseRefName` when the PR already exists
- read the diff of anything you cannot describe from the stat alone
- prior PR numbers worth citing: `git log` messages, linked issues, the base PR

## Format

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

Rules:

- lead with **Motivation** even on trivial PRs
- terse: shortest body that carries the facts. Cut anything the reviewer reads straight off the diff
- testing lives in **Results**. Never a separate `**Testing:**` section
- outputs live there too: when the PR existed to produce something (a dataset, a run, designs, artifacts), give the id or location, specific enough to fetch
- no Reviewers section, no @-mentions in the body: reviewers get tagged in the GitHub UI
- no Claude Code / Anthropic attribution footer. End with the last content section
- no em-dashes. Use colons, commas, parens, or `-`/`--`
- bullets flat by default. Nest only when a section has 2+ distinct groupings, each with 2+ bullets. No italic sub-headings

## Stacks

One branch per PR, each branched off its parent, GitHub native.

- `gh pr create --base <parent-branch>` so each diff shows only its own changes
- build and validate the whole stack locally first, then submit it all at once. Never piecemeal
- root PR body carries the campaign context. Children get a one-liner plus `Stacked on #N`
- rebase the stack with `git rebase --update-refs`, push with `--force-with-lease`
- merge bottom-up. GitHub retargets children onto the grandparent only when the parent branch is deleted on merge; otherwise `gh pr edit <n> --base <branch>` by hand

## Posting

- show the drafted body and ask before `gh pr create`. Creating a PR is visible to others
- updating the body or title of an existing PR is fine to do directly: `gh pr edit <n> --body-file -`
- replies to review threads and reactions always need a go-ahead first, bots included
