# Example 2 — verifying a feature the agent just built

This is the common OpenSpec loop:

```
/opsx:propose "add account input validation"
/opsx:apply          # the agent writes the validator
/opsx:verify         # <- reads the code and judges
/opsx:archive
```

The change is small, the tasks are all checked, and the implementation is real.
A static verify pass has every reason to approve it.

## What running the scenarios found

```
Required Fields Are Present    PASS       3/3 rows
Field Formats Are Enforced     PARTIAL    5/6 rows
Injection Payloads Are Refused FAIL       0/5 rows
Role Is Constrained            PASS
```

**The validator exists, works, and is never applied to `username`.**

The proof is one request with a different field made hostile each time:

| field | hostile value | result |
|---|---|---|
| `role` | `AUDITOR` | **400** with a field-level error |
| `email` | `not-an-email` | **400** |
| `password` | `abc12` | **400** |
| `username` | `../../../../etc/passwd` | **201, stored** |

Same endpoint, same handler, same validator. Three fields guarded, one not.

## Why static verification would pass this

Every task is genuinely done. There *is* validation code. It *does* return
field-level errors. It matches the spec keyword for keyword. Searching the
codebase for "validation" finds it immediately and it looks correct — because it
is correct. The defect is not in the validator; it is that one field never
reaches it.

That gap is invisible to reading and obvious to running.

## Why one scenario, not fifteen

The requirements describe one endpoint with many inputs, so they bind to a single
scenario driven by a data set: **one request per row, one verdict per row**. A
failing row does not stop the others, so a single run reports all fifteen cases
instead of stopping at the first.

## What this costs

One scenario, one data set, one run. The scenarios were already written — they
are the `#### Scenario:` blocks in the spec. Binding them is transcription, not
design.

## Files

```
openspec/changes/add-account-input-validation/
  proposal.md
  tasks.md                                 tasks 1.x checked, 3.x are the gaps found
  specs/user-accounts/spec.md              4 requirements, 10 WHEN/THEN scenarios
  verification/proofarc-evidence.md        the evidence
openspec/schemas/spec-driven-verified/     the schema that adds the artifact
```
