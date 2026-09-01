# Tasks

## 1. Validator

- [x] 1.1 Reject empty username, email and password
- [x] 1.2 Enforce email format
- [x] 1.3 Enforce minimum password length
- [x] 1.4 Enforce maximum username length
- [x] 1.5 Constrain `role` to USER and ADMIN
- [x] 1.6 Return `400` with field-level errors

## 2. Verify

- [x] 2.1 Bind every scenario to an executable test
- [x] 2.2 Run against the deployed service and record evidence

## 3. Gaps the evidence exposed

- [ ] 3.1 Apply the validator to `username` — it currently runs on every field except this one
- [ ] 3.2 Require a TLD in the email host, or state that `qa@localhost` is intentional
- [ ] 3.3 Re-run the matrix and update the evidence
- [ ] 3.4 Archive once every bound scenario is green
