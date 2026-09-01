# Add account input validation

## Why

`POST /api/users` accepts whatever it is given. Before this change there was no
agreement on what a valid account looks like, so every client invented its own
rules and the service enforced none of them consistently.

## What changes

- Reject empty and malformed field values.
- Reject values that carry an injection payload.
- Constrain `role` to the values the system actually supports.
- Return `400` with a field-level error naming what failed.

## Impact

- Affected specs: `user-accounts`
- Affected code: the create handler and its request validator
