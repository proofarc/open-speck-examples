# Add user account management

## Why

The user service exposes account creation, update, search and deactivation, but
nothing states what those endpoints are required to do. Behaviour has been
inferred from the OpenAPI document, which declares no security at all and no
response schema for four of seven operations — so the contract has been guessed
rather than agreed.

This change writes the contract down, and binds every clause to a test that runs.

## What changes

- Specify account update, uniqueness, authentication, input validation and
  malformed-request handling as requirements with WHEN/THEN scenarios.
- Bind each scenario to an executable ProofArc scenario.
- Record the evidence in `verification/proofarc-evidence.md` with scenario and
  execution ids.

## Impact

- Affected specs: `user-accounts`
- Affected code: `POST /api/users`, `PUT /api/users/{id}`, `GET /api/users`,
  `GET /api/users/search`, `PATCH /api/users/{id}/deactivate`
- **Two requirements are currently unmet** — see the evidence file. Writing the
  spec is what surfaced them.
