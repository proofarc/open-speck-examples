# OpenSpec + ProofArc — specs that verify themselves

[OpenSpec](https://openspec.dev) writes requirements as `SHALL` statements with
**WHEN/THEN** scenarios. Those scenarios are acceptance criteria in every respect
except one: nothing executes them.

OpenSpec's verify step says so itself:

> *"validates that implementation aligns with change artifacts — **without running
> tests**. It reads code and makes reasoned judgments."*
> — `skills/openspec-verify-change/SKILL.md`

That is a sound default. It is fast, needs no environment, and for most changes it
is enough. This repo shows what to add when it is not.

**ProofArc turns each WHEN/THEN scenario into a stored, rerunnable test and gives
the change an execution id instead of an opinion.**

---

## The example, in one requirement

The spec states:

```markdown
### Requirement: Usernames And Emails Are Unique
The system SHALL reject an attempt to create an account whose username or email
already exists.

#### Scenario: Duplicate username
- **WHEN** a client creates an account with a username that already exists
- **THEN** the service responds `409`
- **AND** no second account is created
```

The bound test runs, and:

```
ok  Create once                                   201
!!  Create the same username again — expect 409    201
!!  Same email again — expect 409                  201
```

**The service accepts both duplicates.** The requirement is not met.

A static pass would very likely have marked this satisfied. There *is* validation
code, there *is* a create handler, and the words line up with the spec. The
constraint is simply absent, and only sending the same username twice reveals it.

Corroborated independently: after three runs of the validation matrix the
collection held `qa.localhost` three times, each with a distinct id.

---

## What is here

```
openspec/
  changes/add-user-account-management/
    proposal.md          why the change exists
    design.md            why verification runs rather than reads
    tasks.md             work, including the gaps the evidence exposed
    specs/user-accounts/
      spec.md            5 requirements, 11 WHEN/THEN scenarios
    verification/
      proofarc-evidence.md    <- the addition: scenario + execution ids
  schemas/spec-driven-verified/
    schema.yaml          stock spec-driven plus a `verification` artifact
    templates/
      verification.md    what the agent is told to do
```

## Results in this example

| requirement | test | verdict |
|---|---|---|
| Account Update Persists | scenario 1526 | **PASS** — 5/5 |
| Usernames And Emails Are Unique | scenario 1531 | **FAIL** — 2/4 |
| Anonymous Access Is Refused | scenario 1535 | **PASS** — 5/5 |
| Input Is Validated | scenario 1537 + 15-row data set | **PARTIAL** — 8/15 |
| Malformed Requests Are Handled | scenario 1534 | **PASS** — 5/5 |

Five requirements, eleven scenarios, **two requirements the service does not
meet**. Writing the spec is what surfaced them; running it is what proved them.

## How the schema works

OpenSpec schemas are a first-class extension point — YAML plus markdown
templates, no code. `spec-driven-verified` is the stock `spec-driven` schema with
one artifact appended, so an existing project can adopt it without rewriting
anything, and a change needing no runtime evidence produces an empty one.

```bash
cp -r openspec/schemas/spec-driven-verified <your-project>/openspec/schemas/
openspec schema validate spec-driven-verified
# then set it in openspec/config.yaml
```

The agent needs the ProofArc MCP server connected. Anything that speaks MCP —
Claude Code, Cursor, and most of OpenSpec's 40+ supported agents — can drive it.

## The division of labour

| | |
|---|---|
| **OpenSpec** | what we agreed to build, in reviewable prose |
| **ProofArc** | whether the running system actually does it |
| **The agent** | turning a WHEN/THEN clause into an assertion worth making |

Reading answers *"was it built?"*. Running answers *"does it do what we agreed?"*.

## One rule worth stealing

**Invert every assertion once and confirm it fails.** An assertion that passes
both ways is testing nothing — and it is invisible in a green suite. Every claim
in the evidence file was checked that way.
