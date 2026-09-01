# Binding — repo ↔ ProofArc

This repo and the ProofArc project reference each other. Both directions are
recorded so neither side has to guess.

## Platform → repo

Application **404** (`starter-user-service-api`) carries:

```
repoPath        starter/api-test/open-speck-examples
description     …Specs: OpenSpec change artifacts and ProofArc verification
                evidence live at repo_path.
gitUrl          (unset — no remote yet)
```

When a remote exists, set `git_url`, `git_provider` and `default_branch` on the
same application with `update_application`. Nothing else on that record should
change: `appTag`, `authRequirement` and `swaggerPath` drive target resolution and
the API digest.

## Repo → platform

| what | value |
|---|---|
| ProofArc project | **673** — `User Service — starter demo` |
| Application | **404** — `starter-user-service-api` (appTag `starter-user-service-api`) |
| Environment | **575** — `user-service-demo-env` |
| Target | **479** — `user-service API — demo` |
| Credential tag | `api-admin` |

The service under test is a deliberately imperfect demo target. Some of its
flaws are planted so a suite has something real to find; its failures are
fixtures, not production defects.

## How a requirement finds its test

Bindings are derived from the spec, so they are identical on every machine:

```
name  "[<change-id>] <Requirement Name>"
tags  openspec, change:<change-id>, req:<requirement-slug>
```

Look up before creating:

```
find_scenarios(project=673, tags=["req:injection-payloads-are-refused"])
```

Two guards prevent duplicates: scenario names are unique per project (a repeat
create returns HTTP 409), and each change's `verification/proofarc-evidence.md`
records the scenario ids it bound.

## Re-running verification

```
run_by_tag(tags=["change:add-account-input-validation"], project=673,
           environment=575, dry_run=true)
```

`dry_run` first — it returns the queueing plan without executing.

## Rules that outrank convenience

- **A red test is the finding.** Never widen an expectation or delete a bound
  scenario to make a change archivable.
- **Never write a credential into a scenario.** Reference `api-admin` by tag.
- **Negative tests probe non-existent ids** (`999999999`), never real ones.
- **Invert every assertion once** and confirm it fails before trusting it.
