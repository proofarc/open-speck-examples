# Tasks

## 1. Specify

- [x] 1.1 Write the `user-accounts` delta spec with WHEN/THEN scenarios
- [x] 1.2 Review scenarios for testability — each must name a status or a body claim

## 2. Bind each requirement to a test

- [x] 2.1 Account Update Persists → scenario 1526
- [x] 2.2 Usernames And Emails Are Unique → scenario 1531
- [x] 2.3 Anonymous Access Is Refused → scenario 1535
- [x] 2.4 Input Is Validated → scenario 1537 + data set v3.0
- [x] 2.5 Malformed Requests Are Handled → scenario 1534

## 3. Run and record

- [x] 3.1 Execute every bound scenario against environment 575
- [x] 3.2 Record scenario and execution ids in `verification/proofarc-evidence.md`
- [x] 3.3 Confirm endpoint coverage — 7/7 referenced, 7/7 asserted

## 4. Close the gaps the evidence exposed

- [ ] 4.1 Enforce uniqueness on `username` and `email`, return `409`
- [ ] 4.2 Apply the existing validator to `username`
- [ ] 4.3 Re-run scenarios 1531 and 1537 and update the evidence
- [ ] 4.4 Archive once every bound test is green
