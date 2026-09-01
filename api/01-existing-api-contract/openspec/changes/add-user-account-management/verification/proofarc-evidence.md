# Verification evidence — ProofArc

Every scenario in `specs/user-accounts/spec.md` is bound to an executable test in
ProofArc. This file is generated from real runs; the ids resolve to stored
executions with per-step requests and responses.

Project 673 · environment 575 (`user-service-demo-env`) · captured 2026-09-01.

## Summary

| requirement | scenarios | test | verdict |
|---|---|---|---|
| Account Update Persists | 3 | scenario 1526 | **PASS** — 5/5 |
| Usernames And Emails Are Unique | 2 | scenario 1531 | **FAIL** — 2/4 |
| Anonymous Access Is Refused | 2 | scenario 1535 | **PASS** — 5/5 |
| Input Is Validated | 2 | scenario 1537 + dataset v3.0 | **PARTIAL** — 8/15 |
| Malformed Requests Are Handled | 2 | scenario 1534 | **PASS** — 5/5 |

**Not ready to archive.** One requirement is contradicted by the service and one
is only partly met.

---

## Requirement: Account Update Persists — PASS

Scenario 1526, execution 1680, 5/5.

| spec scenario | step | result |
|---|---|---|
| Update changes the stored record | Update it | 200 |
| The change survives a re-read | Read it back | 200 |
| Updating an account that does not exist | Ghost id refused | 404 |

Assertions proving the clauses: `$.username` and `$.email` equal the new values,
`$.updatedAt` exists, **`$.password` does not exist**, `Content-Type` contains
`application/json`, and response time under 2000 ms.

The re-read step is what makes this a test of the requirement rather than of the
endpoint: a `200` from `PUT` does not prove the change persisted.

---

## Requirement: Usernames And Emails Are Unique — FAIL

Scenario 1531, execution 1681, 2/4.

```
ok  Create once                                   201
!!  Create the same username again — expect 409    201
!!  Same email again — expect 409                  201
ok  Clean up                                       200
```

**The spec says SHALL reject. The service accepts.** Both duplicate creates
returned `201` and produced additional accounts.

Corroborated independently: after three runs of the validation matrix the
collection held `qa.localhost` three times and `qa'; DROP TABLE users;--` three
times, each with a distinct id. Uniqueness is not enforced on either field.

**This is the case worth reading twice.** A static verification pass — reading
the code, matching keywords, mapping scenarios to files — would very likely mark
this requirement satisfied. There is validation code, there is a create handler,
the words line up. Only executing it shows that the constraint is absent.

---

## Requirement: Anonymous Access Is Refused — PASS

Scenario 1535, execution 1682, 5/5. Every case answered `403`.

```
No Authorization header at all                     403
Garbage bearer token                               403
Wrong auth scheme (Basic)                          403
Empty bearer value                                 403
Write without a token, on a non-existent id        403
```

The write probe targets `999999999` deliberately: a negative test must be
harmless the one time its assumption is wrong.

---

## Requirement: Input Is Validated — PARTIAL

Scenario 1537 with data set `Rejection matrix - POST /api/users` v3.0, run 55.
One request per row, one verdict per row: **8 of 15 correctly refused.**

| case | expected | actual |
|---|---|---|
| blank username / email / password | 400 | refused |
| whitespace-only email, no `@`, double `@` | 400 | refused |
| password under 6 chars, username 265 chars | 400 | refused |
| email with no TLD (`qa@localhost`) | 400 | **accepted 201** |
| SQL injection in username | 400 | **accepted 201** |
| XSS script tag in username | 400 | **accepted 201** |
| template injection `${7*7}` | 400 | **accepted 201** |
| path traversal in username | 400 | **accepted 201** |
| CRLF header injection in username | 400 | **accepted 201** |

The first clause of the requirement holds; the second does not. Every rejected
case is an email or password rule — **the validator works and simply does not run
on `username`.**

Sharpened by a separate run: `role` *is* checked against an enum
(`role must be one of: USER, ADMIN`) on the same request where `username` accepts
a path traversal unchanged. One field guarded, the other not.

---

## Requirement: Malformed Requests Are Handled — PASS

Scenario 1534, execution 1683, 5/5.

```
Body is not JSON at all                    400
Content-Type is text/plain                 415
No body at all on a create                 400
PUT on a collection                        405
Unknown route                              404
```

No `500` anywhere.

---

## How to re-run

```
execute_scenario(scenario=1526, environment=575)
execute_scenario(scenario=1531, environment=575)
execute_scenario(scenario=1534, environment=575)
execute_scenario(scenario=1535, environment=575, allow_unauthenticated=true)
run_data_driven(name="Rejection matrix - POST /api/users", version="v3.0",
                environment=575, credential_tag="api-admin")
```

Every id above is a stored record. Anyone on the team can re-run them, and each
run appends to the same history rather than producing a new opinion.
