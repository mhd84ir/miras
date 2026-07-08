---
description: Scaffold a new Architecture Decision Record in docs/adr/ and update its index
argument-hint: "<short decision title>"
allowed-tools: Bash, Read, Write, Edit, Grep, Glob
---

# Write an ADR

Title: $ARGUMENTS

An ADR here records a decision *already made*, in the project's own words —
it's not a tool for making the decision itself. All 6 existing ADRs in
`docs/adr/` are status `Accepted`; none were speculative. Read at least 2 of
them (e.g. `docs/adr/0001-*.md` and `docs/adr/0006-*.md`) before drafting, to
match the house voice: terse, concrete, comparative (rejected alternatives
named with a one-line reason each, not just the winner justified in
isolation).

## Steps

0. **Anchor to repo root** — `cd "$(git rev-parse --show-toplevel)"` — before
   any of the paths below (see the same cwd-drift caveat as the other
   project commands: Bash cwd persists across calls and these paths are
   repo-root-relative).

1. **Do you actually have a decision to record, or just a topic?** Check
   whether this conversation already contains the real substance: what
   alternatives were considered, which was chosen, why, and what it costs.
   If so, use that — don't re-ask for things already established. If not —
   if `$ARGUMENTS` names a topic ("crash reporting") rather than a settled
   decision — **don't invent the rationale yourself.** Ask the owner
   directly: what alternatives did you weigh, what did you pick, why, and
   what are the known tradeoffs? An ADR without a real decision behind it
   documents nothing. This mirrors how the project already works (see
   CLAUDE.md / memory: technical decisions get presented as compared options
   before being settled, not decided unilaterally) — this command formalizes
   an already-made call, it doesn't make one.

2. **Determine the next number.** `ls docs/adr/*.md`, find the highest
   `NNNN-*.md`, use the next one, zero-padded to 4 digits.

3. **Derive the filename**: `NNNN-<kebab-case-title>.md` — lowercase, spaces
   and punctuation to single hyphens, matching the existing files' pattern.

4. **Write `docs/adr/NNNN-<slug>.md`** in exactly this shape (Nygard
   template, house style — see the two files you read in step 0):

   ```markdown
   # ADR-NNNN: <Title>

   **Status:** Accepted (<today's date>)

   ## Context

   <What forces this decision — the problem, constraints, and the real
   candidates considered. A sentence or two, not a essay.>

   ## Decision

   Build/use/adopt **<the chosen thing>**.

   ## Rationale

   - <Each bullet: why the choice wins on a specific axis>
   - Rejected: **<alternative>** — <one-line reason it lost>. Repeat per
     rejected alternative actually considered — don't list alternatives
     nobody discussed just to look thorough.

   ## Consequences

   - <Real costs/tradeoffs/follow-on work this decision creates — including
     ones the owner may not love. An ADR that only lists upside is missing
     the point of the section.>
   ```

   Use `Accepted (<today>)` unless the owner says the decision isn't final
   yet, in which case use `Proposed (<today>)` — but flag that this repo has
   no precedent for that status and ask if they actually want a
   not-yet-decided ADR on record, or want to finish deciding first.

5. **Update `docs/adr/README.md`'s table**, inserting a new row in numeric
   order (matching the existing `| [NNNN](NNNN-slug.md) | Title | Status |`
   format) — don't just append; keep it sorted.

6. **Show the finished file and index update** and say plainly that ADRs are
   "immutable once accepted" per this repo's own convention (docs/adr/README.md)
   — worth a real read before moving on, not a rubber stamp.
