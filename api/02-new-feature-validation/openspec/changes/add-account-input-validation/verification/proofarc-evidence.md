# Verification evidence — ProofArc

Project 673 · environment 575 · run 56 · captured 2026-09-01.

## Summary

| requirement | scenarios | verdict |
|---|---|---|
| Required Fields Are Present | 1 | **PASS** — 3/3 rows |
| Field Formats Are Enforced | 3 | **PARTIAL** — 5/6 rows |
| Injection Payloads Are Refused | 5 | **FAIL** — 0/5 rows |
| Role Is Constrained | 1 | **PASS** |

**Not ready to archive.** Tasks 1.1–1.6 are checked, and the validator does exist
and does work. It is simply never applied to `username`.

---

## Bindings

The durable record of which test proves which requirement. Read this before
searching the platform; re-running verification reuses these, never recreates.

| requirement | scenario | tag |
|---|---|---|
| Required Fields Are Present | 1537 (data set v3.0, rows 1-3) | `req:required-fields-are-present` |
| Field Formats Are Enforced | 1537 (rows 4-9) | `req:field-formats-are-enforced` |
| Injection Payloads Are Refused | 1537 (rows 10-15) | `req:injection-payloads-are-refused` |
| Role Is Constrained | 1537 (enum probe) | `req:role-is-constrained` |

All four requirements bind to one scenario because they describe one endpoint;
the data set separates the cases. A requirement needing its own request shape
gets its own scenario.

Lookup, on any machine:

```
find_scenarios(project=673, tags=["req:injection-payloads-are-refused"])
```

Creating a duplicate is refused: scenario names are unique per project, so a
second create with the same name returns HTTP 409.


## Method

The four requirements describe one endpoint with many inputs, so they bind to a
single scenario driven by a data set — one request per row, one verdict per row.

Scenario 1537, data set `Rejection matrix - POST /api/users` v3.0, 15 rows.
A failing row does not stop the others, so every case is reported.

**8 of 15 correctly refused.**

---

## Requirement: Required Fields Are Present — PASS

| row | expected | actual |
|---|---|---|
| blank username | 400 | refused |
| blank email | 400 | refused |
| blank password | 400 | refused |

---

## Requirement: Field Formats Are Enforced — PARTIAL

| row | expected | actual |
|---|---|---|
| whitespace-only email | 400 | refused |
| email with no `@` | 400 | refused |
| email with double `@` | 400 | refused |
| password under 6 chars | 400 | refused |
| username 265 chars | 400 | refused |
| **email with no TLD** (`qa@localhost`) | 400 | **accepted 201** |

The length and password rules hold. One email case slips through an otherwise
working validator — `qa@localhost` is syntactically valid but has no TLD. Decide
whether that is intentional; if it is, the spec should say so.

---

## Requirement: Injection Payloads Are Refused — FAIL

**Every row failed. Not one payload was refused.**

| row | expected | actual |
|---|---|---|
| SQL injection in username | 400 | **accepted 201** |
| SQL payload as username | 400 | **accepted 201** |
| XSS script tag in username | 400 | **accepted 201** |
| template injection `${7*7}` | 400 | **accepted 201** |
| path traversal in username | 400 | **accepted 201** |
| CRLF header injection in username | 400 | **accepted 201** |

Each was stored verbatim as a username and is retrievable through `GET /api/users`.

---

## Requirement: Role Is Constrained — PASS

Same endpoint, same request shape:

```
POST /api/users   { "username": "role-xxxxx", "role": "AUDITOR", ... }
→ 400
{"error":"VALIDATION_FAILED","code":"VAL_001",
 "fieldErrors":[{"field":"role","message":"role must be one of: USER, ADMIN"}]}
```

---

## The finding, stated precisely

**The validator is present, correct, and not wired to `username`.**

That sentence is only available because the same request was sent twice with
different fields hostile:

| field | hostile value | result |
|---|---|---|
| `role` | `AUDITOR` | **400**, field-level error |
| `email` | `not-an-email` | **400** |
| `password` | `abc12` | **400** |
| `username` | `../../../../etc/passwd` | **201, stored** |

One request, one handler, one validator — three fields guarded and one not.

This is what a static verification pass would most likely miss. Tasks 1.1–1.6 are
genuinely implemented; there is validation code, it returns field-level errors,
and it matches the spec keyword for keyword. Reading it gives every reason to
believe the requirement is met. Only sending the payload shows that one field
never reaches it.

---

## How to re-run

```
run_data_driven(name="Rejection matrix - POST /api/users", version="v3.0",
                environment=575, credential_tag="api-admin")
```

Each row is a stored execution with its own request and response.

**Cleanup note:** the seven wrongly-accepted rows create real accounts on every
run. A failed step does not run its `extract:` block, so the new ids cannot be
captured in-scenario. Purge them after each run until 3.1 is fixed.
