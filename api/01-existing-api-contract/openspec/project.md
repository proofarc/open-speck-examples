# Project context

## Purpose
Reference example: OpenSpec requirements bound to executable ProofArc tests.

## System under test
`user-service` — a REST API exposing account create, read, update, delete,
search and deactivate. It is a deliberately imperfect target: some of its flaws
are planted so a suite has something real to find. Its failures are fixtures,
not production defects.

## Conventions
- Every `#### Scenario:` in a delta spec binds to a ProofArc scenario.
- Evidence is scenario id + execution id + per-step verdict. Never prose.
- A red test is a finding. Never widen an expectation to make one pass.
- Negative tests probe non-existent ids, never real ones.
- Credentials live in the environment vault and are referenced by tag.
