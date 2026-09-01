# How the agent and ProofArc work together

A real run. Every call and every id below actually happened on 2026-09-01.

## First, the thing people get wrong

**ProofArc never reads your repo.** It never sees `spec.md`.

**The agent does the reading.** ProofArc gives it tools, stores what it makes, and runs it.

| who | does what |
|---|---|
| **The agent** | reads the spec, decides what to assert, calls the tools |
| **ProofArc** | supplies the recipes, stores the test, runs it, keeps the evidence |

Nothing is automatic. No parser turns markdown into a test.

---

## Step 1 — The agent reads the requirement

From `spec.md`:

```markdown
### Requirement: Anonymous Access Is Refused
The system SHALL refuse every unauthenticated request to the account endpoints.

#### Scenario: No credentials supplied
- **WHEN** a client requests `GET /api/users` with no `Authorization` header
- **THEN** the service responds `401` or `403`

#### Scenario: Malformed credentials supplied
- **WHEN** a client supplies a garbage bearer token or a `Basic` scheme
- **THEN** the service responds `401` or `403` in every case
```

Two scenarios. Remember that — it matters at step 4.

## Step 2 — The agent asks the platform what recipe fits

It sends the requirement **verbatim**. No rewriting.

```
act_on_intent(
  sentence = "The system SHALL refuse every unauthenticated request to the account
              endpoints. WHEN a client requests GET /api/users with no Authorization
              header THEN the service responds 401 or 403.",
  project = 673, environment = 575)
```

Back:

```json
{ "boundPlaybook": { "id": 20, "name": "auth-conformance",
                     "intent": "prove a protected endpoint requires auth (unauth -> 401/403)" },
  "candidates": [{ "id": 20, "score": 7,
                   "why": ["intent-ready","401","403","api","requests","unauthenticated"] }],
  "resolvedParams": [{ "key": "protectedPath", "value": "/api/users", "source": "DEFAULT" },
                     { "key": "flowName", "value": "Auth Conformance 142450", "source": "DEFAULT" }],
  "openQuestions": [{ "key": "appTag", "prompt": "App tag",
                      "options": ["starter-user-service-api","starter-user-service-web"] }] }
```

Three things to notice:

- **It matched on `401`, `403`, `unauthenticated`** — words the WHEN/THEN spells out. Score 7.
- **It resolved what it could** and left one open question — and offered the valid answers.
- **It shows its reasoning** in `why`, so a wrong match is visible rather than silent.

Worth being precise: `protectedPath` came from `source: DEFAULT`, not from the sentence. The playbook's default happens to be `/api/users`. The tool did not parse the path out of the WHEN clause.

## Step 3 — The platform writes the test

The agent answers the one open question and asks for the recipe to be filled in.

```
instantiate_playbook(playbook=20, project=673, environment=575,
  values={ "appTag": "starter-user-service-api",
           "protectedPath": "/api/users",
           "flowName": "OpenSpec REQ-AUTH-USERS — anonymous refused" })
```

Back — **the platform authored this, not the agent**:

```yaml
name: "OpenSpec REQ-AUTH-USERS — anonymous refused"
baseUrl: "{{baseUrl}}"
appTag: "starter-user-service-api"
steps:
- name: "unauthenticated request must be rejected"
  method: "GET"
  path: "/api/users"
  expect:
  - 401
  - 403
```

`scenarioId: 1565`, `valid: true`.

It also volunteered a gotcha it had learned before:

> **REQUISITE** — For login-based (BEARER) auth, wire the environment auth endpoint via
> `set_environment_auth_endpoint` — a credential tag alone supplies the secret, not the login flow.

## Step 4 — The agent notices the recipe is not enough

**This is the step that matters.**

The playbook produced **one** step. The spec has **two** scenarios. The second one — malformed credentials — is not covered.

A recipe cannot know that. It answered the intent it was given. Reading the spec and noticing the gap is the agent's job.

So the agent extends it:

```yaml
- name: "garbage bearer token must be rejected"
  method: "GET"
  path: "/api/users"
  headers:
    Authorization: "Bearer not-a-real-token"
  expect: [401, 403]
- name: "wrong auth scheme must be rejected"
  method: "GET"
  path: "/api/users"
  headers:
    Authorization: "Basic YWRtaW46YWRtaW4="
  expect: [401, 403]
```

Checks it first — this writes nothing, so it is free to iterate:

```
validate_scenario_yaml(...)  ->  { "valid": true, "errors": [] }
update_api_scenario_from_yaml(scenario=1565, ...)  ->  OK
```

## Step 5 — Run it

```
execute_scenario(scenario=1565, environment=575, allow_unauthenticated=true)
```

```
Scenario execution 1722: COMPLETED
Steps: 3/3 passed, total 55ms
  ✓ step 1: unauthenticated request must be rejected   → HTTP 403 (5ms)
  ✓ step 2: garbage bearer token must be rejected      → HTTP 403 (25ms)
  ✓ step 3: wrong auth scheme must be rejected         → HTTP 403 (4ms)
```

Both spec scenarios are now proven, with real status codes from a real server.

## Step 5b — Point the test back at the spec

A scenario in ProofArc should be readable on its own. Someone opening execution
1723 needs to find the requirement it proves without cloning this repo.

**The scenario carries a permalink**, stored in its `description`:

```
Proves requirement: Anonymous Access Is Refused
Spec: https://github.com/proofarc/open-speck-examples/blob/main/api/01-existing-api-contract/
      openspec/changes/add-user-account-management/specs/user-accounts/spec.md#requirement-anonymous-access-is-refused
Change: add-user-account-management
```

The anchor is built the way GitHub builds it: `### Requirement: Anonymous Access
Is Refused` lowercased, spaces to hyphens, colon dropped.

**The run carries tags**:

```
execute_scenario(scenario=1565, environment=575,
  tags=["openspec", "change:add-user-account-management",
        "req:anonymous-access-is-refused"])
```

`tags` must be a **list** — a comma-separated string is rejected.

**Why both.** The description is for a human. The tags make the requirement
re-runnable by name:

```
run_by_tag(tags=["req:anonymous-access-is-refused"], project=673,
           environment=575, dry_run=true)
```

```json
{ "would_queue": { "api_scenarios": [{ "id": 1565,
                     "name": "OpenSpec REQ-AUTH-USERS — anonymous refused" }] },
  "note": "API scenario matches are derived from execution history
           (scenarios have no static tags column yet)." }
```

Read that note carefully: **matches come from execution history**, so a scenario
never run with these tags cannot be found this way. Tag every run, not only the
first. And `dry_run` first — it returns the plan without executing.

Now the traceability runs both ways:

```
spec.md  ──(scenario description permalink)──▶  ProofArc scenario 1565
spec.md  ◀──(scenario + execution ids)────────  evidence file
requirement slug  ──(run tags)──▶  run_by_tag re-runs it on demand
```


## Step 6 — Record it against the requirement

```markdown
| requirement | scenario | execution | verdict |
|---|---|---|---|
| Anonymous Access Is Refused | 1565 | 1722 | PASS — 3/3 |
```

The change now carries evidence instead of an opinion.

---

## The whole exchange

```
agent   reads spec.md
agent → act_on_intent(requirement verbatim)
      ← playbook 20, score 7, one open question
agent   answers the question
agent → instantiate_playbook(20, values)
      ← scenario 1565, YAML written by the platform, plus a gotcha
agent   compares the test against the spec — finds a scenario not covered
agent → validate_scenario_yaml(extended)      free, writes nothing
      ← valid
agent → update_api_scenario_from_yaml(1565)
agent → execute_scenario(1565, tags=[req:..., change:...])
      ← execution 1723, 3/3 passed
agent   writes scenario + execution ids into the evidence file
```

Six calls. Two of them are the agent thinking, not the platform working.

## What each side is actually good at

**The platform is good at what it can know.**
Which recipe fits. What the API declares. Which credential to use. Whether the YAML is valid. What went wrong last time someone did this.

**The agent is good at what nobody wrote down.**
That the spec had two scenarios and the recipe covered one. That a `200` from an update does not prove the change persisted. That a negative test must probe `999999999` and not a real id.

**A useful test of the split:** if the answer is in the spec, the API, or the environment, the platform should supply it. If it takes judgement about what is worth proving, that is the agent.

## Without ProofArc

The agent would write a test file. It runs on one machine, proves nothing to anyone else, and disappears when that machine does.

With it, the test is a record: it has an id, it reruns on demand, anyone on the team can run it, and the requirement has evidence attached that outlives the session.
