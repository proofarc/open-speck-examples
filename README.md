# OpenSpec + ProofArc — worked examples

[OpenSpec](https://openspec.dev) writes requirements as `SHALL` statements with
**WHEN/THEN** scenarios. Those scenarios are acceptance criteria in every respect
but one: nothing executes them.

Its verify step says so plainly:

> *"validates that implementation aligns with change artifacts — **without running
> tests**. It reads code and makes reasoned judgments."*
> — `skills/openspec-verify-change/SKILL.md`

That is the right default: fast, no environment needed, and enough for most
changes. These examples show what to add when it is not.

**ProofArc binds each WHEN/THEN scenario to a stored, rerunnable test, so the
change carries an execution id instead of an opinion.**

## Where this fits in the loop

```
/opsx:explore → /opsx:propose → /opsx:apply → [ verify ] → /opsx:archive
                                                  ^
                                     one slot, right here
```

Not a replacement for static verify. An additional artifact for the requirements
whose failure looks like success in the source.

## Examples

| | scope | what it demonstrates |
|---|---|---|
| [`api/01-existing-api-contract`](api/01-existing-api-contract) | brownfield — pin down an API that already exists | a `SHALL` the service contradicts: duplicate usernames accepted `201` twice |
| [`api/02-new-feature-validation`](api/02-new-feature-validation) | the normal loop — propose, apply, verify | every task done, validator correct, and **never applied to one field** |

`ui/` and `mobile/` are placeholders — the same schema applies, with the scenario
bound to a UI or mobile test instead of an API one.

**Start with 02.** It is the loop most people actually run, and its finding lives
in the change being verified rather than in pre-existing code.

## What both examples share

Both use `spec-driven-verified` — the stock `spec-driven` schema with a single
artifact appended:

```yaml
- id: verification
  template: verification.md
  requires: [specs, tasks]
```

Additive, so an existing project adopts it by copying a folder, and a change that
needs no runtime evidence produces an empty one.

```bash
cp -r openspec/schemas/spec-driven-verified <your-project>/openspec/schemas/
openspec schema validate spec-driven-verified
# then set it in openspec/config.yaml
```

The agent needs the ProofArc MCP server connected. Anything that speaks MCP —
Claude Code, Cursor, and most of OpenSpec's 40+ supported agents — can drive it.

## Honest scope

This is for changes that touch **a running service**. WHEN/THEN scenarios that
already name an HTTP verb, a path and a status code cost almost nothing to bind —
they are the same sentence in a different grammar. A change to a pure-logic module
or a component's styling is not the case for this, and pretending otherwise would
waste the reader's time.

## The division of labour

| | |
|---|---|
| **OpenSpec** | what we agreed to build, in reviewable prose |
| **ProofArc** | whether the running system actually does it |
| **The agent** | turning a WHEN/THEN clause into an assertion worth making |

Reading answers *"was it built?"*. Running answers *"does it do what we agreed?"*.

## One rule worth stealing

**Invert every assertion once and confirm it fails.** An assertion that passes
both ways is testing nothing, and it is invisible in a green suite. Every claim in
these evidence files was checked that way.
